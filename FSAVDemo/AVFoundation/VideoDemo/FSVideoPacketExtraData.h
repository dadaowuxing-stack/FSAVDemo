//
//  FSVideoPacketExtraData.h
//  FSAVDemo
//
//  Created by louis on 2022/7/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FSVideoPacketExtraData : NSObject

@property (nonatomic, strong) NSData *sps;
@property (nonatomic, strong) NSData *pps;
@property (nonatomic, strong) NSData *vps;

@end

NS_ASSUME_NONNULL_END
