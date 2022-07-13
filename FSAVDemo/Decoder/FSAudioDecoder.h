//
//  FSAudioDecoder.h
//  FSAVDemo
//
//  Created by louis on 2022/6/15.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface FSAudioDecoder : NSObject

@property (nonatomic, copy) void (^sampleBufferOutputCallBack)(CMSampleBufferRef sample); // 解码器数据回调.
@property (nonatomic, copy) void (^errorCallBack)(NSError *error); // 解码器错误回调.

- (void)decodeSampleBuffer:(CMSampleBufferRef)sampleBuffer; // 解码.

@end

NS_ASSUME_NONNULL_END
