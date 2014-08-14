//
//  GMLockThread.m
//  imem
//
//  Created by luobin on 14-7-27.
//
//

#import "GMLockThread.h"
#import "GMStorageManager.h"
#import "GMMemManager.h"
#import "GMMemoryAccessObject.h"
#import <libkern/OSAtomic.h>

static OSSpinLock spinLock;

@interface GMLockThread ()

@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, assign) BOOL isSuspend;

@end

@implementation GMLockThread

- (id)init {
    self = [super init];
    if (self) {
        self.isSuspend = YES;
    }
    return self;
}

- (void)main {
    CFRunLoopRun();
}

- (void)suspend {
    OSSpinLockLock(&spinLock);
    if (!self.isSuspend) {
        NSLog(@"Lock Thread suspend.");
        self.isSuspend = YES;
        CFRunLoopRemoveTimer(CFRunLoopGetCurrent(), (CFRunLoopTimerRef)self.timer, kCFRunLoopDefaultMode);
        [self.timer invalidate];
        self.timer = nil;
    }
    OSSpinLockUnlock(&spinLock);
}

- (void)resume {
    OSSpinLockLock(&spinLock);
    if (self.isSuspend) {
        NSLog(@"Lock Thread resume.");
        self.isSuspend = NO;
        self.timer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(timerDidFire) userInfo:nil repeats:YES];
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), (CFRunLoopTimerRef)self.timer, kCFRunLoopDefaultMode);
    }
    OSSpinLockUnlock(&spinLock);
}

- (void)timerDidFire {
    @autoreleasepool {
        if ([[GMMemManager shareInstance] isValid]) {
            NSArray *lockObjects = [[GMStorageManager shareInstance] getLockedObjects];
            for (GMMemoryAccessObject *lockObject in lockObjects) {
                BOOL ok = YES;
                ok = [[GMMemManager shareInstance] modifyMemory:lockObject];
                if (!ok) {
                    NSLog(@"Lock object %@ failed.", lockObject);
                }
            }
        }
    }
}

@end
