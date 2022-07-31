//
//  FSVideoMuxerVC.m
//  FSAVDemo
//
//  Created by louis on 2022/7/14.
//

#import "FSVideoMuxerVC.h"
#import "FSVideoCapture.h"
#import "FSVideoEncoder.h"
#import "FSMP4Muxer.h"

@interface FSVideoMuxerVC ()

@property (nonatomic, strong) FSVideoCaptureConfig *videoCaptureConfig;
@property (nonatomic, strong) FSVideoCapture *videoCapture;
@property (nonatomic, strong) FSVideoEncoderConfig *videoEncoderConfig;
@property (nonatomic, strong) FSVideoEncoder *videoEncoder;
@property (nonatomic, strong) FSMuxerConfig *muxerConfig;
@property (nonatomic, strong) FSMP4Muxer *muxer;
@property (nonatomic, assign) BOOL isWriting;

@property (nonatomic, strong) UIBarButtonItem *startBarButton;

@end

@implementation FSVideoMuxerVC

#pragma mark - Lifecycle

- (void)dealloc {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // 启动后即开始请求视频采集权限并开始采集。
    [self requestAccessForVideo];
    [self setupUI];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.videoCapture.previewLayer.frame = self.view.bounds;
}

#pragma mark - Action

- (void)start {
    if (!self.isWriting) {
        // 启动封装，
        [self.muxer startWriting];
        // 标记开始封装写入。
        self.isWriting = YES;
    } else {
        __weak typeof(self) weakSelf = self;
        [self.videoEncoder flushWithCompleteHandler:^{
            weakSelf.isWriting = NO;
            [weakSelf.muxer stopWriting:^(BOOL success, NSError * _Nonnull error) {
                NSLog(@"muxer stop %@", success ? @"success" : @"failed");
            }];
        }];
    }
}

- (void)changeCamera {
    [self.videoCapture changeDevicePosition:self.videoCapture.config.position == AVCaptureDevicePositionBack ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack];
}

- (void)singleTap:(UIGestureRecognizer *)sender {
    
}

-(void)handleDoubleTap:(UIGestureRecognizer *)sender {
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
    
    // 添加手势。
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTap:)];
    singleTapGesture.numberOfTapsRequired = 1;
    singleTapGesture.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:singleTapGesture];
    
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    doubleTapGesture.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:doubleTapGesture];
    
    [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];

    
    // Navigation item.
    self.startBarButton = [[UIBarButtonItem alloc] initWithTitle:self.startTitle style:UIBarButtonItemStylePlain target:self action:@selector(start)];
    UIBarButtonItem *cameraBarButton = [[UIBarButtonItem alloc] initWithTitle:@"切换" style:UIBarButtonItemStylePlain target:self action:@selector(changeCamera)];
    self.navigationItem.rightBarButtonItems = @[self.startBarButton, cameraBarButton];
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
        _videoCapture.sessionInitSuccessCallBack = ^() {
            dispatch_async(dispatch_get_main_queue(), ^{
                // 预览渲染。
                [weakSelf.view.layer insertSublayer:weakSelf.videoCapture.previewLayer atIndex:0];
                weakSelf.videoCapture.previewLayer.backgroundColor = [UIColor blackColor].CGColor;
                weakSelf.videoCapture.previewLayer.frame = weakSelf.view.bounds;
            });
        };
        _videoCapture.sampleBufferOutputCallBack = ^(CMSampleBufferRef sampleBuffer) {
            if (sampleBuffer && weakSelf.isWriting) {
                // 编码。
                [weakSelf.videoEncoder encodePixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer) ptsTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
            }
        };
        _videoCapture.sessionErrorCallBack = ^(NSError *error) {
            NSLog(@"FSVideoCapture Error:%zi %@", error.code, error.localizedDescription);
        };
    }
    
    return _videoCapture;
}

- (FSVideoEncoderConfig *)videoEncoderConfig {
    if (!_videoEncoderConfig) {
        _videoEncoderConfig = [[FSVideoEncoderConfig alloc] init];
    }
    
    return _videoEncoderConfig;
}

- (FSVideoEncoder *)videoEncoder {
    if (!_videoEncoder) {
        _videoEncoder = [[FSVideoEncoder alloc] initWithConfig:self.videoEncoderConfig];
        __weak typeof(self) weakSelf = self;
        _videoEncoder.sampleBufferOutputCallBack = ^(CMSampleBufferRef sampleBuffer) {
            // 视频编码数据回调。
            if (weakSelf.isWriting) {
                // 当标记封装写入中时，将编码的 H.264/H.265 数据送给封装器。
                [weakSelf.muxer appendSampleBuffer:sampleBuffer];
            }
        };
    }
    
    return _videoEncoder;
}

- (FSMuxerConfig *)muxerConfig {
    if (!_muxerConfig) {
        _muxerConfig = [[FSMuxerConfig alloc] init];
        NSString *videoPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"video_muxer_out.mp4"];
        NSLog(@"MP4 file path: %@", videoPath);
        [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
        _muxerConfig.outputURL = [NSURL fileURLWithPath:videoPath];
        _muxerConfig.muxerType = FSMediaVideo;
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
