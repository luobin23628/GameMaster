//
//  GMMemManager.h
//  imem
//
//  Created by luobin on 14-7-15.
//
//

#import <Foundation/Foundation.h>
#import "GMMemoryAccessObject.h"

@interface GMMemManagerProxy : NSObject

+ (instancetype)shareInstance;

- (int)getPid;

- (BOOL)setPid:(int)pid;

- (BOOL)search:(int)value
       isFirst:(bool)isFirst
        result:(NSArray **)result
         count:(UInt64 *)resultCount;

- (GMMemoryAccessObject *)getMemoryAccessObject:(uint64_t)address;

- (BOOL)modifyMemory:(GMMemoryAccessObject *)result;

- (BOOL)reset;

- (BOOL)clearSearchData;

- (NSArray *)getLockedList;

- (NSArray *)getStoredList;

- (BOOL)isValid:(int)pid;

- (BOOL)removeObjects:(NSArray *)accessObjects;



- (BOOL)addAppIdentifier:(NSString *)identifier;

- (BOOL)removeAppIdentifier:(NSString *)identifier;

- (NSArray *)getAppIdentifiers;

@end
