//
//  FSAudioOutput.m
//  FSAVDemo
//
//  Created by louis on 2022/10/12.
//

#import "FSAudioOutput.h"
#import <AudioToolbox/AudioToolbox.h>

/**
 * AudioOutput(音频输出模块)的职责:
 *
 */

static const AudioUnitElement inputElement = 1;

static OSStatus InputRenderCallback(void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData);
static void CheckStatus(OSStatus status, NSString *message, BOOL fatal);

@interface FSAudioOutput ()

/// 采样率
@property(nonatomic, assign) Float64 sampleRate;
/// 声道数
@property(nonatomic, assign) Float64 channels;
@property(nonatomic, assign) AUGraph            inGraph;
@property(nonatomic, assign) AUNode             ioNode;
@property(nonatomic, assign) AudioUnit          ioUnit;
@property(nonatomic, assign) AUNode             convertNode;
@property(nonatomic, assign) AudioUnit          convertUnit;

@property (readwrite, copy) id<FSFillDataDelegate> fillAudioDataDelegate;

@end

@implementation FSAudioOutput

- (instancetype)initWithChannels:(NSInteger)channels sampleRate:(NSInteger)sampleRate bytesPerSample:(NSInteger)bytePerSample filleDataDelegate:(id<FSFillDataDelegate>)fillAudioDataDelegate {
    self = [super init];
    if (self) {
        // 构建AudioUnit
        [self createAudioUnitByGraph];
    }
    return self;
}

- (BOOL)play {
    return YES;
}

- (void)stop {
    
}

/**
 构建AudioUnit方式:
 1.裸创建方式
 2.AUGraph 创建方式
 */
- (void)createAudioUnitByGraph {
    OSStatus status = noErr;
    // 1.声明并且实例化一个 AUGraph
    status = NewAUGraph(&_inGraph);
    CheckStatus(status, @"NewAUGraph: Could not create a new AUGraph", YES);
    
    // 2.利用 AudioUnit 的描述在 AUGraph 中按照描述增加一个 AUNode
    [self addAudioUnitWithNodes];
    
    // 3.打开 AUGraph，其实打开 AUGraph 的过程也是间接实例化 AUGraph 中所有的 AUNode 的过程。
    // 注意，必须在获取 AudioUnit 之前打开整个 Graph，否则我们不能从对应的 AUNode 里面获取到正确的 AudioUnit。
    status = AUGraphOpen(_inGraph);
    CheckStatus(status, @"AUGraphOpen: Could not open AUGraph", YES);
    
    // 4.在 AUGraph 中的某个 Node 里面获得 AudioUnit 的引用
    [self getUnitsFromNodes];
}

/// 2.利用 AudioUnit 的描述在 AUGraph 中按照描述增加一个 AUNode
- (void)addAudioUnitWithNodes {
    OSStatus status = noErr;
    
    AudioComponentDescription ioDescription;
    // bzero(void *, size_t) 会将内存块(字符串)的前n个字节清零
    // 第一个参数:为内存(字符串)指针,第二个参数:需要清零的字节数
    bzero(&ioDescription, sizeof(ioDescription));
    ioDescription.componentType = kAudioUnitType_Output;
    ioDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    ioDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    status = AUGraphAddNode(_inGraph, &ioDescription, &_ioNode);
    CheckStatus(status, @"AUGraphAddNode: Could not add I/O node to AUGraph", YES);
    
    AudioComponentDescription convertDescription;
    bzero(&convertDescription, sizeof(convertDescription));
    convertDescription.componentType = kAudioUnitType_FormatConverter;
    convertDescription.componentSubType = kAudioUnitSubType_AUConverter;
    convertDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    status = AUGraphAddNode(_inGraph, &convertDescription, &_convertNode);
    CheckStatus(status, @"AUGraphAddNode: Could not add Convert node to AUGraph", YES);
}

/// 4.在 AUGraph 中的某个 Node 里面获得 AudioUnit 的引用
- (void)getUnitsFromNodes {
    OSStatus status = noErr;
    
    status = AUGraphNodeInfo(_inGraph, _ioNode, NULL, &_ioUnit);
    CheckStatus(status, @"AUGraphNodeInfo: Could not retrieve node info for I/O node", YES);
    
    status = AUGraphNodeInfo(_inGraph, _convertNode, NULL, &_convertUnit);
    CheckStatus(status, @"AUGraphNodeInfo: Could not retrieve node info for Convert node", YES);
}

/// 设置属性
- (void)setAudioUnitProperties {
    OSStatus status = noErr;
    // 获取音频数据格式
    AudioStreamBasicDescription streamFormat = [self nonInterleavedPCMFormatWithChannels:_channels];
    // 构造好合适的 ASBD 结构体，最终设置给 AudioUnit 对应的 Scope（Input/Output）
    status = AudioUnitSetProperty(_ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, inputElement, &streamFormat, sizeof(streamFormat));
    CheckStatus(status, @"AudioUnitSetProperty: Could not set stream format on I/O unit output scope", YES);
    
    AudioStreamBasicDescription clientFormat16Int = [self clientPCMFormatWithChannels:_channels];
    // spectial format for converter
    status = AudioUnitSetProperty(_convertUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &streamFormat, sizeof(streamFormat));
    CheckStatus(status, @"AudioUnitSetProperty streamFormat: augraph recorder normal unit set client format error", YES);
    status = AudioUnitSetProperty(_convertUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &clientFormat16Int, sizeof(clientFormat16Int));
    CheckStatus(status, @"AudioUnitSetProperty clientFormat16Int: augraph recorder normal unit set client format error", YES);
}

/**
 AudioUnit 或者说 AUNode 是进行连接有什么方式:
 1.直接将 AUNode 连接起来
 2.通过回调把两个 AUNode 连接起来
 */
- (void)makeNodeConnections {
    OSStatus status = noErr;
    
    status = AUGraphConnectNodeInput(_inGraph, _convertNode, 0, _ioNode, 0);
    CheckStatus(status, @"AUGraphConnectNodeInput: Could not connect I/O node input to mixer node input", YES);
    
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = &InputRenderCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)self;
    
    status = AudioUnitSetProperty(_convertUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0,
                                  &callbackStruct, sizeof(callbackStruct));
    CheckStatus(status, @"AudioUnitSetProperty: Could not set render callback on mixer input scope, element 1", YES);
}

/// iOS 平台的音频格式是 ASBD（AudioStreamBasicDescription），用来描述音频数据的表示方式
/// - Parameter channels: 声道数
- (AudioStreamBasicDescription)nonInterleavedPCMFormatWithChannels:(UInt32)channels {
    /**
     mFormatID: 这个参数是用来指定音频的编码格式，此处音频编码格式指定为 PCM 格式；
     mFormatFlags: 是用来描述声音表示格式的参数，代码中的第一个参数指定每个 sample 的表示格式是 Float 格式；
     参数 NonInterleaved，表面理解这个单词的意思是非交错的，其实对音频来说，就是左右声道是非交错存放的，实际的音频数据会存储在一个 AudioBufferList 结构中的变量 mBuffers 中. 如果 mFormatFlags 指定的是 NonInterleaved，那么左声道就会在 mBuffers[0]里面，右声道就会在 mBuffers[1]里面，而如果 mFormatFlags 指定的是 Interleaved 的话，那么左右声道就会交错排列在 mBuffers[0]里面；
     mBitsPerChannel: 表示的是一个声道的音频数据用多少位；
     参数 mBytesPerFrame 和 mBytesPerPacket 的赋值，这里需要根据 mFormatFlags 的值来分配. 如果在 NonInterleaved 的情况下，就赋值为 bytesPerSample（因为左右声道是分开存放的）；但如果是 Interleaved 的话，那么就应该是 bytesPerSample * channels（因为左右声道是交错存放的），这样才能表示一个 Frame 里面到底有多少个 byte.
     */
    UInt32 bytesPerSample = sizeof(Float32); // 每个样本帧的字节数
    
    AudioStreamBasicDescription asbd;
    bzero(&asbd, sizeof(asbd));
    asbd.mSampleRate = _sampleRate; // 采样率
    asbd.mFormatID = kAudioFormatLinearPCM; // 采样格式
    asbd.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    asbd.mBitsPerChannel = 8 * bytesPerSample; // 每个声道的位数
    asbd.mBytesPerFrame = bytesPerSample;      // 每个样本帧的字节数
    asbd.mBytesPerPacket = bytesPerSample;     // 每个数据包的字节数
    asbd.mFramesPerPacket = 1;                 // 每个包包含的样本帧数
    asbd.mChannelsPerFrame = channels;         // 每个样本帧的声道数
    
    return asbd;
}

- (AudioStreamBasicDescription)clientPCMFormatWithChannels:(UInt32)channels {
    
    AudioStreamBasicDescription clientFormat16Int;
    UInt32 bytesPerSample = sizeof (SInt16);
    bzero(&clientFormat16Int, sizeof(clientFormat16Int));
    clientFormat16Int.mFormatID          = kAudioFormatLinearPCM;
    clientFormat16Int.mFormatFlags       = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    clientFormat16Int.mBytesPerPacket    = bytesPerSample * _channels;
    clientFormat16Int.mFramesPerPacket   = 1;
    clientFormat16Int.mBytesPerFrame     = bytesPerSample * _channels;
    clientFormat16Int.mChannelsPerFrame  = _channels;
    clientFormat16Int.mBitsPerChannel    = 8 * bytesPerSample;
    clientFormat16Int.mSampleRate        = _sampleRate;
    
    return clientFormat16Int;
}

@end

static void CheckStatus(OSStatus status, NSString *message, BOOL fatal) {
    if(status != noErr) {
        char fourCC[16];
        *(UInt32 *)fourCC = CFSwapInt32HostToBig(status);
        fourCC[4] = '\0';
        
        if(isprint(fourCC[0]) && isprint(fourCC[1]) && isprint(fourCC[2]) && isprint(fourCC[3]))
            NSLog(@"%@: %s", message, fourCC);
        else
            NSLog(@"%@: %d", message, (int)status);
        
        if(fatal) {
            exit(-1);
        }
    }
}

static OSStatus InputRenderCallback(void *inRefCon,
                                    AudioUnitRenderActionFlags *ioActionFlags,
                                    const AudioTimeStamp *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData) {
    return noErr;
}
