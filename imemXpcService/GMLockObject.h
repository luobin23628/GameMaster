//
//  GMLockObject.h
//  imem
//
//  Created by luobin on 14-7-27.
//
//

#import <Foundation/Foundation.h>

@interface GMLockObject : NSObject

@property (nonatomic, assign) uint64_t address;
@property (nonatomic, retain) NSData *data;
@property (nonatomic, assign) uint64_t value;

- (id)initWithMemoryAccessObject:(GMMemoryAccessObject *)memoryAccessObject;

- (NSDictionary *)toDictionnary;

@end
