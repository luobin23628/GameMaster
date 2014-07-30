//
//  GMLockManager.h
//  imem
//
//  Created by luobin on 14-7-27.
//
//

#import <Foundation/Foundation.h>

@interface GMStorageManager : NSObject

+ (instancetype)shareInstance;

- (void)addObject:(GMMemoryAccessObject *)lockObject;

- (NSArray *)getAllObjects;

- (NSArray *)getStoredObjects;

- (NSArray *)getLockedObjects;

- (void)cancelAllLock;

@end
