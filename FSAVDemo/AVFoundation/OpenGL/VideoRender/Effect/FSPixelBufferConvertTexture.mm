//
//  FSPixelBufferConvertTexture.m
//  FSAVDemo
//
//  Created by liufengshuo on 2023/3/25.
//

#import "FSPixelBufferConvertTexture.h"
#import <OpenGLES/gltypes.h>
#import "FSGLFilter.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "FSGLBase.h"

static const GLfloat  FSTColorConversion601VideoRange[] = {
    1.164,  1.164, 1.164,
    0.0, -0.392, 2.017,
    1.596, -0.813,   0.0,
};

static const GLfloat  FSTColorConversion601FullRange[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
};

static const GLfloat  FSTColorConversion709VideoRange[] = {
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
};

static const GLfloat  FSTColorConversion709FullRange[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.187, 1.856,
    1.575,    -0.468, 0.0,
};

NSString *const  FSYUV2RGBShader = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D chrominanceTexture;
 uniform mediump mat3 colorConversionMatrix;
 uniform mediump int isFullRange;
 
 void main()
 {
    mediump vec3 yuv;
    lowp vec3 rgb;
    
    if (isFullRange == 1) {
        yuv.x = texture2D(inputImageTexture, textureCoordinate).r;
    } else {
        yuv.x = texture2D(inputImageTexture, textureCoordinate).r -(16.0 / 255.0);
    }
    yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);
    rgb = colorConversionMatrix * yuv;
    
    gl_FragColor = vec4(rgb, 1);
}
 );

@interface  FSPixelBufferConvertTexture () {
    FSGLFilter *_filter;
    GLuint _chrominanceTexture;
    BOOL _isFullRange;
    const GLfloat *_yuvColorMatrix;
    CVOpenGLESTextureCacheRef _textureCache;
}

@end

@implementation  FSPixelBufferConvertTexture

- (instancetype)initWithContext:(EAGLContext *)context {
    self = [super init];
    if (self) {
        CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, context, NULL, &_textureCache);
    }
    return self;
}

- (void)dealloc {
    if (_textureCache) {
        CVOpenGLESTextureCacheFlush(_textureCache, 0);
        CFRelease(_textureCache);
        _textureCache = NULL;
    }
    
    _filter = nil;
}

- (FSTextureFrame *)renderFrame:(CVPixelBufferRef)pixelBuffer time:(CMTime)time {
    if (!pixelBuffer) {
        return nil;
    }
    
    if (CVPixelBufferGetPlaneCount(pixelBuffer) > 0) {
        return [self _yuvRenderFrame:pixelBuffer time:time];
    }
    
    return nil;
}

- (void)_setupYUVProgramMatrix:(BOOL)isFullRange colorSpace:(CFTypeRef)colorSpace {
    if (colorSpace == kCVImageBufferYCbCrMatrix_ITU_R_601_4) {
        _yuvColorMatrix = isFullRange ?  FSTColorConversion601FullRange :  FSTColorConversion601VideoRange;
    } else {
        _yuvColorMatrix = isFullRange ?  FSTColorConversion709FullRange :  FSTColorConversion709VideoRange;
    }
    _isFullRange = isFullRange;
    
    if (!_filter) {
        _filter = [[ FSGLFilter alloc] initWithCustomFBO:NO vertexShader: FSDefaultVertexShader fragmentShader: FSYUV2RGBShader];
        __weak typeof(self) _self = self;
        _filter.preDrawCallBack = ^() {
            __strong typeof(_self) sself = _self;
            if (!sself) {
                return;
            }
            glActiveTexture(GL_TEXTURE5);
            glBindTexture(GL_TEXTURE_2D, sself->_chrominanceTexture);
            glUniform1i([sself->_filter.getProgram getUniformLocation:@"chrominanceTexture"], 5);
            
            glUniformMatrix3fv([sself->_filter.getProgram getUniformLocation:@"colorConversionMatrix"], 1, GL_FALSE, sself->_yuvColorMatrix);
            glUniform1i([sself->_filter.getProgram getUniformLocation:@"isFullRange"], sself->_isFullRange ? 1 : 0);
        };
    }
}

- (BOOL)_pixelBufferIsFullRange:(CVPixelBufferRef)pixelBuffer {
    // 判断 YUV 数据是否为 full range。
    if (@available(iOS 15, *)) {
        CFDictionaryRef cfDicAttributes = CVPixelBufferCopyCreationAttributes(pixelBuffer);
        NSDictionary *dicAttributes = (__bridge_transfer NSDictionary*)cfDicAttributes;
        if (dicAttributes && [dicAttributes objectForKey:@"PixelFormatDescription"]) {
            NSDictionary *pixelFormatDescription = [dicAttributes objectForKey:@"PixelFormatDescription"];
            if (pixelFormatDescription && [pixelFormatDescription objectForKey:(__bridge NSString*)kCVPixelFormatComponentRange]) {
                NSString *componentRange = [pixelFormatDescription objectForKey:(__bridge NSString *)kCVPixelFormatComponentRange];
                return [componentRange isEqualToString:(__bridge NSString *)kCVPixelFormatComponentRange_FullRange];
            }
        }
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        OSType formatType = CVPixelBufferGetPixelFormatType(pixelBuffer);
        return formatType == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
#pragma clang diagnostic pop
    }
    
    return NO;
}

- (FSTextureFrame *)_yuvRenderFrame:(CVPixelBufferRef)pixelBuffer time:(CMTime)time{
    BOOL isFullYUVRange = [self _pixelBufferIsFullRange:pixelBuffer];
    CFTypeRef matrixKey = kCVImageBufferYCbCrMatrix_ITU_R_601_4;
    if (@available(iOS 15, *)) {
        matrixKey = CVBufferCopyAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);
    }else{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        matrixKey = CVBufferGetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);
#pragma clang diagnostic pop
    }
    
    [self _setupYUVProgramMatrix:isFullYUVRange colorSpace:matrixKey];
    
    CVOpenGLESTextureRef luminanceTextureRef = NULL;
    CVOpenGLESTextureRef chrominanceTextureRef = NULL;
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    CVReturn err;
    glActiveTexture(GL_TEXTURE4);
    
    size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_LUMINANCE, (GLsizei)width, (GLsizei)height, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
    if (err){
        NSLog(@" FSPixelBufferConvertTexture CVOpenGLESTextureCacheCreateTextureFromImage error");
        return nil;
    }
    
    GLuint luminanceTexture = CVOpenGLESTextureGetName(luminanceTextureRef);
    glBindTexture(GL_TEXTURE_2D, luminanceTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // UV-plane
    glActiveTexture(GL_TEXTURE5);
    size_t width_uv = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
    size_t height_uv = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, (GLsizei)width_uv, (GLsizei)height_uv, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
    if (err){
        NSLog(@" FSPixelBufferConvertTexture CVOpenGLESTextureCacheCreateTextureFromImage error");
        return nil;
    }
    
    _chrominanceTexture = CVOpenGLESTextureGetName(chrominanceTextureRef);
    glBindTexture(GL_TEXTURE_2D, _chrominanceTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    FSTextureFrame *inputFrame = [[ FSTextureFrame alloc] initWithTextureId:luminanceTexture textureSize:CGSizeMake(width, height) time:time];
    FSTextureFrame *resultFrame = [_filter render:inputFrame];
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    if(luminanceTextureRef) CFRelease(luminanceTextureRef);
    if(chrominanceTextureRef) CFRelease(chrominanceTextureRef);
    
    return resultFrame;
}

@end
