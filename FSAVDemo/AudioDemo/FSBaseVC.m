//
//  FSBaseVC.m
//  FSAVDemo
//
//  Created by louis on 2022/6/8.
//

#import "FSBaseVC.h"

@interface FSBaseVC ()

@end

@implementation FSBaseVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.view.backgroundColor = [UIColor whiteColor];
}

@end
