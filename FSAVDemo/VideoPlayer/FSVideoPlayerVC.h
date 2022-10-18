//
//  FSVideoPlayerVC.h
//  FSAVDemo
//
//  Created by louis on 2022/10/12.
//

#import <UIKit/UIKit.h>
#import "FSAudioOutput.h"
#import "FSVideoOutput.h"
#import "FSAVSynchronizer.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSVideoPlayerVC : UIViewController

+ (instancetype)viewControllerWithContentPath:(NSString *)path
                            contentFrame:(CGRect)frame
                            playerStateDelegate:(id) playerStateDelegate
                            parameters:(NSDictionary *)parameters;

+ (instancetype)viewControllerWithContentPath:(NSString *)path
                                 contentFrame:(CGRect)frame
                          playerStateDelegate:(id<FSPlayerStateDelegate>)playerStateDelegate
                                   parameters:(NSDictionary *)parameters
                  outputEAGLContextShareGroup:(EAGLSharegroup *)sharegroup;

- (instancetype)initWithContentPath:(NSString *)path
              contentFrame:(CGRect)frame
       playerStateDelegate:(id)playerStateDelegate
                parameters:(NSDictionary *)parameters;

- (instancetype)initWithContentPath:(NSString *)path
                        contentFrame:(CGRect)frame
                 playerStateDelegate:(id) playerStateDelegate
                          parameters:(NSDictionary *)parameters
         outputEAGLContextShareGroup:(EAGLSharegroup *)sharegroup;

- (void)play;

- (void)pause;

- (void)stop;

- (void)restart;

- (BOOL)isPlaying;

- (FSVideoOutput*)createVideoOutputInstance;
- (FSVideoOutput*)getVideoOutputInstance;

@end

NS_ASSUME_NONNULL_END
