//
//  FSYUVFrameCopier.h
//  FSAVDemo
//
//  Created by louis on 2022/10/17.
//

#import "FSBaseEffectFilter.h"
#import "FSAVDecoder.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSYUVFrameCopier : FSBaseEffectFilter

- (void) renderWithTexId:(FSVideoFrame*) videoFrame;

@end

NS_ASSUME_NONNULL_END
