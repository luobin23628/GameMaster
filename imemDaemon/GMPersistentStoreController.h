//
//  GMPersistentController.h
//  imem
//
//  Created by LuoBin on 14-8-13.
//
//

#import <Foundation/Foundation.h>

@interface GMPersistentStoreController : NSObject

+ (instancetype)shareInstance;

- (void)insertObject:(uint64_t)address;

- (BOOL)save:(NSError **)error;

- (NSArray *)fetchObjectWithOffset:(int)offset size:(int)size;

@end
