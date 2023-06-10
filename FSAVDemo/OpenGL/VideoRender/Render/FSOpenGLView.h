//
//  FSOpenGLView.h
//  FSAVDemo
//
//  Created by liufengshuo on 2023/3/25.
//  核心功能是提供了设置画面填充模式的接口和渲染一帧纹理的接口

#import <UIKit/UIKit.h>
#import "FSTextureFrame.h"

NS_ASSUME_NONNULL_BEGIN
// 渲染画面填充模式
typedef NS_ENUM(NSInteger, FSGLViewContentMode) {
    // 自动填充满，可能会变形。
    FSGLViewContentModeStretch = 0,
    // 按比例适配，可能会有黑边。
    FSGLViewContentModeFit = 1,
    // 根据比例裁剪后填充满。
    FSGLViewContentModeFill = 2
};

// 使用 OpenGL 实现渲染 View
@interface FSOpenGLView : UIView

- (instancetype)initWithFrame:(CGRect)frame context:(nullable EAGLContext *)context;

@property (nonatomic, assign) FSGLViewContentMode fillMode; // 画面填充模式。

- (void)displayFrame:(nonnull FSTextureFrame *)frame; // 渲染一帧纹理。

@end

NS_ASSUME_NONNULL_END
