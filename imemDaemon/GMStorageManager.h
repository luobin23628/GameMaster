//
//  GMLockManager.h
//  imem
//
//  Created by luobin on 14-7-27.
//
//

#import <Foundation/Foundation.h>
#import "GMMemoryAccessObject.h"

@interface GMStorageManager : NSObject

+ (instancetype)shareInstance;

@property (nonatomic, assign) int pid;

- (void)addObject:(GMMemoryAccessObject *)accessObject;

- (void)removeObject:(GMMemoryAccessObject *)accessObject;

- (void)removeObjects:(NSArray *)accessObjects;

- (void)removeAllLock;

- (NSArray *)getAllObjects;

- (NSArray *)getStoredObjects;

- (NSArray *)getLockedObjects;

@end
