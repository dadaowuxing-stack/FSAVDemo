//
//  BridgeFFmpeg.h
//  FSAVDemo
//
//  Created by louis on 2022/8/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BridgeFFmpeg : NSObject

+(void)doEncodePCM2AAC:(NSString*)src dst:(NSString*)dst;

@end

NS_ASSUME_NONNULL_END
