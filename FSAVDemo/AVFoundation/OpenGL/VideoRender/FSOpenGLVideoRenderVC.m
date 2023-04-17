//
//  FSOpenGLVideoRenderVC.m
//  FSAVDemo
//
//  Created by liufengshuo on 2023/4/17.
//  在这个VC里将采集模块和渲染模块串起来了

#import "FSOpenGLVideoRenderVC.h"
#import "FSVideoCapture.h"
#import "FSPixelBufferConvertTexture.h"
#import "FSOpenGLView.h"

@interface FSOpenGLVideoRenderVC ()
@property (nonatomic, strong) FSVideoCaptureConfig *videoCaptureConfig;
@property (nonatomic, strong) FSVideoCapture *videoCapture;
@property (nonatomic, strong) FSOpenGLView *glView;
@property (nonatomic, strong) FSPixelBufferConvertTexture *pixelBufferConvertTexture;
@property (nonatomic, strong) EAGLContext *context;
@end

@implementation FSOpenGLVideoRenderVC

#pragma mark - Property
- (FSVideoCaptureConfig *)videoCaptureConfig {
    if (!_videoCaptureConfig) {
        _videoCaptureConfig = [[FSVideoCaptureConfig alloc] init];
    }
    
    return _videoCaptureConfig;
}

- (EAGLContext *)context {
    if (!_context) {
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    
    return _context;
}

- (FSPixelBufferConvertTexture *)pixelBufferConvertTexture {
    if (!_pixelBufferConvertTexture) {
        _pixelBufferConvertTexture = [[FSPixelBufferConvertTexture alloc] initWithContext:self.context];
    }
    
    return _pixelBufferConvertTexture;
}

- (FSVideoCapture *)videoCapture {
    if (!_videoCapture) {
        _videoCapture = [[FSVideoCapture alloc] initWithConfig:self.videoCaptureConfig];
        __weak typeof(self) weakSelf = self;
        _videoCapture.sampleBufferOutputCallBack = ^(CMSampleBufferRef sampleBuffer) {
             // 视频采集数据回调。将采集回来的数据给渲染模块渲染。
            [EAGLContext setCurrentContext:weakSelf.context];
            FSTextureFrame *textureFrame = [weakSelf.pixelBufferConvertTexture renderFrame:CMSampleBufferGetImageBuffer(sampleBuffer) time:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
            [weakSelf.glView displayFrame:textureFrame];
            [EAGLContext setCurrentContext:nil];
        };
        _videoCapture.sessionErrorCallBack = ^(NSError* error) {
            NSLog(@"FSVideoCapture Error:%zi %@", error.code, error.localizedDescription);
        };
    }
    
    return _videoCapture;
}

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];

    [self requestAccessForVideo];
    [self setupUI];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.glView.frame = self.view.bounds;
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
            // 许可对话没有出现，发起授权许可。
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    [weakSelf.videoCapture startRunning];
                } else {
                    // 用户拒绝。
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:{
            // 已经开启授权，可继续。
            [weakSelf.videoCapture startRunning];
            break;
        }
        default:
            break;
    }
}

- (void)setupUI {
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.title = @"Video Render";
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Navigation item.
    UIBarButtonItem *cameraBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Camera" style:UIBarButtonItemStylePlain target:self action:@selector(changeCamera)];
    self.navigationItem.rightBarButtonItems = @[cameraBarButton];
    
    // 渲染 view。
    _glView = [[FSOpenGLView alloc] initWithFrame:self.view.bounds context:self.context];
    _glView.fillMode = FSGLViewContentModeFill;
    [self.view addSubview:self.glView];
}

@end
