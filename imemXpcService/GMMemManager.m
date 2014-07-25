//
//  GMMemManager.m
//  imem
//
//  Created by luobin on 14-7-15.
//
//

#import "GMMemManager.h"
#import <libkern/OSCacheControl.h>
#import <LightMessaging.h>

#define MaxCount 100

@interface GMMemManager()

@property (nonatomic, assign) mach_port_t task;

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
	if ((kret = task_for_pid(mach_task_self(), pid, &task)) != KERN_SUCCESS) {
		NSLog(@"task_for_pid() failed, error %d: %s. Forgot to run as root?\n", kret, mach_error_string(kret));
        return NO;
    }
    self.task = task;
    resultCount = 0;
    return YES;
}

- (UInt64)resultCount {
    return resultCount;
}

- (vm_size_t)virtualSize {
    task_basic_info_data_t taskInfo;
    mach_msg_type_number_t infoCount = TASK_BASIC_INFO_COUNT;
    kern_return_t kret = task_info(self.task,
                                   TASK_BASIC_INFO,
                                   (task_info_t)&taskInfo,
                                   &infoCount);
    if (kret == KERN_SUCCESS) {
        return taskInfo.virtual_size;
    } else {
        return 0;
    }
}

- (NSArray *)search:(int64_t)value isFirst:(bool)isFirst {
    if (isFirst) {
        return [self searchFirst:value];
    } else {
        return [self searchAgain:value];
    }
}

- (NSArray *)searchFirst:(uint64_t)value {
    resultCount = 0;
    
    mach_timebase_info_data_t timebase_info;
    if (mach_timebase_info(&timebase_info) != KERN_SUCCESS) return nil;
    uint64_t begin = mach_absolute_time();
    
    void(^findBlock)(vm_address_t, vm_prot_t) = ^(vm_address_t realAddress, vm_prot_t protection) {
        if (resultCount < kMaxCount) {
            results[resultCount] = realAddress;
            resultCount++;
        }
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
    NSLog(@"elapse time %.4f", (CGFloat)nanos / NSEC_PER_SEC);
    
    if (resultCount <= MaxCount) {
        NSMutableArray *ret = [NSMutableArray array];
        for (int i = 0; i < resultCount; i++) {
            [ret addObject:@(results[i])];
        }
        return ret;
    } else {
        return [NSArray array];
    }
}

- (void)searchFirst:(void *)value
          valueSize:(size_t)valueSize
          findBlock:(void(^)(vm_address_t realAddress, vm_prot_t protection))findBlock {
    kern_return_t kret;
    vm_size_t virtualSize = [self virtualSize];
    
    // Output all searched results
	vm_address_t address = 0;
    vm_address_t baseAddress = 0;
    vm_address_t endAddress = 0;
	vm_size_t size;
	mach_port_t object_name;
	vm_region_basic_info_data_64_t info;
	mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
	while (vm_region(self.task, &address, &size, VM_REGION_BASIC_INFO, (vm_region_info_t)&info, &count, &object_name) == KERN_SUCCESS)
	{
        if (baseAddress == 0) {
            baseAddress = address;
            endAddress = baseAddress + virtualSize;
        }
        if (address >= endAddress) {
            break;
        }
        vm_prot_t protection = info.protection;
        if (!info.shared && !info.reserved && (protection &VM_PROT_READ)&& (protection &VM_PROT_WRITE)) {
            
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
                //                NSLog(@"mac_vm_read fails, address:%x, error %d:%s", address, kret, mach_error_string(kret));
            }
        }
		address += size;
	}
}

- (void)searchAgain:(void *)value
          valueSize:(size_t)valueSize
          findBlock:(void(^)(vm_address_t realAddress, const void *buffer,  size_t bufferSize))findBlock {
    int resultCt = resultCount;
    
    kern_return_t kret;
    vm_size_t virtualSize = [self virtualSize];
    
    // Output all searched results
    int i = 0;
    vm_address_t currentAddress = 0;
	vm_address_t address = 0;
    vm_address_t baseAddress = 0;
    vm_address_t endAddress = 0;
	vm_size_t size;
	mach_port_t object_name;
	vm_region_basic_info_data_64_t info;
	mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
	while (vm_region(self.task, &address, &size, VM_REGION_BASIC_INFO, (vm_region_info_t)&info, &count, &object_name) == KERN_SUCCESS)
	{
        if (baseAddress == 0) {
            baseAddress = address;
            endAddress = baseAddress + virtualSize;
        }
        if (address >= endAddress) {
            break;
        }
        vm_prot_t protection = info.protection;
        if (!info.shared && !info.reserved && (protection &VM_PROT_READ)&& (protection &VM_PROT_WRITE)) {
            currentAddress = results[i];

            if (address <= currentAddress < address + size) {
                pointer_t buffer;
                mach_msg_type_number_t bufferSize = size;
                if ((kret = vm_read(self.task, (mach_vm_address_t)address, size, &buffer, &bufferSize)) == KERN_SUCCESS) {
                    
                    while (address <= currentAddress < address + size) {
                        void *pos = currentAddress - address + buffer;
                        if (bufferSize - (currentAddress - address) >= valueSize && memmem(pos, valueSize, value, valueSize)) {
                            if (findBlock) {
                                findBlock(currentAddress, value, valueSize);
                            }
                        }
                        if (i >= resultCt) {
                            break;
                        } else {
                            i ++;
                            currentAddress = results[i];
                        }
                    }
                    
                } else {
                    //                NSLog(@"mac_vm_read fails, address:%x, error %d:%s", address, kret, mach_error_string(kret));
                }
            }
        }
		address += size;
	}
}

- (NSArray *)searchAgain:(int64_t)value {
    mach_timebase_info_data_t timebase_info;
    if (mach_timebase_info(&timebase_info) != KERN_SUCCESS) return nil;
    uint64_t begin = mach_absolute_time();
    
    
    __block int newResultCount = 0;
    
    void(^findBlock)(vm_address_t, const void *,  size_t) = ^(vm_address_t address, const void *buffer,  size_t bufferSize) {
        results[newResultCount] = address;
        newResultCount++;
    };
    
    uint8_t v = (uint8_t)value;
    [self searchAgain:&v
            valueSize:sizeof(v)
            findBlock:findBlock];
    
    uint64_t end = mach_absolute_time();
    uint64_t nanos  = (end - begin)* timebase_info.numer / timebase_info.denom;
    NSLog(@"elapse time %.4f", (CGFloat)nanos / NSEC_PER_SEC);
    
    resultCount = newResultCount;
    
    if (resultCount <= MaxCount) {
        NSMutableArray *ret = [NSMutableArray array];
        for (int i = 0; i < resultCount; i++) {
            [ret addObject:@(results[i])];
        }
        return ret;
    } else {
        return [NSArray array];
    }
    
    return nil;
}

- (NSDictionary *)getResult:(vm_address_t)address {
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
    vm_address_t address = [result address];
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

- (BOOL)reset {
    resultCount = 0;
    return YES;
}

- (void)dealloc {
    [super dealloc];
}

@end
