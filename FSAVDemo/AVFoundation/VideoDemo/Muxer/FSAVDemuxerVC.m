//
//  FSAVDemuxerVC.m
//  FSAVDemo
//
//  Created by louis on 2022/7/21.
//

#import "FSAVDemuxerVC.h"
#import "FSMP4Demuxer.h"
#import "FSMP4Muxer.h"

@interface FSAVDemuxerVC ()

@property (nonatomic, strong) FSDemuxerConfig *demuxerConfig;
@property (nonatomic, strong) FSMP4Demuxer *demuxer;
@property (nonatomic, strong) FSMuxerConfig *muxerConfig;
@property (nonatomic, strong) FSMP4Muxer *muxer;

@end

@implementation FSAVDemuxerVC

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *startBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Start" style:UIBarButtonItemStylePlain target:self action:@selector(start)];
    self.navigationItem.rightBarButtonItems = @[startBarButton];
}

#pragma mark - Action
- (void)start {
    __weak typeof(self) weakSelf = self;
    NSLog(@"FSMP4Demuxer start");
    [self.demuxer startReading:^(BOOL success, NSError * _Nonnull error) {
        if (success) {
            // Demuxer 启动成功后，就可以从它里面获取解封装后的数据了.
            [weakSelf fetchAndRemuxData];
        }else{
            NSLog(@"FSDemuxer error: %zi %@", error.code, error.localizedDescription);
        }
    }];
}

#pragma mark - Utility

- (void)fetchAndRemuxData {
    // 异步地从 Demuxer 获取解封装后的 H.264/H.265 编码数据，再重新封装.
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.muxer startWriting];
        while (self.demuxer.hasVideoSampleBuffer || self.demuxer.hasAudioSampleBuffer) {
            CMSampleBufferRef videoBuffer = [self.demuxer copyNextVideoSampleBuffer];
            if (videoBuffer) {
                [self.muxer appendSampleBuffer:videoBuffer];
                CFRelease(videoBuffer);
            }
            
            CMSampleBufferRef audioBuffer = [self.demuxer copyNextAudioSampleBuffer];
            if (audioBuffer) {
                [self.muxer appendSampleBuffer:audioBuffer];
                CFRelease(audioBuffer);
            }
        }
        if (self.demuxer.demuxerStatus == FSMP4DemuxerStatusCompleted) {
            NSLog(@"FSMP4Demuxer complete");
            [self.muxer stopWriting:^(BOOL success, NSError * _Nonnull error) {
                NSLog(@"FSMP4Muxer complete:%d", success);
            }];
        }
    });
}

#pragma mark - Property

- (FSDemuxerConfig *)demuxerConfig {
    if (!_demuxerConfig) {
        _demuxerConfig = [[FSDemuxerConfig alloc] init];
        _demuxerConfig.demuxerType = FSMediaAV;
        NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"input_1280x720" ofType:@"mp4"];
        _demuxerConfig.asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
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

- (FSMuxerConfig *)muxerConfig {
    if (!_muxerConfig) {
        _muxerConfig = [[FSMuxerConfig alloc] init];
        NSString *videoPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"av_remuxer_output.mp4"];
        NSLog(@"MP4 file path: %@", videoPath);
        [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
        _muxerConfig.outputURL = [NSURL fileURLWithPath:videoPath];
        _muxerConfig.muxerType = FSMediaAV;
    }
    
    return _muxerConfig;
}

- (FSMP4Muxer *)muxer {
    if (!_muxer) {
        _muxer = [[FSMP4Muxer alloc] initWithConfig:self.muxerConfig];
    }
    
    return _muxer;
}

@end
