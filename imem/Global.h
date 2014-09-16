//
//  Global.h
//  imem
//
//  Created by luobin on 14-7-16.
//
//

#ifndef imem_Global_h
#define imem_Global_h

#import "LightMessaging.h"
#import "GMMemoryAccessObject.h"
#import "MAZeroingWeakRef.h"

static LMConnection connection = {
	MACH_PORT_NULL,
	"imem.datasource"
};

#define GMMessageIdGetPid       1
#define GMMessageIdSetPid       2
#define GMMessageIdSearch       3
#define GMMessageIdGetMemoryAccessObject    4
#define GMMessageIdModify       5
#define GMMessageIdReset        6
#define GMMessageIdCheckValid   7
#define GMMessageIdGetLockedList  8
#define GMMessageIdGetStoredList  9
#define GMMessageIdRemoveLockedOrStoredObjects  10

#define GMMessageIdAddAppIdentifier  20
#define GMMessageIdRemoveAppIdentifier  20
#define GMMessageIdGetAppIdentifiers  20

#endif
