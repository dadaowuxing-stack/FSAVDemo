//
//  FSVideoPlayDemoVC.h
//  FSAVDemo
//
//  Created by louis on 2022/10/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FSVideoPlayDemoVC : UIViewController

+ (id)viewControllerWithContentPath:(NSString *)path
                       contentFrame:(CGRect)frame
                       parameters: (NSDictionary *)parameters;

@end

NS_ASSUME_NONNULL_END
