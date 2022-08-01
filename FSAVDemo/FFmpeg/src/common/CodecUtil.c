//
//  CodecUtil.c
//  FSAVDemo
//
//  Created by louis on 2022/7/30.
//

#include "CodecUtil.h"

// 选择采样率(仅音频)
int select_sample_rate(AVCodec *codec, int rate) {
    int best_rate = 0;
    int def_rate = 44100;
    // 支持的采样率（仅音频）
    const int *p = codec->supported_samplerates;
    if (!p) {
        return def_rate;
    }
    
    //  取出采样率不为空则继续遍历
    while (*p) {
        best_rate = *p;
        // 取到的采样率和指定的采样率一样则结束遍历
        if (*p == rate) {
            break;
        }
        p++;
    }
    // 获取到的采样率并且和指定的采样率不一致并且和默认不一致 则返回 默认的采样率
    if (best_rate != rate && best_rate != 0 && best_rate != def_rate) {
        return def_rate;
    }
    
    return best_rate;
}

// 选择采样格式
enum AVSampleFormat select_sample_format(AVCodec *codec, enum AVSampleFormat fmt) {
    enum AVSampleFormat retfmt = AV_SAMPLE_FMT_NONE;
    enum AVSampleFormat deffmt = AV_SAMPLE_FMT_FLTP;
    // 获取支持的采样格式（仅音频）
    const enum AVSampleFormat *fmts = codec->sample_fmts;
    if (!fmts) {
        return deffmt;
    }
    
    while (*fmts != AV_SAMPLE_FMT_NONE) {
        retfmt = *fmts;
        // 取到的值是否等于默认值
        if (retfmt == fmt) {
            break;
        }
        fmts++;
    }
    if (retfmt != fmt && retfmt != AV_SAMPLE_FMT_NONE && retfmt != deffmt) {
        return deffmt;
    }
    
    return retfmt;
}

// 选择声道布局
int64_t select_channel_layout(AVCodec *codec, int64_t ch_layout) {
    int64_t retch = 0;
    int64_t defch = AV_CH_LAYOUT_STEREO;
    // 获取支持的声道数（仅音频）
    const uint64_t *chs = codec->channel_layouts;
    
    if (!chs) {
        return defch;
    }
    
    while (*chs) {
        retch = *chs;
        if (retch == *chs) {
            break;
        }
        chs++;
    }
    
    if (retch != ch_layout && retch != 0 && retch != defch) {
        return defch;
    }
    
    return retch;
}
