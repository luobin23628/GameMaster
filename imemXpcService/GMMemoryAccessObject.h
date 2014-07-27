//
//  GMMemoryValueObject.h
//  imem
//
//  Created by luobin on 14-7-28.
//
//

#import <Foundation/Foundation.h>

typedef enum _GMOptType {
    GMOptTypeEdit = 0,
    GMOptTypeEditAndSave = 1,
    GMOptTypeEditAndLock = 2
} GMOptType;


@interface GMMemoryAccessObject : NSObject<NSCoding>

- (id)initWithDictionry:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionnary;

@property (nonatomic, assign) uint64_t address;
@property (nonatomic, assign) uint64_t value;
@property (nonatomic, assign) GMOptType optType;

@end
