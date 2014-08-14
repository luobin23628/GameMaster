//
//  GMPersistentController.h
//  imem
//
//  Created by LuoBin on 14-8-13.
//
//

#import <Foundation/Foundation.h>

@protocol Adderss <NSObject>

@property (nonatomic, readonly) uint64_t address;

@end

@interface GMPersistentStoreController : NSObject

+ (instancetype)shareInstance;

- (void)insertObject:(uint64_t)address;

- (void)deleteObject:(id<Adderss>)address;

- (BOOL)save:(NSError **)error;

- (void)truncateAll;

- (NSArray *)fetchObjectWithOffset:(int)offset size:(int)size;

@end
