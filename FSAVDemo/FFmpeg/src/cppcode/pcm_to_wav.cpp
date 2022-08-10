//
//  pcm_to_wav.cpp
//  FSAVDemo
//
//  Created by louis on 2022/8/9.
//

#include "pcm_to_wav.hpp"

#define ERROR_BUF(ret) \
char errbuf[1024]; \
av_strerror(ret, errbuf, sizeof (errbuf));

#define FMT_NAME "avfoundation"
#define DEVICE_NAME ":0"

AudioPcmToWav *AudioPcmToWav::m_SingleInstance = nullptr;
std::mutex AudioPcmToWav::m_Mutex;

AudioPcmToWav *&AudioPcmToWav::GetInstance() {
    
    if (m_SingleInstance == nullptr) {
        std::unique_lock<std::mutex> lock(m_Mutex); // 加锁
        if (m_SingleInstance == nullptr) {
            m_SingleInstance = new (std::nothrow) AudioPcmToWav;
        }
    }
    
    return m_SingleInstance;
}

void AudioPcmToWav::deleteInstance() {
    std::unique_lock<std::mutex> lock(m_Mutex); // 加锁
    if (m_SingleInstance) {
        delete m_SingleInstance;
        m_SingleInstance = nullptr;
    }
}

AudioPcmToWav::AudioPcmToWav() {
    
}

AudioPcmToWav::~AudioPcmToWav() {
    
}

static void pcm2Wav(WAVHeader &header, string pcmpath, string wavpath) {
    // 一个样本的字节数 = bitsPerSample * numChannels >> 3
    header.blockAlign = header.bitsPerSample * header.numChannels >> 3;
    // 字节率 = sampleRate * blockAlign
    header.byteRate = header.sampleRate * header.blockAlign;
    
    // 打开pcm文件
    FILE *pcmFile = fopen(pcmpath.c_str(), "rb");
    if (!pcmFile) {
        LOGD("pcm file 文件打开失败: %s", pcmpath.c_str());
        return;
    }
    
    LOGD("222222pcmpath ====== %s", pcmpath.c_str());
    uint32_t pcmFileSize = (uint32_t)filesystem::file_size(pcmpath.c_str());
    LOGD("pcmFileSize ====== %d", pcmFileSize);
    header.dataChunkDataSize = pcmFileSize;
    header.riffChunkDataSize = header.dataChunkDataSize
                                   + sizeof (WAVHeader)
                                   - sizeof (header.riffChunkId)
                                   - sizeof (header.riffChunkDataSize);
    // 打开wav文件
    FILE *wavFile = fopen(wavpath.c_str(), "wb+");
    if (!wavFile) {
        LOGD("wav file文件打开失败: %s", wavpath.c_str());
        fclose(pcmFile);
        return;
    }
    
    // 写入头部
    fwrite(&header, sizeof(WAVHeader), 1, wavFile);
    
    // 写入pcm数据
    char buf[1024];
     unsigned long size;
    while ((size = fread(buf, 1, sizeof(buf), pcmFile)) > 0) {
        fwrite(buf, size, 1, wavFile);
    }
    
    // 关闭文件
    fclose(pcmFile);
    fclose(wavFile);
}

void AudioPcmToWav::doPcm2Wav(string pcmpath, string wavpath) {
    // 获取输入格式对象
    AVInputFormat *fmt = av_find_input_format(FMT_NAME);
    if (!fmt) {
        LOGD("av_find_input_format error: %s", FMT_NAME);
        return;
    }
    // 格式上下文（将来可以利用上下文操作设备）
    AVFormatContext *ctx = nullptr;
    // 打开设备
    int ret = avformat_open_input(&ctx, DEVICE_NAME, fmt, nullptr);
    if (ret < 0) {
        LOGD("avformat_open_input error: %s", DEVICE_NAME);
        return;
    }
    
    // 打开文件
    FILE *file = fopen(pcmpath.c_str(), "wb+");
    if (!file) {
        LOGD("file fopen error: %s", pcmpath.c_str());
        // 关闭设备
        avformat_close_input(&ctx);
        return;
    }
    
    isRecording = true;
    
    // 数据包
    AVPacket *pkt = av_packet_alloc();
    while (isRecording) {
        // 不断采集数据
        ret = av_read_frame(ctx, pkt);
        // 采集成功
        if (ret == 0) {
            fwrite(pkt->data, pkt->size, 1, file);
        } else if (ret == AVERROR(EAGAIN)) { // 资源临时不可用
            LOGD("EAGAIN");
            continue;
        } else { // 其他错误
            LOGD("av_read_frame error");
            break;
        }
        // 必须要加，释放pkt内部的资源
        av_packet_unref(pkt);
    }
    
    isRecording = false;
    
    // 关闭文件
    fclose(file);
    // 释放资源
    av_packet_free(&pkt);
    
    // 获取输入流
    AVStream *stream = ctx->streams[0];
    // 获取音频参数
    AVCodecParameters *params = stream->codecpar;


    /** pcm转wav */
    WAVHeader header;
    header.sampleRate = params->sample_rate;
    header.bitsPerSample = av_get_bits_per_sample(params->codec_id);
    header.numChannels = params->channels;
    if (params->codec_id >= AV_CODEC_ID_PCM_F32BE) {
        header.audioFormat = AUDIO_FORMAT_FLOAT;
    }
    pcm2Wav(header, pcmpath, wavpath);
    
    // 关闭设备
    avformat_close_input(&ctx);
    
    LOGD("------正常结束------");
}

void AudioPcmToWav::doStop() {
    isRecording = false;
}

