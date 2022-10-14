//
//  FSAVSynchronizer.m
//  FSAVDemo
//
//  Created by louis on 2022/10/12.
//

#import "FSAVSynchronizer.h"

@interface FSAVSynchronizer ()

@property (nonatomic, weak) id<FSPlayerStateDelegate> playerStateDelegate;

@end

@implementation FSAVSynchronizer

- (id)initWithPlayerStateDelegate:(id<FSPlayerStateDelegate>)playerStateDelegate {
    self = [super init];
    if (self) {
        _playerStateDelegate = playerStateDelegate;
    }
    return self;
}

- (FSOpenState)openFile:(NSString *)path
            parameters:(NSDictionary*)parameters
                  error:(NSError **)error {
    
    return OPEN_SUCCESS;
}

@end
