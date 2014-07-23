//
//  GMMemManager.h
//  imem
//
//  Created by luobin on 14-7-15.
//
//

#import <Foundation/Foundation.h>

#define kMaxCount 1000000

@interface GMMemManager : NSObject {
    vm_address_t results[kMaxCount];
    int resultCount;
}

@property (nonatomic, assign, readonly) UInt64 resultCount;

+ (instancetype)shareInstance;

- (BOOL)setPid:(int)pid;

- (NSArray *)search:(int64_t)value isFirst:(bool)isFirst;

- (NSDictionary *)getResult:(vm_address_t)address;

- (BOOL)modifyMemory:(NSDictionary *)result;

- (BOOL)reset;

@end
