//
//  FSAudioRenderVC.m
//  FSAVDemo
//
//  Created by louis on 2022/7/14.
//

#import "FSAudioRenderVC.h"
#import <AVFoundation/AVFoundation.h>
#import "FSWeakProxy.h"
// 解封装
#import "FSMP4Demuxer.h"
// 解码
#import "FSAudioDecoder.h"
// 渲染
#import "FSAudioRender.h"

#define FSDecoderMaxCache 4096 * 5 // 解码数据缓冲区最大长度.

@interface FSAudioRenderVC ()

@property (nonatomic, strong) FSDemuxerConfig *demuxerConfig;
@property (nonatomic, strong) FSMP4Demuxer *audioDemuxer;
@property (nonatomic, strong) FSAudioDecoder *audioDecoder;
@property (nonatomic, strong) FSAudioRender *audioRender;

@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) NSMutableData *pcmDataCache; // 解码数据缓冲区.
@property (nonatomic, assign) NSInteger pcmDataCacheLength;
@property (nonatomic, strong) CADisplayLink *timer;

@end

@implementation FSAudioRenderVC

#pragma mark - Lifecycle

- (void)dealloc {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.semaphore = dispatch_semaphore_create(1);
    self.pcmDataCache = [[NSMutableData alloc] init];
    
    [self _setupAudioSession];
    
    // 通过一个 timer 来保证持续从文件中解封装和解码一定量的数据.
    self.timer = [CADisplayLink displayLinkWithTarget:[FSWeakProxy proxyWithTarget:self] selector:@selector(timerCallBack:)];
    [self.timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [self.timer setPaused:NO];
    
    [self.audioDemuxer startReading:^(BOOL success, NSError * _Nonnull error) {
        NSLog(@"FSMP4Demuxer start:%d", success);
    }];
}

#pragma mark - Action

- (void)buttonAction:(UIButton *)sender {
    if (!self.isRecording) {
        self.isRecording = YES;
        [self.audioButton setTitle:self.stopTitle forState:UIControlStateNormal];
        [self _startRender];
    } else {
        self.isRecording = NO;
        [self.audioButton setTitle:self.startTitle forState:UIControlStateNormal];
        [self _stopRender];
    }
}

- (void)_startRender {
    // 开始渲染
    [self.audioRender startPlaying];
}

- (void)_stopRender {
    // 停止渲染
    [self.audioRender stopPlaying];
}

#pragma mark - Utility

- (void)_setupAudioSession {
    // 1、获取音频会话实例.
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    // 2、设置分类.
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error) {
        NSLog(@"AVAudioSession setCategory error");
    }
    
    // 3、激活会话.
    [session setActive:YES error:&error];
    if (error) {
        NSLog(@"AVAudioSession setActive error");
    }
}

- (void)timerCallBack:(CADisplayLink *)timer {
    // 定时从文件中解封装和解码一定量（不超过 FSDecoderMaxCache）的数据.
    if (self.pcmDataCacheLength <  FSDecoderMaxCache && self.audioDemuxer.demuxerStatus == FSMP4DemuxerStatusRunning && self.audioDemuxer.hasAudioSampleBuffer) {
        CMSampleBufferRef audioBuffer = [self.audioDemuxer copyNextAudioSampleBuffer];
        if (audioBuffer) {
            [self decodeSampleBuffer:audioBuffer];
            CFRelease(audioBuffer);
        }
    }
}

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
    NSLog(@"Samples Num: %ld", CMSampleBufferGetNumSamples(sampleBuffer)); // 包数量
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

#pragma mark - Property

- (FSDemuxerConfig *)demuxerConfig {
    if (!_demuxerConfig) {
        _demuxerConfig = [[FSDemuxerConfig alloc] init];
        _demuxerConfig.demuxerType = FSMediaAudio;
        NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"input" ofType:@"mp4"];
        _demuxerConfig.asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
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
                dispatch_semaphore_wait(weakSelf.semaphore, DISPATCH_TIME_FOREVER);
                [weakSelf.pcmDataCache appendData:[NSData dataWithBytes:dataPointer length:totolLength]];
                weakSelf.pcmDataCacheLength += totolLength;
                dispatch_semaphore_signal(weakSelf.semaphore);
            }
        };
    }
    
    return _audioDecoder;
}

- (FSAudioRender *)audioRender {
    if (!_audioRender) {
        __weak typeof(self) weakSelf = self;
        // 这里设置的音频声道数、采样位深、采样率需要跟输入源的音频参数一致.
        _audioRender = [[FSAudioRender alloc] initWithChannels:2 bitDepth:16 sampleRate:44100];
        _audioRender.errorCallBack = ^(NSError* error) {
            NSLog(@"FSAudioRender error:%zi %@", error.code, error.localizedDescription);
        };
        // 渲染输入数据回调.在这里把缓冲区的数据交给系统音频渲染单元渲染.
        _audioRender.audioBufferInputCallBack = ^(AudioBufferList * _Nonnull audioBufferList) {
            if (weakSelf.pcmDataCacheLength < audioBufferList->mBuffers[0].mDataByteSize) {
                memset(audioBufferList->mBuffers[0].mData, 0, audioBufferList->mBuffers[0].mDataByteSize);
            } else {
                dispatch_semaphore_wait(weakSelf.semaphore, DISPATCH_TIME_FOREVER);
                memcpy(audioBufferList->mBuffers[0].mData, weakSelf.pcmDataCache.bytes, audioBufferList->mBuffers[0].mDataByteSize);
                [weakSelf.pcmDataCache replaceBytesInRange:NSMakeRange(0, audioBufferList->mBuffers[0].mDataByteSize) withBytes:NULL length:0];
                weakSelf.pcmDataCacheLength -= audioBufferList->mBuffers[0].mDataByteSize;
                dispatch_semaphore_signal(weakSelf.semaphore);
            }
        };
    }
    
    return _audioRender;
}

@end
