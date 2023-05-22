//
//  FSGLProgram.h
//  FSAVDemo
//
//  Created by liufengshuo on 2023/3/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// FSGLProgram 封装了使用 GL 程序的部分 API
@interface FSGLProgram : NSObject

- (instancetype)initWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader;

- (void)use; // 使用 GL 程序
- (int)getUniformLocation:(NSString *)name; // 根据名字获取 uniform 位置值
- (int)getAttribLocation:(NSString *)name; // 根据名字获取 attribute 位置值

@end

NS_ASSUME_NONNULL_END
