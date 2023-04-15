//
//  FSFrame.h
//  FSAVDemo
//
//  Created by liufengshuo on 2023/3/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FSFrameType) {
    FSFrameBuffer = 0,  // 数据缓冲区类型
    FSFrameTexture = 1, // 纹理类型
};

@interface FSGLFrame : NSObject

@property (nonatomic, assign) FSFrameType frameType;

- (instancetype)initWithType:(FSFrameType)type;

@end

NS_ASSUME_NONNULL_END
