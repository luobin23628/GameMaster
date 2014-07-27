//
//  GMLockThread.m
//  imem
//
//  Created by luobin on 14-7-27.
//
//

#import "GMLockThread.h"
#import "GMLockManager.h"
#import "GMMemManager.h"

@interface GMLockThread ()

@property (nonatomic, retain) NSTimer *timer;

@end

@implementation GMLockThread

- (id)init {
    self = [super init];
    if (self) {
        self.timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(invokeLock) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)main {
    while(YES) {
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addTimer:self.timer forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

- (void)invokeLock {
    @autoreleasepool {
        if ([[GMMemManager shareInstance] isValid]) {
            NSArray *lockObjects = [[GMLockManager shareInstance] lockObjects];
            for (GMMemoryAccessObject *lockObject in lockObjects) {
                BOOL ok = YES;
                GMMemoryAccessObject *accessObject = [[GMMemManager shareInstance] getResult:lockObject.address];
                if (!accessObject) {
                    ok = NO;
                } else if (accessObject.value != lockObject.value) {
                    NSLog(@"value has changed. address:%08llX current value:%lld change to value %lld.", lockObject.address, accessObject.value, lockObject.value);
                    ok = [[GMMemManager shareInstance] modifyMemory:lockObject];
                }
                if (!ok) {
                    NSLog(@"lock object %@ failed.", [lockObject toDictionnary]);
                }
            }
        }
    }
}

@end
