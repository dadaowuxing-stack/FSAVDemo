//
//  FSWeakProxy.h
//  FSAVDemo
//
//  Created by louis on 2022/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FSWeakProxy : NSProxy

- (instancetype)initWithTarget:(id)target;
+ (instancetype)proxyWithTarget:(id)target;
@property (nonatomic, weak, readonly) id target;

@end

NS_ASSUME_NONNULL_END
