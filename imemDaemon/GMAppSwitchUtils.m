//
//  GMLockManager.m
//  imem
//
//  Created by luobin on 14-7-27.
//
//

#import "GMAppSwitchUtils.h"
#import <libkern/OSAtomic.h>

#define imemIdentifier @"com.luobin.imem"

static OSSpinLock spinLock;

@interface GMAppSwitchUtils()

@property (nonatomic, retain) NSMutableArray *appIdentifierList;
@property (nonatomic, retain) NSString *savedPlistPath;

@end

@implementation GMAppSwitchUtils

+ (instancetype)shareInstance {
    @synchronized(self){
        static GMAppSwitchUtils *appSwitchUtils = nil;
        if (!appSwitchUtils) {
            appSwitchUtils = [[GMAppSwitchUtils alloc] init];
        }
        return appSwitchUtils;
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
        self.savedPlistPath = [path stringByAppendingPathComponent:@"app.plist"];
        if ([fileManager fileExistsAtPath:self.savedPlistPath isDirectory:nil]) {
            NSMutableArray *appIdentifierList = [[[NSMutableArray alloc] initWithContentsOfFile:self.savedPlistPath] autorelease];
            if (appIdentifierList) {
                self.appIdentifierList = appIdentifierList;
            } else {
                [fileManager removeItemAtPath:self.savedPlistPath error:nil];
                self.appIdentifierList = [NSMutableArray array];
            }
            self.appIdentifierList = appIdentifierList;
        } else {
            self.appIdentifierList = [NSMutableArray array];
        }
    }
    return self;
}

- (void)synchronize {
    if (self.appIdentifierList.count) {
        [self.appIdentifierList writeToFile:self.savedPlistPath atomically:YES];
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:self.savedPlistPath error:nil];
    }
}

- (void)dealloc {
    self.savedPlistPath = nil;
    self.appIdentifierList = nil;
    [super dealloc];
}

+ (void)addAppIdentifier:(NSString *)identifier {
    [[GMAppSwitchUtils shareInstance] addAppIdentifier:identifier];
}

+ (void)removeAppIdentifier:(NSString *)identifier {
    [[GMAppSwitchUtils shareInstance] removeAppIdentifier:identifier];
}

+ (NSArray *)getAppIdentifiers {
    return [[GMAppSwitchUtils shareInstance] getAppIdentifiers];
}

- (void)addAppIdentifier:(NSString *)identifier {
    if (identifier) {
        OSSpinLockLock(&spinLock);
        [self.appIdentifierList addObject:identifier];
        [self synchronize];
        OSSpinLockUnlock(&spinLock);
    }
}

- (void)removeAppIdentifier:(NSString *)identifier {
    if (identifier) {
        OSSpinLockLock(&spinLock);
        [self.appIdentifierList removeObject:identifier];
        [self synchronize];
        OSSpinLockUnlock(&spinLock);
    }
}

- (NSArray *)getAppIdentifiers {
    NSMutableArray *appIdentifierList = nil;
    OSSpinLockLock(&spinLock);
    appIdentifierList = self.appIdentifierList;
    OSSpinLockUnlock(&spinLock);
    return appIdentifierList;
}

@end
