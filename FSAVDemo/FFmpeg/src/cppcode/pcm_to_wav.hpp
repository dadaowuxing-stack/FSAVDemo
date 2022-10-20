//
//  pcm_to_wav.hpp
//  FSAVDemo
//
//  Created by louis on 2022/8/9.
//  PCM 转 WAV

#ifndef pcm_to_wav_hpp
#define pcm_to_wav_hpp

#include <stdio.h>
#include <stdint.h>
#include <string>
#include <mutex>
#include "CLog.h"
#include <strstream>
#include <filesystem>

extern "C" {
// 设备
#include <libavdevice/avdevice.h>
// 格式
#include <libavformat/avformat.h>
// 工具（比如错误处理）
#include <libavutil/avutil.h>
}

#define AUDIO_FORMAT_PCM 1
#define AUDIO_FORMAT_FLOAT 3

using namespace std;

typedef struct WAVHeader_tag {
    // RIFF chunk的Id
    uint8_t riffChunkId[4] = {'R', 'I', 'F', 'F'};
    // RIFF chunk的data大小, 即文件总长度减去8字节
    uint32_t riffChunkDataSize;
    
    // "WAVE"
    uint8_t format[4] = {'W', 'A', 'V', 'E'};
    
    /** fmt chunk */
    // fmt chunk的Id
    uint8_t fmtChunkId[4] = {'f', 'm', 't', ' '};
    // fmt chunk的data大小, 存储PCM数据时,是16
    uint32_t fmtChunkDataSize = 16;
    // 音频编码, 1表示PCM, 3表示Floating Point
    uint16_t audioFormat = AUDIO_FORMAT_PCM;
    // 声道数
    uint16_t numChannels;
    // 采样率
    uint32_t sampleRate;
    // 字节率 = sampleRate * blockAlign
    uint32_t byteRate;
    // 一个样本的字节数 = bitsPerSample * numChannels >> 3
    uint16_t blockAlign;
    // 位深度
    uint16_t bitsPerSample;
    
    /** data chunk */
    // data chunk的Id
    uint8_t dataChunkId[4] = {'d', 'a', 't', 'a'};
    // data chunk的data大小: 音频数据的总长度, 即文件的总长度减去文件头的长度(一般是 44).
    uint32_t dataChunkDataSize;
    
} WAVHeader;

class AudioPcmToWav {
public:
    static AudioPcmToWav *&GetInstance();
    static void deleteInstance();
    
    bool isRecording;
    
    void doPcm2Wav(string pcmpath, string wavpath);
    void doStop();
    
private:
    /// 构造函数
    AudioPcmToWav();
    /// 析构
    ~AudioPcmToWav();
    
    AudioPcmToWav(const AudioPcmToWav &singal);
    const AudioPcmToWav &operator=(const AudioPcmToWav &singal);
    
private:
    static AudioPcmToWav *m_SingleInstance;
    static std::mutex m_Mutex;
};

#endif /* pcm_to_wav_hpp */
