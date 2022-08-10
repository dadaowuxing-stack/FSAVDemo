//
//  FSBridgeFFmpeg.h
//  FSAVDemo
//
//  Created by louis on 2022/8/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FSBridgeFFmpeg : NSObject

/// 测试FFmpeg库是否可用
+ (void)testLib;

/// 录制->pcm
+ (void)doRecord;

/// 播放->pcm
+ (void)doPlayPcm;

/// pcm -> aac
+(void)doPcm2AAC;

/// pcm -> wav
+ (void)doPcm2Wav;

+ (void)doResample:(NSString*)src dst:(NSString*)dst;

@end

NS_ASSUME_NONNULL_END
