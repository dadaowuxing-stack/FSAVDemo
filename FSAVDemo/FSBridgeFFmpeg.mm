//
//  FSBridgeFFmpeg.m
//  FSAVDemo
//
//  Created by louis on 2022/8/3.
//

#import "FSBridgeFFmpeg.h"
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

+ (void)doAudioCapture:(NSString *)path {
    
    string fmt_name = "avfoundation";
    string device_name = ":0";
    string file_path = jstring2string(path);
    AudioRecord *audioRecord = AudioRecord::GetInstance();
    if (audioRecord->isRecording) {
        audioRecord->doStopRecord();
    } else {
        audioRecord->doStartRecord(fmt_name, device_name, file_path);
    }
}

/// PCM 转 AAC
/// @param src 源文件路径
/// @param dst 目标文件路径
+ (void)doEncodePCM2AAC:(NSString *)src dst:(NSString *)dst {
    
    string srcpath = jstring2string(src);
    string dstpath = jstring2string(dst);

    AudioEncode aEncode(srcpath, dstpath);
    AudioEncodeSpec in_spec;
    in_spec.sample_fmt = AV_SAMPLE_FMT_S16;
    in_spec.sample_rate = 44100;
    in_spec.channel_layout = AV_CH_LAYOUT_STEREO;
    aEncode.doEncode(in_spec, CodecFormatAAC, true);
}

@end
