//
//  audio_record.cpp
//  FSAVDemo
//
//  Created by louis on 2022/8/2.
//

#include "audio_record.hpp"

#include "CLog.h"

extern "C" {
// 设备
#include <libavdevice/avdevice.h>
// 格式
#include <libavformat/avformat.h>
// 工具（比如错误处理）
#include <libavutil/avutil.h>
#include <libavcodec/avcodec.h>
}

void showSpec(AVFormatContext *ctx) {
    // 获取输入流
    AVStream *stream = ctx->streams[0];
    // 获取音频参数
    AVCodecParameters *params = stream->codecpar;
    // 声道数
    LOGD("声道数 params->channels: %d", params->channels);
    // 采样率
    LOGD("采样率 params->sample_rate: %d", params->sample_rate);
    // 采样格式
    LOGD("采样格式 params->format: %d", params->format);
    // 每一个样本的一个声道占用多少个字节
    LOGD("每一个样本的一个声道占用多少个字节 av_get_bytes_per_sample((AVSampleFormat) params->format): %d", av_get_bytes_per_sample((AVSampleFormat) params->format));
}

AudioRecord *AudioRecord::m_SingleInstance = nullptr;
std::mutex AudioRecord::m_Mutex;

AudioRecord *&AudioRecord::GetInstance() {
    
    if (m_SingleInstance == nullptr) {
        std::unique_lock<std::mutex> lock(m_Mutex); // 加锁
        if (m_SingleInstance == nullptr) {
            m_SingleInstance = new (std::nothrow) AudioRecord;
        }
    }
    
    return m_SingleInstance;
}

void AudioRecord::deleteInstance() {
    std::unique_lock<std::mutex> lock(m_Mutex); // 加锁
    if (m_SingleInstance) {
        delete m_SingleInstance;
        m_SingleInstance = nullptr;
    }
}

AudioRecord::AudioRecord() {
    
}

AudioRecord::~AudioRecord() {
    
}

void AudioRecord::doStartRecord(string fmt_name, string device_name, string file_path) {
    LOGD("开始录制");
    isRecording = true;
    // 获取输入格式对象(平台不一样输入的格式也不一样: iOS/Mac 平台是:avfoundation)
    AVInputFormat *fmt = av_find_input_format(fmt_name.c_str());
    if (!fmt) {
        LOGD("av_find_input_format error: %s", fmt_name.c_str());
        return;
    }
    // 格式上下文（贯穿整个过程,将来可以利用上下文操作设备）
    AVFormatContext *ctx = nullptr;
    // 打开设备, 获取上下文信息
    int ret = avformat_open_input(&ctx, device_name.c_str(), fmt, nullptr);
    if (ret < 0) {
        LOGD("avformat_open_input error: %s", device_name.c_str());
        return;
    }
    
    // 打印录音设备参数信息
    showSpec(ctx);
    
    // 打开文件
    FILE *file = fopen(file_path.c_str(), "wb+");
    if (!file) {
        LOGD("file fopen error: %s", file_path.c_str());
        // 关闭设备
        avformat_close_input(&ctx);
        return;
    }
    
    // 声明数据包(它是一个结构体,采集的数据会存放到数据包中)
    // Allocate an AVPacket and set its fields to default values.
    AVPacket *pkt = av_packet_alloc();
    while (isRecording) {
        // 不断采集数据()
        ret = av_read_frame(ctx, pkt);
        // 采集成功
        if (ret == 0) {
            fwrite(pkt->data, pkt->size, 1, file);
        } else if (ret == AVERROR(EAGAIN)) { // 资源临时不可用
            continue;
        } else { // 其他错误
            LOGD("av_read_frame error");
            break;
        }
        // 必须要加，释放pkt内部的资源(the packet must be freed with av_packet_unref when it is no longer needed.)
        av_packet_unref(pkt);
    }
    // 关闭文件
    fclose(file);
    // 释放资源
    av_packet_free(&pkt);

    // 关闭设备
    avformat_close_input(&ctx);
}

void AudioRecord::doStopRecord() {
    isRecording = false;
    LOGD("结束录制");
}
