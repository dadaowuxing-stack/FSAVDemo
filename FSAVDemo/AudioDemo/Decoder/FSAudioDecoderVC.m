//
//  FSAudioDecoderVC.m
//  FSAVDemo
//
//  Created by louis on 2022/7/14.
//

#import "FSAudioDecoderVC.h"
#import <AVFoundation/AVFoundation.h>
#import "FSAudioTools.h"
// 解封装
#import "FSMP4Demuxer.h"
// 解码
#import "FSAudioDecoder.h"

@interface FSAudioDecoderVC ()

@property (nonatomic, strong) FSDemuxerConfig *demuxerConfig;
@property (nonatomic, strong) FSMP4Demuxer *audioDemuxer;          // 4.解封装
@property (nonatomic, strong) FSAudioDecoder *audioDecoder;        // 5.解码

@end

@implementation FSAudioDecoderVC

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
                // 解码
                [weakSelf decodeSampleBuffer:audioBuffer];
                CFRelease(audioBuffer);
            }
        }
        if (self.audioDemuxer.demuxerStatus == FSMP4DemuxerStatusCompleted) {
            NSLog(@"FSMP4Demuxer complete");
        }
    });
}

// 解码
- (void)decodeSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    // 获取解封装后的 AAC 编码裸数据.
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t totolLength;
    char *dataPointer = NULL;
    CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &totolLength, &dataPointer);
    if (totolLength == 0 || !dataPointer) {
        return;
    }
    
    // 目前 AudioDecoder 的解码接口实现的是单包（packet，1 packet 有 1024 帧）解码.而从 Demuxer 获取的一个 CMSampleBuffer 可能包含多个包，所以这里要拆一下包，再送给解码器.
    NSLog(@"SampleNum: %ld", CMSampleBufferGetNumSamples(sampleBuffer));
    for (NSInteger index = 0; index < CMSampleBufferGetNumSamples(sampleBuffer); index++) {
        // 1、获取一个包的数据.
        size_t sampleSize = CMSampleBufferGetSampleSize(sampleBuffer, index);
        CMSampleTimingInfo timingInfo;
        CMSampleBufferGetSampleTimingInfo(sampleBuffer, index, &timingInfo);
        char *sampleDataPointer = malloc(sampleSize);
        memcpy(sampleDataPointer, dataPointer, sampleSize);
        
        // 2、将数据封装到 CMBlockBuffer 中.
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
            // 3、将 CMBlockBuffer 封装到 CMSampleBuffer 中.
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
            
            // 4、解码这个包的数据.
            if (packetSampleBuffer) {
                [self.audioDecoder decodeSampleBuffer:packetSampleBuffer];
                CFRelease(packetSampleBuffer);
            }
        }
        dataPointer += sampleSize;
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
        NSString *assetPath = [[NSBundle mainBundle] pathForResource:@"input" ofType:@"mp4"];
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

- (FSAudioDecoder *)audioDecoder {
    if (!_audioDecoder) {
        __weak typeof(self) weakSelf = self;
        _audioDecoder = [[FSAudioDecoder alloc] init];
        _audioDecoder.errorCallBack = ^(NSError *error) {
            NSLog(@"FSAudioDecoder error:%zi %@", error.code, error.localizedDescription);
        };
        // 解码数据回调.在这里把解码后的音频 PCM 数据存储为文件.
        // 解码数据回调.在这里把解码后的音频 PCM 数据缓冲起来等待渲染.
        _audioDecoder.sampleBufferOutputCallBack = ^(CMSampleBufferRef sampleBuffer) {
            if (sampleBuffer) {
                CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
                size_t totolLength;
                char *dataPointer = NULL;
                CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &totolLength, &dataPointer);
                if (totolLength == 0 || !dataPointer) {
                    return;
                }
                // 把数据存储为文件
                [weakSelf.fileHandle writeData:[NSData dataWithBytes:dataPointer length:totolLength]];
            }
        };
    }
    
    return _audioDecoder;
}

@end
