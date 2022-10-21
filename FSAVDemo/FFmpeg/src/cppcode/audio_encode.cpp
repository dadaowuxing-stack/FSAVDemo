//
//  audio_encode.cpp
//  FSAVDemo
//
//  Created by louis on 2022/8/2.
//

#include "audio_encode.hpp"
#include "CLog.h"
#include <math.h>

#define ERROR_BUF(ret) \
char errbuf[1024]; \
av_strerror(ret, errbuf, sizeof (errbuf));

/// 选择音频编码器
/// - Parameter format: 音频格式类型
static AVCodec* select_codec(CodecFormat format) {
    AVCodec *codec = nullptr;
    
    if (format == CodecFormatAAC) {
        // codec = avcodec_find_encoder(AV_CODEC_ID_AAC); // ffmpeg 自带的 aac 编码器
        codec = avcodec_find_encoder_by_name("libfdk_aac"); // 引入的 fdk_aac 编码器
    } else if (format == CodecFormatMP3) {
        //codec = avcodec_find_encoder(AV_CODEC_ID_MP3);
        codec = avcodec_find_encoder_by_name("libmp3lame");
    } else if (format == CodecFormatAC3) {
        codec = avcodec_find_encoder(AV_CODEC_ID_AC3);
    }
    
    return codec;
}

static int check_sample_fmt(const AVCodec *codec, enum AVSampleFormat sample_fmt) {
    const enum AVSampleFormat *sample_fmts = codec->sample_fmts;
    while (*sample_fmts != AV_SAMPLE_FMT_NONE) {
        LOGD("sample_fmt_name: %s", av_get_sample_fmt_name(*sample_fmts));
        if (*sample_fmts == sample_fmt) {
            return 1;
        }
        sample_fmts++;
    }
    return 0;
}

/// 音视频编码的方法
/// @param codecCtx 编码上下文
/// @param packet 数据包
/// @param frame 编码帧
/// @param file 文件
static int encode(AVCodecContext *codecCtx, AVPacket *packet, AVFrame *frame, FILE *file) {
    // 向编码器提供原始视频或音频帧
    int ret = avcodec_send_frame(codecCtx, frame);
    if (ret < 0) {
        ERROR_BUF(ret);
        LOGD("avcodec_send_frame error: %s", errbuf);
        return ret;
    }
    
    while (true) {
        ret = avcodec_receive_packet(codecCtx, packet);
        if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) { // EAGAIN 有可能是编码器需要先缓冲一部分数据，并不是真正的编码错误
            if (ret == AVERROR_EOF) {
                LOGD("encode error %d",ret);
            }
            return 0;
        } else if (ret < 0) {   // 产生了真正的编码错误
            return ret;
        }
        if (file) {
            fwrite(packet->data, packet->size, 1, file);
        }
        // 每次编码avcodec_receive_packet都会重新为packet分配内存，所以这里用完之后要主动释放
        av_packet_unref(packet);
    }
}

/// 初始化构造函数(初始化列表:初始化顺序只跟成员变量的声明顺序有关)
/// @param srcpath 源路径
/// @param dstpath 目标路径
AudioEncode::AudioEncode(string srcpath, string dstpath) :m_srcpath(srcpath), m_dstpath(dstpath) {
    m_pCodecCtx = nullptr;
    m_pFmtCtx = nullptr;
    m_pSwrCtx = nullptr;
}

/// 析构函数
AudioEncode::~AudioEncode() {
    
}

void AudioEncode::releaseResources() {
    if (m_pFmtCtx) {
        avformat_free_context(m_pFmtCtx);
        m_pFmtCtx = nullptr;
    }
    if (m_pCodecCtx) {
        avcodec_free_context(&m_pCodecCtx);
        m_pCodecCtx = nullptr;
    }
    if (m_pSwrCtx) {
        swr_free(&m_pSwrCtx);
        m_pSwrCtx = nullptr;
    }
    
    LOGD("------encode end------");
}

void AudioEncode::doEncode(AudioEncodeSpec &in_spec, CodecFormat format, bool saveByFile) {
    if (m_srcpath.length() == 0) {
        LOGD("srcpath not found");
        return;
    }
    if (m_dstpath.length() == 0) {
        LOGD("detpath not found");
        return;
    }
    
    FILE *srcFile = nullptr;
    FILE *dstFile = nullptr;
    // 存放编码前的数据（如:pcm）
    AVFrame *srcFrame = nullptr;
    // 存放编码后的数据（如:aac）
    AVPacket *packet = nullptr;
    // 返回结果
    int ret = 0;
    
    // 三元素: 采样率,采样格式,声道布局
    // 采样率
    int src_sample_rate = in_spec.sample_rate;
    // 采样格式
    AVSampleFormat src_sample_fmt = in_spec.sample_fmt; // 文件是16位整形类型方式存储的
    // 声道布局
    uint64_t src_ch_layout = in_spec.channel_layout;
    
    LOGD("srcpath: %s dstpath: s%", m_srcpath.c_str(), m_dstpath.c_str());
    
    // 1.查找(获取)编码器
    AVCodec *pCodec = select_codec(format);
    if (!pCodec) {
        LOGD("codec not found");
        return;
    }
    
    // 1.1 检查输入数据的采样格式(libfdk_aac对输入数据的要求：采样格式必须是16位整数)
    if (!check_sample_fmt(pCodec, src_sample_fmt)) {
        LOGD("unsupported sample format: %s", av_get_sample_fmt_name(src_sample_fmt));
        return;
    }
    
    // 2.创建编码上下文(贯穿编码整个过程),这个和avcodec_open2()传入的必须是同一个编码器,不然会报错
    m_pCodecCtx = avcodec_alloc_context3(pCodec);
    if (!m_pCodecCtx) {
        LOGD("avcodec_alloc_context3 error");
        return;
    }
    
    // 3.设置PCM编码目标参数
    // 采样率
    m_pCodecCtx->sample_rate = src_sample_rate;
    // 采样格式
    m_pCodecCtx->sample_fmt = src_sample_fmt;
    // 声道布局
    m_pCodecCtx->channel_layout = src_ch_layout;
    
    // 码率(对于不同的编码器最优码率不一样，单位bit/s)
    m_pCodecCtx->bit_rate = 32000;
    // 规格
    m_pCodecCtx->profile = FF_PROFILE_AAC_HE_V2;
    
    // 4.打开编码器上下文(初始化上下文, 打开此上下文的编码器)
    ret = avcodec_open2(m_pCodecCtx, pCodec, nullptr);
    if (ret < 0) {
        ERROR_BUF(ret)
        LOGD("avcodec_open2 error: %s", errbuf);
        releaseResources();
        return;
    }
    
    LOGD("编码参数: sample_rate: %d sample_fmt: %s channels: %d frame_size: %d", m_pCodecCtx->sample_rate, av_get_sample_fmt_name(m_pCodecCtx->sample_fmt), m_pCodecCtx->channels, m_pCodecCtx->frame_size);
    
    /** AVFrame中音频存储数据的方式：
     *  1、planner方式：每个声道的数据分别存储在data[0],data[1]...中
     *  2、packet方式：顺序存储方式，每个声道的采样数据都存储在data[0]中，在内存中依次存储，以双声道为例，比如LRLRLRLR......，其中
     *  L代表左声道数据，R代表右声道数据
     *  具体的存储方式由AVFrame的format属性决定，参考AVSampleFormat枚举，带P的为planner方式，否则packet方式
     *
     *  PCM文件中音频数据的存储方式：
     *  以双声道为例，一般都是按照LRLR.....的方式存储，也就是packet方式。所以从pcm文件中读取数据到AVFrame中时，要注意存储方式是否对应。
     *  对于字节对齐方式分配内存大小的总结：类似下面av_samples_alloc_array_and_samples()函数和av_frame_get_buffer()函数的最后一个参数
     *  1、分配的内存总大小为 line_size*声道数，其中line_size >= nb_samples * 每个采样字节数(音频)；
     *  2、如果指定了align 参数，那么line_size的大小为align参数的整数倍，如果为1，则line_size=nb_samples*每个采样字节数
     *  3、当align为0时，自动根据目前cpu架构位数进行分配，但最终不一定是按照32或者64的参数进行分配
     */
    // 5.分配内存块,用于存储未压缩的音频数据
    // 存放编码前的数据(PCM)
    srcFrame = av_frame_alloc();
    if (!srcFrame) {
        LOGD("av_frame_alloc error");
        releaseResources();
        return;
    }
    
    // 每个声道的样本大小(number of audio samples (per channel))
    // frame缓冲区中的样本帧数量（由ctx->frame_size决定）
    srcFrame->nb_samples = m_pCodecCtx->frame_size;
    // 声道布局
    srcFrame->channel_layout = m_pCodecCtx->channel_layout;
    // 采样率
    srcFrame->sample_rate = m_pCodecCtx->sample_rate;
    // 采样格式
    srcFrame->format = m_pCodecCtx->sample_fmt;
    
    /** 创建输入缓冲区
     通过以上三个参数(nb_samples、format、channel_layout)即可确定一个AVFrame缓冲区的大小，即其中的音频数据的大小；
     然后通过此方法分配对应的内存块；第二个参数代表根据cpu的架构自动选择对齐位数，最好填写为0.
     */
    ret = av_frame_get_buffer(srcFrame, 0);
    if (ret < 0) {
        ERROR_BUF(ret)
        LOGD("src av_frame_get_buffer error: %s", errbuf);
        releaseResources();
        return;
    }
    
    // 让缓冲区(内存块)可写(确保帧数据可写，尽可能避免数据复制)
    ret = av_frame_make_writable(srcFrame);
    if (ret < 0) {
        ERROR_BUF(ret)
        LOGD("src av_frame_make_writable error: %s", errbuf);
        releaseResources();
        return;
    }
    
    // 分配一个packet,用于存放编码后的数据
    packet = av_packet_alloc();
    if (!packet) {
        LOGD("av_packet_alloc error");
        releaseResources();
        return;
    }
    
    // 打开文件
    srcFile = fopen(m_srcpath.c_str(), "rb");
    if (!srcFile) {
        LOGD("srcFile fopen error: %s", m_srcpath.c_str());
        releaseResources();
        return;
    }
    if (saveByFile) {
        dstFile = fopen(m_dstpath.c_str(), "wb+");
        if (!dstFile) {
            LOGD("dstFile fopen error: %s", m_dstpath.c_str());
            releaseResources();
            return;
        }
    }
    
    size_t readsize = 0;
    //int require_size = av_samples_get_buffer_size(nullptr, src_nb_channels, src_nb_samples, src_sample_format, 0);
    while ((readsize = fread(srcFrame->data[0], 1, srcFrame->linesize[0], srcFile)) > 0) {
        if (ret < srcFrame->linesize[0]) {
            // 每个样本的字节数
            int bytes = av_get_bytes_per_sample((AVSampleFormat) srcFrame->format);
            // 声道数
            int ch = av_get_channel_layout_nb_channels(srcFrame->channel_layout);
            // 设置真正有效的样本帧数量
            // 防止编码器编码了一些冗余数据
            // readsize: 读取的大小; (bytes * ch): 样本帧的大小
            srcFrame->nb_samples = int(readsize) / (bytes * ch);
        }
        if (encode(m_pCodecCtx, packet, srcFrame, dstFile) < 0) {
            goto end;
        }
    }
    
    // 刷新缓冲区
    encode(m_pCodecCtx, packet, nullptr, dstFile);

end:
    
    fclose(srcFile);
    if (dstFile) {
        fclose(dstFile);
    }
    av_packet_free(&packet);
    av_frame_free(&srcFrame);
    
    releaseResources();
}
