//
//  audio_encode.hpp
//  FSAVDemo
//
//  Created by louis on 2022/8/2.
//  音频编码

#ifndef audio_encode_hpp
#define audio_encode_hpp

extern "C" {
// 编解码
#include <libavcodec/avcodec.h>
// 格式
#include <libavformat/avformat.h>
// 重采样
#include <libswresample/swresample.h>
// 工具
#include <libavutil/opt.h>
#include <libavutil/error.h>
}

#include <stdio.h>
#include <string>

using namespace std;

typedef enum {
    CodecFormatAAC,
    CodecFormatMP3,
    CodecFormatAC3,
} CodecFormat;

typedef struct {
    string file_path;          // 文件
    AVSampleFormat sample_fmt; // 采样格式
    int sample_rate;           // 采样率
    uint64_t channel_layout;   // 声道布局
} AudioEncodeSpec;

class AudioEncode {
public:
    
    /// 音频编码构造函数
    /// @param srcpath 源文件路径
    /// @param dstpath 目标文件路径
    AudioEncode(string srcpath, string dstpath);
    
    /// 析构函数
    ~AudioEncode();
    
    /// 音频编码
    /// @param in_spec 输入信息
    /// @param format 编码格式
    /// @param saveByFile 是否保存为文件
    /// aac有两种封装格式，ADIF和ADTS，比较常用的是ADTS。FFMpeg进行aac编码后的数据就是ADTS的格式数据。这个数据直接写入文件即可播放。
    /// doEncode默认通过FFMpeg库提供的AVFormatContext(格式上下文)写入数据，如果saveByFile为true，还同时直接将编码后的aac数据由File提供接口写入文件
    void doEncode(AudioEncodeSpec &in_spec, CodecFormat format = CodecFormatAAC, bool saveByFile = false);
    
private:
    string m_srcpath, m_dstpath; // 源路径, 目标路径
    AVCodecContext *m_pCodecCtx; // 编码上下文
    AVFormatContext *m_pFmtCtx;  // 格式上下文
    SwrContext *m_pSwrCtx; // 重采样上下文(音频重采样的结构体)
    
    /// 释放资源
    void releaseResources();
};

#endif /* audio_encode_hpp */
