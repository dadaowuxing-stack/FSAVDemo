//
//  FSGLFrameBuffer.m
//  FSAVDemo
//
//  Created by liufengshuo on 2023/3/25.
//

#import "FSGLFrameBuffer.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>

@interface FSGLFrameBuffer () {
    GLuint _mTextureId;
    GLuint _mFboId;
    FSGLTextureAttributes *_mTextureAttributes;
    CGSize _mSize;
    int _mLastFboId;
}

@end

@implementation FSGLFrameBuffer

- (instancetype)initWithSize:(CGSize)size {
    return [self initWithSize:size textureAttributes:[FSGLTextureAttributes new]];
}

- (instancetype)initWithSize:(CGSize)size textureAttributes:(FSGLTextureAttributes*)textureAttributes{
    self = [super init];
    if (self) {
        _mTextureId = -1;
        _mFboId = -1;
        _mLastFboId = -1;
        _mSize = size;
        _mTextureAttributes = textureAttributes;
        [self _setup];
    }
    return self;
}

- (void)dealloc {
    if (_mTextureId != -1) {
        glDeleteTextures(1, &_mTextureId);
        _mTextureId = -1;
    }
    
    if (_mFboId != -1) {
        glDeleteFramebuffers(1, &_mFboId);
        _mFboId = -1;
    }
}

- (CGSize)getSize {
    return _mSize;
}

- (GLuint)getTextureId {
    return _mTextureId;
}

- (void)bind {
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &_mLastFboId);
    if (_mFboId != -1) {
        glBindFramebuffer(GL_FRAMEBUFFER, _mFboId);
        glViewport(0, 0, _mSize.width, _mSize.height);
    }
}

- (void)unbind {
    glBindFramebuffer(GL_FRAMEBUFFER, _mLastFboId);
}

- (void)_setup {
    [self _setupTexture];
    [self _setupFrameBuffer];
    [self _bindTexture2FrameBuffer];
}

-(void)_setupTexture {
    if (_mTextureId == -1) {
        glGenTextures(1, &_mTextureId);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, _mTextureId);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, _mTextureAttributes.minFilter);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, _mTextureAttributes.magFilter);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _mTextureAttributes.wrapS);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _mTextureAttributes.wrapT);
        if ((int)_mSize.width % 4 != 0) {
            glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        }
        glTexImage2D(GL_TEXTURE_2D, 0, _mTextureAttributes.internalFormat, _mSize.width, _mSize.height, 0, _mTextureAttributes.format, _mTextureAttributes.type, NULL);
        glBindTexture(GL_TEXTURE_2D, 0);
    }
}

- (void)_setupFrameBuffer {
    if (_mFboId == -1) {
        glGenFramebuffers(1, &_mFboId);
    }
}

- (void)_bindTexture2FrameBuffer {
    if (_mFboId != -1 && _mTextureId != -1 && _mSize.width != 0 && _mSize.height != 0) {
        glBindFramebuffer(GL_FRAMEBUFFER, _mFboId);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _mTextureId, 0);
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (status != GL_FRAMEBUFFER_COMPLETE) {
            NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
        }
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }
}

@end
