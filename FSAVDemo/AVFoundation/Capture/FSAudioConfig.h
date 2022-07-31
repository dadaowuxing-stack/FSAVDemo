//
//  FSAudioConfig.h
//  FSAVDemo
//
//  Created by louis on 2022/5/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FSAudioConfig : NSObject

+ (instancetype)defaultConfig;

@property (nonatomic, assign) NSUInteger sampleRate; // 采样率,默认 44100
@property (nonatomic, assign) NSUInteger channels;   // 声道数,默认 2
@property (nonatomic, assign) NSUInteger bitDepth;   // 位深度,默认 16

@end

NS_ASSUME_NONNULL_END
