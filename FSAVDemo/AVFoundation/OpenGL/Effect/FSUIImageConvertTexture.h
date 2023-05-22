//
//  FSUIImageConvertTexture.h
//  FSAVDemo
//
//  Created by liufengshuo on 2023/4/20.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import "FSTextureFrame.h"

NS_ASSUME_NONNULL_BEGIN
// FSUIImageConvertTexture 是一个将 UIImage 转换为纹理 Texture 的工具类，兼容颜色空间的转换处理
@interface FSUIImageConvertTexture : NSObject

+ (FSTextureFrame *)renderImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
