//
//  GMMem.h
//  GameMaster
//
//  Created by luobin on 14-7-5.
//
//

struct __GMMem {
    mach_port_t task;
    NSMutableArray *results;
    NSUInteger resultCount;
} ;

typedef struct __GMMem * GMMemRef;

typedef struct {
    int value;
    uint64_t  address;
    BOOL writable;
} GMResult;

NSArray *GMGetAllProcesses(void);

GMMemRef GMMemRefCreate(int pid);

NSArray *GMMemRefSearch(GMMemRef mem, int64_t value, bool isFirst);

void GMMemRefModify(GMMemRef mem, uint64_t address, int64_t value);

void GMMemRefReset(GMMemRef mem);

void GMMemRefRelease(GMMemRef mem);

