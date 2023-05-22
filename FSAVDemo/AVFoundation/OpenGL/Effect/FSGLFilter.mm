//
//  FSGLFilter.m
//  FSAVDemo
//
//  Created by liufengshuo on 2023/3/25.
//

#import "FSGLFilter.h"
#import <OpenGLES/ES2/glext.h>

@interface FSGLFilter() {
    BOOL _mIsCustomFBO;
    FSGLFrameBuffer *_mFrameBuffer;
    FSGLProgram *_mProgram;
    FSGLTextureAttributes *_mGLTextureAttributes;

    int _mTextureUniform;
    int _mPostionMatrixUniform;
    int _mPositionAttribute;
    int _mTextureCoordinateAttribute;
}

@end

@implementation FSGLFilter

- (instancetype)initWithCustomFBO:(BOOL)isCustomFBO vertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader {
    return [self initWithCustomFBO:isCustomFBO vertexShader:vertexShader fragmentShader:fragmentShader textureAttributes:[FSGLTextureAttributes new]];
}

- (instancetype)initWithCustomFBO:(BOOL)isCustomFBO vertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader textureAttributes:(FSGLTextureAttributes *)textureAttributes {
    self = [super init];
    if (self) {
        // 初始化。
        _mTextureUniform = -1;
        _mPostionMatrixUniform = -1;
        _mPositionAttribute = -1;
        _mTextureCoordinateAttribute = -1;
        _mIsCustomFBO = isCustomFBO;
        _mGLTextureAttributes = textureAttributes;
        // 加载和编译 shader，并链接到着色器程序。
        [self _setupProgram:vertexShader fragmentShader:fragmentShader];
    }
    return self;
}

- (void)dealloc {
    if (_mFrameBuffer != nil) {
        _mFrameBuffer = nil;
    }

    if (_mProgram != nil) {
        _mProgram = nil;
    }
}

- ( FSGLFrameBuffer *)getOutputFrameBuffer {
    // 当没有指定外部 FBO 时，内部会生成一个 FBO，这里返回的是内部的 FBO。
    return _mFrameBuffer;
}

-( FSGLProgram *)getProgram {
    // 返回 GL 程序。
    return _mProgram;
}

- (void)setIntegerUniformValue:(NSString *)uniformName intValue:(int)intValue {
    // 设置 GL 程序变量值。
    if (_mProgram != nil) {
        int uniforamIndex = [_mProgram getUniformLocation:uniformName];
        [_mProgram use];
        glUniform1i(uniforamIndex, intValue);
    }
}

- (void)setFloatUniformValue:(NSString *)uniformName floatValue:(float)floatValue {
    // 设置 GL 程序变量值。
    if (_mProgram != nil) {
        int uniforamIndex = [_mProgram getUniformLocation:uniformName];
        [_mProgram use];
        glUniform1f(uniforamIndex, floatValue);
    }
}

- (void)_setupFrameBuffer:(CGSize)size {
    // 如果指定使用外部的 FBO，则这里就直接返回。
    if (_mIsCustomFBO) {
        return;
    }

    // 如果没指定使用外部的 FBO，这里就再创建一个 FBO。
    if (_mFrameBuffer == nil || _mFrameBuffer.getSize.width != size.width || _mFrameBuffer.getSize.height != size.height) {
        if (_mFrameBuffer != nil) {
            _mFrameBuffer = nil;
        }

        _mFrameBuffer = [[ FSGLFrameBuffer alloc] initWithSize:size textureAttributes:_mGLTextureAttributes];
    }
}

- (void)_setupProgram:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader {
    // 加载和编译 shader，并链接到着色器程序。
    if (_mProgram == nil) {
        _mProgram = [[ FSGLProgram alloc] initWithVertexShader:vertexShader fragmentShader:fragmentShader];
        // 获取与 Shader 中对应参数的位置值：
        _mTextureUniform = [_mProgram getUniformLocation:@"inputImageTexture"];
        _mPostionMatrixUniform = [_mProgram getUniformLocation:@"mvpMatrix"];
        _mPositionAttribute = [_mProgram getAttribLocation:@"position"];
        _mTextureCoordinateAttribute = [_mProgram getAttribLocation:@"inputTextureCoordinate"];
    }
}

- ( FSTextureFrame *)render:( FSTextureFrame *)frame {
    // 渲染一帧纹理。
    
    if (frame == nil) {
        return frame;
    }

     FSTextureFrame *resultFrame = frame.copy;
    [self _setupFrameBuffer:frame.textureSize];

    if (_mFrameBuffer != nil) {
        [_mFrameBuffer bind];
    }

    if (_mProgram != nil) {
        // 使用 GL 程序。
        [_mProgram use];
        
        // 清理窗口颜色。
        glClearColor(0, 0, 0, 1);
        glClear(GL_COLOR_BUFFER_BIT);

        // 激活和绑定纹理单元，并设置 uniform 采样器与之对应。
        glActiveTexture(GL_TEXTURE1); // 在绑定纹理之前先激活纹理单元。默认激活的纹理单元是 GL_TEXTURE0，这里激活了 GL_TEXTURE1。
        glBindTexture(GL_TEXTURE_2D, frame.textureId); // 绑定这个纹理到当前激活的纹理单元 GL_TEXTURE1。
        glUniform1i(_mTextureUniform, 1); // 设置 _mTextureUniform 的对应的纹理单元为 1，即 GL_TEXTURE1，从而保证每个 uniform 采样器对应着正确的纹理单元。

        if (_mPostionMatrixUniform >= 0) {
            glUniformMatrix4fv(_mPostionMatrixUniform, 1, false, frame.mvpMatrix.m); // 把矩阵数据发送给着色器对应的参数。
        }

        // 启用顶点位置属性通道。
        glEnableVertexAttribArray(_mPositionAttribute);
        // 启用纹理坐标属性通道。
        glEnableVertexAttribArray(_mTextureCoordinateAttribute);

        static const GLfloat squareVertices[] = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f,  1.0f,
            1.0f,  1.0f,
        };
        // 关联顶点位置数据。
        glVertexAttribPointer(_mPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
        
        static GLfloat textureCoordinates[] = {
            0.0f, 0.0f,
            1.0f, 0.0f,
            0.0f, 1.0f,
            1.0f, 1.0f,
        };
        // 关联纹理坐标数据。
        glVertexAttribPointer(_mTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);

        // 绘制前回调。回调中可以更新绘制需要的相关数据。
        if (self.preDrawCallBack) {
            self.preDrawCallBack();
        }
        
        // 绘制所有图元。
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        // 绘制后回调。
        if (self.postDrawCallBack) {
            self.postDrawCallBack();
        }

        // 解绑纹理。
        glBindTexture(GL_TEXTURE_2D, 0);

        // 关闭顶点位置属性通道。
        glDisableVertexAttribArray(_mPositionAttribute);
        // 关闭纹理坐标属性通道。
        glDisableVertexAttribArray(_mTextureCoordinateAttribute);
    }

    if (_mFrameBuffer != nil) {
        // 解绑内部 FBO。
        [_mFrameBuffer unbind];
    }

    if (_mFrameBuffer != nil) {
        // 清理内部 FBO。
        resultFrame.textureId = _mFrameBuffer.getTextureId;
        resultFrame.textureSize = _mFrameBuffer.getSize;
    }
    
    // 返回渲染好的纹理。
    return resultFrame;
}

@end
