//
//  audio_encode.cpp
//  FSAVDemo
//
//  Created by louis on 2022/8/2.
//

#include "audio_encode.hpp"
#include "CLog.h"
#include <math.h>

static AVCodec* select_codec(CodecFormat format) {
    AVCodec *codec = nullptr;
    
    if (format == CodecFormatAAC) {
        
    } else if (format == CodecFormatMP3) {
        
    } else if (format == CodecFormatAC3) {
        
    }
    
    return codec;
}

static int check_sample_fmt(const AVCodec *codec, enum AVSampleFormat sample_fmt) {
    const enum AVSampleFormat *sample_fmts = codec->sample_fmts;
    while (*sample_fmts != AV_SAMPLE_FMT_NONE) {
        LOGD("sample_fmt_name: ", av_get_sample_fmt_name(*sample_fmts));
        if (*sample_fmts == sample_fmt) {
            return 1;
        }
        sample_fmts++;
    }
    return 0;
}

/// 初始化构造函数(初始化列表:初始化顺序只跟成员变量的声明顺序有关)
/// @param srcpath 源路径
/// @param dstpath 目标路径
AudioEncode::AudioEncode(string srcpath, string dstpath) :m_srcpath(srcpath), m_dstpath(dstpath) {
    m_pCodecCtx = nullptr;
    m_pFmtCtx = nullptr;
    m_pSwrCtx = nullptr;
}

/// 析构函数
AudioEncode::~AudioEncode() {
    
}


/// 编码方法
/// @param fmtCtx 格式上下文
/// @param codecCtx 编码上下文
/// @param pkt 数据包
/// @param frame 数据帧
/// @param file 文件
void AudioEncode::encode(AVFormatContext *fmtCtx, AVCodecContext *codecCtx, AVPacket *pkt, AVFrame *frame, FILE *file) {
    if (fmtCtx == nullptr || codecCtx == nullptr || pkt == nullptr) {
        return;
    }
    
}

void AudioEncode::doEncode(CodecFormat format, bool saveByFile) {
    if (m_srcpath.length() == 0) {
        LOGD("srcpath not found");
        return;
    }
    if (m_dstpath.length() == 0) {
        LOGD("detpath not found");
        return;
    }
    // 三元素: 采样率,采样格式,声道布局
    // 采样率
    int src_sample_rate = 44100;
    int dst_sample_rate = 44100;
    // 采样格式
    AVSampleFormat src_sample_format = AV_SAMPLE_FMT_FLT; // 文件是16位整形类型方式存储的
    AVSampleFormat dst_sample_format = AV_SAMPLE_FMT_FLT;
    // 声道布局
    uint64_t src_ch_layout = AV_CH_LAYOUT_STEREO;
    uint64_t dst_ch_layout = AV_CH_LAYOUT_STEREO;
    
    int src_nb_samples = 1024;
    // 获取声道数
    int src_nb_channels = av_get_channel_layout_nb_channels(src_ch_layout);
    
    LOGD("srcpath: %s dstpath: s%", m_srcpath.c_str(), m_dstpath.c_str());
    
    // 返回结果
    int ret = 0;
    
    // 1.查找(获取)编码器
    AVCodec *pCodec = select_codec(format);
    if (!pCodec) {
        LOGD("codec not found");
        return;
    }
    
    // 1.1 检查输入数据的采样格式(libfdk_aac对输入数据的要求：采样格式必须是16位整数)
    if (!check_sample_fmt(pCodec, src_sample_format)) {
        LOGD("unsupported sample format", av_get_sample_fmt_name(src_sample_format));
        return;
    }
    
    // 2.创建编码上下文
    
}
