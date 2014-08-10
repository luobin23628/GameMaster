//
//  GMMemoryValueObject.m
//  imem
//
//  Created by luobin on 14-7-28.
//
//

#import "GMMemoryAccessObject.h"

#define kResultKeyAddress   @"ResultKeyAddress"
#define kResultKeyValue     @"ResultKeyValue"
#define kResultKeyOptType   @"ResultKeyOptType"
#define kResultKeyValueType   @"ResultKeyValueType"

@implementation GMMemoryAccessObject

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInt64:self.address forKey:kResultKeyAddress];
    [aCoder encodeInt64:self.value forKey:kResultKeyValue];
    [aCoder encodeInt:self.optType forKey:kResultKeyOptType];
    [aCoder encodeInt:self.valueType forKey:kResultKeyValueType];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.address = [aDecoder decodeInt64ForKey:kResultKeyAddress];
        self.value = [aDecoder decodeInt64ForKey:kResultKeyValue];
        self.optType = [aDecoder decodeIntForKey:kResultKeyOptType];
        self.valueType = [aDecoder decodeIntForKey:kResultKeyValueType];
    }
    return self;
}

//- (id)initWithDictionry:(NSDictionary *)dictionary {
//    self = [super init];
//    if (self) {
//        self.address = [[dictionary objectForKey:kResultKeyAddress] unsignedLongLongValue];
//        self.value = [[dictionary objectForKey:kResultKeyValue] unsignedLongLongValue];
//        self.optType = [[dictionary objectForKey:kResultKeyOptType] intValue];
//    }
//    return self;
//}
//
- (NSDictionary *)toDictionnary {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:@(self.address) forKey:kResultKeyAddress];
    [dictionary setObject:@(self.value) forKey:kResultKeyValue];
    [dictionary setObject:@(self.optType) forKey:kResultKeyOptType];
    return dictionary;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", [self toDictionnary]];
}

@end
