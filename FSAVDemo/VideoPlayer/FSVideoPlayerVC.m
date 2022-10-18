//
//  FSVideoPlayerVC.m
//  FSAVDemo
//
//  Created by louis on 2022/10/12.
//

#import "FSVideoPlayerVC.h"

@interface FSVideoPlayerVC ()<FSFillDataDelegate>{
    FSVideoOutput  *_videoOutput;
    FSAudioOutput  *_audioOutput; // 音频输出模块
    NSDictionary   *_parameters;
    CGRect         _contentFrame;
    
    BOOL           _isPlaying;
    EAGLSharegroup *_shareGroup;
}

@property(nonatomic, strong) FSAVSynchronizer      *synchronizer;        // 音频视频同步
@property(nonatomic, copy) NSString                *videoFilePath;       // 视频文件路径
@property(nonatomic, weak) id<FSPlayerStateDelegate> playerStateDelegate;// 播放状态代理

@end

@implementation FSVideoPlayerVC

+ (instancetype)viewControllerWithContentPath:(NSString *)path
                                 contentFrame:(CGRect)frame
                          playerStateDelegate:(id<FSPlayerStateDelegate>) playerStateDelegate
                                   parameters: (NSDictionary *)parameters {
    return [[FSVideoPlayerVC alloc] initWithContentPath:path
                                           contentFrame:frame
                                    playerStateDelegate:playerStateDelegate
                                             parameters:parameters];
}

+ (instancetype)viewControllerWithContentPath:(NSString *)path
                                 contentFrame:(CGRect)frame
                          playerStateDelegate:(id<FSPlayerStateDelegate>) playerStateDelegate
                                   parameters: (NSDictionary *)parameters
                  outputEAGLContextShareGroup:(EAGLSharegroup *)sharegroup
{
    return [[FSVideoPlayerVC alloc] initWithContentPath:path
                                           contentFrame:frame
                                    playerStateDelegate:playerStateDelegate
                                             parameters:parameters
                            outputEAGLContextShareGroup:sharegroup];
}

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
    // 初始化音视频同步模块
    _synchronizer = [[FSAVSynchronizer alloc] initWithPlayerStateDelegate:self.playerStateDelegate];
    __weak FSVideoPlayerVC *weakSelf = self;
    BOOL isIOS8OrUpper = ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0);
    dispatch_async(dispatch_get_global_queue(isIOS8OrUpper ? QOS_CLASS_USER_INTERACTIVE: DISPATCH_QUEUE_PRIORITY_HIGH, 0) , ^{
        __strong FSVideoPlayerVC *strongSelf = weakSelf;
        if (strongSelf) {
            NSError *error = nil;
            FSOpenState state = OPEN_FAILED;
            if([strongSelf->_parameters count] > 0){
                state = [strongSelf.synchronizer openFile:strongSelf.videoFilePath parameters:strongSelf->_parameters error:&error];
            } else {
                state = [strongSelf.synchronizer openFile:strongSelf.videoFilePath error:&error];
            }
            if(OPEN_SUCCESS == state){
                //启动AudioOutput与VideoOutput
                dispatch_async(dispatch_get_main_queue(), ^{
                    strongSelf->_videoOutput = [strongSelf createVideoOutputInstance];
                    strongSelf->_videoOutput.contentMode = UIViewContentModeScaleAspectFill;
                    strongSelf->_videoOutput.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
                    self.view.backgroundColor = [UIColor clearColor];
                    [self.view insertSubview:strongSelf->_videoOutput atIndex:0];
                });
                NSInteger audioChannels = [strongSelf->_synchronizer getAudioChannels];
                NSInteger audioSampleRate = [strongSelf->_synchronizer getAudioSampleRate];
                NSInteger bytesPerSample = 2;
                strongSelf->_audioOutput = [[FSAudioOutput alloc] initWithChannels:audioChannels sampleRate:audioSampleRate bytesPerSample:bytesPerSample filleDataDelegate:self];
                [strongSelf->_audioOutput play];
                strongSelf->_isPlaying = YES;
                
                if(strongSelf.playerStateDelegate && [strongSelf.playerStateDelegate respondsToSelector:@selector(openSucceed)]){
                    [strongSelf.playerStateDelegate openSucceed];
                }
            } else if(OPEN_FAILED == state){
                if(strongSelf.playerStateDelegate && [strongSelf.playerStateDelegate respondsToSelector:@selector(connectFailed)]){
                    [strongSelf.playerStateDelegate connectFailed];
                }
            }
        }
    });
}

- (FSVideoOutput*)createVideoOutputInstance {
    CGRect bounds = self.view.bounds;
    NSInteger textureWidth = [_synchronizer getVideoFrameWidth];
    NSInteger textureHeight = [_synchronizer getVideoFrameHeight];
    return [[FSVideoOutput alloc] initWithFrame:bounds
                                   textureWidth:textureWidth
                                  textureHeight:textureHeight
                                     shareGroup:_shareGroup];
}

- (FSVideoOutput*) getVideoOutputInstance {
    return _videoOutput;
}

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:_contentFrame];
    self.view.backgroundColor = [UIColor clearColor];
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
