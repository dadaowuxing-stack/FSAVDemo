//
//  FSMetalView.h
//  FSAVDemo
//
//  Created by louis on 2022/7/19.
//

#import <UIKit/UIKit.h>
#import "FSMediaBase.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSMetalView : UIView

@property (nonatomic, assign) FSMetalViewContentMode fillMode; // 画面填充模式.
- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer; // 渲染.

@end

NS_ASSUME_NONNULL_END
