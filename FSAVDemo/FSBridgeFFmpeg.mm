//
//  FSBridgeFFmpeg.m
//  FSAVDemo
//
//  Created by louis on 2022/8/3.
//

#import "FSBridgeFFmpeg.h"
#include <string>

#include "audio_encode.hpp"

@implementation FSBridgeFFmpeg


/// OC 字符串转 C 字符串
/// @param jsStr OC 字符串
std::string jstring2string(NSString *jsStr) {
    const char *cstr = [jsStr UTF8String];
    std::string str = std::string(cstr);
    return str;
}

/// PCM 转 AAC
/// @param src 源文件路径
/// @param dst 目标文件路径
+ (void)doEncodePCM2AAC:(NSString *)src dst:(NSString *)dst {
    
    string srcpath = jstring2string(src);
    string dstpath = jstring2string(dst);

    AudioEncode aEncode(srcpath, dstpath);
    AudioEncodeSpec in_spec;
    in_spec.sample_fmt = AV_SAMPLE_FMT_S16;
    in_spec.sample_rate = 44100;
    in_spec.channel_layout = AV_CH_LAYOUT_STEREO;
    aEncode.doEncode(in_spec, CodecFormatAAC, true);
}

@end
