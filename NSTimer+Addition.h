//
//  NSTimer+Addition.h
//
//
//  Created by thilong on 14-1-24.
//  Copyright (c) 2014年 thilong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTimer (Addition)

- (void)pauseTimer;
- (void)resumeTimer;
- (void)resumeTimerAfterTimeInterval:(NSTimeInterval)interval;
@end
