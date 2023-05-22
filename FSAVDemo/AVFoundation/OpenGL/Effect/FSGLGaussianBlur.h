//
//  FSGLGaussianBlur.h
//  FSAVDemo
//
//  Created by liufengshuo on 2023/4/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

extern NSString *const FSGLGaussianBlurVertexShader;
extern NSString *const FSGLGaussianBlurFragmentShader;

NS_ASSUME_NONNULL_END
