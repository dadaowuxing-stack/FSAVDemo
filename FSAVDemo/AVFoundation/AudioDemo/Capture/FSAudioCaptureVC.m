//
//  FSAudioCaptureVC.m
//  FSAVDemo
//
//  Created by louis on 2022/7/14.
//

#import "FSAudioCaptureVC.h"
#import <AVFoundation/AVFoundation.h>
// 采集
#import "FSAudioCapture.h"

@interface FSAudioCaptureVC ()

@property (nonatomic, strong) FSAudioConfig *audioConfig;
@property (nonatomic, strong) FSAudioCapture *audioCapture;   // 1.采集

@end

@implementation FSAudioCaptureVC

- (void)viewDidLoad {
    [super viewDidLoad];
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
    } else {
        self.isRecording = NO;
        [self.audioButton setTitle:self.startTitle forState:UIControlStateNormal];
        
        // 停止采集器.
        [self.audioCapture stopRunning];
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
                 (1)采集音频数据, 将 PCM 数据写入文件
                 */
                // 1.获取 CMBlockBuffer，这里面封装着 PCM 数据.
                CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
                size_t lengthAtOffsetOutput, totalLengthOutput;
                char *dataPointer;
                
                // 2.从 CMBlockBuffer 中获取 PCM 数据存储到文件中.
                // 将数据复制到 dataPointer 中
                CMBlockBufferGetDataPointer(blockBuffer, 0, &lengthAtOffsetOutput, &totalLengthOutput, &dataPointer);
                [strongSelf.fileHandle writeData:[NSData dataWithBytes:dataPointer length:totalLengthOutput]];
            }
        };
    }
    return _audioCapture;
}

@end
