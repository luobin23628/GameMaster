//
//  GMMemManager.h
//  imem
//
//  Created by luobin on 14-7-15.
//
//

#import <Foundation/Foundation.h>

@interface GMMemManagerProxy : NSObject

+ (instancetype)shareInstance;

- (BOOL)setPid:(int)pid;

- (BOOL)search:(int)value
       isFirst:(bool)isFirst
        result:(NSArray **)result
         count:(UInt64 *)resultCount;

- (NSDictionary *)getResult:(uint64_t)address;

- (BOOL)modifyMemory:(NSDictionary *)result;

- (BOOL)reset;

@end
