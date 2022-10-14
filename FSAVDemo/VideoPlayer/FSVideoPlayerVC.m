//
//  FSVideoPlayerVC.m
//  FSAVDemo
//
//  Created by louis on 2022/10/12.
//

#import "FSVideoPlayerVC.h"

@interface FSVideoPlayerVC ()<FSFillDataDelegate>{
    FSAudioOutput  *_audioOutput; // 音频输出模块
    NSDictionary   *_parameters;
    CGRect         _contentFrame;
    
    BOOL           _isPlaying;
    EAGLSharegroup *_shareGroup;
}

@property(nonatomic, strong) FSAVSynchronizer      *synchronizer;
@property(nonatomic, copy) NSString                *videoFilePath;
@property(nonatomic, weak) id<FSPlayerStateDelegate> playerStateDelegate;

@end

@implementation FSVideoPlayerVC

- (instancetype)initWithContentPath:(NSString *)path
                       contentFrame:(CGRect)frame
                playerStateDelegate:(id) playerStateDelegate
                         parameters:(NSDictionary *)parameters {
    return [self initWithContentPath:path
                        contentFrame:frame
                 playerStateDelegate:playerStateDelegate
                          parameters:parameters
         outputEAGLContextShareGroup:nil];
}

- (instancetype)initWithContentPath:(NSString *)path
                       contentFrame:(CGRect)frame
                playerStateDelegate:(id) playerStateDelegate
                         parameters:(NSDictionary *)parameters
        outputEAGLContextShareGroup:(EAGLSharegroup *)sharegroup {
    NSAssert(path.length > 0, @"content path is empty");
    self = [super init];
    if (self) {
        _videoFilePath = path;
        _contentFrame = frame;
        _playerStateDelegate = playerStateDelegate;
        _parameters = parameters;
        _shareGroup = sharegroup;
        [self start];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

- (void)start {
    _synchronizer = [[FSAVSynchronizer alloc] initWithPlayerStateDelegate:_playerStateDelegate];
    __weak FSVideoPlayerVC *weakSelf = self;
    BOOL isIOS8OrUpper = ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0);
    dispatch_async(dispatch_get_global_queue(isIOS8OrUpper ? QOS_CLASS_USER_INTERACTIVE : DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        __strong FSVideoPlayerVC *strongSelf = weakSelf;
        if (strongSelf) {
            
        }
    });
}

- (void)play {
    if (_isPlaying) {
        return;
    }
    if(_audioOutput){
        [_audioOutput play];
    }
}

- (void)pause {
    if (!_isPlaying) {
        return;
    }
    if(_audioOutput){
        [_audioOutput stop];
    }
}

- (void)stop {
    if(_audioOutput){
        [_audioOutput stop];
        _audioOutput = nil;
    }
}

- (void)restart {
    
}

- (BOOL)isPlaying {
    return _isPlaying;
}

#pragma mark - FSFillDataDelegate

- (NSInteger)fillAudioData:(nonnull SInt16 *)sampleBuffer
                 numFrames:(NSInteger)frameNum
               numChannels:(NSInteger)channels {
    
    return -1;
}

@end
