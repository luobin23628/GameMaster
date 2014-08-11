
#import <UIKit/UIKit.h>


#define GMApplicationDidBecomeActiveNamePrefix @"__GM_ApplicationDidBecomeActiveNotification__"
#define GMApplicationWillResignActiveNamePrefix @"__GM_ApplicationWillResignActiveNotification__"

static void __GM_applicationDidBecomeActiveNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSString *notificationName =     [NSString stringWithFormat:@"%@%@", GMApplicationDidBecomeActiveNamePrefix, [NSBundle mainBundle].bundleIdentifier];
    ;
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)notificationName, NULL, NULL, YES);
}

static void __GM_applicationWillResignActiveNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSString *notificationName =     [NSString stringWithFormat:@"%@%@", GMApplicationWillResignActiveNamePrefix, [NSBundle mainBundle].bundleIdentifier];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)notificationName, NULL, NULL, YES);
}

static __attribute__((constructor)) void _logosLocalCtor_3d22e308() {
	@autoreleasepool {
        CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(),
                                        NULL,
                                        __GM_applicationDidBecomeActiveNotification,
                                        (CFStringRef)UIApplicationDidBecomeActiveNotification,
                                        NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(),
                                        NULL,
                                        __GM_applicationWillResignActiveNotification,
                                        (CFStringRef)UIApplicationWillResignActiveNotification,
                                        NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);

	}
}

