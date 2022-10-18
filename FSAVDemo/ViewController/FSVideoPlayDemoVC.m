//
//  FSVideoPlayDemoVC.m
//  FSAVDemo
//
//  Created by louis on 2022/10/17.
//

#import "FSVideoPlayDemoVC.h"
#import "FSVideoPlayerVC.h"

@interface FSVideoPlayDemoVC ()<FSPlayerStateDelegate> {
    FSVideoPlayerVC *_videoPlayerVC;
}

@end

@implementation FSVideoPlayDemoVC

+ (id)viewControllerWithContentPath:(NSString *)path
                       contentFrame:(CGRect)frame
                         parameters: (NSDictionary *)parameters {
    return [[FSVideoPlayDemoVC alloc] initWithContentPath:path
                                             contentFrame:frame
                                               parameters:parameters];
}

- (id)initWithContentPath:(NSString *)path
              contentFrame:(CGRect)frame
                parameters:(NSDictionary *)parameters {
    
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        NSMutableDictionary *requestHeader = [NSMutableDictionary dictionary];
        requestHeader[kMIN_BUFFERED_DURATION] = @(1.0f);
        requestHeader[kMAX_BUFFERED_DURATION] = @(3.0f);
        _videoPlayerVC = [FSVideoPlayerVC viewControllerWithContentPath:path contentFrame:frame playerStateDelegate:self parameters:requestHeader];
        [self addChildViewController:_videoPlayerVC];
        [self.view addSubview:_videoPlayerVC.view];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Video Play Demo";
    self.view.backgroundColor = [UIColor blackColor];
}

- (void) viewWillDisappear:(BOOL)animated {
    [_videoPlayerVC stop];
    [_videoPlayerVC.view removeFromSuperview];
    [_videoPlayerVC removeFromParentViewController];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    if ([_videoPlayerVC isPlaying]) {
        NSLog(@"restart after memorywarning");
        [self restart];
    } else {
        [_videoPlayerVC stop];
    }
}


#pragma mark - Player State Callback

- (void)restart {
    //Loading 或者 毛玻璃效果在这里处理
    [_videoPlayerVC restart];
}

- (void)connectFailed {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alterView = [[UIAlertView alloc] initWithTitle:@"提示信息" message:@"打开视频失败, 请检查文件或者远程连接是否存在！" delegate:self cancelButtonTitle:@"取消" otherButtonTitles: nil];
        [alterView show];
    });
}

- (void)statisticsCallback:(FSStatistics *)statistics {
    long long beginOpen = statistics.beginOpen;
    float successOpen = statistics.successOpen;
    float firstScreenTimeMills = statistics.firstScreenTimeMills;
    float failOpen = statistics.failOpen;
    float failOpenType = statistics.failOpenType;
    int retryTimes = statistics.retryTimes;
    float duration = statistics.duration;
    NSMutableArray* bufferStatusRecords = statistics.bufferStatusRecords;
    NSMutableString* statisticsString = [NSMutableString stringWithFormat:
                                              @"beginOpen : [%lld]", beginOpen];
    [statisticsString appendFormat:@"successOpen is [%.3f]", successOpen];
    [statisticsString appendFormat:@"firstScreenTimeMills is [%.3f]", firstScreenTimeMills];
    [statisticsString appendFormat:@"failOpen is [%.3f]", failOpen];
    [statisticsString appendFormat:@"failOpenType is [%.3f]", failOpenType];
    [statisticsString appendFormat:@"retryTimes is [%d]", retryTimes];
    [statisticsString appendFormat:@"duration is [%.3f]", duration];
    for (NSString* bufferStatus in bufferStatusRecords) {
        [statisticsString appendFormat:@"buffer status is [%@]", bufferStatus];
    }
    
    NSLog(@"statistics is %@", statisticsString);
}

- (void)onCompletion {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alterView = [[UIAlertView alloc] initWithTitle:@"提示信息" message:@"视频播放完毕了" delegate:self cancelButtonTitle:@"取消" otherButtonTitles: nil];
        [alterView show];
    });
    
}
@end
