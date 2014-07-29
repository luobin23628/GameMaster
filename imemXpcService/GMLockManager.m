//
//  GMLockManager.m
//  imem
//
//  Created by luobin on 14-7-27.
//
//

#import "GMLockManager.h"
#import <libkern/OSAtomic.h>
#import "GMLockThread.h"

static OSSpinLock spinLock;

@interface GMLockManager()

@property (nonatomic, retain) NSMutableArray *lockObjectList;
@property (nonatomic, retain) GMLockThread *lockThread;

@end

@implementation GMLockManager

+ (instancetype)shareInstance {
    @synchronized(self){
        static GMLockManager *sharedManager = nil;
        if (!sharedManager) {
            sharedManager = [[GMLockManager alloc] init];
        }
        return sharedManager;
    }
}

- (id)init {
    self = [super init];
    if (self) {
        self.lockObjectList = [NSMutableArray array];
        self.lockThread = [[[GMLockThread alloc] init] autorelease];
        [self.lockThread start];
    }
    return self;
}

- (void)dealloc {
    self.lockObjectList = nil;
    [super dealloc];
}

- (void)addLockObject:(GMMemoryAccessObject *)lockObject {
    OSSpinLockLock(&spinLock);
    NSUInteger index = [self.lockObjectList indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
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
        [self.lockObjectList removeObjectAtIndex:index];
    }
    [self.lockObjectList addObject:lockObject];
    OSSpinLockUnlock(&spinLock);
    [self.lockThread resume];
}

- (NSArray *)lockObjects {
    return self.lockObjectList;
}

- (void)cancelAllLock {
    OSSpinLockLock(&spinLock);
    [self.lockObjectList removeAllObjects];
    OSSpinLockUnlock(&spinLock);
    [self.lockThread suspend];
}

@end
