//
//  FSAudioEncoder.h
//  FSAVDemo
//
//  Created by louis on 2022/6/8.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface FSAudioEncoder : NSObject

- (instancetype)initWithAudioBitrate:(NSInteger)audioBitrate;

@property (nonatomic, assign, readonly) NSInteger audioBitrate; // 音频编码码率.
@property (nonatomic, copy) void (^sampleBufferOutputCallBack)(CMSampleBufferRef sample); // 音频编码数据回调.
@property (nonatomic, copy) void (^errorCallBack)(NSError *error); // 音频编码错误回调.

- (void)encodeSampleBuffer:(CMSampleBufferRef)buffer; // 编码.

@end

NS_ASSUME_NONNULL_END
