//
//  FSAudioDemuxerVC.m
//  FSAVDemo
//
//  Created by louis on 2022/7/14.
//

#import "FSAudioDemuxerVC.h"
#import "FSAudioTools.h"
#import "FSMP4Demuxer.h"

@interface FSAudioDemuxerVC ()

@property (nonatomic, strong) FSDemuxerConfig *demuxerConfig;
@property (nonatomic, strong) FSMP4Demuxer *audioDemuxer;          // 4.解封装

@end

@implementation FSAudioDemuxerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

#pragma mark - Action

- (void)buttonAction:(UIButton *)sender {
    // 采集->编码->封装->解封装->解码->渲染
    [self _demuxerAction];
}

- (void)_demuxerAction {
    __weak typeof(self) weakSelf = self;
    [self.audioDemuxer startReading:^(BOOL success, NSError * _Nonnull error) {
        if (success) {
            // Demuxer 启动成功后，就可以从它里面获取解封装后的数据了.
            [weakSelf fetchAndSaveDemuxedData];
        } else {
            NSLog(@"FSMP4Demuxer error: %zi %@", error.code, error.localizedDescription);
        }
    }];
}

#pragma mark - Utility

- (void)fetchAndSaveDemuxedData {
    // 异步地从 Demuxer 获取解封装后的 AAC 编码数据，送给解码器进行解码.
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (weakSelf.audioDemuxer.hasAudioSampleBuffer) {
            CMSampleBufferRef audioBuffer = [weakSelf.audioDemuxer copyNextAudioSampleBuffer];
            if (audioBuffer) {
                // 解封装
                [weakSelf saveSampleBuffer:audioBuffer];
                CFRelease(audioBuffer);
            }
        }
        if (self.audioDemuxer.demuxerStatus == FSMP4DemuxerStatusCompleted) {
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


#pragma mark - Properties
// 解封装
- (FSDemuxerConfig *)demuxerConfig {
    if (!_demuxerConfig) {
        _demuxerConfig = [[FSDemuxerConfig alloc] init];
        // 只解封装音频.
        _demuxerConfig.demuxerType = FSMediaAudio;
        // 待解封装的资源.
        NSString *assetPath = [[NSBundle mainBundle] pathForResource:@"input_1280x720" ofType:@"mp4"];
        _demuxerConfig.asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:assetPath]];
    }
    
    return _demuxerConfig;
}

- (FSMP4Demuxer *)audioDemuxer {
    if (!_audioDemuxer) {
        _audioDemuxer = [[FSMP4Demuxer alloc] initWithConfig:self.demuxerConfig];
        _audioDemuxer.errorCallBack = ^(NSError *error) {
            NSLog(@"FSMP4Demuxer error:%zi %@", error.code, error.localizedDescription);
        };
    }
    
    return _audioDemuxer;
}

@end
