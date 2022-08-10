//
//  FSBridgeFFmpeg.m
//  FSAVDemo
//
//  Created by louis on 2022/8/3.
//

#import "FSBridgeFFmpeg.h"
#import "FSFileManager.h"
#include <string>
#include "Common.h"

#include <stdio.h>
#ifdef __cplusplus
extern "C" {
#endif

#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavdevice/avdevice.h>

#ifdef __cplusplus
}
#endif

#include "audio_encode.hpp"
#include "audio_record.hpp"
#include "audio_resample.hpp"
#include "play_pcm.hpp"
#include "pcm_to_wav.hpp"
#include "play_wav.hpp"

@interface FSBridgeFFmpeg() {}

@end

@implementation FSBridgeFFmpeg

static void custom_log_callback(void *ptr,int level, const char* format,va_list val) {
    if (level > av_log_get_level()) {
        return;
    }
    char out[200] = {0};
    int prefixe = 0;
    av_log_format_line2(ptr,level,format,val,out,200,&prefixe);
    LOGD("%s",out);
}

+ (void)testLib {
    
    AVCodec *codec = avcodec_find_encoder_by_name("libx264");
    if (!codec) {
        LOGD("not found libx264");
    } else {
        LOGD("yes found libx264");
    }

    AVCodec *codec1 = avcodec_find_encoder_by_name("libmp3lame");
    if (!codec1) {
        LOGD("not found libmp3lame");
    } else {
        LOGD("yes found libmp3lame");
    }

    AVCodec *codec2 = avcodec_find_encoder_by_name("libfdk_aac");
    if (!codec2) {
        LOGD("not found libfdk_aac");
    } else {
        LOGD("yes found libfdk_aac");
    }

    show_avfoundation_device();
    
    // 打印ffmpeg日志
    av_log_set_level(AV_LOG_QUIET);
    av_log_set_callback(custom_log_callback);
}

void show_avfoundation_device() {
    
    avdevice_register_all();
    AVFormatContext *pFormatCtx = avformat_alloc_context();
    AVDictionary* options = NULL;
    av_dict_set(&options,"list_devices","true",0);
    AVInputFormat *iformat = av_find_input_format("avfoundation");
    printf("==AVFoundation Device Info===\n");
    avformat_open_input(&pFormatCtx,"", iformat, &options);
    printf("=============================\n");
    if(avformat_open_input(&pFormatCtx,"0", iformat, NULL) != 0){
        printf("Couldn't open input stream.\n");
        return ;
    }
}

/// OC 字符串转 C 字符串
/// @param jsStr OC 字符串
std::string jstring2string(NSString *jsStr) {
    const char *cstr = [jsStr UTF8String];
    std::string str = std::string(cstr);
    return str;
}

+ (void)doRecord {
    AudioRecord *audioRecord = AudioRecord::GetInstance();
    if (audioRecord->isRecording) {
        audioRecord->doStopRecord();
    } else {
        string fmt_name = "avfoundation";
        string device_name = ":0";
        NSString  *path = [[FSFileManager documentsDirectory] stringByAppendingPathComponent:@"audio_record_out.pcm"];
        string filepath = jstring2string(path);
        BOOL isSuccess = [FSFileManager createFileAtPath:path];
        if (isSuccess) {
            audioRecord->doStartRecord(fmt_name, device_name, filepath);
        }
    }
}

+ (void)doPlayPcm {
    
    NSString *path = [[FSFileManager documentsDirectory] stringByAppendingPathComponent:@"audio_record_out.pcm"];
    BOOL isExists = [FSFileManager isExistsAtPath:path];
    if (!isExists) {
        path = [[NSBundle mainBundle] pathForResource:@"44100_s16le_2" ofType:@"pcm"];
    }
    string srcpath = jstring2string(path);
    
    AudioPlaySpec spec;
    spec.sampleRate = 44100;
    spec.format = AUDIO_S16LSB;
    spec.channels = 2;
    spec.samples = 1024;
    
    AudioPlayPCM *aPlayPCM = AudioPlayPCM::GetInstance();
    if (aPlayPCM->isPlaying) {
        aPlayPCM->doStopPlay();
    } else {
        aPlayPCM->doStartPlay(srcpath, spec);
    }
}

/// PCM to AAC
+ (void)doPcm2AAC {
    NSString *src = [[NSBundle mainBundle] pathForResource:@"44100_s16le_2" ofType:@"pcm"];
    NSString *dst = [[FSFileManager documentsDirectory] stringByAppendingPathComponent:@"pcm2aac_out.pcm"];
    
    string srcpath = jstring2string(src);
    string dstpath = jstring2string(dst);
    
    BOOL isSuccess = [FSFileManager createFileAtPath:dst];
    if (isSuccess) {
        AudioEncode aEncode(srcpath, dstpath);
        AudioEncodeSpec in_spec;
        in_spec.sample_fmt = AV_SAMPLE_FMT_S16;
        in_spec.sample_rate = 44100;
        in_spec.channel_layout = AV_CH_LAYOUT_STEREO;
        aEncode.doEncode(in_spec, CodecFormatAAC, true);
    }
}

+ (void)doPcm2Wav {
    AudioPcmToWav *pcm2wav = AudioPcmToWav::GetInstance();
    if (pcm2wav->isRecording) {
        pcm2wav->doStop();
    } else {
        NSString *pcm = [[FSFileManager documentsDirectory] stringByAppendingPathComponent:@"pcm2wav_out.pcm"];
        NSString *wav = [[FSFileManager documentsDirectory] stringByAppendingPathComponent:@"pcm2wav_out.wav"];
        string pcmpath = jstring2string(pcm);
        string wavpath = jstring2string(wav);
        BOOL isPcmSuccess = [FSFileManager createFileAtPath:pcm];
        BOOL isWavSuccess = [FSFileManager createFileAtPath:wav];
        if (isPcmSuccess && isWavSuccess) {
            pcm2wav->doPcm2Wav(pcmpath, wavpath);
        }
    }
}

+ (void)doResample:(NSString*)src dst:(NSString*)dst {
    string srcpath = jstring2string(src);
    string dstpath = jstring2string(dst);

    AudioResampleSpec spec1;
    spec1.filePath = srcpath;
    spec1.sampleFmt = AV_SAMPLE_FMT_S16;
    spec1.sampleRate = 44100;
    spec1.chLayout = AV_CH_LAYOUT_STEREO;
    
    AudioResampleSpec spec2;
    spec2.filePath = dstpath;
    spec2.sampleFmt = AV_SAMPLE_FMT_FLT;
    spec2.sampleRate = 48000;
    spec2.chLayout = AV_CH_LAYOUT_MONO;
    
    AudioResample aResample;
    aResample.doResample(spec1, spec2);
}

@end
