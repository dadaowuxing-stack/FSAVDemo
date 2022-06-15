//
//  FSAudioCaptureVC.m
//  FSAVDemo
//
//  Created by louis on 2022/5/27.
//

#import "FSAudioHandleVC.h"
#import <AVFoundation/AVFoundation.h>
#import "FSAudioTools.h"
#import "FSAudioEncoder.h"
#import "FSAudioCapture.h"
#import "FSMuxerConfig.h"
#import "FSMP4Muxer.h"

@interface FSAudioHandleVC ()

@property (nonatomic, strong) FSAudioConfig *audioConfig;
@property (nonatomic, strong) FSAudioCapture *audioCapture; // 音频采集
@property (nonatomic, strong) FSAudioEncoder *audioEncoder; // 音频编码
@property (nonatomic, strong) FSMuxerConfig *muxerConfig;
@property (nonatomic, strong) FSMP4Muxer *muxer;

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
    switch (self.opType) {
        case FSMediaOpTypeAudioCapture: {
            pathComponent = @"out.pcm";
        }
            break;
        case FSMediaOpTypeAudioEncoder: {
            pathComponent = @"out.aac";
        }
            break;
        case FSMediaOpTypeAudioMuxer: {
            pathComponent = @"out.m4a";
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
    
    self.audioButton = [self buttonWithFrame:CGRectMake(100, 100, 150, 50) title:@"开始采集" action:@selector(audioButtonAction:)];
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
    if (!self.isRecording) {
        self.isRecording = YES;
        [self.audioButton setTitle:@"停止采集" forState:UIControlStateNormal];
        // 启动采集器。
        [self.audioCapture startRunning];
        // 启动封装器。
        [self.muxer startWriting];
    } else {
        self.isRecording = NO;
        [self.audioButton setTitle:@"开始采集" forState:UIControlStateNormal];
        // 停止采集器。
        [self.audioCapture stopRunning];
        // 停止封装器。
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
                if (self.opType == FSMediaOpTypeAudioCapture) {
                    // 1.获取 CMBlockBuffer，这里面封装着 PCM 数据.
                    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
                    size_t lengthAtOffsetOutput, totalLengthOutput;
                    char *dataPointer;
                    
                    // 2.从 CMBlockBuffer 中获取 PCM 数据存储到文件中.
                    CMBlockBufferGetDataPointer(blockBuffer, 0, &lengthAtOffsetOutput, &totalLengthOutput, &dataPointer);
                    [strongSelf.fileHandle writeData:[NSData dataWithBytes:dataPointer length:totalLengthOutput]];
                } else if (self.opType == FSMediaOpTypeAudioEncoder || self.opType == FSMediaOpTypeAudioMuxer) {
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

- (FSAudioEncoder *)audioEncoder {
    if (!_audioEncoder) {
        __weak typeof(self) weakSelf = self;
        _audioEncoder = [[FSAudioEncoder alloc] initWithAudioBitrate:96000];
        _audioEncoder.errorCallBack = ^(NSError* error) {
            NSLog(@"FSAudioEncoder error:%zi %@", error.code, error.localizedDescription);
        };
        // 音频编码数据回调:在这里将 AAC 数据写入文件.
        // 音频编码数据回调:这里编码的 AAC 数据送给封装器。
        // 与之前将编码后的 AAC 数据存储为 AAC 文件不同的是，这里编码后送给封装器的 AAC 数据是没有添加 ADTS 头的，因为我们这里封装的是 M4A 格式，不需要 ADTS 头.
        _audioEncoder.sampleBufferOutputCallBack = ^(CMSampleBufferRef sampleBuffer) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (self.opType == FSMediaOpTypeAudioEncoder) {
                if (sampleBuffer) {
                    // 1.获取音频编码参数信息.
                    AudioStreamBasicDescription audioFormat = *CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sampleBuffer));
                    
                    // 2.获取音频编码数据。AAC 裸数据.
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
            } else if (self.opType == FSMediaOpTypeAudioMuxer) {
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

- (FSMP4Muxer *)muxer {
    if (!_muxer) {
        _muxer = [[FSMP4Muxer alloc] initWithConfig:self.muxerConfig];
        _muxer.errorCallBack = ^(NSError* error) {
            NSLog(@"FSMP4Muxer error:%zi %@", error.code, error.localizedDescription);
        };
    }
    
    return _muxer;
}

@end
