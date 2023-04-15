//
//  FSVideoEncoder.h
//  FSAVDemo
//
//  Created by louis on 2022/7/15.
//

#import <Foundation/Foundation.h>
#import "FSVideoEncoderConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSVideoEncoder : NSObject

- (instancetype)initWithConfig:(FSVideoEncoderConfig*)config;

@property (nonatomic, strong, readonly) FSVideoEncoderConfig *config; // 视频编码配置参数.
@property (nonatomic, copy) void (^sampleBufferOutputCallBack)(CMSampleBufferRef sampleBuffer); // 视频编码数据回调.
@property (nonatomic, copy) void (^errorCallBack)(NSError *error); // 视频编码错误回调.
- (void)encodePixelBuffer:(CVPixelBufferRef)pixelBuffer ptsTime:(CMTime)timeStamp; // 编码.
- (void)refresh; // 刷新重建编码器.
- (void)flush; // 清空编码缓冲区.
- (void)flushWithCompleteHandler:(void (^)(void))completeHandler; // 清空编码缓冲区并回调完成.

@end

NS_ASSUME_NONNULL_END
