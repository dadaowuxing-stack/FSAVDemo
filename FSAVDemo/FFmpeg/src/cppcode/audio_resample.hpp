//
//  audio_resample.hpp
//  FSAVDemo
//
//  Created by louis on 2022/8/6.
//  音频重采样

#ifndef audio_resample_hpp
#define audio_resample_hpp

#include <stdio.h>
#include <string>
#include "CLog.h"

extern "C" {
#include <libavformat/avformat.h>
#include <libswresample/swresample.h>
#include <libavutil/avutil.h>
}

using namespace std;

typedef struct {
    string filePath;
    int sampleRate;
    AVSampleFormat sampleFmt;
    int chLayout;
} AudioResampleSpec;

/** 广义的音频的重采样包括：
 *  1、采样格式(sample_format)转化：比如采样格式从16位整形变为浮点型
 *  2、采样率(sample_rate)的转换：降采样和升采样，比如44100采样率降为2000采样率
 *  3、存放方式转化：音频数据从packet方式变为planner方式。有的硬件平台在播放声音时需要的音频数据是
 *  planner格式的，而有的可能又是packet格式的，或者其它需求原因经常需要进行这种存放方式的转化。一般可以自己手动转换
 */
class AudioResample {
    
public:
    AudioResample();
    ~AudioResample();
    
    static void doResample(AudioResampleSpec &src, AudioResampleSpec &dst);
    
    static void doResample(string src_Filepath,
                           int src_SampleRate,
                           AVSampleFormat src_SampleFmt,
                           int src_ChLayout,
                           
                           string dst_Filepath,
                           int dst_SampleRate,
                           AVSampleFormat dst_SampleFmt,
                           int dst_ChLayout);
};

#endif /* audio_resample_hpp */
