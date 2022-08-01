//
//  CodecUtil.h
//  FSAVDemo
//
//  Created by louis on 2022/7/30.
//

#ifndef CodecUtil_h
#define CodecUtil_h

#include <stdio.h>
/* 音视频编解码 */
#include <libavcodec/avcodec.h>

/** 选择采样率(仅音频)
 *  1、如果音频编码器支持rate指定的采样率，则返回值为rate
 *  2、如果音频编码器的suported_samplerates为NULL或者不支持rate指定的采样率，则返回44100；
 */
extern int select_sample_rate(AVCodec *codec,int rate);

#endif /* CodecUtil_h */
