//
//  play_pcm.cpp
//  FSAVDemo
//
//  Created by louis on 2022/8/6.
//

#include "play_pcm.hpp"

AudioPlayPCM *AudioPlayPCM::m_SingleInstance = nullptr;
std::mutex AudioPlayPCM::m_Mutex;

AudioPlayPCM *&AudioPlayPCM::GetInstance() {
    
    if (m_SingleInstance == nullptr) {
        std::unique_lock<std::mutex> lock(m_Mutex); // 加锁
        if (m_SingleInstance == nullptr) {
            m_SingleInstance = new (std::nothrow) AudioPlayPCM;
        }
    }
    
    return m_SingleInstance;
}

void AudioPlayPCM::deleteInstance() {
    std::unique_lock<std::mutex> lock(m_Mutex); // 加锁
    if (m_SingleInstance) {
        delete m_SingleInstance;
        m_SingleInstance = nullptr;
    }
}

AudioPlayPCM::AudioPlayPCM() {
    
}

AudioPlayPCM::~AudioPlayPCM() {
    
}

void pull_audio_data(void *userdata,
                     // 需要往 stream 中填充的 pcm 数据
                     Uint8 *stream,
                     // 希望填充的大小(samples * format *channels / 8)
                     int len) {
    // 清空stream(静音处理)
    SDL_memset(stream, 0, len);
    // 取出 AudioBuffer
    AudioBuffer *buffer = (AudioBuffer *)userdata;
    // 文件数据还没有准备好
    if (buffer->len <= 0) return;
    // 取 len, bufferLen 的最小值(为了保证数据安全,防止指针越界)
    buffer->pullLen = (len > buffer->len) ? buffer->len : len;

    SDL_MixAudio(stream,
                 buffer->data,
                 buffer->pullLen,
                 SDL_MIX_MAXVOLUME);
    buffer->data += buffer->pullLen; // 指针移动(指向数据的位置移动)
    buffer->len -= buffer->pullLen;  // 缓冲数据长度减小
}

/**
 * SDL播放音频有2种模式
 * Push(推) [程序]主动推送数据给[音频设备]
 * Pull(拉) [音频设备]主动向[程序]拉数据
 */
void AudioPlayPCM::doStartPlay(string srcpath, AudioPlaySpec playSpec) {
    
    isPlaying = true;
    
    SDL_SetMainReady();
    
    // 1.初始化 Audio 子系统
    if (SDL_Init(SDL_INIT_AUDIO)) {
        LOGD("SDL_Init error: %s", SDL_GetError());
        return;
    }

    // 采样大小
    int sample_size = 16;
    // 每个样本占用多少个字节(采样大小 * 声道数)
    int bytes_per_sample ((sample_size * playSpec.channels) >> 3);
    // 文件缓冲区大小
    size_t buffer_size = (playSpec.samples * bytes_per_sample);

    /// 音频参数
    SDL_AudioSpec spec;
    // 采样率
    spec.freq = playSpec.sampleRate;
    // 采样格式
    spec.format = playSpec.format;
    // 声道数
    spec.channels = playSpec.channels;
    // 音频缓冲区的样本数量(这个值必须是 2 的幂)
    spec.samples = playSpec.samples;
    // 回调
    spec.callback = pull_audio_data;
    // 传给回调的参数
    AudioBuffer buffer;
    spec.userdata = &buffer;

    // 2.打开音频设备
    if (SDL_OpenAudio(&spec, nullptr)) {
        LOGD("SDL_OpenAudio error: %s", SDL_GetError());
        // 清除所有子系统
        SDL_Quit();
        return;
    }

    // 3.打开pcm文件
    FILE *file = fopen(srcpath.c_str(), "rb");
    if (!file) {
        LOGD("file open error: %s", srcpath.c_str());
        // 关闭设备
        SDL_CloseAudio();
        // 清除所有子系统
        SDL_Quit();
        return;
    }

    // 4.开始播放(0 是取消暂停,即播放的意思)
    SDL_PauseAudio(0);

    // 存放从文件中读取的数据
    Uint8 data[buffer_size];
    while (isPlaying) {
        // 只要是从文件中读取的音频数据,还没填充完毕,就跳过
        if (buffer.len > 0) continue;
        // 读取到数据的长度(将数据读取到 data缓冲区中中,每次读取BUFFER_SIZE大小,返回实际独到的大小bufferLen)
        buffer.len = (int)fread(data, 1, buffer_size, file);
        // 文件数据已经读取完毕
        if (buffer.len <= 0) {
            // 剩余样本数量
            int samples = buffer.pullLen / bytes_per_sample;
            int ms = samples * 1000 / playSpec.sampleRate;
            SDL_Delay(ms);
            break;
        };
        // 读取到了文件数据
        buffer.data = data;
    }
    
    isPlaying = false;

    // 关闭文件
    fclose(file);
    // 关闭设备
    SDL_CloseAudio();
    // 清空所有的子系统
    SDL_Quit();
    
    LOGD("正常结束");
}

void AudioPlayPCM::doStopPlay() {
    isPlaying = false;
}
