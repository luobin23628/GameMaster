//
//  NSDictionary+Additions.h
//  imem
//
//  Created by luobin on 14-7-20.
//
//

#import <Foundation/Foundation.h>

#define kResultKeyAddress   @"ResultKeyAddress"
#define kResultKeyValue     @"ResultKeyValue"
#define kResultKeyProtection  @"ResultKeyProtection"

@interface NSDictionary (Additions)

- (unsigned long long)address;

- (int)value;

- (vm_prot_t)protection;

- (BOOL)writable;

@end

