//
//  play_wav.hpp
//  FSAVDemo
//
//  Created by louis on 2022/8/6.
//

#ifndef play_wav_hpp
#define play_wav_hpp

#include <stdio.h>
#include <string>
#include <mutex>
#include "Common.h"

using namespace std;

class AudioPlayWav {
    
public:
    
    static AudioPlayWav *&GetInstance();
    static void deleteInstance();
    
    bool isPlaying;
    
    void doStartPlay(string srcpath, AudioPlaySpec sepc);
    void doStopPlay();
    
private:
    /// 构造函数
    AudioPlayWav();
    /// 析构
    ~AudioPlayWav();
    
    AudioPlayWav(const AudioPlayWav &singal);
    const AudioPlayWav &operator=(const AudioPlayWav &singal);
    
private:
    static AudioPlayWav *m_SingleInstance;
    static std::mutex m_Mutex;
};

#endif /* play_wav_hpp */
