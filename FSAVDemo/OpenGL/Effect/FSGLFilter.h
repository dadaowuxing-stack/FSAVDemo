//
//  FSGLFilter.h
//  FSAVDemo
//
//  Created by liufengshuo on 2023/3/25.
//  FSGLFilter 封装了 shader 的加载、编译和着色器程序链接，以及 FBO 的管理

#import <Foundation/Foundation.h>
#import "FSGLFrameBuffer.h"
#import "FSGLProgram.h"
#import "FSTextureFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSGLFilter : NSObject

//  FSGLFilter 初始化
// 这里 isCustomFBO 传 YES，表示直接用外部的 FBO（即上面创建的 FBO 对象 _frameBufferHandle）
- (instancetype)initWithCustomFBO:(BOOL)isCustomFBO vertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader;
- (instancetype)initWithCustomFBO:(BOOL)isCustomFBO vertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader textureAttributes:( FSGLTextureAttributes *)textureAttributes;

@property (nonatomic, copy) void (^preDrawCallBack)(void); // 渲染前回调
@property (nonatomic, copy) void (^postDrawCallBack)(void); // 渲染后回调

- (FSGLFrameBuffer *)getOutputFrameBuffer; // 获取内部的 FBO
- (FSGLProgram *)getProgram; // 获取 GL 程序
- (FSTextureFrame *)render:(FSTextureFrame *)frame; // 渲染一帧纹理

// 设置 GL 程序变量值
- (void)setIntegerUniformValue:(NSString *)uniformName intValue:(int)intValue;
- (void)setFloatUniformValue:(NSString *)uniformName floatValue:(float)floatValue;

@end

NS_ASSUME_NONNULL_END
