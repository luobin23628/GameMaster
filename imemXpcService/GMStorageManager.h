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

- (void)addObject:(GMMemoryAccessObject *)accessObject;

- (void)removeObject:(GMMemoryAccessObject *)accessObject;

- (void)removeObjects:(NSArray *)accessObjects;

- (void)removeAllLock;

- (NSArray *)getAllObjects;

- (NSArray *)getStoredObjects;

- (NSArray *)getLockedObjects;

@end
