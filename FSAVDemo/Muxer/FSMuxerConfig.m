//
//  FSMuxerConfig.m
//  FSAVDemo
//
//  Created by louis on 2022/6/15.
//

#import "FSMuxerConfig.h"

@implementation FSMuxerConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _muxerType = FSMediaAV;
        _preferredTransform = CGAffineTransformIdentity;
    }
    return self;
}

@end
