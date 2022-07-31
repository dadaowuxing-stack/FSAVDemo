//
//  FSDemuxerConfig.m
//  FSAVDemo
//
//  Created by louis on 2022/6/15.
//

#import "FSDemuxerConfig.h"

@implementation FSDemuxerConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _demuxerType = FSMediaAV; // 音视频都有
    }
    
    return self;
}

@end
