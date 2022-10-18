//
//  FSAVDecoder.h
//  FSAVDemo
//
//  Created by louis on 2022/10/12.
//

#import <Foundation/Foundation.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libswresample/swresample.h>
#include <libavutil/pixdesc.h>
#include <libavcodec/avcodec.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FSFrameType) {
    FSFrameTypeAudio,
    FSFrameTypeVideo,
};

/// 数据统计(埋点)
@interface FSStatistics : NSObject

@property (nonatomic, assign) long long beginOpen;                 // 开始试图去打开一个直播流的绝对时间
@property (nonatomic, assign) float successOpen;                   // 成功打开流花费时间
@property (nonatomic, assign) float firstScreenTimeMills;          // 首屏时间
@property (nonatomic, assign) float failOpen;                      // 流打开失败花费时间
@property (nonatomic, assign) float failOpenType;                  // 流打开失败类型
@property (nonatomic, assign) int retryTimes;                      // 打开流重试次数
@property (nonatomic, assign) float duration;                      // 拉流时长
@property (nonatomic, strong) NSMutableArray* bufferStatusRecords; // 拉流状态

@end

@interface FSFrame : NSObject

@property (nonatomic, assign) FSFrameType type; // 帧类型
@property (nonatomic, assign) CGFloat position;
@property (nonatomic, assign) CGFloat duration; // 时间戳

@end

/// 音频帧，这个结构体中记录了一段 PCM Buffer 以及这一帧的时间戳等信息
@interface FSAudioFrame : FSFrame

@property (nonatomic, strong) NSData *samples;

@end

/// 视频帧，这个结构体中记录了 YUV 数据以及这一帧数据的宽、高以及时间戳等信息.
@interface FSVideoFrame : FSFrame

@property (nonatomic, assign) NSUInteger width;
@property (nonatomic, assign) NSUInteger height;
@property (nonatomic, assign) NSUInteger linesize;
@property (nonatomic, strong) NSData *luma;
@property (nonatomic, strong) NSData *chromaB;
@property (nonatomic, strong) NSData *chromaR;
@property (nonatomic, strong) id imageBuffer;

@end

#ifndef SUBSCRIBE_VIDEO_DATA_TIME_OUT
#define SUBSCRIBE_VIDEO_DATA_TIME_OUT               20
#endif
#ifndef NET_WORK_STREAM_RETRY_TIME
#define NET_WORK_STREAM_RETRY_TIME                  3
#endif
#ifndef RTMP_TCURL_KEY
#define RTMP_TCURL_KEY                              @"RTMP_TCURL_KEY"
#endif

#ifndef FPS_PROBE_SIZE_CONFIGURED
#define FPS_PROBE_SIZE_CONFIGURED                   @"FPS_PROBE_SIZE_CONFIGURED"
#endif
#ifndef PROBE_SIZE
#define PROBE_SIZE                                  @"PROBE_SIZE"
#endif
#ifndef MAX_ANALYZE_DURATION_ARRAY
#define MAX_ANALYZE_DURATION_ARRAY                  @"MAX_ANALYZE_DURATION_ARRAY"
#endif

@interface FSAVDecoder : NSObject {
    AVFormatContext *_formatCtx;
    BOOL            _isOpenInputSuccess;
    
    FSStatistics    *_statistics;
    
    int             totalVideoFramecount;
    long long       decodeVideoFrameWasteTimeMills;
    
    NSArray         *_videoStreams;
    NSArray         *_audioStreams;
    NSInteger       _videoStreamIndex;
    NSInteger       _audioStreamIndex;
    AVCodecContext  *_videoCodecCtx;
    AVCodecContext  *_audioCodecCtx;
    CGFloat         _videoTimeBase;
    CGFloat         _audioTimeBase;
}

- (BOOL)openFile:(NSString *)path
       parameter:(NSDictionary*)parameters
           error:(NSError **)error;

- (NSArray *)decodeFrames:(CGFloat)minDuration
    decodeVideoErrorState:(int *)decodeVideoErrorState;

/** 子类重写这两个方法 **/
- (BOOL)openVideoStream;
- (void)closeVideoStream;

- (FSVideoFrame *)decodeVideo:(AVPacket)packet
                  packetSize:(int) pktSize
       decodeVideoErrorState:(int *)decodeVideoErrorState;
    
- (void)closeFile;

- (void)interrupt;

- (BOOL)isOpenInputSuccess;

- (void)triggerFirstScreen;
- (void)addBufferStatusRecord:(NSString*) statusFlag;

- (FSStatistics *)getStatistics;

- (BOOL)detectInterrupted;
- (BOOL)isEOF;
- (BOOL)isSubscribed;
- (NSUInteger)frameWidth;
- (NSUInteger)frameHeight;
- (CGFloat)sampleRate;
- (NSUInteger)channels;
- (BOOL)validVideo;
- (BOOL)validAudio;
- (CGFloat)getVideoFPS;
- (CGFloat)getDuration;

@end

NS_ASSUME_NONNULL_END
