//
//  FSVideoEncoderVC.m
//  FSAVDemo
//
//  Created by louis on 2022/7/14.
//

#import "FSVideoEncoderVC.h"
#import "FSVideoPacketExtraData.h"
#import "FSVideoCapture.h"
#import "FSVideoEncoder.h"

@interface FSVideoEncoderVC ()

@property (nonatomic, strong) FSVideoCaptureConfig *videoCaptureConfig;
@property (nonatomic, strong) FSVideoCapture *videoCapture;
@property (nonatomic, strong) FSVideoEncoderConfig *videoEncoderConfig;
@property (nonatomic, strong) FSVideoEncoder *videoEncoder;
@property (nonatomic, assign) BOOL isEncoding;

@property (nonatomic, strong) UIBarButtonItem *startBarButton;

@end

@implementation FSVideoEncoderVC

#pragma mark - Lifecycle

- (void)dealloc {}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Navigation item.
    self.startBarButton = [[UIBarButtonItem alloc] initWithTitle:self.startTitle style:UIBarButtonItemStylePlain target:self action:@selector(start)];
    UIBarButtonItem *cameraBarButton = [[UIBarButtonItem alloc] initWithTitle:@"切换" style:UIBarButtonItemStylePlain target:self action:@selector(changeCamera)];
    self.navigationItem.rightBarButtonItems = @[self.startBarButton, cameraBarButton];
    
    [self requestAccessForVideo];
    
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    doubleTapGesture.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:doubleTapGesture];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.videoCapture.previewLayer.frame = self.view.bounds;
}

#pragma mark - Action
- (void)start {
    if (!self.isEncoding) {
        self.isEncoding = YES;
        [self.startBarButton setTitle:self.stopTitle];
        [self.videoEncoder refresh];
    } else {
        self.isEncoding = NO;
        [self.startBarButton setTitle:self.startTitle];
        [self.videoEncoder flush];
    }
}

- (void)onCameraSwitchButtonClicked:(UIButton *)button {
    [self.videoCapture changeDevicePosition:self.videoCapture.config.position == AVCaptureDevicePositionBack ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack];
}

- (void)changeCamera {
    [self.videoCapture changeDevicePosition:self.videoCapture.config.position == AVCaptureDevicePositionBack ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack];
}

-(void)handleDoubleTap:(UIGestureRecognizer *)sender {
    [self.videoCapture changeDevicePosition:self.videoCapture.config.position == AVCaptureDevicePositionBack ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack];
}

#pragma mark - Private Method

- (void)requestAccessForVideo{
    __weak typeof(self) weakSelf = self;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusNotDetermined: {
            // 许可对话没有出现，发起授权许可
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    [weakSelf.videoCapture startRunning];
                } else {
                    // 用户拒绝
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            // 已经开启授权，可继续
            [weakSelf.videoCapture startRunning];
            break;
        }
        default:
            break;
    }
}

- (FSVideoPacketExtraData *)getPacketExtraData:(CMSampleBufferRef)sampleBuffer {
    // 从 CMSampleBuffer 中获取 extra data
    if (!sampleBuffer) {
        return nil;
    }
    
    // 获取编码类型
    CMVideoCodecType codecType = CMVideoFormatDescriptionGetCodecType(CMSampleBufferGetFormatDescription(sampleBuffer));
    
    FSVideoPacketExtraData *extraData = nil;
    if (codecType == kCMVideoCodecType_H264) {
        // 获取 H.264 的 extra data：sps、pps
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0);
        if (statusCode == noErr) {
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0);
            if (statusCode == noErr) {
                extraData = [[FSVideoPacketExtraData alloc] init];
                extraData.sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                extraData.pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
            }
        }
    } else if (codecType == kCMVideoCodecType_HEVC) {
        // 获取 H.265 的 extra data：vps、sps、pps
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        size_t vparameterSetSize, vparameterSetCount;
        const uint8_t *vparameterSet;
        if (@available(iOS 11.0, *)) {
            OSStatus statusCode = CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(format, 0, &vparameterSet, &vparameterSetSize, &vparameterSetCount, 0);
            if (statusCode == noErr) {
                size_t sparameterSetSize, sparameterSetCount;
                const uint8_t *sparameterSet;
                OSStatus statusCode = CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(format, 1, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0);
                if (statusCode == noErr) {
                    size_t pparameterSetSize, pparameterSetCount;
                    const uint8_t *pparameterSet;
                    OSStatus statusCode = CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(format, 2, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0);
                    if (statusCode == noErr) {
                        extraData = [[FSVideoPacketExtraData alloc] init];
                        extraData.vps = [NSData dataWithBytes:vparameterSet length:vparameterSetSize];
                        extraData.sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                        extraData.pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                    }
                }
            }
        } else {
            // 其他编码格式
        }
    }
    
    return extraData;
}

- (BOOL)isKeyFrame:(CMSampleBufferRef)sampleBuffer {
    CFArrayRef array = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    if (!array) {
        return NO;
    }
    
    CFDictionaryRef dic = (CFDictionaryRef)CFArrayGetValueAtIndex(array, 0);
    if (!dic) {
        return NO;
    }
    
    // 检测 sampleBuffer 是否是关键帧
    BOOL keyframe = !CFDictionaryContainsKey(dic, kCMSampleAttachmentKey_NotSync);
    
    return keyframe;
}

- (void)saveSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    // 将编码数据存储为文件
    // iOS 的 VideoToolbox 编码和解码只支持 AVCC/HVCC 的码流格式 但是 Android 的 MediaCodec 只支持 AnnexB 的码流格式 这里我们做一下两种格式的转换示范，将 AVCC/HVCC 格式的码流转换为 AnnexB 再存储
    // 1、AVCC/HVCC 码流格式：[extradata]|[length][NALU]|[length][NALU]|...
    // VPS、SPS、PPS 不用 NALU 来存储，而是存储在 extradata 中；每个 NALU 前有个 length 字段表示这个 NALU 的长度（不包含 length 字段），length 字段通常是 4 字节
    // 2、AnnexB 码流格式：[startcode][NALU]|[startcode][NALU]|...
    // 每个 NAL 前要添加起始码：0x00000001；VPS、SPS、PPS 也都用这样的 NALU 来存储，一般在码流最前面
    if (sampleBuffer) {
        NSMutableData *resultData = [NSMutableData new];
        uint8_t nalPartition[] = {0x00, 0x00, 0x00, 0x01};
        
        // 关键帧前添加 vps（H.265)、sps、pps 这里要注意顺序别乱了
        if ([self isKeyFrame:sampleBuffer]) {
            FSVideoPacketExtraData *extraData = [self getPacketExtraData:sampleBuffer];
            if (extraData.vps) {
                [resultData appendBytes:nalPartition length:4];
                [resultData appendData:extraData.vps];
            }
            [resultData appendBytes:nalPartition length:4];
            [resultData appendData:extraData.sps];
            [resultData appendBytes:nalPartition length:4];
            [resultData appendData:extraData.pps];
        }
        
        // 获取编码数据 这里的数据是 AVCC/HVCC 格式的
        CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        size_t length, totalLength;
        char *dataPointer;
        OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
        if (statusCodeRet == noErr) {
            size_t bufferOffset = 0;
            static const int NALULengthHeaderLength = 4;
            // 拷贝编码数据
            while (bufferOffset < totalLength - NALULengthHeaderLength) {
                // 通过 length 字段获取当前这个 NALU 的长度
                uint32_t NALUnitLength = 0;
                memcpy(&NALUnitLength, dataPointer + bufferOffset, NALULengthHeaderLength);
                NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
                
                // 拷贝 AnnexB 起始码字节
                [resultData appendData:[NSData dataWithBytes:nalPartition length:4]];
                // 拷贝这个 NALU 的字节
                [resultData appendData:[NSData dataWithBytes:(dataPointer + bufferOffset + NALULengthHeaderLength) length:NALUnitLength]];
                
                // 步进
                bufferOffset += NALULengthHeaderLength + NALUnitLength;
            }
        }
        
        [self.fileHandle writeData:resultData];
    }
}

#pragma mark - Property

- (FSVideoCaptureConfig *)videoCaptureConfig {
    if (!_videoCaptureConfig) {
        _videoCaptureConfig = [[FSVideoCaptureConfig alloc] init];
        // 这里我们采集数据用于编码，颜色格式用了默认的：kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    }
    return _videoCaptureConfig;
}

- (FSVideoCapture *)videoCapture {
    if (!_videoCapture) {
        _videoCapture = [[FSVideoCapture alloc] initWithConfig:self.videoCaptureConfig];
        __weak typeof(self) weakSelf = self;
        _videoCapture.sessionInitSuccessCallBack = ^() {
            dispatch_async(dispatch_get_main_queue(), ^{
                // 预览渲染
                [weakSelf.view.layer insertSublayer:weakSelf.videoCapture.previewLayer atIndex:0];
                weakSelf.videoCapture.previewLayer.backgroundColor = [UIColor blackColor].CGColor;
                weakSelf.videoCapture.previewLayer.frame = weakSelf.view.bounds;
            });
        };
        // Capture 回调的视频帧也是 CMSampleBuffer 类型的对象，但是它和编码器输出的CMSampleBuffer所包含的内容完全不一样
        _videoCapture.sampleBufferOutputCallBack = ^(CMSampleBufferRef sampleBuffer) {
            if (weakSelf.isEncoding && sampleBuffer) {
                // 编码
                [weakSelf.videoEncoder encodePixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer) ptsTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
            }
        };
        _videoCapture.sessionErrorCallBack = ^(NSError* error) {
            NSLog(@"FSVideoCapture Error:%zi %@", error.code, error.localizedDescription);
        };
    }
    
    return _videoCapture;
}

- (FSVideoEncoderConfig *)videoEncoderConfig {
    if (!_videoEncoderConfig) {
        _videoEncoderConfig = [[FSVideoEncoderConfig alloc] init];
        NSString *fileName = @"video_encoder_out.h264";
        if (_videoEncoderConfig.codecType == kCMVideoCodecType_HEVC) {
            fileName = @"video_encoder_out.h265";
        }
        NSString *videoPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileName];
        [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
        [[NSFileManager defaultManager] createFileAtPath:videoPath contents:nil attributes:nil];
        self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:videoPath];
    }
    
    return _videoEncoderConfig;
}

- (FSVideoEncoder *)videoEncoder {
    if (!_videoEncoder) {
        _videoEncoder = [[FSVideoEncoder alloc] initWithConfig:self.videoEncoderConfig];
        __weak typeof(self) weakSelf = self;
        _videoEncoder.sampleBufferOutputCallBack = ^(CMSampleBufferRef sampleBuffer) {
            // 保存编码后的数据
            [weakSelf saveSampleBuffer:sampleBuffer];
        };
    }
    return _videoEncoder;
}

@end
