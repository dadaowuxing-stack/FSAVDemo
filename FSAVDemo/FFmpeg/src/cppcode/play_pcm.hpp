//
//  play_pcm.hpp
//  FSAVDemo
//
//  Created by louis on 2022/8/6.
//

#ifndef play_pcm_hpp
#define play_pcm_hpp

#include <stdio.h>
#include <string>
#include <mutex>
#include "CLog.h"
#include "Common.h"

using namespace std;

class AudioPlayPCM {
    
public:
    
    static AudioPlayPCM *&GetInstance();
    static void deleteInstance();
    
    bool isPlaying;
    
    void doStartPlay(string srcpath, AudioPlaySpec sepc);
    void doStopPlay();
    
private:
    /// 构造函数
    AudioPlayPCM();
    /// 析构
    ~AudioPlayPCM();
    
    AudioPlayPCM(const AudioPlayPCM &singal);
    const AudioPlayPCM &operator=(const AudioPlayPCM &singal);
    
private:
    static AudioPlayPCM *m_SingleInstance;
    static std::mutex m_Mutex;
};

#endif /* play_pcm_hpp */
