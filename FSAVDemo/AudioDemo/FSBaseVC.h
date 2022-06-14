//
//  FSBaseVC.h
//  FSAVDemo
//
//  Created by louis on 2022/6/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FSMediaOpType) {
    FSMediaOpTypeAudioCapture = 0,
    FSMediaOpTypeAudioEncoder,
    FSMediaOpTypeAudioMuxer,
    FSMediaOpTypeAudioDemuxer,
    FSMediaOpTypeAudioDecoder,
    
    FSMediaOpTypeVideoCapture,
    FSMediaOpTypeVideoEncoder,
    FSMediaOpTypeVideoMuxer,
    FSMediaOpTypeVideoDemuxer,
    FSMediaOpTypeVideoDecoder,
};

@interface FSBaseVC : UIViewController

@property (nonatomic, assign) FSMediaOpType opType;

@end

NS_ASSUME_NONNULL_END
