//
//  FSBaseVC.m
//  FSAVDemo
//
//  Created by louis on 2022/6/8.
//

#import "FSBaseVC.h"

@interface FSBaseVC ()

@end

@implementation FSBaseVC

- (void)dealloc {
    if (_fileHandle) {
        [_fileHandle closeFile];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.isRecording = NO;
    [self _setupUI];
    [self _initConfig];
}

- (void)_initConfig {
    NSString *pathComponent = @"";
    self.startTitle = @"开始采集";
    self.stopTitle = @"停止采集";
    switch (self.opType) {
        case FSMediaOpTypeAudioCapture: {
            pathComponent = @"audio_capture_out.pcm";
            self.startTitle = @"开始采集";
            self.stopTitle = @"停止采集";
            [self.view addSubview:self.audioButton];
        } break;
        case FSMediaOpTypeVideoCapture: {  // 采集
            self.startTitle = @"开始采集";
            self.stopTitle = @"停止采集";
        }
            break;
        case FSMediaOpTypeAudioEncoder: {
            pathComponent = @"audio_encoder_out.aac";
            self.startTitle = @"开始编码";
            self.stopTitle = @"停止编码";
            [self.view addSubview:self.audioButton];
        } break;
        case FSMediaOpTypeVideoEncoder: {  // 编码
            self.startTitle = @"开始编码";
            self.stopTitle = @"停止编码";
        }
            break;
        case FSMediaOpTypeAudioMuxer: {
            pathComponent = @"audio_muxer_out.m4a";
            self.startTitle = @"开始封装";
            self.stopTitle = @"停止封装";
            [self.view addSubview:self.audioButton];
        } break;
        case FSMediaOpTypeVideoMuxer: {   // 封装
            self.startTitle = @"开始封装";
            self.stopTitle = @"停止封装";
        } break;
        case FSMediaOpTypeAudioDemuxer: {
            pathComponent = @"audio_demuxer_out.aac";
            self.startTitle = @"开始解封装";
            self.stopTitle = @"停止解封装";
            [self.view addSubview:self.audioButton];
        }
            break;
        case FSMediaOpTypeVideoDemuxer: { // 解封装
            self.startTitle = @"开始解封装";
            self.stopTitle = @"停止解封装";
            pathComponent = @"video_demuxer_out.h264";
        }
            break;
        case FSMediaOpTypeAudioDecoder: {
            pathComponent = @"audio_decoder_out.pcm";
            self.startTitle = @"开始解码";
            self.stopTitle = @"停止解码";
            [self.view addSubview:self.audioButton];
        }
            break;
        case FSMediaOpTypeVideoDecoder: { // 解码
            pathComponent = @"video_decoder_out.yuv";
            self.startTitle = @"开始解码";
            self.stopTitle = @"停止解码";
        }
            break;
        case FSMediaOpTypeAudioRender: {
            self.startTitle = @"开始渲染";
            self.stopTitle = @"停止渲染";
            [self.view addSubview:self.audioButton];
        }
            break;
        case FSMediaOpTypeVideoRender: { // 渲染
            
        }
            break;
            
            
        default:
            break;
    }
    [self.audioButton setTitle:self.startTitle forState:UIControlStateNormal];
    if (pathComponent.length) {
        self.path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:pathComponent];
        NSLog(@"opType: %ld ------ file path: %@", self.opType, self.path);
        [[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
        [[NSFileManager defaultManager] createFileAtPath:self.path contents:nil attributes:nil];
        self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.path];
    }
}

- (UIButton *)buttonWithFrame:(CGRect)frame title:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:frame];
    button.layer.borderWidth = 1;
    button.layer.cornerRadius = 8;
    button.layer.borderColor = [UIColor redColor].CGColor;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16.0];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}


- (void)_setupUI {
    self.audioButton = [self buttonWithFrame:CGRectMake(100, 100, 150, 50) title:self.startTitle action:@selector(buttonAction:)];
}

- (void)buttonAction:(UIButton *)sender {}

@end
