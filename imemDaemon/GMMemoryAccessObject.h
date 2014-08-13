//
//  GMMemoryValueObject.h
//  imem
//
//  Created by luobin on 14-7-28.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef enum _GMOptType {
    GMOptTypeEdit = 0,
    GMOptTypeEditAndSave = 1,
    GMOptTypeEditAndLock = 2
} GMOptType;

typedef enum _GMValueType {
    GMValueTypeIntAuto = 0,
    GMValueTypeInt16 = 1,
    GMValueTypeInt32 = 2,
    GMValueTypeInt64 = 3,
    GMValueTypeFloat = 4
} GMValueType;

@interface GMMemoryAccessObject : NSObject<NSCoding>

@property (nonatomic, assign) uint64_t address;
@property (nonatomic, assign) uint64_t value;
@property (nonatomic, assign) GMValueType valueType;
@property (nonatomic, assign) GMOptType optType;

@end
