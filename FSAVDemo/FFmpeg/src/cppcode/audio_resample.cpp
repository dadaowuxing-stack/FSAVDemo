//
//  audio_resample.cpp
//  FSAVDemo
//
//  Created by louis on 2022/8/6.
//

#include "audio_resample.hpp"

#define ERROR_BUF(ret) \
char errbuf[1024]; \
av_strerror(ret, errbuf, sizeof (errbuf));

AudioResample::AudioResample() {
    
}

AudioResample::~AudioResample() {
    
}

void AudioResample::doResample(AudioResampleSpec &in, AudioResampleSpec &out) {
    doResample(in.filePath, in.sampleRate, in.sampleFmt, in.chLayout,
               out.filePath, out.sampleRate, out.sampleFmt, out.chLayout);
}

void AudioResample::doResample(string inFilepath,
                               int inSampleRate,
                               AVSampleFormat inSampleFmt,
                               int inChLayout,
                               
                               string outFilepath,
                               int outSampleRate,
                               AVSampleFormat outSampleFmt,
                               int outChLayout) {
    
    FILE *inFile = nullptr;
    FILE *outFile = nullptr;
    
    /********输入缓冲区********/
    // 指向缓冲区的指针
    uint8_t **in_data = nullptr;
    // 缓冲区大小
    int inLineSize = 0;
    // 声道数
    int inChs = av_get_channel_layout_nb_channels(inChLayout);
    // 一个样本的大小
    int inBytesPerSample = inChs * av_get_bytes_per_sample(inSampleFmt);
    // 输入缓冲区样本数量
    int inSamples = 1024;
    // 读取文件数据的大小
    size_t len = 0;
    
    /********输出缓冲区********/
    // 指向缓冲区的指针
    uint8_t **out_data = nullptr;
    // 缓冲区大小
    int outLineSize = 0;
    // 声道数
    int outChs = av_get_channel_layout_nb_channels(outChLayout);
    // 一个样本的大小
    int outBytesPerSample = outChs * av_get_bytes_per_sample(outSampleFmt);
    /**
     inSampleRate     inSamples
     ------------- = -----------
     outSampleRate    outSamples
     
     缓冲区的样本数量(向上取整)
     outSamples = outSampleRate * inSamples / inSampleRate
     */
    // 输出缓冲区样本数量(向上取整)
    int outSamples = av_rescale_rnd(outSampleRate, inSamples, inSampleRate, AV_ROUND_UP);
    
    LOGD("输入缓冲区: %d, %d", inSampleRate, inSamples);
    LOGD("输出缓冲区: %d, %d", outSampleRate, outSamples);
    
    // 返回结果
    int ret = 0;
    // 创建采样上下文
    SwrContext *ctx = swr_alloc_set_opts(nullptr, outChLayout, outSampleFmt, outSampleRate, inChLayout, inSampleFmt, inSampleRate, 0, nullptr);
    if (!ctx) {
        LOGD("swr_alloc_set_opts error");
        goto end;
    }
    
    // 初始化重采样
    ret = swr_init(ctx);
    if (ret < 0) {
        ERROR_BUF(ret);
        LOGD("swr_init error: %s", errbuf);
        goto end;
    }
    
    // 创建输入缓冲区
    ret = av_samples_alloc_array_and_samples(&in_data,
                                             &inLineSize,
                                             inChs,
                                             inSamples,
                                             inSampleFmt,
                                             1);
    if (ret < 0) {
        ERROR_BUF(ret);
        LOGD("创建输入缓冲区 av_samples_alloc_array_and_samples error: %s", errbuf);
        goto end;
    }
    
    // 创建输出缓冲区
    ret = av_samples_alloc_array_and_samples(&out_data,
                                             &outLineSize,
                                             outChs,
                                             outSamples,
                                             outSampleFmt,
                                             1);
    if (ret < 0) {
        ERROR_BUF(ret);
        LOGD("创建输出缓冲区 av_samples_alloc_array_and_samples error: %s", errbuf);
        goto end;
    }
    
    inFile = fopen(inFilepath.c_str(), "rb");
    if (inFile == nullptr) {
        LOGD("fopen inFile error: %s", inFilepath.c_str());
        return;
    }
    
    outFile = fopen(outFilepath.c_str(), "wb+");
    if (outFile == nullptr) {
        LOGD("fopen outFile error: %s", outFilepath.c_str());
        return;
    }
    
    // 读取文件数据(inData[0] 等价 *inData)
    while ((len = fread(in_data[0], 1, inLineSize, inFile)) > 0) {
        // 读取样本数量
        inSamples = (int)len / inBytesPerSample;
        
        // 重采样(返回值为转换后的样本数量)
        ret = swr_convert(ctx, out_data, outSamples, (const uint8_t **)in_data, inSamples);
        if (ret < 0) {
            ERROR_BUF(ret);
            LOGD("swr_convert error: %s", errbuf);
            goto end;
        }
        
        // 将转换后的数据写入输出文件(packet格式)
        fwrite(out_data[0], 1, ret * outBytesPerSample, outFile);
    }
    
    // 检查输出缓冲区是否还有残留样本(已重采样过的,转换过的)
    while ((ret = swr_convert(ctx,
                              out_data, outSamples,
                              nullptr, 0)) > 0) {
        fwrite(out_data[0], 1, ret * outBytesPerSample, outFile);
    }
    
end:
    // 关闭文件
    fclose(inFile);
    fclose(outFile);
    // 释放输入缓冲区
    if (in_data) {
        av_freep(&in_data[0]);
    }
    av_freep(&in_data);
    
    // 释放输出缓冲区
    if (out_data) {
        av_freep(&out_data[0]);
    }
    av_freep(&out_data);
    // 释放重采样上下文
    swr_free(&ctx);
    
    LOGD("======正常结束======");
}
