//
//  FSAudioMuxerVC.m
//  FSAVDemo
//
//  Created by louis on 2022/7/14.
//

#import "FSAudioMuxerVC.h"
#import <AVFoundation/AVFoundation.h>
// 采集
#import "FSAudioCapture.h"
// 编码
#import "FSAudioEncoder.h"
// 封装
#import "FSMP4Muxer.h"

@interface FSAudioMuxerVC ()

@property (nonatomic, strong) FSAudioConfig *audioConfig;
@property (nonatomic, strong) FSAudioCapture *audioCapture;   // 1.采集
@property (nonatomic, strong) FSAudioEncoder *audioEncoder;   // 2.编码
@property (nonatomic, strong) FSMuxerConfig *muxerConfig;
@property (nonatomic, strong) FSMP4Muxer *audioMuxer;         // 3.封装

@end

@implementation FSAudioMuxerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _setupAudioSession];
}

#pragma mark - Action

- (void)buttonAction:(UIButton *)sender {
    // 采集->编码->封装->解封装->解码->渲染
    [self _captureAction];
}

- (void)_captureAction {
    if (!self.isRecording) {
        self.isRecording = YES;
        [self.audioButton setTitle:self.stopTitle forState:UIControlStateNormal];
        
        // 启动采集器.
        [self.audioCapture startRunning];
        // 启动封装器.
        [self.audioMuxer startWriting];
    } else {
        self.isRecording = NO;
        [self.audioButton setTitle:self.startTitle forState:UIControlStateNormal];
        
        // 停止采集器.
        [self.audioCapture stopRunning];
        // 停止封装器.
        [self.audioMuxer stopWriting:^(BOOL success, NSError * _Nonnull error) {
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
                 (2) 将采集的 PCM 数据送给编码器
                 */
                [strongSelf.audioEncoder encodeSampleBuffer:sampleBuffer];
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
            if (sampleBuffer) {
                // 音频封装:将数据传给封装器
                [strongSelf.audioMuxer appendSampleBuffer:sampleBuffer];
            }
        };
    }
    return _audioEncoder;
}

- (FSMuxerConfig *)muxerConfig {
    if (!_muxerConfig) {
        _muxerConfig = [[FSMuxerConfig alloc] init];
        _muxerConfig.outputURL = [NSURL fileURLWithPath:self.path];
        _muxerConfig.muxerType = FSMediaAudio; // 音频封装->m4a
    }
    
    return _muxerConfig;
}

// 音频封装
- (FSMP4Muxer *)audioMuxer {
    if (!_audioMuxer) {
        _audioMuxer = [[FSMP4Muxer alloc] initWithConfig:self.muxerConfig];
        _audioMuxer.errorCallBack = ^(NSError* error) {
            NSLog(@"FSMP4Muxer error:%zi %@", error.code, error.localizedDescription);
        };
    }
    
    return _audioMuxer;
}

@end
