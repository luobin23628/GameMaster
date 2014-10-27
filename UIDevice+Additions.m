//
//  UIDevice+_Additions.m
//  imem
//
//  Created by luobin on 14-10-27.
//
//

#import "UIDevice+Additions.h"

@implementation UIDevice (Additions)

- (NSInteger)majorVersion {
    static NSInteger result = -1;
    if (result == -1) {
        NSNumber *majorVersion = [[self.systemVersion componentsSeparatedByString:@"."] objectAtIndex:0];
        result = majorVersion.integerValue;
    }
    return result;
}

- (BOOL)isIOS7 {
    static NSInteger result = -1;
    if (result == -1) {
        result = [self majorVersion] >= 7;
    }
    return (BOOL)result;
}

- (BOOL)needsUI7Kit {
    static NSInteger result = -1;
    if (result == -1) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        result = ![self isIOS7];
#else
        result = YES;
#endif
    }
    return (BOOL)result;
}

@end
