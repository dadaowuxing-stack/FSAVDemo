//
//  FSAVSynchronizer.h
//  FSAVDemo
//
//  Created by louis on 2022/10/12.
//

#import <Foundation/Foundation.h>
#import "FSAVDecoder.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FSOpenState) {
    OPEN_SUCCESS,
    OPEN_FAILED,
    CLIENT_CANCEL,
};

#define TIMEOUT_DECODE_ERROR            20
#define TIMEOUT_BUFFER                  10

extern NSString * const kMIN_BUFFERED_DURATION;
extern NSString * const kMAX_BUFFERED_DURATION;

@protocol FSPlayerStateDelegate <NSObject>

@optional;

- (void)openSucceed;

- (void)connectFailed;

- (void)hideLoading;

- (void)showLoading;

- (void)onCompletion;

- (void)statisticsCallback:(FSStatistics*)statistics;

- (void)restart;

@end

@interface FSAVSynchronizer : NSObject

- (id)initWithPlayerStateDelegate:(id<FSPlayerStateDelegate>)playerStateDelegate;

- (FSOpenState)openFile:(NSString *)path
            parameters:(NSDictionary*)parameters
                  error:(NSError **)error;

- (FSOpenState)openFile:(NSString *)path
                  error:(NSError **)error;

- (void)closeFile;


- (void)audioCallbackFillData:(SInt16 *)outData
                     numFrames:(UInt32)numFrames
                   numChannels:(UInt32)numChannels;

- (FSVideoFrame*) getCorrectVideoFrame;

- (void)run;
- (BOOL)isOpenInputSuccess;
- (void)interrupt;

- (BOOL)isPlayCompleted;

- (NSInteger)getAudioSampleRate;
- (NSInteger)getAudioChannels;
- (CGFloat)getVideoFPS;
- (NSInteger)getVideoFrameHeight;
- (NSInteger)getVideoFrameWidth;
- (BOOL)isValid;
- (CGFloat)getDuration;

@end

NS_ASSUME_NONNULL_END
