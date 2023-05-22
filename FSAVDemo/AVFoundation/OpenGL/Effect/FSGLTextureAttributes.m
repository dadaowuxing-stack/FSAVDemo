//
//  FSGLTextureAttributes.m
//  FSAVDemo
//
//  Created by liufengshuo on 2023/3/25.
//

#import "FSGLTextureAttributes.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>

@implementation FSGLTextureAttributes

- (instancetype)init {
    self = [super init];
    if (self) {
        _minFilter = GL_LINEAR; // 混合附近纹素的颜色来计算片元的颜色
        _magFilter = GL_LINEAR; // 混合附近纹素的颜色来计算片元的颜色
        _wrapS = GL_CLAMP_TO_EDGE; // 采样纹理边缘，即剩余部分显示纹理临近的边缘颜色值
        _wrapT = GL_CLAMP_TO_EDGE; // 采样纹理边缘，即剩余部分显示纹理临近的边缘颜色值 
        _internalFormat = GL_RGBA;
        _format = GL_RGBA;
        _type = GL_UNSIGNED_BYTE;
    }
    
    return self;
}

@end
