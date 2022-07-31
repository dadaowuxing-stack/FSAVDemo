//
//  FSDemuxerConfig.h
//  FSAVDemo
//
//  Created by louis on 2022/6/15.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "FSMediaBase.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSDemuxerConfig : NSObject

@property (nonatomic, strong) AVAsset *asset; // 待解封装的资源.
@property (nonatomic, assign) FSMediaType demuxerType; // 解封装类型.

@end

NS_ASSUME_NONNULL_END
