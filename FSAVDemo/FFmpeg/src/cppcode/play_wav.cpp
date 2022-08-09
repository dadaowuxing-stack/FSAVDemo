//
//  play_wav.cpp
//  FSAVDemo
//
//  Created by louis on 2022/8/6.
//

#include "play_wav.hpp"

AudioPlayWav *AudioPlayWav::m_SingleInstance = nullptr;
std::mutex AudioPlayWav::m_Mutex;

AudioPlayWav *&AudioPlayWav::GetInstance() {
    
    if (m_SingleInstance == nullptr) {
        std::unique_lock<std::mutex> lock(m_Mutex); // 加锁
        if (m_SingleInstance == nullptr) {
            m_SingleInstance = new (std::nothrow) AudioPlayWav;
        }
    }
    
    return m_SingleInstance;
}

void AudioPlayWav::deleteInstance() {
    std::unique_lock<std::mutex> lock(m_Mutex); // 加锁
    if (m_SingleInstance) {
        delete m_SingleInstance;
        m_SingleInstance = nullptr;
    }
}

AudioPlayWav::AudioPlayWav() {
    
}

AudioPlayWav::~AudioPlayWav() {
    
}

void AudioPlayWav::doStartPlay(string srcpath, AudioPlaySpec sepc) {
    isPlaying = true;
}

void AudioPlayWav::doStopPlay() {
    isPlaying = false;
}
