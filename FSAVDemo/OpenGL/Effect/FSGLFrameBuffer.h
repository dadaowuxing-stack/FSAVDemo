//
//  FSGLFrameBuffer.h
//  FSAVDemo
//
//  Created by liufengshuo on 2023/3/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FSGLTextureAttributes.h"

NS_ASSUME_NONNULL_BEGIN

// 封装了对 FBO 使用的 API
@interface FSGLFrameBuffer : NSObject

- (instancetype)initWithSize:(CGSize)size;
- (instancetype)initWithSize:(CGSize)size textureAttributes:(FSGLTextureAttributes *)textureAttributes;
- (CGSize)getSize; // 纹理 size
- (GLuint)getTextureId; // 纹理 id
- (void)bind; // 绑定 FBO
- (void)unbind; // 解绑 FBO

@end

NS_ASSUME_NONNULL_END
