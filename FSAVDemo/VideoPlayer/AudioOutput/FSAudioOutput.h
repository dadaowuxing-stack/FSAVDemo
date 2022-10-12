//
//  FSAudioOutput.h
//  FSAVDemo
//
//  Created by louis on 2022/10/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FSFillDataDelegate <NSObject>

- (NSInteger)fillAudioData:(SInt16*)sampleBuffer
                 numFrames:(NSInteger)frameNum
               numChannels:(NSInteger)channels;

@end

@interface FSAudioOutput : NSObject

/// 初始化音频输出模块
/// - Parameters:
///   - channels: 声道数
///   - sampleRate: 采样率
///   - bytePerSample: 每个样本的字节数
///   - fillAudioDataDelegate: 音频数据填充代理
- (instancetype)initWithChannels:(NSInteger)channels
                      sampleRate:(NSInteger)sampleRate
                  bytesPerSample:(NSInteger)bytePerSample
               filleDataDelegate:(id<FSFillDataDelegate>) fillAudioDataDelegate;

- (BOOL)play;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
