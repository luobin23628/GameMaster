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
#import "ALApplicationList.h"

#define GMApplicationDidBecomeActiveNamePrefix @"__GM_ApplicationDidBecomeActiveNotification__"
#define GMApplicationWillResignActiveNamePrefix @"__GM_ApplicationWillResignActiveNotification__"

#define imemIdentifier @"com.luobin.imem"

static OSSpinLock spinLock;

@interface GMStorageManager()

@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSMutableArray *objectList;
@property (nonatomic, retain) NSString *basePath;
@property (nonatomic, retain) NSString *savedPlistPath;
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
        NSString *documentPath = @"/private/var/mobile/Documents";
        NSString *path = [documentPath stringByAppendingPathComponent:@"com.binge.imem.daemon/"];
        BOOL isDirectory;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:path isDirectory:&isDirectory] || !isDirectory) {
            [fileManager removeItemAtPath:path error:nil];
            
            NSError *error = nil;
            [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
            if (error) {
                NSLog(@"error %@", error);
            }
        }
        self.identifier = nil;
        self.basePath = path;
        self.lockThread = [[[GMLockThread alloc] init] autorelease];
        [self.lockThread start];
        
        [self addObserverForIdentifier:imemIdentifier];
    }
    return self;
}

static void applicationDidBecomeActiveNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    @autoreleasepool {
        NSLog(@"applicationDidBecomeActiveNotification %@", userInfo);
        [[GMStorageManager shareInstance] updateLockThreadState];
    }
}

static void applicationWillResignActiveNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    @autoreleasepool {
        NSLog(@"applicationWillResignActiveNotification %@", userInfo);
        [[[GMStorageManager shareInstance] lockThread] suspend];
    }
}

- (void)addObserverForIdentifier:(NSString *)identifier {
    NSString *notificationName = [NSString stringWithFormat:@"%@%@", GMApplicationDidBecomeActiveNamePrefix, identifier];
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    applicationDidBecomeActiveNotification,
                                    (CFStringRef)notificationName,
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    
    notificationName = [NSString stringWithFormat:@"%@%@", GMApplicationWillResignActiveNamePrefix, identifier];
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    applicationWillResignActiveNotification,
                                    (CFStringRef)notificationName,
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
}

- (void)removeObserverForIdentifier:(NSString *)identifier {
    NSString *notificationName = [NSString stringWithFormat:@"%@%@", GMApplicationDidBecomeActiveNamePrefix, identifier];
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                       NULL,
                                       (CFStringRef)notificationName,
                                       NULL);
    
    notificationName = [NSString stringWithFormat:@"%@%@", GMApplicationWillResignActiveNamePrefix, identifier];
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                       NULL,
                                       (CFStringRef)notificationName,
                                       NULL);
}

- (void)setPid:(int)pid {
    if (_pid != pid) {
        _pid = pid;
        [self.lockThread suspend];
        [self removeObserverForIdentifier:self.identifier];
        if (pid <= 0) {
            self.identifier = nil;
            self.savedPlistPath = nil;
            self.objectList = [NSMutableArray array];
        } else {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            self.identifier = [self getIdentifierWithPid:pid];
            NSAssert(self.identifier, @"identifier must not be null.");
            self.savedPlistPath = [self.basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_storageObjects.plist", self.identifier]];
            if ([fileManager fileExistsAtPath:self.savedPlistPath isDirectory:nil]) {
                NSMutableArray *objectList = [NSKeyedUnarchiver unarchiveObjectWithFile:self.savedPlistPath];
                if (objectList) {
                    self.objectList = objectList;
                } else {
                    [fileManager removeItemAtPath:self.savedPlistPath error:nil];
                    self.objectList = [NSMutableArray array];
                }
                self.objectList = objectList;
            } else {
                self.objectList = [NSMutableArray array];
            }
            
            [self addObserverForIdentifier:self.identifier];
        }
    }
}

- (NSString *)getIdentifierWithPid:(int)pid {
	ALApplicationList *appList = [ALApplicationList sharedApplicationList];
	NSDictionary *applications = [appList applicationsFilteredUsingPredicate:[NSPredicate predicateWithFormat:@"pid = %d", pid]];
    NSArray *displayIdentifiers = applications.allKeys;
    if (displayIdentifiers.count) {
        return [displayIdentifiers firstObject];
    }
    return nil;
}

- (void)synchronize {
    if (self.objectList.count) {
        [NSKeyedArchiver archiveRootObject:self.objectList toFile:self.savedPlistPath];
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:self.savedPlistPath error:nil];
    }
}

- (void)dealloc {
    [self removeObserverForIdentifier:imemIdentifier];
    [self removeObserverForIdentifier:self.identifier];
    self.identifier = nil;
    [self.objectList removeObserver:self forKeyPath:nil context:nil];
    self.savedPlistPath = nil;
    self.basePath = nil;
    [self.lockThread cancel];
    self.lockThread = nil;
    self.objectList = nil;
    [super dealloc];
}

- (NSUInteger)findIndexOfObject:(GMMemoryAccessObject *)accessObject {
    NSUInteger index = [self.objectList indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[GMMemoryAccessObject class]]) {
            GMMemoryAccessObject *object = (GMMemoryAccessObject *)obj;
            if (object.address == accessObject.address) {
                *stop = YES;
                return YES;
            }
        }
        *stop = NO;
        return NO;
    }];
    return index;
}

- (void)addObject:(GMMemoryAccessObject *)accessObject {
    OSSpinLockLock(&spinLock);
    NSUInteger index = [self findIndexOfObject:accessObject];
    if (index != NSNotFound) {
        [self.objectList removeObjectAtIndex:index];
    }
    [self.objectList addObject:accessObject];
    [self synchronize];
    OSSpinLockUnlock(&spinLock);
    if (accessObject.optType == GMOptTypeEditAndLock) {
        [self.lockThread resume];
    }
}

- (void)removeObject:(GMMemoryAccessObject *)accessObject {
    if (accessObject) {
        [self removeObjects:@[accessObject]];
    }
}

- (void)removeObjects:(NSArray *)accessObjects {
    if (!accessObjects) {
        return;
    }
    OSSpinLockLock(&spinLock);
    BOOL isLockedObject = NO;
    for (GMMemoryAccessObject *accessObject in accessObjects) {
        NSUInteger index = [self findIndexOfObject:accessObject];
        if (index != NSNotFound) {
            GMMemoryAccessObject *oriAccessObject = [self.objectList objectAtIndex:index];
            if (oriAccessObject.optType == GMOptTypeEditAndLock) {
                isLockedObject = YES;
            }
            [self.objectList removeObjectAtIndex:index];
        }
    }
    [self synchronize];
    OSSpinLockUnlock(&spinLock);
    if (isLockedObject && ![self getLockedObjects].count) {
        [self.lockThread suspend];
    }
}

- (NSArray *)getAllObjects {
    return self.objectList;
}

- (NSArray *)getStoredObjects {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"optType = %d", GMOptTypeEditAndSave];
    OSSpinLockLock(&spinLock);
    NSArray *ret = [self.objectList filteredArrayUsingPredicate:predicate];
    OSSpinLockUnlock(&spinLock);
    return ret;
}

- (NSArray *)getLockedObjects {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"optType = %d", GMOptTypeEditAndLock];
    OSSpinLockLock(&spinLock);
    NSArray *ret = [self.objectList filteredArrayUsingPredicate:predicate];
    OSSpinLockUnlock(&spinLock);
    return ret;
}

- (void)removeAllLock {
    OSSpinLockLock(&spinLock);
    [self.objectList removeAllObjects];
    [self synchronize];
    OSSpinLockUnlock(&spinLock);
    [self updateLockThreadState];
}

- (void)updateLockThreadState {
    OSSpinLockLock(&spinLock);
    BOOL isLockedObject = NO;
    for (GMMemoryAccessObject *accessObject in self.objectList) {
        if (accessObject.optType == GMOptTypeEditAndLock) {
            isLockedObject = YES;
            break;
        }
    }
    [self synchronize];
    OSSpinLockUnlock(&spinLock);
    if (isLockedObject) {
        [self.lockThread resume];
    } else {
        [self.lockThread suspend];
    }
}

@end
