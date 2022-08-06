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

using namespace std;

typedef struct {
    string fmt_name;    // 格式名称
    string device_name; // 设备名称
    string file_path;   // 文件路径
} AudioRecordSpec;

class AudioRecord {
    
public:
    bool isRecording;
    /// 构造函数
    /// @param spec 录制信息
    AudioRecord(AudioRecordSpec &spec);
    
    /// 析构
    ~AudioRecord();
    
    void doStartRecord();
    void doStopRecord();
    
private:
    AudioRecordSpec m_spec;
};

#endif /* audio_record_hpp */
