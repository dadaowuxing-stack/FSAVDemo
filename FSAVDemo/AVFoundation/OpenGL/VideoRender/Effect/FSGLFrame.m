//
//  FSFrame.m
//  FSAVDemo
//
//  Created by liufengshuo on 2023/3/25.
//

#import "FSGLFrame.h"

@implementation FSGLFrame

- (instancetype)initWithType:(FSFrameType)type {
    self = [super init];
    if(self){
        _frameType = type;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if(self){
        _frameType = FSFrameBuffer;
    }
    return self;
}

@end
