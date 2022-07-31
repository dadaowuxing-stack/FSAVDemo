//
//  FSBaseVC.h
//  FSAVDemo
//
//  Created by louis on 2022/6/8.
//

#import <UIKit/UIKit.h>
#import "FSMediaBase.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSBaseVC : UIViewController

@property (nonatomic, copy) void (^audioHandleCallBack)(FSMediaOpType type); // 音频操作回调

@property (nonatomic, assign) FSMediaOpType opType;

@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) UIButton *audioButton;
@property (nonatomic, assign) BOOL isRecording;

@property (nonatomic, copy) NSString *startTitle;
@property (nonatomic, copy) NSString *stopTitle;

@property (nonatomic, copy) NSString *path;

- (void)buttonAction:(UIButton *)sender;

@end

NS_ASSUME_NONNULL_END
