//
//  FSVideoEncoder.m
//  FSAVDemo
//
//  Created by louis on 2022/7/15.
//

#import "FSVideoEncoder.h"
#import <VideoToolBox/VideoToolBox.h>
#import <UIKit/UIKit.h>

#define FSEncoderRetrySessionMaxCount 5
#define FSEncoderEncodeFrameFailedMaxCount 20

@interface FSVideoEncoder ()

@property (nonatomic, assign) VTCompressionSessionRef compressionSession;
@property (nonatomic, strong, readwrite) FSVideoEncoderConfig *config; // 视频编码配置参数
@property (nonatomic, strong) dispatch_queue_t encoderQueue;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, assign) BOOL needRefreshSession; // 是否需要刷新重建编码器
@property (nonatomic, assign) NSInteger retrySessionCount; // 刷新重建编码器的次数
@property (nonatomic, assign) NSInteger encodeFrameFailedCount; // 编码失败次数

@end

@implementation FSVideoEncoder

#pragma mark - LifeCycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    [self _releaseCompressionSession];
    dispatch_semaphore_signal(_semaphore);
}

- (instancetype)initWithConfig:(FSVideoEncoderConfig *)config {
    self = [super init];
    if (self) {
        _config = config;
        _encoderQueue = dispatch_queue_create("com.louis.videoEncoder", DISPATCH_QUEUE_SERIAL);
        _semaphore = dispatch_semaphore_create(1);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    
    return self;
}

#pragma mark - Public Method

- (void)refresh {
    self.needRefreshSession = YES; // 标记位待刷新重建编码器
}

- (void)flush {
    // 清空编码缓冲区
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.encoderQueue, ^{
        dispatch_semaphore_wait(weakSelf.semaphore, DISPATCH_TIME_FOREVER);
        [weakSelf _flush];
        dispatch_semaphore_signal(weakSelf.semaphore);
    });
}

- (void)flushWithCompleteHandler:(void (^)(void))completeHandler {
    // 清空编码缓冲区并回调完成
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.encoderQueue, ^{
        dispatch_semaphore_wait(weakSelf.semaphore, DISPATCH_TIME_FOREVER);
        [weakSelf _flush];
        dispatch_semaphore_signal(weakSelf.semaphore);
        if (completeHandler) {
            completeHandler();
        }
    });
}
/// 编码器的输入是 CVPixelBuffer 类型的结构体，输出是 CMSampleBuffer 类型的结构体
/// CVPixelBufferRef 是准备待编码的视频数据
- (void)encodePixelBuffer:(CVPixelBufferRef)pixelBuffer ptsTime:(CMTime)timeStamp {
    // 编码
    if (!pixelBuffer || self.retrySessionCount >= FSEncoderRetrySessionMaxCount || self.encodeFrameFailedCount >= FSEncoderEncodeFrameFailedMaxCount) {
        return;
    }
    
    CFRetain(pixelBuffer);
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.encoderQueue, ^{
        dispatch_semaphore_wait(weakSelf.semaphore, DISPATCH_TIME_FOREVER);
        OSStatus setupStatus = noErr;
        // 1、如果还没创建过编码器或者需要刷新重建编码器，就创建编码器
        if (!weakSelf.compressionSession || weakSelf.needRefreshSession) {
            [weakSelf _releaseCompressionSession];
            setupStatus = [weakSelf _setupCompressionSession];
            // 支持重试，记录重试次数
            weakSelf.retrySessionCount = setupStatus == noErr ? 0 : (weakSelf.retrySessionCount + 1);
            if (setupStatus != noErr) {
                [weakSelf _releaseCompressionSession];
                NSLog(@"FSVideoEncoder setupCompressionSession error:%d", setupStatus);
            } else {
                weakSelf.needRefreshSession = NO;
            }
        }
        
        // 重试超过 FSEncoderRetrySessionMaxCount 次仍然失败则认为创建失败，报错
        if (!weakSelf.compressionSession) {
            CFRelease(pixelBuffer);
            dispatch_semaphore_signal(weakSelf.semaphore);
            if (weakSelf.retrySessionCount >= FSEncoderRetrySessionMaxCount && weakSelf.errorCallBack) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.errorCallBack([NSError errorWithDomain:NSStringFromClass([FSVideoEncoder class]) code:setupStatus userInfo:nil]);
                });
            }
            return;
        }
        
        // 2、对 pixelBuffer 进行编码
        VTEncodeInfoFlags flags;
        OSStatus encodeStatus = VTCompressionSessionEncodeFrame(weakSelf.compressionSession, pixelBuffer, timeStamp, CMTimeMake(1, (int32_t) weakSelf.config.fps), NULL, NULL, &flags);
        if (encodeStatus == kVTInvalidSessionErr) {
            // 编码失败进行重建编码器重试
            [weakSelf _releaseCompressionSession];
            setupStatus = [weakSelf _setupCompressionSession];
            weakSelf.retrySessionCount = setupStatus == noErr ? 0 : (weakSelf.retrySessionCount + 1);
            if (setupStatus == noErr) {
                encodeStatus = VTCompressionSessionEncodeFrame(weakSelf.compressionSession, pixelBuffer, timeStamp, CMTimeMake(1, (int32_t) weakSelf.config.fps), NULL, NULL, &flags);
            } else {
                [weakSelf _releaseCompressionSession];
            }
            
            NSLog(@"FSVideoEncoder kVTInvalidSessionErr");
        }
        // 记录编码失败次数
        if (encodeStatus != noErr) {
            NSLog(@"FSVideoEncoder VTCompressionSessionEncodeFrame error:%d", encodeStatus);
        }
        weakSelf.encodeFrameFailedCount = encodeStatus == noErr ? 0 : (weakSelf.encodeFrameFailedCount + 1);
        
        CFRelease(pixelBuffer);
        dispatch_semaphore_signal(weakSelf.semaphore);
        
        // 编码失败次数超过 FSEncoderEncodeFrameFailedMaxCount 次，报错
        if (weakSelf.encodeFrameFailedCount >= FSEncoderEncodeFrameFailedMaxCount && weakSelf.errorCallBack) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.errorCallBack([NSError errorWithDomain:NSStringFromClass([FSVideoEncoder class]) code:encodeStatus userInfo:nil]);
            });
        }
    });
}

#pragma mark - Privte Method

/**
 创建编码器，配置编解码参数：根据需要配置视频编解码参数，例如视频分辨率、帧率、码率、编码格式等。
 常用的 VideoToolbox 参数包括：

 kCVPixelBufferPixelFormatTypeKey：指定像素格式，例如 kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange 表示 YUV 格式。

 kVTCompressionPropertyKey_ProfileLevel：指定编码的 H.264 等级和配置文件。

 kVTCompressionPropertyKey_AverageBitRate：指定编码的平均比特率。

 kVTCompressionPropertyKey_MaxKeyFrameInterval：指定关键帧的最大间隔。

 kVTDecompressionPropertyKey_UsingHardwareAcceleratedVideoDecoder：指定是否使用硬件加速解码。

 kVTDecompressionPropertyKey_OutputPixelFormat：指定解码输出的像素格式。
 */
- (OSStatus)_setupCompressionSession {
    if (_compressionSession) {
        return noErr;
    }
    
    // 1、创建视频编码器实例
    // 这里要设置画面尺寸、编码器类型、编码数据回调
    OSStatus status = VTCompressionSessionCreate(NULL, _config.size.width, _config.size.height, _config.codecType, NULL, NULL, NULL, encoderOutputCallback, (__bridge void *) self, &_compressionSession);
    if (status != noErr) {
        NSLog(@"Failed to create compression session with error %d", (int)status);
        return status;
    }
    
    // 2、设置编码器属性：实时编码
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_RealTime, (__bridge CFTypeRef) @(YES));
    
    // 3、设置编码器属性：编码 profile
    status = VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_ProfileLevel, (__bridge CFStringRef) self.config.profile);
    if (status != noErr) {
        return status;
    }
    
    // 4、设置编码器属性：是否支持 B 帧
    status = VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_AllowFrameReordering, (__bridge CFTypeRef) @(self.config.openBFrame));
    if (status != noErr) {
        return status;
    }
    
    if (self.config.codecType == kCMVideoCodecType_H264) {
        // 5、如果是 H.264 编码，设置编码器属性：熵编码类型为 CABAC，上下文自适应的二进制算术编码
        status = VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_H264EntropyMode, kVTH264EntropyMode_CABAC);
        if (status != noErr) {
            return status;
        }
    }
    
    // 6、设置编码器属性：画面填充模式
    NSDictionary *transferDic= @{
        (__bridge NSString *) kVTPixelTransferPropertyKey_ScalingMode: (__bridge NSString *) kVTScalingMode_Letterbox,
    };
    status = VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_PixelTransferProperties, (__bridge CFTypeRef) (transferDic));
    if (status != noErr) {
        return status;
    }
    
    // 7、设置编码器属性：平均码率
    status = VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef) @(self.config.bitrate));
    if (status != noErr) {
        return status;
    }
    
    // 8、设置编码器属性：码率上限
    if (!self.config.openBFrame && self.config.codecType == kCMVideoCodecType_H264) {
        NSArray *limit = @[@(self.config.bitrate * 1.5 / 8), @(1)];
        status = VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef) limit);
        if (status != noErr) {
            return status;
        }
    }
    
    // 9、设置编码器属性：期望帧率
    status = VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef) @(self.config.fps));
    if (status != noErr) {
        return status;
    }
    
    // 10、设置编码器属性：最大关键帧间隔帧数，也就是 GOP 帧数
    status = VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef) @(self.config.gopSize));
    if (status != noErr) {
        return status;
    }
    
    // 11、设置编码器属性：最大关键帧间隔时长
    status = VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, (__bridge CFTypeRef)@(_config.gopSize / _config.fps));
    if (status != noErr) {
        return status;
    }
    
    // 12、预备编码
    status = VTCompressionSessionPrepareToEncodeFrames(_compressionSession);
    return status;
}

- (void)_releaseCompressionSession {
    if (_compressionSession) {
        // 强制处理完所有待编码的帧
        VTCompressionSessionCompleteFrames(_compressionSession, kCMTimeInvalid);
        // 销毁编码器
        VTCompressionSessionInvalidate(_compressionSession);
        CFRelease(_compressionSession);
        _compressionSession = NULL;
    }
}

- (void)_flush {
    // 清空编码缓冲区
    if (_compressionSession) {
        // 传入 kCMTimeInvalid 时，强制处理完所有待编码的帧，清空缓冲区
        VTCompressionSessionCompleteFrames(_compressionSession, kCMTimeInvalid);
    }
}

#pragma mark - NSNotification

- (void)didEnterBackground:(NSNotification *)notification {
    self.needRefreshSession = YES; // 退后台回来后需要刷新重建编码器
}

#pragma mark - EncoderOutputCallback

static void encoderOutputCallback(void * CM_NULLABLE outputCallbackRefCon,
                                  void * CM_NULLABLE sourceFrameRefCon,
                                  OSStatus status,
                                  VTEncodeInfoFlags infoFlags,
                                  CMSampleBufferRef sampleBuffer) {
    if (!sampleBuffer) {
        if (infoFlags & kVTEncodeInfo_FrameDropped) {
            NSLog(@"VideoToolboxEncoder kVTEncodeInfo_FrameDropped");
        }
        return;
    }
    
    // 向外层回调编码数据
    FSVideoEncoder *videoEncoder = (__bridge FSVideoEncoder *) outputCallbackRefCon;
    if (videoEncoder && videoEncoder.sampleBufferOutputCallBack) {
        videoEncoder.sampleBufferOutputCallBack(sampleBuffer);
    }
}

@end
