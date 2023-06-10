//
//  FSPixelBufferConvertTexture.h
//  FSAVDemo
//
//  Created by liufengshuo on 2023/3/25.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <CoreVideo/CoreVideo.h>
#import "FSTextureFrame.h"

NS_ASSUME_NONNULL_BEGIN

//  FSPixelBufferConvertTexture 是一个将 CVPixelBuffer 转换为纹理 Texture 的工具类，兼容颜色空间的转换处理
@interface  FSPixelBufferConvertTexture : NSObject

- (instancetype)initWithContext:(EAGLContext *)context;
- (FSTextureFrame *)renderFrame:(CVPixelBufferRef)pixelBuffer time:(CMTime)time; // 将 CVPixelBuffer 转换为纹理 Texture

@end

NS_ASSUME_NONNULL_END
