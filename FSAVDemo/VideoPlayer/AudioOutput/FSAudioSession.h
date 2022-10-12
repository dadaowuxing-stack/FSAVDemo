//
//  FSAudioSession.h
//  FSAVDemo
//
//  Created by louis on 2022/10/12.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

// 音频会话延迟时间
extern const NSTimeInterval AUSAudioSessionLatency_Background;
extern const NSTimeInterval AUSAudioSessionLatency_Default;
extern const NSTimeInterval AUSAudioSessionLatency_LowLatency;

@interface FSAudioSession : NSObject

+ (FSAudioSession *)sharedInstance;

@property(nonatomic, strong) AVAudioSession *audioSession; // 底层系统音频会话
@property(nonatomic, assign) Float64 preferredSampleRate;
@property(nonatomic, assign, readonly) Float64 currentSampleRate;
@property(nonatomic, assign) NSTimeInterval preferredLatency;
@property(nonatomic, assign) BOOL active;
@property(nonatomic, strong) NSString *category;

- (void)addRouteChangeListener;

@end

NS_ASSUME_NONNULL_END
