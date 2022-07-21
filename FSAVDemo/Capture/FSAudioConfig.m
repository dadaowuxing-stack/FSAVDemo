//
//  FSAudioConfig.m
//  FSAVDemo
//
//  Created by louis on 2022/5/27.
//

#import "FSAudioConfig.h"

@implementation FSAudioConfig
/**
 命令播放: ffplay -ar 44100 -ac 2 -f s16le out.pcm
 */
+ (instancetype)defaultConfig {
    FSAudioConfig *config = [[self alloc] init];
    config.sampleRate = 44100;
    config.channels = 2;
    config.bitDepth = 16;
    
    return config;
}

@end
