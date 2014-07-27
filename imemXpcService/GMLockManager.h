//
//  GMLockManager.h
//  imem
//
//  Created by luobin on 14-7-27.
//
//

#import <Foundation/Foundation.h>
#import "GMLockObject.h"

@interface GMLockManager : NSObject

+ (instancetype)shareInstance;

- (void)addLockObject:(GMMemoryAccessObject *)lockObject;

- (NSArray *)lockObjects;


@end
