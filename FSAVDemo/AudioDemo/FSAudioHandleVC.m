//
//  FSAudioCaptureVC.m
//  FSAVDemo
//
//  Created by louis on 2022/5/27.
//

#import "FSAudioHandleVC.h"
#import <AVFoundation/AVFoundation.h>
#import "FSAudioTools.h"
// 采集
#import "FSAudioCapture.h"
// 编码
#import "FSAudioEncoder.h"
// 封装
#import "FSMP4Muxer.h"
// 解封装
#import "FSMP4Demuxer.h"
// 解码
#import "FSAudioDecoder.h"

@interface FSAudioHandleVC ()

@property (nonatomic, strong) FSAudioConfig *audioConfig;
@property (nonatomic, strong) FSAudioCapture *audioCapture;   // 1.采集
@property (nonatomic, strong) FSAudioEncoder *audioEncoder;   // 2.编码
@property (nonatomic, strong) FSMuxerConfig *muxerConfig;
@property (nonatomic, strong) FSMP4Muxer *muxer;              // 3.封装
@property (nonatomic, strong) FSDemuxerConfig *demuxerConfig;
@property (nonatomic, strong) FSMP4Demuxer *demuxer;          // 4.解封装
@property (nonatomic, strong) FSAudioDecoder *decoder;        // 5.解码


@property (nonatomic, strong) NSFileHandle *fileHandle;

@property (nonatomic, strong) UIButton *audioButton;
@property (nonatomic, assign) BOOL isRecording;

@property (nonatomic, copy) NSString *startTitle;
@property (nonatomic, copy) NSString *stopTitle;

@property (nonatomic, copy) NSString *audioPath;

@end

@implementation FSAudioHandleVC

- (void)dealloc {
    if (_fileHandle) {
        [_fileHandle closeFile];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isRecording = NO;
    
    [self _initConfig];
    [self _setupAudioSession];
    [self _setupUI];
}

- (void)_initConfig {
    NSString *pathComponent = @"out.pcm";
    self.startTitle = @"开始采集";
    self.stopTitle = @"停止采集";
    switch (self.opType) {
        case FSMediaOpTypeAudioCapture: {  // 采集
            pathComponent = @"capture_out.pcm";
            self.startTitle = @"开始采集";
            self.stopTitle = @"停止采集";
        }
            break;
        case FSMediaOpTypeAudioEncoder: {  // 编码
            pathComponent = @"encoder_out.aac";
            self.startTitle = @"开始编码";
            self.stopTitle = @"停止编码";
        }
            break;
        case FSMediaOpTypeAudioMuxer: {   // 封装
            pathComponent = @"muxer_out.m4a";
            self.startTitle = @"开始封装";
            self.stopTitle = @"停止封装";
        }
            break;
        case FSMediaOpTypeAudioDemuxer: { // 解封装
            pathComponent = @"demuxer_out.aac";
            self.startTitle = @"开始解封装";
            self.stopTitle = @"停止解封装";
        }
            break;
        case FSMediaOpTypeAudioDecoder: { // 解封装
            pathComponent = @"decoder_out.pcm";
            self.startTitle = @"开始解码";
            self.stopTitle = @"停止解码";
        }
            break;
            
        default:
            break;
    }
    self.audioPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:pathComponent];
    NSLog(@"opType: %ld ------ file path: %@", self.opType, self.audioPath);
    [[NSFileManager defaultManager] removeItemAtPath:self.audioPath error:nil];
    [[NSFileManager defaultManager] createFileAtPath:self.audioPath contents:nil attributes:nil];
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.audioPath];
}

- (void)_setupUI {
    
    self.audioButton = [self buttonWithFrame:CGRectMake(100, 100, 150, 50) title:self.startTitle action:@selector(audioButtonAction:)];
    [self.view addSubview:self.audioButton];
}

- (UIButton *)buttonWithFrame:(CGRect)frame title:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:frame];
    button.layer.borderWidth = 1;
    button.layer.cornerRadius = 8;
    button.layer.borderColor = [UIColor redColor].CGColor;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16.0];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

#pragma mark - Action

- (void)audioButtonAction:(UIButton *)sender {
    // 采集->编码->封装->解封装->解码->渲染
    [self _captureAction];
}

- (void)_captureAction {
    if (!self.isRecording) {
        self.isRecording = YES;
        [self.audioButton setTitle:self.stopTitle forState:UIControlStateNormal];
        // 解封装&解码
        if (self.opType == FSMediaOpTypeAudioDemuxer || self.opType == FSMediaOpTypeAudioDecoder) {
            NSLog(@"FSMP4Demuxer start");
            __weak typeof(self) weakSelf = self;
            [self.demuxer startReading:^(BOOL success, NSError * _Nonnull error) {
                if (success) {
                    // Demuxer 启动成功后，就可以从它里面获取解封装后的数据了.
                    [weakSelf fetchAndSaveDemuxedData];
                } else {
                    NSLog(@"FSMP4Demuxer error: %zi %@", error.code, error.localizedDescription);
                }
            }];
            return;
        }
        // 启动采集器.
        [self.audioCapture startRunning];
        // 启动封装器.
        [self.muxer startWriting];
    } else {
        self.isRecording = NO;
        [self.audioButton setTitle:self.startTitle forState:UIControlStateNormal];
        // 解封装&解码
        if (self.opType == FSMediaOpTypeAudioDemuxer || self.opType == FSMediaOpTypeAudioDecoder) {
            return;
        }
        // 停止采集器.
        [self.audioCapture stopRunning];
        // 停止封装器.
        [self.muxer stopWriting:^(BOOL success, NSError * _Nonnull error) {
            NSLog(@"FSMP4Muxer %@", success ? @"success" : [NSString stringWithFormat:@"error %zi %@", error.code, error.localizedDescription]);
        }];
    }
}

- (void)_setupAudioSession {
    NSError *error = nil;
    
    // 1.获取音频会话实例.
    AVAudioSession *session = [AVAudioSession sharedInstance];

    // 2.设置分类和选项.
    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
    if (error) {
        NSLog(@"AVAudioSession setCategory error.");
        error = nil;
        return;
    }
    
    // 3.设置模式.
    [session setMode:AVAudioSessionModeVideoRecording error:&error];
    if (error) {
        NSLog(@"AVAudioSession setMode error.");
        error = nil;
        return;
    }

    // 4.激活会话.
    [session setActive:YES error:&error];
    if (error) {
        NSLog(@"AVAudioSession setActive error.");
        error = nil;
        return;
    }
}

#pragma mark - Utility

- (void)fetchAndSaveDemuxedData {
    // 异步地从 Demuxer 获取解封装后的 AAC 编码数据，送给解码器进行解码。
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (weakSelf.demuxer.hasAudioSampleBuffer) {
            CMSampleBufferRef audioBuffer = [weakSelf.demuxer copyNextAudioSampleBuffer];
            if (audioBuffer) {
                // 解封装
                if (weakSelf.opType == FSMediaOpTypeAudioDemuxer) {
                    [weakSelf saveSampleBuffer:audioBuffer];
                }
                // 解码
                else if (weakSelf.opType == FSMediaOpTypeAudioDecoder) {
                    [weakSelf decodeSampleBuffer:audioBuffer];
                }
                CFRelease(audioBuffer);
            }
        }
        if (self.demuxer.demuxerStatus == FSMP4DemuxerStatusCompleted) {
            NSLog(@"FSMP4Demuxer complete");
        }
    });
}

// 保存样本数据
- (void)saveSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    // 将解封装后的数据存储为 AAC 文件.
    if (sampleBuffer) {
        // 获取解封装后的 AAC 编码裸数据.
        AudioStreamBasicDescription streamBasicDescription = *CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sampleBuffer));
        CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        size_t totolLength;
        char *dataPointer = NULL;
        CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &totolLength, &dataPointer);
        if (totolLength == 0 || !dataPointer) {
            return;
        }
        
        // 将 AAC 编码裸数据存储为 AAC 文件，这时候需要在每个包前增加 ADTS 头信息.
        for (NSInteger index = 0; index < CMSampleBufferGetNumSamples(sampleBuffer); index++) {
            size_t sampleSize = CMSampleBufferGetSampleSize(sampleBuffer, index);
            [self.fileHandle writeData:[FSAudioTools adtsDataWithChannels:streamBasicDescription.mChannelsPerFrame sampleRate:streamBasicDescription.mSampleRate rawDataLength:sampleSize]];
            [self.fileHandle writeData:[NSData dataWithBytes:dataPointer length:sampleSize]];
            dataPointer += sampleSize;
        }
    }
}

// 解码
- (void)decodeSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    // 获取解封装后的 AAC 编码裸数据。
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t totolLength;
    char *dataPointer = NULL;
    CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &totolLength, &dataPointer);
    if (totolLength == 0 || !dataPointer) {
        return;
    }
    
    // 目前 AudioDecoder 的解码接口实现的是单包（packet，1 packet 有 1024 帧）解码。而从 Demuxer 获取的一个 CMSampleBuffer 可能包含多个包，所以这里要拆一下包，再送给解码器。
    NSLog(@"SampleNum: %ld", CMSampleBufferGetNumSamples(sampleBuffer));
    for (NSInteger index = 0; index < CMSampleBufferGetNumSamples(sampleBuffer); index++) {
        // 1、获取一个包的数据。
        size_t sampleSize = CMSampleBufferGetSampleSize(sampleBuffer, index);
        CMSampleTimingInfo timingInfo;
        CMSampleBufferGetSampleTimingInfo(sampleBuffer, index, &timingInfo);
        char *sampleDataPointer = malloc(sampleSize);
        memcpy(sampleDataPointer, dataPointer, sampleSize);
        
        // 2、将数据封装到 CMBlockBuffer 中。
        CMBlockBufferRef packetBlockBuffer;
        OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                              sampleDataPointer,
                                                              sampleSize,
                                                              NULL,
                                                              NULL,
                                                              0,
                                                              sampleSize,
                                                              0,
                                                              &packetBlockBuffer);
        
        if (status == noErr) {
            // 3、将 CMBlockBuffer 封装到 CMSampleBuffer 中。
            CMSampleBufferRef packetSampleBuffer = NULL;
            const size_t sampleSizeArray[] = {sampleSize};
            status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                               packetBlockBuffer,
                                               CMSampleBufferGetFormatDescription(sampleBuffer),
                                               1,
                                               1,
                                               &timingInfo,
                                               1,
                                               sampleSizeArray,
                                               &packetSampleBuffer);
            CFRelease(packetBlockBuffer);
            
            // 4、解码这个包的数据。
            if (packetSampleBuffer) {
                [self.decoder decodeSampleBuffer:packetSampleBuffer];
                CFRelease(packetSampleBuffer);
            }
        }
        dataPointer += sampleSize;
    }
}

#pragma mark - Properties

- (FSAudioConfig *)audioConfig {
    if (!_audioConfig) {
        _audioConfig = [FSAudioConfig defaultConfig];
    }
    
    return _audioConfig;
}

// 音频采集
- (FSAudioCapture *)audioCapture {
    if (!_audioCapture) {
        __weak typeof(self) weakSelf = self;
        _audioCapture = [[FSAudioCapture alloc] initWithConfig:self.audioConfig];
        _audioCapture.errorCallBack = ^(NSError* error) {
            NSLog(@"FSAudioCapture error: %zi %@", error.code, error.localizedDescription);
        };
        // 音频采集数据回调: 在这里将 PCM 数据写入文件. or 在这里采集的 PCM 数据送给编码器.
        _audioCapture.sampleBufferOutputCallBack = ^(CMSampleBufferRef sampleBuffer) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (sampleBuffer) {
                /**
                 (1) 将 PCM 数据写入文件
                 */
                // 采集
                if (self.opType == FSMediaOpTypeAudioCapture) {
                    // 1.获取 CMBlockBuffer，这里面封装着 PCM 数据.
                    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
                    size_t lengthAtOffsetOutput, totalLengthOutput;
                    char *dataPointer;
                    
                    // 2.从 CMBlockBuffer 中获取 PCM 数据存储到文件中.
                    CMBlockBufferGetDataPointer(blockBuffer, 0, &lengthAtOffsetOutput, &totalLengthOutput, &dataPointer);
                    [strongSelf.fileHandle writeData:[NSData dataWithBytes:dataPointer length:totalLengthOutput]];
                }
                // 编码&封装
                else if (self.opType == FSMediaOpTypeAudioEncoder || self.opType == FSMediaOpTypeAudioMuxer) {
                    /**
                     (2) 将采集的 PCM 数据送给编码器
                     */
                    [strongSelf.audioEncoder encodeSampleBuffer:sampleBuffer];
                }
            }
        };
    }
    return _audioCapture;
}

// 音频编码
- (FSAudioEncoder *)audioEncoder {
    if (!_audioEncoder) {
        __weak typeof(self) weakSelf = self;
        _audioEncoder = [[FSAudioEncoder alloc] initWithAudioBitrate:96000];
        _audioEncoder.errorCallBack = ^(NSError* error) {
            NSLog(@"FSAudioEncoder error:%zi %@", error.code, error.localizedDescription);
        };
        // 音频编码数据回调:在这里将 AAC 数据写入文件.
        // 音频编码数据回调:这里编码的 AAC 数据送给封装器.
        // 与之前将编码后的 AAC 数据存储为 AAC 文件不同的是，这里编码后送给封装器的 AAC 数据是没有添加 ADTS 头的，因为我们这里封装的是 M4A 格式，不需要 ADTS 头.
        _audioEncoder.sampleBufferOutputCallBack = ^(CMSampleBufferRef sampleBuffer) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (self.opType == FSMediaOpTypeAudioEncoder) {
                if (sampleBuffer) {
                    // 1.获取音频编码参数信息.
                    AudioStreamBasicDescription audioFormat = *CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sampleBuffer));
                    
                    // 2.获取音频编码数据.AAC 裸数据.
                    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
                    size_t totolLength;
                    char *dataPointer = NULL;
                    CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &totolLength, &dataPointer);
                    if (totolLength == 0 || !dataPointer) {
                        return;
                    }
                    
                    // 3.在每个 AAC packet 前先写入 ADTS 头数据.
                    // 由于 AAC 数据存储文件时需要在每个包（packet）前添加 ADTS 头来用于解码器解码音频流，所以这里添加一下 ADTS 头.
                    [strongSelf.fileHandle writeData:[FSAudioTools adtsDataWithChannels:audioFormat.mChannelsPerFrame sampleRate:audioFormat.mSampleRate rawDataLength:totolLength]];
                    
                    // 4.写入 AAC packet 数据.
                    [strongSelf.fileHandle writeData:[NSData dataWithBytes:dataPointer length:totolLength]];
                }
            }
            // 封装
            else if (self.opType == FSMediaOpTypeAudioMuxer) {
                [strongSelf.muxer appendSampleBuffer:sampleBuffer];
            }
        };
    }
    return _audioEncoder;
}

- (FSMuxerConfig *)muxerConfig {
    if (!_muxerConfig) {
        _muxerConfig = [[FSMuxerConfig alloc] init];
        _muxerConfig.outputURL = [NSURL fileURLWithPath:self.audioPath];
        _muxerConfig.muxerType = FSMediaAudio; // 音频封装->m4a
    }
    
    return _muxerConfig;
}

// 音频封装
- (FSMP4Muxer *)muxer {
    if (!_muxer) {
        _muxer = [[FSMP4Muxer alloc] initWithConfig:self.muxerConfig];
        _muxer.errorCallBack = ^(NSError* error) {
            NSLog(@"FSMP4Muxer error:%zi %@", error.code, error.localizedDescription);
        };
    }
    
    return _muxer;
}

// 解封装
- (FSDemuxerConfig *)demuxerConfig {
    if (!_demuxerConfig) {
        _demuxerConfig = [[FSDemuxerConfig alloc] init];
        // 只解封装音频.
        _demuxerConfig.demuxerType = FSMediaAudio;
        // 待解封装的资源.
        NSString *assetPath = [[NSBundle mainBundle] pathForResource:@"input" ofType:@"mp4"];
        _demuxerConfig.asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:assetPath]];
    }
    
    return _demuxerConfig;
}

- (FSMP4Demuxer *)demuxer {
    if (!_demuxer) {
        _demuxer = [[FSMP4Demuxer alloc] initWithConfig:self.demuxerConfig];
        _demuxer.errorCallBack = ^(NSError *error) {
            NSLog(@"FSMP4Demuxer error:%zi %@", error.code, error.localizedDescription);
        };
    }
    
    return _demuxer;
}

- (FSAudioDecoder *)decoder {
    if (!_decoder) {
        __weak typeof(self) weakSelf = self;
        _decoder = [[FSAudioDecoder alloc] init];
        _decoder.errorCallBack = ^(NSError *error) {
            NSLog(@"FSAudioDecoder error:%zi %@", error.code, error.localizedDescription);
        };
        // 解码数据回调。在这里把解码后的音频 PCM 数据存储为文件。
        _decoder.sampleBufferOutputCallBack = ^(CMSampleBufferRef sampleBuffer) {
            if (sampleBuffer) {
                CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
                size_t totolLength;
                char *dataPointer = NULL;
                CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &totolLength, &dataPointer);
                if (totolLength == 0 || !dataPointer) {
                    return;
                }
                
                [weakSelf.fileHandle writeData:[NSData dataWithBytes:dataPointer length:totolLength]];
            }
        };
    }
    
    return _decoder;
}

@end
