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
#import "GMStorageManager.h"

#define MaxCount 100

@interface GMMemManager()

@property (nonatomic, assign) mach_port_t task;
@property (nonatomic, assign) uint64_t lastValue;
@property (nonatomic, assign) dispatch_source_t source;

@end

@implementation GMMemManager
@dynamic pid;

+ (instancetype)shareInstance {
    static GMMemManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[GMMemManager alloc] init];
    });
    return sharedManager;
}

- (id)init {
    self = [super init];
    if (self) {
        [GMStorageManager shareInstance];
    }
    return self;
}

//- (NSString *)appIdentifier {
//    return [[NSUserDefaults standardUserDefaults] objectForKey:@"appIdentifier"];
//}
//
//- (void)invalidateAppIdentifier {
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"appIdentifier"];
//}
//
//- (BOOL)setAppIdentifier:(NSString *)appIdentifier {
//    [[NSUserDefaults standardUserDefaults] setObject:appIdentifier forKey:@"appIdentifier"];
//    [self setPid:0];
//    return YES;
//}

- (BOOL)setPid:(int)pid {
    // Get task of specified PID
	kern_return_t kret;
	mach_port_t task; // type vm_map_t = mach_port_t in mach_types.defs
	if ((kret = task_for_pid(mach_task_self(), pid, &task)) != KERN_SUCCESS) {
		NSLog(@"task_for_pid() failed, error %d: %s. Forgot to run as root?\n", kret, mach_error_string(kret));
        return NO;
    }
    [[GMStorageManager shareInstance] setPid:pid];
    _pid = pid;
    self.lastValue = 0;
    self.task = task;
    resultCount = 0;
    if (results) {
        IntArrayDealloc(results);
        results = nil;
    }
    [self startMonitorForProcess:pid];
    return YES;
}

- (int)pid {
    return _pid;
}

- (UInt64)resultCount {
    return resultCount;
}

- (NSArray *)search:(uint64_t)value isFirst:(bool)isFirst {
    if (!self.task || ![self isValid]) {
        _pid = 0;
        self.task = 0;
        self.lastValue = 0;
        resultCount = 0;
        return nil;
    };
    self.lastValue = value;
    if (isFirst) {
        return [self searchFirst:value];
    } else {
        return [self searchAgain:value];
    }
}

- (NSArray *)searchFirst:(uint64_t)value {
    
    resultCount = 0;
    
    if (results) {
        IntArrayDealloc(results);
        results = nil;
    }
    
    if (value == 0) {
        results = IntArrayCreate(10000);
    } else if (value  < 10) {
        results = IntArrayCreate(1000);
    } else {
        results = IntArrayCreate(100);
    }
    
    mach_timebase_info_data_t timebase_info;
    if (mach_timebase_info(&timebase_info) != KERN_SUCCESS) return nil;
    uint64_t begin = mach_absolute_time();
    
    void(^findBlock)(vm_address_t, vm_prot_t) = ^(vm_address_t realAddress, vm_prot_t protection) {
        if (resultCount < kMaxCount) {
            IntArrayAddValue(results, realAddress);
            resultCount++;
        }
    };
    
    if (value !=0 && value <= UINT16_MAX) {
        uint16_t v = (uint16_t)value;
        [self searchFirst:&v
                valueSize:sizeof(v)
                findBlock:findBlock];
    } else if (value !=0  && value <= UINT32_MAX) {
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
            [ret addObject:@(IntArrayValueAtIndex(results, i))];
        }
        return ret;
    } else {
        return [NSArray array];
    }
}

- (NSArray *)searchAgain:(uint64_t)value {
    mach_timebase_info_data_t timebase_info;
    if (mach_timebase_info(&timebase_info) != KERN_SUCCESS) return nil;
    uint64_t begin = mach_absolute_time();
    
    __block int newResultCount = 0;
    
    void(^findBlock)(vm_address_t, const void *,  size_t) = ^(vm_address_t address, const void *buffer,  size_t bufferSize) {
        IntArraySetValueAtIndex(results, newResultCount, address);
        newResultCount++;
    };
    
    if (value !=0 && value <= UINT16_MAX) {
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
    NSLog(@"elapse time %.4f", (CGFloat)nanos / NSEC_PER_SEC);
    
    NSLog(@"newResultCount:%d", newResultCount);
    NSLog(@"resultCount:%d", resultCount);
    
    IntArraySubstractSize(results, newResultCount);
    
    resultCount = newResultCount;
    
    if (resultCount <= MaxCount) {
        NSMutableArray *ret = [NSMutableArray array];
        for (int i = 0; i < resultCount; i++) {
            [ret addObject:@(IntArrayValueAtIndex(results, i))];
        }
        return ret;
    } else {
        return [NSArray array];
    }
}

- (GMMemoryAccessObject *)getMemoryAccessObject:(vm_address_t)address {
    if (!self.task || ![self isValid]) {
        _pid = 0;
        self.task = 0;
        resultCount = 0;
        self.lastValue = 0;
        return nil;
    };
    
    GMValueType valueType;
    
    kern_return_t kret;
    mach_vm_size_t size;
    
    uint64_t value = 0;
    uint64_t lastValue = self.lastValue;
    if (lastValue !=0 && lastValue <= UINT16_MAX) {
        size = sizeof((uint16_t)lastValue);
        mach_msg_type_number_t bufferSize = size;
        void *buffer = malloc(bufferSize);
        if ((kret = vm_read_overwrite(self.task, (mach_vm_address_t)address, sizeof(uint32_t), buffer, &bufferSize)) == KERN_SUCCESS) {
            if (bufferSize == sizeof(uint32_t)) {
                uint16_t i = 0;
                value = *((uint16_t *)(buffer + sizeof(uint16_t)));
                if (memmem(buffer + sizeof(uint16_t), sizeof(uint16_t), &i, sizeof(i))) {
                    value = *((uint32_t *)buffer);
                    valueType = GMValueTypeInt32;
                } else {
                    value = *((uint16_t *)buffer);
                    valueType = GMValueTypeInt16;
                }
            } else {
                value = *((uint16_t *)buffer);
                valueType = GMValueTypeInt16;
            }
        }
        if (buffer != nil) {
            free(buffer);
            buffer = nil;
        }
    } else if (lastValue <= UINT32_MAX) {
        size = sizeof((uint32_t)lastValue);
        mach_msg_type_number_t bufferSize = size;
        void *buffer = malloc(bufferSize);
        if ((kret = vm_read_overwrite(self.task, (mach_vm_address_t)address, size, buffer, &bufferSize)) == KERN_SUCCESS) {
            value = *((uint32_t *)buffer);
            valueType = GMValueTypeInt32;
        }
        if (buffer != nil) {
            free(buffer);
            buffer = nil;
        }
    } else if (lastValue <= UINT64_MAX) {
        size = sizeof((uint64_t)lastValue);
        mach_msg_type_number_t bufferSize = size;
        void *buffer = malloc(bufferSize);
        if ((kret = vm_read_overwrite(self.task, (mach_vm_address_t)address, size, buffer, &bufferSize)) == KERN_SUCCESS) {
            value = *((uint64_t *)buffer);
            valueType = GMValueTypeInt64;
        }
        if (buffer != nil) {
            free(buffer);
            buffer = nil;
        }
    } else {
        return nil;
    }
    if (kret != KERN_SUCCESS) {
        return nil;
    }
    
    GMMemoryAccessObject *memoryAccessObject = [[GMMemoryAccessObject alloc] init];
    memoryAccessObject.valueType = valueType;
    memoryAccessObject.address = address;
    memoryAccessObject.value = value;
    return [memoryAccessObject autorelease];
}

- (BOOL)modifyMemory:(GMMemoryAccessObject *)accessObject {
    if (!self.task || ![self isValid]) {
        _pid = 0;
        self.task = 0;
        resultCount = 0;
        self.lastValue = 0;
        return NO;
    };
    vm_address_t address = [accessObject address];
    uint64_t value = [accessObject value];
    
    size_t valueSize;
    if (value != 0 && value <= UINT16_MAX) {
        valueSize = sizeof(uint16_t);
    } else if (value <= UINT32_MAX) {
        valueSize = sizeof(uint32_t);
    } else if (value <= UINT64_MAX) {
        valueSize = sizeof(uint64_t);
    } else {
        return NO;
    }
    
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
    
    BOOL changeProtection = !(oriProtection & VM_PROT_READ)
    || !(oriProtection & VM_PROT_WRITE);
    
    GMOptType optType = [accessObject optType];
    if (optType == GMOptTypeEditAndLock && changeProtection) {
        return NO;
    }
    
    /* Change memory protections to rw- */
    if (changeProtection) {
        if((kret = vm_protect(self.task, address, valueSize, false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY)) != KERN_SUCCESS) {
            NSLog(@"vm_protect failed, error %d: %s\n", kret, mach_error_string(kret));
            return NO;
        }
    }
    
    /* Actually perform the write */
    if ((kret = vm_write(self.task, address, (pointer_t)&value, valueSize)) != KERN_SUCCESS) {
        NSLog(@"mach_vm_write failed, error %d: %s\n", kret, mach_error_string(kret));
        return NO;
    }
    
//    /* Flush CPU data cache to save write to RAM */
//    sys_dcache_flush(address, valueSize);
//    /* Invalidate instruction cache to make the CPU read patched instructions from RAM */
//    sys_icache_invalidate(address, valueSize);
    
    if (optType == GMOptTypeEditAndSave || optType == GMOptTypeEditAndLock) {
        [[GMStorageManager shareInstance] addObject:accessObject];
    }
    
    /* Change memory protections back to*/
    if (changeProtection) {
        if((kret = vm_protect(self.task, address, valueSize, false, oriProtection)) != KERN_SUCCESS) {
            NSLog(@"vm_protect failed, error %d: %s\n", kret, mach_error_string(kret));
            return NO;
        }
    }
    return YES;
}

- (BOOL)reset {
    if (results) {
        IntArrayDealloc(results);
        results = nil;
    }
    resultCount = 0;
    return YES;
}

- (void)dealloc {
    [self stopMonitor];
    [super dealloc];
}

#pragma mark - Private

- (NSString *)getIdentifierWithPid:(int)pid {
    NSDictionary *appInfo = [AppUtil appInfoForProcessID:pid];
    if (appInfo) {
        return [appInfo objectForKey:@"appID"]
    }
    return nil;
}

- (BOOL)isValid:(int)pid {
    return pid == _pid && self.task && [self virtualSize] > 0;
}

- (BOOL)isValid {
    return [self virtualSize] > 0;
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
        if ((protection &VM_PROT_READ)&& (protection &VM_PROT_WRITE)) {
            mach_msg_type_number_t bufferSize = size;
            void *buffer = malloc(bufferSize);
            if ((kret = vm_read_overwrite(self.task, (mach_vm_address_t)address, size, buffer, &bufferSize)) == KERN_SUCCESS) {
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
            if (buffer != nil)
            {
                free(buffer);
                buffer = nil;
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
        if ((protection &VM_PROT_READ)&& (protection &VM_PROT_WRITE)) {
            currentAddress = IntArrayValueAtIndex(results, i);
            
            while (currentAddress < address) {
                NSLog(@"%d, ignore address. %X not exist.", i, currentAddress);
                
                i ++;
                if (i >= resultCt) {
                    return;
                }
                currentAddress = IntArrayValueAtIndex(results, i);
            }
            
            if (address <= currentAddress && currentAddress < address + size) {
                mach_msg_type_number_t bufferSize = size;
                void *buffer = malloc(bufferSize);
                if ((kret = vm_read_overwrite(self.task, (mach_vm_address_t)address, size, buffer, &bufferSize)) == KERN_SUCCESS) {
                    while (address <= currentAddress && currentAddress < address + size) {
                        void *pos = currentAddress - address + buffer;
                        if (bufferSize - (currentAddress - address) >= valueSize && memmem(pos, valueSize, value, valueSize)) {
                            if (findBlock) {
                                findBlock(currentAddress, value, valueSize);
                            }
                        }
                        i ++;
                        if (i >= resultCt) {
                            return;
                        }
                        currentAddress = IntArrayValueAtIndex(results, i);
                    }
                } else {
                    //                NSLog(@"mac_vm_read fails, address:%x, error %d:%s", address, kret, mach_error_string(kret));
                }
                if (buffer != nil) {
                    free(buffer);
                    buffer = nil;
                }
            }
        }
        NSLog(@"vm_region %d, protection:%d address:%d size:%d, currentAddress:%d next region", i, protection, address, size, currentAddress);
		address += size;
	}
}

#pragma Monitor Process

- (void)startMonitorForProcess:(int)pid
{
    [self stopMonitor];
    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_PROC, pid, DISPATCH_PROC_EXIT, queue);
    self.source = source;
    if (source)
    {
        dispatch_source_set_event_handler(source, ^{
            _pid = 0;
            self.lastValue = 0;
            self.task = 0;
            resultCount = 0;
            NSLog(@"Process:%d exit. Clean up...", _pid);
            [[GMStorageManager shareInstance] setPid:0];
            [self stopMonitor];
        });
        dispatch_resume(source);
    }
}

- (void)stopMonitor {
    if (self.source) {
        dispatch_source_cancel(self.source);
        dispatch_release(self.source);
        self.source = nil;
    }
}

@end
