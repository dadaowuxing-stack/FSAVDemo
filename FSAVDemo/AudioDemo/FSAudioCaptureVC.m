//
//  FSAudioCaptureVC.m
//  FSAVDemo
//
//  Created by fengshuo liu on 2022/5/27.
//

#import "FSAudioCaptureVC.h"

@interface FSAudioCaptureVC ()

@end

@implementation FSAudioCaptureVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.title = @"Audio Capture";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self _setupUI];
}

- (void)_setupUI {
    
}

@end
