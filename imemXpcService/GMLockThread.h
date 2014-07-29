//
//  GMLockThread.h
//  imem
//
//  Created by luobin on 14-7-27.
//
//

#import <Foundation/Foundation.h>

@interface GMLockThread : NSThread

- (void)suspend;

- (void)resume;

@end
