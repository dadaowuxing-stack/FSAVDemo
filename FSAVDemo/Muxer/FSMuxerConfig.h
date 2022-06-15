//
//  FSMuxerConfig.h
//  FSAVDemo
//
//  Created by louis on 2022/6/15.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "FSMediaBase.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSMuxerConfig : NSObject

@property (nonatomic, strong) NSURL *outputURL; // 封装文件输出地址.
@property (nonatomic, assign) FSMediaType muxerType; // 封装文件类型.
@property (nonatomic, assign) CGAffineTransform preferredTransform; // 图像的变换信息.比如：视频图像旋转.

@end

NS_ASSUME_NONNULL_END
