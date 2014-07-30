//
//  GMLockManager.m
//  imem
//
//  Created by luobin on 14-7-27.
//
//

#import "GMStorageManager.h"
#import <libkern/OSAtomic.h>
#import "GMLockThread.h"

static OSSpinLock spinLock;

@interface GMStorageManager()

@property (nonatomic, retain) NSMutableArray *objectList;
@property (nonatomic, retain) GMLockThread *lockThread;

@end

@implementation GMStorageManager

+ (instancetype)shareInstance {
    @synchronized(self){
        static GMStorageManager *sharedManager = nil;
        if (!sharedManager) {
            sharedManager = [[GMStorageManager alloc] init];
        }
        return sharedManager;
    }
}

- (id)init {
    self = [super init];
    if (self) {
        self.objectList = [NSMutableArray array];
        self.lockThread = [[[GMLockThread alloc] init] autorelease];
        [self.lockThread start];
    }
    return self;
}

- (void)dealloc {
    self.objectList = nil;
    [super dealloc];
}

- (void)addObject:(GMMemoryAccessObject *)lockObject {
    OSSpinLockLock(&spinLock);
    NSUInteger index = [self.objectList indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[GMMemoryAccessObject class]]) {
            GMMemoryAccessObject *accessObject = (GMMemoryAccessObject *)obj;
            if (accessObject.address == lockObject.address) {
                *stop = YES;
                return YES;
            }
        }
        *stop = NO;
        return NO;
    }];
    if (index != NSNotFound) {
        [self.objectList removeObjectAtIndex:index];
    }
    [self.objectList addObject:lockObject];
    OSSpinLockUnlock(&spinLock);
    if (lockObject.optType == GMOptTypeEditAndLock) {
        [self.lockThread resume];
    }
}

- (NSArray *)getAllObjects {
    return self.objectList;
}

- (NSArray *)getStoredObjects {
    OSSpinLockLock(&spinLock);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"optType = %d", GMOptTypeEditAndSave];
    NSArray *ret = [self.objectList filteredArrayUsingPredicate:predicate];
    OSSpinLockUnlock(&spinLock);
    return ret;
}

- (NSArray *)getLockedObjects {
    OSSpinLockLock(&spinLock);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"optType = %d", GMOptTypeEditAndLock];
    NSArray *ret = [self.objectList filteredArrayUsingPredicate:predicate];
    OSSpinLockUnlock(&spinLock);
    return ret;
}

- (void)cancelAllLock {
    OSSpinLockLock(&spinLock);
    [self.objectList removeAllObjects];
    OSSpinLockUnlock(&spinLock);
    [self.lockThread suspend];
}

@end
