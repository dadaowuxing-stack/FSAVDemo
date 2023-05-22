//
//  FSVideoEncoderConfig.h
//  FSAVDemo
//
//  Created by louis on 2022/7/15.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN
/**
 视频分辨率：指视频图像的大小，一般用像素来表示。例如，1920x1080 表示水平方向有 1920 个像素，垂直方向有 1080 个像素。视频分辨率越高，图像越清晰，但同时也会增加视频文件的大小。

 帧率：指视频中每秒钟播放的帧数，单位为 fps（frames per second）。例如，25fps 表示每秒播放 25 帧视频。帧率越高，视频播放越流畅，但同时也会增加视频文件的大小。

 码率：指视频编码时每秒钟的数据量，单位为 bps（bits per second）。例如，1000 kbps 表示每秒钟编码出 1000 kbit 的视频数据。码率越高，视频质量越高，但同时也会增加视频文件的大小。
 
 GOP（Group of Pictures）是视频编码中的一个重要概念，指的是一组连续的视频帧。在视频编码中，通常将视频帧分为两类：I 帧、P 帧和 B 帧。

 I 帧（Intra-coded picture）：又称关键帧，是视频序列中的一个独立帧，不依赖于其他帧进行解码，每个 GOP 中一般只有一个 I 帧。I 帧包含整个视频图像的所有信息，具有最高的图像质量，但编码后的数据量也最大。

 P 帧（Predicted picture）：是视频序列中的一种预测帧，通过对前面一个 I 帧或 P 帧进行预测得到。P 帧只包含与前面帧的差异信息，相对于 I 帧数据量较小。

 B 帧（Bi-directional predicted picture）：是视频序列中的双向预测帧，通过对前面一个 I 帧或 P 帧和后面一个 I 帧或 P 帧进行预测得到。B 帧包含了前后两个帧的差异信息，相对于 P 帧数据量更小。

 GOP 是由一组连续的 I 帧、P 帧和 B 帧组成的，其中第一个帧必须是 I 帧，其他帧可以是 P 帧或 B 帧。GOP 的大小和结构可以根据具体的编码需求进行调整，通常采用固定大小的 GOP 结构，例如 15 帧或 30 帧。

 GOP 的大小和结构对视频质量和编解码效率都有影响。较小的 GOP 可以提高视频的编解码效率，但会增加码率和带宽要求；较大的 GOP 可以减小码率和带宽要求，但会降低视频的质量和编解码效率。因此，需要根据具体的应用场景进行合理的 GOP 配置。
 */
@interface FSVideoEncoderConfig : NSObject

@property (nonatomic, assign) CGSize size; // 分辨率.
@property (nonatomic, assign) NSInteger bitrate; // 码率.
@property (nonatomic, assign) NSInteger fps; // 帧率.
@property (nonatomic, assign) NSInteger gopSize; // GOP 帧数.
@property (nonatomic, assign) BOOL openBFrame; // 编码是否使用 B 帧.
@property (nonatomic, assign) CMVideoCodecType codecType; // 编码器类型.
@property (nonatomic, assign) NSString *profile; // 编码 profile.

@end

NS_ASSUME_NONNULL_END
