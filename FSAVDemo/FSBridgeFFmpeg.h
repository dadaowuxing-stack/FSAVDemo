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

+ (void)doAudioCapture:(NSString *)path;

/// pcm 转 aac
/// @param src 输入文件路径
/// @param dst 输出文件路径
+(void)doEncodePCM2AAC:(NSString *)src dst:(NSString *)dst;

+ (void)doResample:(NSString*)src dst:(NSString*)dst;

+ (void)doPlayPCM:(NSString*)src;

@end

NS_ASSUME_NONNULL_END
