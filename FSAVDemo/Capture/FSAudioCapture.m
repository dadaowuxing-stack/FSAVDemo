//
//  FSAudioCapture.m
//  FSAVDemo
//
//  Created by louis on 2022/5/27.
//  音频采集->pcm

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
        _captureQueue = dispatch_queue_create("com.louis.audioCaptureQueue", DISPATCH_QUEUE_SERIAL);
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
            // 第一次 startRunning 时创建音频采集实例.
            [strongSelf setupAudioCaptureInstance:&error];
            if (error) {
                // 捕捉并回调创建音频实例时的错误.
                [strongSelf callBackError:error];
                return;
            }
        }
        
        // 开始采集.
        OSStatus startStatus = AudioOutputUnitStart(weakSelf.audioCaptureInstance);
        if (startStatus != noErr) {
            // 捕捉并回调开始采集时的错误.
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
            // 停止采集.
            OSStatus stopStatus = AudioOutputUnitStop(strongSelf.audioCaptureInstance);
            if (stopStatus != noErr) {
                // 捕捉并回调停止采集时的错误.
                [strongSelf callBackError:[NSError errorWithDomain:NSStringFromClass([FSAudioCapture class]) code:stopStatus userInfo:nil]];
            }
        }
    });
}

#pragma mark - Utilities

// 创建音频采集实例
- (void)setupAudioCaptureInstance:(NSError **)error {
    // 1.设置音频组件描述.其中 type、subtype、manufacturer 三属性组合起来标识一种音频组件.
    // 构造RemoteIO类型的AudioUnit描述的结构体
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
    // 4.设置实例(AudioUnit)的属性: 是否可读写; 0 不可读写; 1 可读写.
    UInt32 flag = 1;
    AudioUnitSetProperty(_audioCaptureInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flag, sizeof(flag));
    
    // 5.设置实例的属性: 音频参数, 如: 数据格式, 声道数, 采样位深, 采样率等.
    // 设置音频编码器输出参数。其中一些参数与输入的音频数据参数一致
    AudioStreamBasicDescription outputFormat = {0};
    outputFormat.mFormatID = kAudioFormatLinearPCM; // 原始数据为 PCM，采用声道交错格式.
    outputFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    outputFormat.mChannelsPerFrame = (UInt32) self.config.channels; // 每个样本帧的声道数
    outputFormat.mFramesPerPacket = 1; // 每个数据包帧数.AAC 固定是 1024，这个是由 AAC 编码规范规定的.对于未压缩数据(PCM)设置为1.
    outputFormat.mBitsPerChannel = (UInt32) self.config.bitDepth; // 采样位深(每个样本的位数)
    outputFormat.mBytesPerFrame = outputFormat.mChannelsPerFrame * outputFormat.mBitsPerChannel / 8; // 每个样本帧字节数 (byte = bit / 8)
    outputFormat.mBytesPerPacket = outputFormat.mFramesPerPacket * outputFormat.mBytesPerFrame; // 每个包的字节数
    outputFormat.mSampleRate = self.config.sampleRate; // 采样率
    self.audioFormat = outputFormat;
    
    // 设置 AudioUnit 的属性
    status = AudioUnitSetProperty(_audioCaptureInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &outputFormat, sizeof(outputFormat));
    if (status != noErr) {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:status userInfo:nil];
        return;
    }
    // 6.设置实例的属性: 数据回调函数.
    // 构造一个AURenderCallback的结构体，并指定一个回调函数，然后设置给RemoteIO Unit的输入端，当RemoteIO Unit需要数据输入的时候就会回调该回调函数
    AURenderCallbackStruct callback;
    callback.inputProcRefCon = (__bridge void *) self;
    callback.inputProc = audioBufferCallBack;
    // 设置 AudioUnit 的属性
    status = AudioUnitSetProperty(_audioCaptureInstance, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &callback, sizeof(callback));
    if (status != noErr) {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:status userInfo:nil];
        return;
    }
    // 7.初始化实例.
    // 初始化一个 AudioUnit (AudioUnit 就是一种 AudioComponentInstance).
    // 如果初始化成功，说明 input/output 的格式是可支持的，并且处于可以开始渲染的状态.
    status = AudioUnitInitialize(_audioCaptureInstance);
    if (status != noErr) {
        *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:status userInfo:nil];
        return;
    }
}


/// 音频采集错误回调
/// @param error 错误
- (void)callBackError:(NSError *)error {
    self.isError = YES;
    if (error && self.errorCallBack) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.errorCallBack(error);
        });
    }
}


/// 将数据封装为 CMSampleBuffer
/// @param buffers 数据缓冲区,用来保存缓冲的数据
/// @param inTimeStamp 数据的时间戳
/// @param inNumberFrames 数据的帧数
/// @param description 视频采样参数
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
    // PTS(Presentation Tmestamp, 显示时间戳).
    CMTime presentationTime = CMTimeMake(time, 1000000000.0f);
    // 对于音频，PTS 和 DTS(Decoding Time Stamp, 解码时间戳) 是一样的.
    CMSampleTimingInfo timing = {CMTimeMake(1, description.mSampleRate), presentationTime, presentationTime};
    
    // 3.创建 CMSampleBuffer 实例.
    status = CMSampleBufferCreate(kCFAllocatorDefault, NULL, false, NULL, NULL, format, (CMItemCount) inNumberFrames, 1, &timing, 0, NULL, &sampleBuffer);
    if (status != noErr) {
        CFRelease(format);
        return nil;
    }
    
    // 4.创建 CMBlockBuffer 实例.其中数据拷贝自 AudioBufferList，并将 CMBlockBuffer 实例关联到 CMSampleBuffer 实例.
    status = CMSampleBufferSetDataBufferFromAudioBufferList(sampleBuffer, kCFAllocatorDefault, kCFAllocatorDefault, 0, &buffers);
    if (status != noErr) {
        CFRelease(format);
        return nil;
    }
    CFRelease(format);
    
    return sampleBuffer;
}

#pragma mark Captrue Callback

// 输入数据的回调函数
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
        
        // 用来保存音频缓冲数据的结构体
        AudioBuffer buffer;
        buffer.mData = NULL;
        buffer.mDataByteSize = 0;
        // 采集的时候设置了数据格式是 kAudioFormatLinearPCM，即声道交错格式，所以即使是双声道这里也设置 mNumberChannels 为 1.
        // 对于双声道的数据，会按照采样位深 16 bit 每组，一组接一组地进行两个声道数据的交错拼装.
        buffer.mNumberChannels = 1;
        
        // 1.创建 AudioBufferList 空间，用来接收采集回来的数据.
        // 创建编码输出缓冲区 AudioBufferList 接收编码后的数据
        AudioBufferList bufferList;
        bufferList.mNumberBuffers = 1;
        bufferList.mBuffers[0] = buffer;
        
        // 2.获取音频 PCM 数据，存储到 AudioBufferList 中.
        // 这里有几个问题要说明清楚：
        // 1）每次回调会过来多少数据？
        // 按照上面采集音频参数的设置：PCM为声道交错格式, 每帧的声道数为2, 采样位深为 16 bit. 这样每帧的字节数是 4 字节（左右声道各 2 字节）.
        // 返回数据的帧数是 inNumberFrames. 这样一次回调回来的数据字节数是多少就是：mBytesPerFrame(4) * inNumberFrames.
        // 2）这个数据回调的频率跟音频采样率有关系吗？
        // 这个数据回调的频率与音频采样率（上面设置的 mSampleRate 44100）是没关系的. 声道数、采样位深、采样率共同决定了设备单位时间里采样数据的大小，这些数据是会缓冲起来，然后一块一块的通过这个数据回调给我们，这个回调的频率是底层一块一块给我们数据的速度，跟采样率无关.
        // 3）这个数据回调的频率是多少？
        // 这个数据回调的间隔是 [AVAudioSession sharedInstance].preferredIOBufferDuration，频率即该值的倒数.我们可以通过 [[AVAudioSession sharedInstance] setPreferredIOBufferDuration:1 error:nil] 设置这个值来控制回调频率.
        OSStatus status = AudioUnitRender(capture.audioCaptureInstance,
                                          ioActionFlags,
                                          inTimeStamp,
                                          inBusNumber,
                                          inNumberFrames,
                                          &bufferList);
        
        // 3、数据封装及回调.
        if (status == noErr) {
            // 使用工具方法将数据封装为 CMSampleBuffer.
            // CMSampleBuffer是一个由Core Media框架提供的Core Foundation风格对象，用于在媒体管道传输数字样本.
            // CMSampleBuffer的角色是将基础的样本数据进行封装并提供格式和时间信息，还会加上所有在转换和处理数据时用到的元数据.
            CMSampleBufferRef sampleBuffer = [FSAudioCapture sampleBufferFromAudioBufferList:bufferList inTimeStamp:inTimeStamp inNumberFrames:inNumberFrames description:capture.audioFormat];
            // 音频采集数据回调.
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
