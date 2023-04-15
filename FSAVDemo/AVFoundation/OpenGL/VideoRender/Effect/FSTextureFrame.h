//
//  FSTextureFrame.h
//  FSAVDemo
//
//  Created by liufengshuo on 2023/3/25.
//  帧纹理

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>
#import <GLKit/GLKit.h>
#import "FSGLFrame.h"

NS_ASSUME_NONNULL_BEGIN

// 表示一帧纹理对象
@interface FSTextureFrame : FSGLFrame

@property (nonatomic, assign) CGSize textureSize;
@property (nonatomic, assign) GLuint textureId;
@property (nonatomic, assign) CMTime time;
@property (nonatomic, assign) GLKMatrix4 mvpMatrix;

- (instancetype)initWithTextureId:(GLuint)textureId textureSize:(CGSize)textureSize time:(CMTime)time;

@end

NS_ASSUME_NONNULL_END
