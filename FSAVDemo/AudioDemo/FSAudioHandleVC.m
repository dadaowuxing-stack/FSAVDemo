//
//  FSAudioCaptureVC.m
//  FSAVDemo
//
//  Created by louis on 2022/5/27.
//

#import "FSAudioHandleVC.h"
#import "FSAudioTools.h"
#import "FSAudioEncoder.h"
#import "FSAudioCapture.h"
#import <AVFoundation/AVFoundation.h>

@interface FSAudioHandleVC ()

@property (nonatomic, strong) FSAudioConfig *audioConfig;
@property (nonatomic, strong) FSAudioCapture *audioCapture; // 音频采集
@property (nonatomic, strong) FSAudioEncoder *audioEncoder; // 音频编码

@property (nonatomic, strong) NSFileHandle *fileHandle;

@property (nonatomic, strong) UIButton *audioButton;
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, copy) NSString *startTitle;
@property (nonatomic, copy) NSString *stopTitle;

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
    
    [self _setupAudioSession];
    [self _setupUI];
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
                
            }
                break;
                
            default:
                break;
        }
        NSString *audioPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:pathComponent];
        NSLog(@"audio file path: %@", audioPath);
        [[NSFileManager defaultManager] removeItemAtPath:audioPath error:nil];
        [[NSFileManager defaultManager] createFileAtPath:audioPath contents:nil attributes:nil];
        self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:audioPath];
        [self.audioCapture startRunning];
    } else {
        self.isRecording = NO;
        [self.audioButton setTitle:@"开始采集" forState:UIControlStateNormal];
        [self.audioCapture stopRunning];
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
                } else if (self.opType == FSMediaOpTypeAudioEncoder) {
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
        // 音频编码数据回调。在这里将 AAC 数据写入文件.
        _audioEncoder.sampleBufferOutputCallBack = ^(CMSampleBufferRef sampleBuffer) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
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
        };
    }
    return _audioEncoder;
}

@end
