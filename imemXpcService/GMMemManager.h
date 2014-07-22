//
//  GMMemManager.h
//  imem
//
//  Created by luobin on 14-7-15.
//
//

#import <Foundation/Foundation.h>

@interface GMMemManager : NSObject

@property (nonatomic, assign, readonly) UInt64 resultCount;

+ (instancetype)shareInstance;

- (BOOL)setPid:(int)pid;

- (NSArray *)search:(int64_t)value isFirst:(bool)isFirst;

- (NSDictionary *)getResult:(uint64_t)address;

- (BOOL)modifyMemory:(NSDictionary *)result;

- (BOOL)reset;

@end
