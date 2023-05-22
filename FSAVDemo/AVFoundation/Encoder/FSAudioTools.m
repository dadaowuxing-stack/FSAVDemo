//
//  FSAudioTools.m
//  FSAVDemo
//
//  Created by louis on 2022/6/8.
//
/**
 音频格式：常见的音频格式包括PCM、AAC、MP3、WAV等。其中，PCM是最基本的音频格式，没有压缩，占用空间较大，但音质较好；AAC和MP3是常用的有损压缩格式，占用空间较小，但音质会有所损失；WAV是微软公司开发的一种无损压缩格式，占用空间较大，但音质非常好。

 采样率：采样率指每秒钟对声音信号的采样次数，常见的采样率有44.1kHz、48kHz、96kHz等。采样率越高，音质越好，但占用空间也越大。

 声道数：声道数指音频信号中使用的声道数量，常见的声道数有单声道（Mono）和立体声（Stereo）。单声道只有一个声道，立体声有左右两个声道。还有一些多声道格式，如5.1声道、7.1声道等。
 */
#import "FSAudioTools.h"

@implementation FSAudioTools

/**
 AAC音频文件的每一帧由ADTS Header和AAC Audio Data组成.
 每一帧的ADTS的头文件都包含了音频的采样率，声道，帧长度等信息，这样解码器才能解析读取。 一般情况下ADTS的头信息都是7个字节，分为2部分：
 固定头信息: adts_fixed_header();
 可变头信息: adts_variable_header();
 按音频参数生产 AAC packet 对应的 ADTS 头数据.
 当编码器编码的是 AAC 裸流数据时，需要在每个 AAC packet 前添加一个 ADTS 头用于解码器解码音频流.
 参考文档：
 ADTS 格式参考：http://wiki.multimedia.cx/index.php?title=ADTS
 MPEG-4 Audio 格式参考：http://wiki.multimedia.cx/index.php?title=MPEG-4_Audio#Channel_Configurations
 */
+ (NSData *)adtsDataWithChannels:(NSInteger)channels sampleRate:(NSInteger)sampleRate rawDataLength:(NSInteger)rawDataLength {
    // 1.创建数据缓冲区.
    int adtsLength = 7; // ADTS 头固定 7 字节.
    char *packet = malloc(sizeof(char) * adtsLength);
    
    // 2、设置各数据字段。
    int profile = 2; // MPEG-4 Audio Object Type: 2 表示 AAC LC.
    NSInteger sampleRateIndex = [self.class sampleRateIndex:sampleRate]; // MPEG-4 Sampling Frequency Index: 取得采样率对应的 index.
    int channelCfg = (int) channels; // MPEG-4 Audio Channel Configuration.
    NSUInteger fullLength = adtsLength + rawDataLength; // 这里的长度字段是：ADTS 头数据和 AAC packet 数据的总长度.
    
    //  3、填充 ADTS 数据.
    /**
     ADTS Header consists of 7 or 9 bytes (without or with CRC).
     
     syncword：帧同步标识一个帧的开始，固定为0xFFF
     ID：MPEG 标示符。0表示MPEG-4，1表示MPEG-2
     layer：固定为'00'
     protection_absent：标识是否进行误码校验。0表示有CRC校验，1表示没有CRC校验
     profile：标识使用哪个级别的AAC。1: AAC Main 2:AAC LC (Low Complexity) 3:AAC SSR (Scalable Sample Rate) 4:AAC LTP (Long Term Prediction)
     sampling_frequency_index：标识使用的采样率的下标
     private_bit：私有位，编码时设置为0，解码时忽略
     channel_configuration：标识声道数
     original_copy：编码时设置为0，解码时忽略
     home：编码时设置为0，解码时忽略
     */
    packet[0] = (char) 0xFF; // 11111111     = syncword
    packet[1] = (char) 0xF9; // 1111 1 00 1  = syncword MPEG-2 Layer CRC
    packet[2] = (char) (((profile - 1) << 6) + (sampleRateIndex << 2) + (channelCfg >> 2));
    packet[3] = (char) (((channelCfg & 3) << 6) + (fullLength >> 11));
    packet[4] = (char) ((fullLength & 0x7FF) >> 3);
    packet[5] = (char) (((fullLength & 7) << 5) + 0x1F);
    packet[6] = (char) 0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    
    return data;
}

// 音频采样率对应的 index.
+ (NSInteger)sampleRateIndex:(NSInteger)frequencyInHz {
    NSInteger sampleRateIndex = 0;
    switch (frequencyInHz) {
        case 96000:
            sampleRateIndex = 0;
            break;
        case 88200:
            sampleRateIndex = 1;
            break;
        case 64000:
            sampleRateIndex = 2;
            break;
        case 48000:
            sampleRateIndex = 3;
            break;
        case 44100:
            sampleRateIndex = 4;
            break;
        case 32000:
            sampleRateIndex = 5;
            break;
        case 24000:
            sampleRateIndex = 6;
            break;
        case 22050:
            sampleRateIndex = 7;
            break;
        case 16000:
            sampleRateIndex = 8;
            break;
        case 12000:
            sampleRateIndex = 9;
            break;
        case 11025:
            sampleRateIndex = 10;
            break;
        case 8000:
            sampleRateIndex = 11;
            break;
        case 7350:
            sampleRateIndex = 12;
            break;
        default:
            sampleRateIndex = 15;
    }
    
    return sampleRateIndex;
}

@end
