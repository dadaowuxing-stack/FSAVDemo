//
//  main.m
//  FSAVDemo
//
//  Created by louis on 2022/5/27.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#include <libavdevice/avdevice.h>

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
