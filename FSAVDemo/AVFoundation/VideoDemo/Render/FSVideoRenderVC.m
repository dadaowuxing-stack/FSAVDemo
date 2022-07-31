//
//  FSVideoRenderVC.m
//  FSAVDemo
//
//  Created by louis on 2022/7/14.
//

#import "FSVideoRenderVC.h"
#import "FSVideoCapture.h"
#import "FSMetalView.h"

@interface FSVideoRenderVC ()

@property (nonatomic, strong) FSVideoCaptureConfig *videoCaptureConfig;
@property (nonatomic, strong) FSVideoCapture *videoCapture;
@property (nonatomic, strong) FSMetalView *metalView;

@end

@implementation FSVideoRenderVC

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self requestAccessForVideo];
    [self setupUI];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.metalView.frame = self.view.bounds;
}

#pragma mark - Action

- (void)changeCamera {
    [self.videoCapture changeDevicePosition:self.videoCapture.config.position == AVCaptureDevicePositionBack ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack];
}

#pragma mark - Private Method

- (void)requestAccessForVideo {
    __weak typeof(self) weakSelf = self;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusNotDetermined:{
            // 许可对话没有出现，发起授权许可.
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    [weakSelf.videoCapture startRunning];
                } else {
                    // 用户拒绝.
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:{
            // 已经开启授权，可继续.
            [weakSelf.videoCapture startRunning];
            break;
        }
        default:
            break;
    }
}

- (void)setupUI {
    // Navigation item.
    UIBarButtonItem *cameraBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Camera" style:UIBarButtonItemStylePlain target:self action:@selector(changeCamera)];
    self.navigationItem.rightBarButtonItems = @[cameraBarButton];
    
    // 渲染 view.
    _metalView = [[FSMetalView alloc] initWithFrame:self.view.bounds];
    _metalView.fillMode = FSMetalViewContentModeFill;
    [self.view addSubview:self.metalView];
}

#pragma mark - Property

- (FSVideoCaptureConfig *)videoCaptureConfig {
    if (!_videoCaptureConfig) {
        _videoCaptureConfig = [[FSVideoCaptureConfig alloc] init];
    }
    
    return _videoCaptureConfig;
}

- (FSVideoCapture *)videoCapture {
    if (!_videoCapture) {
        _videoCapture = [[FSVideoCapture alloc] initWithConfig:self.videoCaptureConfig];
        __weak typeof(self) weakSelf = self;
        _videoCapture.sampleBufferOutputCallBack = ^(CMSampleBufferRef sampleBuffer) {
             // 视频采集数据回调.将采集回来的数据给渲染模块渲染.
            [weakSelf.metalView renderPixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer)];
        };
        _videoCapture.sessionErrorCallBack = ^(NSError* error) {
            NSLog(@"FSVideoCapture Error:%zi %@", error.code, error.localizedDescription);
        };
    }
    
    return _videoCapture;
}

@end
