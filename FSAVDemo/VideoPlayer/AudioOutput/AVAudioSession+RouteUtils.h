//
//  AVAudioSession+RouteUtils.h
//  FSAVDemo
//
//  Created by louis on 2022/10/12.
//

#import <AVFAudio/AVFAudio.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAudioSession (RouteUtils)

- (BOOL)usingBlueTooth;

- (BOOL)usingWiredMicrophone;

- (BOOL)shouldShowEarphoneAlert;

@end

NS_ASSUME_NONNULL_END
