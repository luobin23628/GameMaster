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
@property (nonatomic, assign) GMLockThread *lockThread;

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

- (void)addLockObject:(GMLockObject *)lockObject {
    OSSpinLockLock(&spinLock);
    [self.lockObjectList addObject:lockObject];
    OSSpinLockUnlock(&spinLock);
}

- (NSArray *)lockObjects {
    return self.lockObjectList;
}

@end
