//
//  FSAudioTools.h
//  FSAVDemo
//
//  Created by louis on 2022/6/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FSAudioTools : NSObject

// 按音频参数生成 AAC packet 对应的 ADTS 头数据。
+ (NSData *)adtsDataWithChannels:(NSInteger)channels sampleRate:(NSInteger)sampleRate rawDataLength:(NSInteger)rawDataLength;

@end

NS_ASSUME_NONNULL_END
