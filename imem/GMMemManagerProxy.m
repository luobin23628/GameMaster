//
//  GMMemManager.m
//  imem
//
//  Created by luobin on 14-7-15.
//
//

#import "GMMemManagerProxy.h"
#import "GMMem.h"

@interface GMMemManagerProxy()

@end

@implementation GMMemManagerProxy

+ (instancetype)shareInstance {
    static GMMemManagerProxy *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[GMMemManagerProxy alloc] init];
    });
    return sharedManager;
}

- (BOOL)setPid:(int)pid {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    LMResponseBuffer responseBuffer;
    LMConnectionSendTwoWay(&connection, GMMessageIdSetPid, &pid, sizeof(pid), &responseBuffer);
    int32_t ret = LMResponseConsumeInteger(&responseBuffer);
    return ret == 1;
#endif
}

- (BOOL)search:(int)value isFirst:(bool)isFirst result:(NSArray **)result count:(UInt64 *)count {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    LMResponseBuffer buffer;
    NSMutableData *data = [NSMutableData data];
    [data appendBytes:&value length:sizeof(value)];
    [data appendBytes:&isFirst length:sizeof(isFirst)];
    LMConnectionSendTwoWayData(&connection, GMMessageIdSearch, (CFDataRef)data, &buffer);
    
    uint32_t length = LMMessageGetDataLength(&buffer.message);
	if (length) {
        void *bytes = LMMessageGetData(&buffer.message);
        if (count) {
            *count = *((UInt64 *)bytes);
        }
        if (result) {
            NSData *data = [NSData dataWithBytesNoCopy:bytes + sizeof(UInt64) length:length - sizeof(UInt64) freeWhenDone:NO];
            *result = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:0 format:NULL errorDescription:NULL];
        }
        LMResponseBufferFree(&buffer);
        return YES;
	} else {
        LMResponseBufferFree(&buffer);
        return NO;
	}
#endif
}

- (NSDictionary *)getResult:(uint64_t)address {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    LMResponseBuffer responseBuffer;
    LMConnectionSendTwoWay(&connection, GMMessageIdGetResult, &address, sizeof(address), &responseBuffer);
    NSDictionary *result = LMResponseConsumePropertyList(&responseBuffer);
    return result;
#endif
}

- (BOOL)modifyMemory:(NSDictionary *)result {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    LMResponseBuffer responseBuffer;
    LMConnectionSendTwoWayPropertyList(&connection, GMMessageIdModify, result, &responseBuffer);
    int32_t ret = LMResponseConsumeInteger(&responseBuffer);
    return ret == 1;
#endif
}

- (BOOL)reset {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    LMResponseBuffer responseBuffer;
    LMConnectionSendTwoWay(&connection, GMMessageIdReset, NULL, 0, &responseBuffer);
    int32_t ret = LMResponseConsumeInteger(&responseBuffer);
    return ret == 1;
#endif
}

- (void)dealloc {

    [super dealloc];
}

@end
