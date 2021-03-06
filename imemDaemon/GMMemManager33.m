//
//  GMMemManager.m
//  imem
//
//  Created by luobin on 14-7-15.
//
//

#import "GMMemManager.h"
#import <libkern/OSCacheControl.h>
#import <mach/vm_map.h>
#import <mach/mach_traps.h>

#define MaxCount 100

@interface GMMemManager()

@property (nonatomic, assign) mach_port_t task;
@property (nonatomic, retain) NSMutableArray *results;
@end

@implementation GMMemManager

+ (instancetype)shareInstance {
    static GMMemManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[GMMemManager alloc] init];
    });
    return sharedManager;
}

- (BOOL)setPid:(int)pid {
    // Get task of specified PID
	kern_return_t kret;
	mach_port_t task; // type vm_map_t = mach_port_t in mach_types.defs
	if ((kret = task_for_pid(mach_task_self(), pid, &task)) != KERN_SUCCESS)
	{
		NSLog(@"task_for_pid() failed, error %d: %s. Forgot to run as root?\n", kret, mach_error_string(kret));
        return NO;
    }
    //    CFArrayCreateMutable(NULL, 666, const CFArrayCallBacks *callBacks)
    self.task = task;
    self.results = [NSMutableArray array];
    return YES;
}

- (UInt64)resultCount {
    return [self.results count];
}

- (NSArray *)search:(int64_t)value isFirst:(bool)isFirst {
    if (isFirst) {
        return [self searchFirst:value];
    } else {
        return [self searchAgain:value];
    }
}

- (NSArray *)searchFirst:(uint64_t)value {
    [self.results removeAllObjects];
    
    mach_timebase_info_data_t timebase_info;
    mach_timebase_info(&timebase_info);
    
    uint64_t begin = mach_absolute_time();
    
    void(^findBlock)(vm_address_t, vm_prot_t) = ^(vm_address_t realAddress, vm_prot_t protection) {
        //        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        //        [result setObject:@(realAddress) forKey:kResultKeyAddress];
        //        [result setObject:@(value) forKey:kResultKeyValue];
        //        [result setObject:@(protection) forKey:kResultKeyProtection];
        //        [self.results addObject:result];
        
        [self.results addObject:@(realAddress)];
    };
    
    if (value <= UINT8_MAX) {
        uint8_t v = (uint8_t)value;
        [self searchFirst:&v
                valueSize:sizeof(v)
                findBlock:findBlock];
        
    } else if (value <= UINT16_MAX) {
        uint16_t v = (uint16_t)value;
        [self searchFirst:&v
                valueSize:sizeof(v)
                findBlock:findBlock];
    } else if (value <= UINT32_MAX) {
        uint32_t v = (uint32_t)value;
        [self searchFirst:&v
                valueSize:sizeof(v)
                findBlock:findBlock];
    } else if (value <= UINT64_MAX) {
        uint64_t v = (uint64_t)value;
        [self searchFirst:&v
                valueSize:sizeof(v)
                findBlock:findBlock];
    } else {
        return nil;
    }
    
    uint64_t end = mach_absolute_time();
    uint64_t nanos  = (end - begin)* timebase_info.numer / timebase_info.denom;
    NSLog(@"searchFirst elapse time %.4f", (CGFloat)nanos / NSEC_PER_SEC);
    
    if (self.results.count <= MaxCount) {
        return self.results;
    } else {
        return [NSArray array];
    }
}

- (void)searchFirst:(void *)value
          valueSize:(size_t)valueSize
          findBlock:(void(^)(vm_address_t realAddress, vm_prot_t protection))findBlock {
    kern_return_t kret;
    
    // Output all searched results
	vm_address_t address = 0;
	vm_size_t size;
	mach_port_t object_name;
	vm_region_basic_info_data_64_t info;
	mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
	while (vm_region(self.task, &address, &size, VM_REGION_BASIC_INFO, (vm_region_info_t)&info, &count, &object_name) == KERN_SUCCESS)
	{
        vm_prot_t protection = info.protection;

        if ( (protection &VM_PROT_READ)&& (protection &VM_PROT_WRITE)) {
            pointer_t buffer;
            mach_msg_type_number_t bufferSize = size;
            if ((kret = vm_read(self.task, (mach_vm_address_t)address, size, &buffer, &bufferSize)) == KERN_SUCCESS) {
                void *pos = memmem(buffer, bufferSize, value, valueSize);
                while (pos) {
                    vm_address_t realAddress = pos - buffer + address;
                    if (findBlock) {
                        findBlock(realAddress, protection);
                    }
                    pos = memmem(pos + 1, (void*)(bufferSize + buffer) - pos - 1, value, valueSize);
                }
            } else {
                NSLog(@"mac_vm_read fails, address:%x, error %d:%s", address, kret, mach_error_string(kret));
            }
        }
        

		address += size;
	}
}

- (void)searchAgain:(void *)value
          valueSize:(size_t)valueSize
          findBlock:(void(^)(vm_address_t realAddress, const void *buffer,  size_t bufferSize))findBlock {
    kern_return_t kret;
    mach_vm_offset_t address = 0;
    for (int i = 0; i < [self.results count]; i++) {
        pointer_t buffer;
        mach_msg_type_number_t bufferSize = valueSize;
        
        address = [[self.results objectAtIndex:i] unsignedLongLongValue];
        
        if ((kret = vm_read(self.task, (mach_vm_address_t)address, valueSize, &buffer, &bufferSize)) == KERN_SUCCESS) {
			void *substring = NULL;
			if ((substring = memmem(buffer, bufferSize, value, valueSize)) != NULL) {
                if (findBlock) {
                    findBlock(address, buffer, bufferSize);
                }
			}
		}
    }
}

- (NSArray *)searchAgain:(int64_t)value {
    
    mach_timebase_info_data_t timebase_info;
    mach_timebase_info(&timebase_info);
    uint64_t begin = mach_absolute_time();
    
    NSMutableArray *newResults = [NSMutableArray array];
    
    void(^findBlock)(vm_address_t, const void *,  size_t) = ^(vm_address_t address, const void *buffer,  size_t bufferSize) {
        [newResults addObject:@(address)];
    };
    
    if (value <= UINT8_MAX) {
        uint8_t v = (uint8_t)value;
        [self searchAgain:&v
                valueSize:sizeof(v)
                findBlock:findBlock];
        
    } else if (value <= UINT16_MAX) {
        uint16_t v = (uint16_t)value;
        [self searchAgain:&v
                valueSize:sizeof(v)
                findBlock:findBlock];
    } else if (value <= UINT32_MAX) {
        uint32_t v = (uint32_t)value;
        [self searchAgain:&v
                valueSize:sizeof(v)
                findBlock:findBlock];
    } else if (value <= UINT64_MAX) {
        uint64_t v = (uint64_t)value;
        [self searchAgain:&v
                valueSize:sizeof(v)
                findBlock:findBlock];
    } else {
        return nil;
    }
    
    uint64_t end = mach_absolute_time();
    uint64_t nanos  = (end - begin)* timebase_info.numer / timebase_info.denom;
    NSLog(@"searchAgain elapse time %.4f", (CGFloat)nanos / NSEC_PER_SEC);
    
    [self.results removeAllObjects];
    [self.results addObjectsFromArray:newResults];
    
    if (self.results.count <= MaxCount) {
        return self.results;
    } else {
        return [NSArray array];
    }
}

- (NSDictionary *)getResult:(uint64_t)address {
    kern_return_t kret;
    mach_vm_size_t size;
    
    pointer_t buffer;
    size = sizeof(int); // because oldValue and newValue are int
    mach_msg_type_number_t bufferSize = (mach_msg_type_number_t)size;
    
    if ((kret = vm_read(self.task, (mach_vm_address_t)address, size, &buffer, &bufferSize)) == KERN_SUCCESS) {
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        [result setObject:@(address) forKey:kResultKeyAddress];
        [result setObject:@(*((int *)buffer)) forKey:kResultKeyValue];
        return result;
    }
    return nil;
}

- (BOOL)modifyMemory:(NSDictionary *)result {
    uint64_t address = [result address];
    int value = [result value];
    vm_prot_t protection = [result protection];
    
    vm_prot_t oriProtection;
    kern_return_t kret;
	vm_address_t regionAddress = 0;
	vm_size_t regionSize;
	mach_port_t object_name;
	vm_region_basic_info_data_64_t info;
	mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
	while (vm_region(self.task, &regionAddress, &regionSize, VM_REGION_BASIC_INFO, (vm_region_info_t)&info, &count, &object_name) == KERN_SUCCESS) {
        if (regionAddress + regionSize > address) {
            oriProtection = info.protection;
            break;
        }
		regionAddress += regionSize;
	}
    if (!oriProtection) {
        return NO;
    }
    if (!protection) {
        protection = oriProtection;
    }
    
    BOOL changeProtection = !(oriProtection & VM_PROT_READ)
    || !(oriProtection & VM_PROT_WRITE)
    || !(oriProtection & VM_PROT_COPY);
    
    /* Change memory protections to rw- */
    if (changeProtection) {
        if((kret = vm_protect(self.task, address, sizeof(value), false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY)) != KERN_SUCCESS) {
            NSLog(@"vm_protect failed, error %d: %s\n", kret, mach_error_string(kret));
            return NO;
        }
    }
    
    /* Actually perform the write */
    if ((kret = vm_write(self.task, address, (pointer_t)&value, sizeof(value))) != KERN_SUCCESS) {
        NSLog(@"mach_vm_write failed, error %d: %s\n", kret, mach_error_string(kret));
        return NO;
    }
    
    /* Flush CPU data cache to save write to RAM */
    sys_dcache_flush(address, sizeof(value));
    /* Invalidate instruction cache to make the CPU read patched instructions from RAM */
    sys_icache_invalidate(address, sizeof(value));
    
    /* Change memory protections back to*/
    if (changeProtection) {
        if((kret = vm_protect(self.task, address, sizeof(value), false, protection)) != KERN_SUCCESS) {
            NSLog(@"vm_protect failed, error %d: %s\n", kret, mach_error_string(kret));
            return NO;
        }
    }
    return YES;
}

- (BOOL)searchRegionHasPrivilege:(vm_prot_t)pri
                       withBlock:(void (^)(vm_address_t offset, mach_msg_type_number_t size, char *buf))block {
    kern_return_t kr;
    
    mach_msg_type_number_t region_size = 0;
    vm_region_basic_info_data_t info;
    
    /* must set to >= VM_REGION_BASIC_INFO_COUNT
     * or will cause KERN_INVALID_ARGUMENT
     * ref vm_map_region function from: http://www.opensource.apple.com/source/xnu/xnu-792.13.8/osfmk/vm/vm_map.c
     */
    mach_msg_type_number_t infoCnt = VM_REGION_BASIC_INFO_COUNT;
    mach_port_t objname;
    
    vm_address_t region_addr = 1;
    while((size_t)region_addr != 0)
    {
        region_addr += region_size;
        
        kr = vm_region(self.task,
                       &region_addr,
                       &region_size,
                       VM_REGION_BASIC_INFO,
                       (vm_region_info_t)&info,
                       &infoCnt,
                       &objname);
        
        if (kr != KERN_SUCCESS) {
            return NO;
        }
        
        if(info.protection != pri)
            continue;
        
        char *region_buf = (char*)malloc(region_size);
        
        vm_size_t count;
        
        kr = vm_read_overwrite(self.task,
                               region_addr,
                               region_size,
                               (vm_offset_t)region_buf,
                               &count);
        
        if (kr != KERN_SUCCESS) {
            free(region_buf);
            return NO;
        }
        
        block(region_addr, region_size, region_buf);
        free(region_buf);
    }
    
    return YES;
}

- (BOOL)reset {
    [self.results removeAllObjects];
    return YES;
}

- (void)dealloc {
    self.results = nil;
    [super dealloc];
}

@end
