//
//  pcm_to_wav.hpp
//  FSAVDemo
//
//  Created by louis on 2022/8/9.
//

#ifndef pcm_to_wav_hpp
#define pcm_to_wav_hpp

#include <stdio.h>
#include <string>

using namespace std;

typedef struct {
    
} WAVHeader;

class AudioPcmToWav {
public:
    
    AudioPcmToWav();
    
    ~AudioPcmToWav();
    
    static void doPcm2Wav(WAVHeader header, string pcmpath, string wavpath);
};

#endif /* pcm_to_wav_hpp */
