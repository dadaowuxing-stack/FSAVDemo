//
//  FSAVSynchronizer.h
//  FSAVDemo
//
//  Created by louis on 2022/10/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FSOpenState) {
    OPEN_SUCCESS,
    OPEN_FAILED,
    CLIENT_CANCEL,
};

@protocol FSPlayerStateDelegate <NSObject>

@end

@interface FSAVSynchronizer : NSObject

- (id)initWithPlayerStateDelegate:(id<FSPlayerStateDelegate>)playerStateDelegate;

- (FSOpenState)openFile:(NSString *)path
            parameters:(NSDictionary*)parameters
                  error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
