//
//  audio_record.hpp
//  FSAVDemo
//
//  Created by louis on 2022/8/2.
//

#ifndef audio_record_hpp
#define audio_record_hpp

#include <stdio.h>
#include <string>
#include <mutex>

using namespace std;

class AudioRecord {
    
public:
    
    static AudioRecord *&GetInstance();
    static void deleteInstance();
    
    bool isRecording;
    
    void doStartRecord(string fmt_name, string device_name, string file_path);
    void doStopRecord();
    
private:
    /// 构造函数
    AudioRecord();
    /// 析构
    ~AudioRecord();
    
    AudioRecord(const AudioRecord &singal);
    const AudioRecord &operator=(const AudioRecord &singal);
    
private:
    static AudioRecord *m_SingleInstance;
    static std::mutex m_Mutex;
};

#endif /* audio_record_hpp */
