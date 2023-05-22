//
//  FSVideoEncoderConfig.m
//  FSAVDemo
//
//  Created by louis on 2022/7/15.
//

#import "FSVideoEncoderConfig.h"
#import <VideoToolbox/VideoToolbox.h>

/**
 使用VideoToolbox和AudioToolbox进行音视频编解码时，可能会遇到以下问题：

 1. 内存泄漏：在使用VideoToolbox和AudioToolbox进行编解码时，需要手动管理内存，如果不及时释放资源，可能会导致内存泄漏。
 解决方法是在合适的地方释放相关资源，例如在回调函数中释放。

 2. 性能问题：使用VideoToolbox和AudioToolbox进行编解码时，可能会出现性能问题，例如卡顿、延迟等。
 解决方法是优化编解码算法、调整编解码参数、减少不必要的计算等。

 3. 兼容性问题：不同设备和系统版本对VideoToolbox和AudioToolbox的支持程度不同，可能会导致兼容性问题。
 解决方法是针对不同设备和系统版本进行测试，并根据具体情况进行适当的调整。

 4. 视频帧率不稳定：在进行视频编码时，可能会出现视频帧率不稳定的情况，导致视频画面不连贯。
 解决方法是调整视频帧率、优化编码算法、减少不必要的计算等。

 5. 音视频同步问题：在进行音视频编解码时，可能会出现音视频同步问题，导致声音和画面不匹配。
 解决方法是调整音视频采样率、帧率等参数，并根据具体情况进行适当的调整。

 需要注意的是，使用VideoToolbox和AudioToolbox进行音视频编解码需要一定的音视频编解码基础知识，并且需要根据具体情况进行适当的调整和优化。
 */
@implementation FSVideoEncoderConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _size = CGSizeMake(1080, 1920);
        _bitrate = 5000 * 1024;
        _fps = 30;
        _gopSize = _fps * 5;
        _openBFrame = YES;
        
        BOOL supportHEVC = NO;
        if (@available(iOS 11.0, *)) {
            if (&VTIsHardwareDecodeSupported) {
                supportHEVC = VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC);
            }
        }
        
        _codecType = supportHEVC ? kCMVideoCodecType_HEVC : kCMVideoCodecType_H264;
        _profile = supportHEVC ? (__bridge NSString *) kVTProfileLevel_HEVC_Main_AutoLevel : AVVideoProfileLevelH264HighAutoLevel;
    }
    
    return self;
}

@end
