//
//  FSTextureFrame.m
//  FSAVDemo
//
//  Created by liufengshuo on 2023/3/25.
//

#import "FSTextureFrame.h"

@implementation FSTextureFrame

- (instancetype)initWithTextureId:(GLuint)textureId textureSize:(CGSize)textureSize time:(CMTime)time {
    self = [super init];
    if(self){
        _textureId = textureId;
        _textureSize = textureSize;
        _time = time;
        _mvpMatrix = GLKMatrix4Identity;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    FSTextureFrame *copy = [[FSTextureFrame allocWithZone:zone] init];
    copy.textureId = _textureId;
    copy.textureSize = _textureSize;
    copy.time = _time;
    copy.mvpMatrix = _mvpMatrix;
    return copy;
}

@end
