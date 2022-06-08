//
//  FSAudioCapture.h
//  FSAVDemo
//
//  Created by louis on 2022/5/27.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "FSAudioConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSAudioCapture : NSObject

@property (nonatomic, readonly, strong) FSAudioConfig *config;
@property (nonatomic, copy) void (^sampleBufferOutputCallBack)(CMSampleBufferRef sample); // 音频采集数据回调
@property (nonatomic, copy) void (^errorCallBack)(NSError *error); // 音频采集错误回调

- (instancetype)initWithConfig:(FSAudioConfig *)config;

/**
 开始采集音频数据
 */
- (void)startRunning;
/**
 停止采集音频数据
 */
- (void)stopRunning;

@end

NS_ASSUME_NONNULL_END
