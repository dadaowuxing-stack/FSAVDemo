//
//  FSVideoOutput.h
//  FSAVDemo
//
//  Created by louis on 2022/10/17.
//

#import <UIKit/UIKit.h>
#import "FSAVDecoder.h"
#import "FSBaseEffectFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSVideoOutput : UIView

- (id)initWithFrame:(CGRect)frame textureWidth:(NSInteger)textureWidth textureHeight:(NSInteger)textureHeight;
- (id)initWithFrame:(CGRect)frame textureWidth:(NSInteger)textureWidth textureHeight:(NSInteger)textureHeight  shareGroup:(EAGLSharegroup *)shareGroup;

- (void)presentVideoFrame:(FSVideoFrame*)frame;

- (FSBaseEffectFilter*)createImageProcessFilterInstance;
- (FSBaseEffectFilter*)getImageProcessFilterInstance;

- (void)destroy;

@end

NS_ASSUME_NONNULL_END
