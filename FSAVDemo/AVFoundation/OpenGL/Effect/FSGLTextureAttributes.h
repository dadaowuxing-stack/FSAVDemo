//
//  FSGLTextureAttributes.h
//  FSAVDemo
//
//  Created by liufengshuo on 2023/3/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
// 对纹理 Texture 属性的封装
@interface FSGLTextureAttributes : NSObject

@property(nonatomic, assign) int minFilter; // GL_TEXTURE_MIN_FILTER，多个纹素对应一个片元时的处理方式
@property(nonatomic, assign) int magFilter; // GL_TEXTURE_MAG_FILTER，没有足够的纹素来映射片元时的处理方式
@property(nonatomic, assign) int wrapS; // GL_TEXTURE_WRAP_S，超出范围的纹理处理方式，ST 坐标 S
@property(nonatomic, assign) int wrapT; // GL_TEXTURE_WRAP_T，超出范围的纹理处理方式，ST 坐标 T
@property(nonatomic, assign) int internalFormat;
@property(nonatomic, assign) int format;
@property(nonatomic, assign) int type;

@end

NS_ASSUME_NONNULL_END
