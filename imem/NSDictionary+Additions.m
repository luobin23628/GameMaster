//
//  NSDictionary+Additions.m
//  imem
//
//  Created by luobin on 14-7-20.
//
//


#import "NSDictionary+Additions.h"

@implementation NSDictionary (Additions)

- (unsigned long long)address {
    return [[self objectForKey:kResultKeyAddress] unsignedLongLongValue];
}

- (int)value {
    return [[self objectForKey:kResultKeyValue] intValue];
}

- (BOOL)writable {
    return [self protection] & VM_PROT_WRITE;
}

- (vm_prot_t)protection {
    return [[self objectForKey:kResultKeyProtection] intValue];
}


@end
