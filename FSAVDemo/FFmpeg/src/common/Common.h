//
//  Common.h
//  FSAVDemo
//
//  Created by louis on 2022/7/30.
//

#ifndef Common_h
#define Common_h

#ifdef __cplusplus
extern "C" {
#endif

#import <SDL2/SDL.h>

#include "CLog.h"
#include "CodecUtil.h"

typedef struct AudioBuffer_tag {
    int len = 0;
    int pullLen = 0;
    Uint8 *data = nullptr;
} AudioBuffer;

typedef struct {
    Uint8 channels;
    SDL_AudioFormat format;
    int sampleRate;
    Uint16 samples;
} AudioPlaySpec;

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* Common_h */
