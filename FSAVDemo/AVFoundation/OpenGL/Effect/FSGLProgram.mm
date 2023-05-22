//
//  FSGLProgram.m
//  FSAVDemo
//
//  Created by liufengshuo on 2023/3/25.
//

#import "FSGLProgram.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>

@interface FSGLProgram () {
    int _mProgram;
    int _mVertexShader;
    int _mFragmentShader;
}

@end

@implementation FSGLProgram

- (instancetype)initWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader {
    self = [super init];
    if (self) {
        [self _createProgram:vertexShader fragmentSource:fragmentShader];
    }
    return self;
}

- (void)dealloc {
    if (_mVertexShader != 0) {
        glDeleteShader(_mVertexShader);
        _mVertexShader = 0;
    }

    if (_mFragmentShader != 0) {
        glDeleteShader(_mFragmentShader);
        _mFragmentShader = 0;
    }

    if (_mProgram != 0) {
        glDeleteProgram(_mProgram);
        _mProgram = 0;
    }
}

// 使用 GL 程序。
- (void)use {
    if (_mProgram != 0) {
        glUseProgram(_mProgram);
    }
}

// 根据名字获取 uniform 位置值
- (int)getUniformLocation:(NSString *)name {
    return glGetUniformLocation(_mProgram, [name UTF8String]);
}

// 根据名字获取 attribute 位置值
- (int)getAttribLocation:(NSString *)name {
    return glGetAttribLocation(_mProgram, [name UTF8String]);
}

// 加载和编译 shader，并链接 GL 程序。
- (void)_createProgram:(NSString *)vertexSource fragmentSource:(NSString *)fragmentSource {
    _mVertexShader = [self _loadShader:GL_VERTEX_SHADER source:vertexSource];
    _mFragmentShader = [self _loadShader:GL_FRAGMENT_SHADER source:fragmentSource];

    if (_mVertexShader != 0 && _mFragmentShader != 0) {
        _mProgram = glCreateProgram();
        glAttachShader(_mProgram, _mVertexShader);
        glAttachShader(_mProgram, _mFragmentShader);

        glLinkProgram(_mProgram);
        GLint linkStatus;
        glGetProgramiv(_mProgram, GL_LINK_STATUS, &linkStatus);
        if (linkStatus != GL_TRUE) {
            glDeleteProgram(_mProgram);
            _mProgram = 0;
        }
    }
}

// 加载和编译 shader。
- (int)_loadShader:(int)shaderType source:(NSString *)source {
    int shader = glCreateShader(shaderType);
    const GLchar *cSource = (GLchar *) [source UTF8String];
    glShaderSource(shader,1, &cSource,NULL);
    glCompileShader(shader);

    GLint compiled;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    if (compiled != GL_TRUE) {
        glDeleteShader(shader);
        shader = 0;
    }

    return shader;
}

@end
