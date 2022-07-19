//
//  FSVideoCaptureConfig.h
//  FSAVDemo
//
//  Created by louis on 2022/7/14.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "FSMediaBase.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSVideoCaptureConfig : NSObject

@property (nonatomic, copy) AVCaptureSessionPreset preset; // 视频采集参数，比如分辨率等，与画质相关。
@property (nonatomic, assign) AVCaptureDevicePosition position; // 摄像头位置，前置/后置摄像头。
@property (nonatomic, assign) AVCaptureVideoOrientation orientation; // 视频画面方向。
@property (nonatomic, assign) NSInteger fps; // 视频帧率。
@property (nonatomic, assign) OSType pixelFormatType; // 颜色空间格式。
@property (nonatomic, assign) FSVideoCaptureMirrorType mirrorType; // 镜像类型。

@end

NS_ASSUME_NONNULL_END
