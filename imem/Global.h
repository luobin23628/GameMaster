//
//  Global.h
//  imem
//
//  Created by luobin on 14-7-16.
//
//

#ifndef imem_Global_h
#define imem_Global_h

#import <LightMessaging.h>
#import "NSDictionary+Additions.h"
#import "MAZeroingWeakRef.h"

static LMConnection connection = {
	MACH_PORT_NULL,
	"imem.datasource"
};

#define GMMessageIdSetPid       1
#define GMMessageIdSearch       2
#define GMMessageIdGetResult    3
#define GMMessageIdModify       4
#define GMMessageIdReset        5


#endif
