//
//  GMMemManager.m
//  imem
//
//  Created by luobin on 14-7-15.
//
//

#import "GMMemManagerProxy.h"

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
    kern_return_t ret = LMConnectionSendTwoWay(&connection, GMMessageIdSetPid, &pid, sizeof(pid), &responseBuffer);
    if (ret == KERN_SUCCESS) {
        BOOL ok = LMResponseConsumeInteger(&responseBuffer);
        return ok;
    } else {
        return NO;
    }
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
    kern_return_t kert = LMConnectionSendTwoWayData(&connection, GMMessageIdSearch, (CFDataRef)data, &buffer);
    
    uint32_t length = LMMessageGetDataLength(&buffer.message);
	if (length && kert == KERN_SUCCESS) {
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

- (GMMemoryAccessObject *)getMemoryAccessObject:(uint64_t)address {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    LMResponseBuffer responseBuffer;
    kern_return_t ret = LMConnectionSendTwoWay(&connection, GMMessageIdGetMemoryAccessObject, &address, sizeof(address), &responseBuffer);
    if (ret == KERN_SUCCESS) {
        return (GMMemoryAccessObject *)LMResponseConsumeArchiverObject(&responseBuffer);
    } else {
        return nil;
    }
#endif
}

- (BOOL)modifyMemory:(GMMemoryAccessObject *)accessObject {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    LMResponseBuffer responseBuffer;
    kern_return_t ret = LMConnectionSendTwoWayArchiverObject(&connection, GMMessageIdModify, accessObject, &responseBuffer);
    if (ret == KERN_SUCCESS) {
        BOOL ok = LMResponseConsumeInteger(&responseBuffer);
        return ok;
    } else {
        return NO;
    }
#endif
}

- (BOOL)reset {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    LMResponseBuffer responseBuffer;
    kern_return_t ret = LMConnectionSendTwoWay(&connection, GMMessageIdReset, NULL, 0, &responseBuffer);
    if (ret == KERN_SUCCESS) {
        BOOL ok = LMResponseConsumeInteger(&responseBuffer);
        return ok;
    } else {
        return NO;
    }
#endif
}

- (BOOL)isValid:(int)pid {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    LMResponseBuffer responseBuffer;
    kern_return_t ret = LMConnectionSendTwoWay(&connection, GMMessageIdCheckValid, &pid, sizeof(pid), &responseBuffer);
    if (ret == KERN_SUCCESS) {
        BOOL ok = LMResponseConsumeInteger(&responseBuffer);
        return ok;
    } else {
        return NO;
    }
#endif
}

- (NSArray *)getLockedList {
#if TARGET_IPHONE_SIMULATOR
    return nil;
#else
    LMResponseBuffer responseBuffer;
    kern_return_t ret = LMConnectionSendTwoWay(&connection, GMMessageIdGetLockedList, NULL, 0, &responseBuffer);
    if (ret == KERN_SUCCESS) {
        return (NSArray *)LMResponseConsumeArchiverObject(&responseBuffer);
    } else {
        return nil;
    }
#endif
}

- (NSArray *)getStoredList {
#if TARGET_IPHONE_SIMULATOR
    return nil;
#else
    LMResponseBuffer responseBuffer;
    kern_return_t ret = LMConnectionSendTwoWay(&connection, GMMessageIdGetStoredList, NULL, 0, &responseBuffer);
    if (ret == KERN_SUCCESS) {
        return (NSArray *)LMResponseConsumeArchiverObject(&responseBuffer);
    } else {
        return nil;
    }
#endif
}

- (void)dealloc {

    [super dealloc];
}

@end
