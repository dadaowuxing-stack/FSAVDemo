//
//  FSMediaBase.h
//  FSAVDemo
//
//  Created by louis on 2022/6/15.
//

#ifndef FSMediaBase_h
#define FSMediaBase_h

typedef NS_ENUM(NSInteger, FSMediaType) {
    FSMediaNone = 0,
    FSMediaAudio = 1 << 0,                   // 仅音频.
    FSMediaVideo = 1 << 1,                   // 仅视频.
    FSMediaAV = FSMediaAudio | FSMediaVideo, // 音视频都有.
};

// 封装器的状态机.
typedef NS_ENUM(NSInteger, FSMP4MuxerStatus) {
    FSMP4MuxerStatusUnknown = 0,
    FSMP4MuxerStatusRunning = 1,
    FSMP4MuxerStatusFailed = 2,
    FSMP4MuxerStatusCompleted = 3,
    FSMP4MuxerStatusCancelled = 4,
};

// 解封装器的状态机.
typedef NS_ENUM(NSInteger, FSMP4DemuxerStatus) {
    FSMP4DemuxerStatusUnknown = 0,
    FSMP4DemuxerStatusRunning = 1,
    FSMP4DemuxerStatusFailed = 2,
    FSMP4DemuxerStatusCompleted = 3,
    FSMP4DemuxerStatusCancelled = 4,
};

typedef NS_ENUM(NSInteger, FSVideoCaptureMirrorType) {
    FSVideoCaptureMirrorNone = 0,
    FSVideoCaptureMirrorFront = 1 << 0,
    FSVideoCaptureMirrorBack = 1 << 1,
    FSVideoCaptureMirrorAll = (FSVideoCaptureMirrorFront | FSVideoCaptureMirrorBack),
};

// 渲染画面填充模式。
typedef NS_ENUM(NSInteger, FSMetalViewContentMode) {
    // 自动填充满，可能会变形。
    FSMetalViewContentModeStretch = 0,
    // 按比例适配，可能会有黑边。
    FSMetalViewContentModeFit = 1,
    // 根据比例裁剪后填充满。
    FSMetalViewContentModeFill = 2
};

// 操作
typedef NS_ENUM(NSInteger, FSMediaOpType) {
    FSMediaOpTypeAudioCapture = 0,
    FSMediaOpTypeAudioEncoder,
    FSMediaOpTypeAudioMuxer,
    FSMediaOpTypeAudioDemuxer,
    FSMediaOpTypeAudioDecoder,
    FSMediaOpTypeAudioRender,
    
    FSMediaOpTypeVideoCapture,
    FSMediaOpTypeVideoEncoder,
    FSMediaOpTypeVideoMuxer,
    FSMediaOpTypeVideoDemuxer,
    FSMediaOpTypeVideoDecoder,
    FSMediaOpTypeVideoRender,
};

#endif /* FSMediaBase_h */
