//
//  FSAudioCapture.m
//  FSAVDemo
//
//  Created by louis on 2022/5/27.
//

#import "FSAudioCapture.h"
#import <mach/mach_time.h>
#import <AVFoundation/AVFoundation.h>

@interface FSAudioCapture ()

@property (nonatomic, assign) AudioComponentInstance audioCaptureInstance; // 音频采集实例
@property (nonatomic, assign) AudioStreamBasicDescription audioFormat;     // 视频采集参数
@property (nonatomic, readwrite, strong) FSAudioConfig *config; // 音频采集配置参数
@property (nonatomic, strong) dispatch_queue_t captureQueue;    // 音频采集队列
@property (nonatomic, assign) BOOL isError;

@end

@implementation FSAudioCapture

- (void)dealloc {
    // 清理音频采集实例
    if (_audioCaptureInstance) {
        AudioOutputUnitStop(_audioCaptureInstance);
        AudioComponentInstanceDispose(_audioCaptureInstance);
        _audioCaptureInstance = nil;
    }
}

- (instancetype)initWithConfig:(FSAudioConfig *)config {
    self = [super init];
    if (self) {
        _config = config;
        // 创建串行队列,用于采集音频数据
        _captureQueue = dispatch_queue_create("com.fengshuoliu.audioCaptureQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

/**
 开始采集音频数据
 */
- (void)startRunning {
    if (self.isError) {
        return;
    }
    __weak typeof (self) weakSelf = self;
    dispatch_async(_captureQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf.audioCaptureInstance) {
            NSError *error = nil;
            // 第一次 startRunning 时创建音频采集实例。
            [strongSelf setupAudioCaptureInstance:&error];
            if (error) {
                // 捕捉并回调创建音频实例时的错误。
                [strongSelf callBackError:error];
                return;
            }
        }
        
        // 开始采集。
        OSStatus startStatus = AudioOutputUnitStart(weakSelf.audioCaptureInstance);
        if (startStatus != noErr) {
            // 捕捉并回调开始采集时的错误。
            [weakSelf callBackError:[NSError errorWithDomain:NSStringFromClass([FSAudioCapture class]) code:startStatus userInfo:nil]];
        }
    });
}
/**
 停止采集音频数据
 */
- (void)stopRunning {
    if (self.isError) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(_captureQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.audioCaptureInstance) {
            // 停止采集。
            OSStatus stopStatus = AudioOutputUnitStop(strongSelf.audioCaptureInstance);
            if (stopStatus != noErr) {
                // 捕捉并回调停止采集时的错误。
                [strongSelf callBackError:[NSError errorWithDomain:NSStringFromClass([FSAudioCapture class]) code:stopStatus userInfo:nil]];
            }
        }
    });
}

#pragma mark - Utilities

// 创建音频采集实例
- (void)setupAudioCaptureInstance:(NSError **)error {
    // 1.设置音频组件描述.
    AudioComponentDescription acDesc = {
        .componentType = kAudioUnitType_Output,
        // 回声消除模式
        //.componentSubType = kAudioUnitSubType_VoiceProcessingIO,
        .componentSubType = kAudioUnitSubType_RemoteIO,
        .componentManufacturer = kAudioUnitManufacturer_Apple,
        .componentFlags = 0,
        .componentFlagsMask = 0,
    };
    // 2.查找符合指定描述的音频组件.
    AudioComponent component = AudioComponentFindNext(NULL, &acDesc);
    // 3.创建音频组件实例.
    OSStatus status = AudioComponentInstanceNew(component, &_audioCaptureInstance);
    if (status != noErr) {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:status userInfo:nil];
        return;
    }
    // 4.设置实例的属性: 是否可读写; 0 不可读写; 1 可读写.
    UInt32 flag = 1;
    AudioUnitSetProperty(_audioCaptureInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flag, sizeof(flag));
    
    // 5.设置实例的属性: 音频参数, 如: 数据格式, 声道数, 采样位深, 采样率等.
    AudioStreamBasicDescription asbDesc = {0};
    asbDesc.mFormatID = kAudioFormatLinearPCM; // 原始数据为 PCM，采用声道交错格式。
    asbDesc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    asbDesc.mChannelsPerFrame = (UInt32) self.config.channels; // 每个样本帧的声道数
    asbDesc.mFramesPerPacket = 1; // 每个数据包帧数
    asbDesc.mBitsPerChannel = (UInt32) self.config.bitDepth; // 采样位深(每个样本的位数)
    asbDesc.mBytesPerFrame = asbDesc.mChannelsPerFrame * asbDesc.mBitsPerChannel / 8; // 每个样本帧字节数 (byte = bit / 8)
    asbDesc.mBytesPerPacket = asbDesc.mFramesPerPacket * asbDesc.mBytesPerFrame; // 每个包的字节数
    asbDesc.mSampleRate = self.config.sampleRate; // 采样率
    self.audioFormat = asbDesc;
    status = AudioUnitSetProperty(_audioCaptureInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &asbDesc, sizeof(asbDesc));
    if (status != noErr) {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:status userInfo:nil];
        return;
    }
    // 6.设置实例的属性: 数据回调函数.
    AURenderCallbackStruct callback;
    callback.inputProcRefCon = (__bridge void *) self;
    callback.inputProc = audioBufferCallBack;
    status = AudioUnitSetProperty(_audioCaptureInstance, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &callback, sizeof(callback));
    if (status != noErr) {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:status userInfo:nil];
        return;
    }
    // 7.初始化实例.
    status = AudioUnitInitialize(_audioCaptureInstance);
    if (status != noErr) {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:status userInfo:nil];
        return;
    }
}

- (void)callBackError:(NSError *)error {
    self.isError = YES;
    if (error && self.errorCallBack) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.errorCallBack(error);
        });
    }
}

+ (CMSampleBufferRef)sampleBufferFromAudioBufferList:(AudioBufferList)buffers inTimeStamp:(const AudioTimeStamp *)inTimeStamp inNumberFrames:(UInt32)inNumberFrames description:(AudioStreamBasicDescription)description {
    
    CMSampleBufferRef sampleBuffer = NULL; // 待生成的 CMSampleBuffer 实例的引用.
    
    // 1.创建音频流的格式描述信息.
    CMFormatDescriptionRef format = NULL;
    OSStatus status = CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &description, 0, NULL, 0, NULL, NULL, &format);
    if (status != noErr) {
        CFRelease(format);
        return nil;
    }
    
    // 2.处理音频帧的时间戳信息.
    mach_timebase_info_data_t info = {0, 0};
    mach_timebase_info(&info);
    uint64_t time = inTimeStamp->mHostTime;
    // 转换为纳秒.
    time *= info.numer;
    time /= info.denom;
    // PTS。
    CMTime presentationTime = CMTimeMake(time, 1000000000.0f);
    // 对于音频，PTS 和 DTS 是一样的.
    CMSampleTimingInfo timing = {CMTimeMake(1, description.mSampleRate), presentationTime, presentationTime};
    
    // 3.创建 CMSampleBuffer 实例.
    status = CMSampleBufferCreate(kCFAllocatorDefault, NULL, false, NULL, NULL, format, (CMItemCount) inNumberFrames, 1, &timing, 0, NULL, &sampleBuffer);
    if (status != noErr) {
        CFRelease(format);
        return nil;
    }
    
    // 4.创建 CMBlockBuffer 实例。其中数据拷贝自 AudioBufferList，并将 CMBlockBuffer 实例关联到 CMSampleBuffer 实例.
    status = CMSampleBufferSetDataBufferFromAudioBufferList(sampleBuffer, kCFAllocatorDefault, kCFAllocatorDefault, 0, &buffers);
    if (status != noErr) {
        CFRelease(format);
        return nil;
    }
    
    CFRelease(format);
    return sampleBuffer;
}

#pragma mark Captrue Callback

static OSStatus audioBufferCallBack(void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData) {
    @autoreleasepool {
        FSAudioCapture *capture = (__bridge FSAudioCapture *) inRefCon;
        if (!capture) {
            return -1;
        }
        
        // 1.创建 AudioBufferList 空间，用来接收采集回来的数据.
        AudioBuffer buffer;
        buffer.mData = NULL;
        buffer.mDataByteSize = 0;
        // 采集的时候设置了数据格式是 kAudioFormatLinearPCM，即声道交错格式，所以即使是双声道这里也设置 mNumberChannels 为 1.
        // 对于双声道的数据，会按照采样位深 16 bit 每组，一组接一组地进行两个声道数据的交错拼装.
        buffer.mNumberChannels = 1;
        AudioBufferList buffers;
        buffers.mNumberBuffers = 1;
        buffers.mBuffers[0] = buffer;
        
        // 2.获取音频 PCM 数据，存储到 AudioBufferList 中.
        // 这里有几个问题要说明清楚：
        // 1）每次回调会过来多少数据？
        // 按照上面采集音频参数的设置：PCM为声道交错格式, 每帧的声道数为2, 采样位深为 16 bit. 这样每帧的字节数是 4 字节（左右声道各 2 字节）。
        // 返回数据的帧数是 inNumberFrames. 这样一次回调回来的数据字节数是多少就是：mBytesPerFrame(4) * inNumberFrames.
        // 2）这个数据回调的频率跟音频采样率有关系吗？
        // 这个数据回调的频率与音频采样率（上面设置的 mSampleRate 44100）是没关系的. 声道数、采样位深、采样率共同决定了设备单位时间里采样数据的大小，这些数据是会缓冲起来，然后一块一块的通过这个数据回调给我们，这个回调的频率是底层一块一块给我们数据的速度，跟采样率无关.
        // 3）这个数据回调的频率是多少？
        // 这个数据回调的间隔是 [AVAudioSession sharedInstance].preferredIOBufferDuration，频率即该值的倒数。我们可以通过 [[AVAudioSession sharedInstance] setPreferredIOBufferDuration:1 error:nil] 设置这个值来控制回调频率.
        OSStatus status = AudioUnitRender(capture.audioCaptureInstance,
                                          ioActionFlags,
                                          inTimeStamp,
                                          inBusNumber,
                                          inNumberFrames,
                                          &buffers);
        
        // 3、数据封装及回调。
        if (status == noErr) {
            // 使用工具方法将数据封装为 CMSampleBuffer。
            CMSampleBufferRef sampleBuffer = [FSAudioCapture sampleBufferFromAudioBufferList:buffers inTimeStamp:inTimeStamp inNumberFrames:inNumberFrames description:capture.audioFormat];
            // 回调数据。
            if (capture.sampleBufferOutputCallBack) {
                capture.sampleBufferOutputCallBack(sampleBuffer);
            }
            if (sampleBuffer) {
                CFRelease(sampleBuffer);
            }
        }
        
        return status;
    }
}

@end
