#define _GNU_SOURCE 1
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <dlfcn.h>
#include <sys/time.h>
#include <sys/select.h>
#include <time.h>
#include <mach/mach_time.h>

void MSHookFunction(void *symbol, void *replace, void **result);

static struct timeval timebase_gettimeofday;

struct tiacc {
    long long int lastsysval;
    long long int lastourval;
};

static struct tiacc accumulators[3] = {{0,0}, {0,0}, {0,0}};

static int num = 10;
static int denom = 5;
static long long int shift = 0;

static long long int filter_time(long long int nanos, struct tiacc* acc) {
    if (acc->lastsysval == 0) {
        acc->lastsysval = nanos;
        acc->lastourval = nanos;
        return acc->lastourval;
    }
    long long int delta = nanos - acc->lastsysval;
    acc->lastsysval = nanos;
    
    delta = delta * num / denom;
    acc->lastourval+=delta;
    return acc->lastourval;
}

static uint64_t (*original_mach_absolute_time)();
uint64_t new_mach_absolute_time() {
    uint64_t t = original_mach_absolute_time();
    
    uint64_t ret = filter_time(t, accumulators+0);
    
    return ret;
}

static int (*original_gettimeofday)(struct timeval *tv, struct timezone *tz);

int new_gettimeofday(struct timeval *tv, struct timezone *tz) {
    int ret = original_gettimeofday(tv, tz);
    long long q = 1000000LL * (tv->tv_sec - timebase_gettimeofday.tv_sec)
        + (tv->tv_usec - timebase_gettimeofday.tv_usec);
    long long t = q;
    q = filter_time(q*1000LL, accumulators+1)/1000;
    tv->tv_sec = (q/1000000)+timebase_gettimeofday.tv_sec + shift;
    tv->tv_usec = q%1000000+timebase_gettimeofday.tv_usec;
    if (tv->tv_usec >= 1000000) {
        tv->tv_usec-=1000000;
        tv->tv_sec+=1;
    }

    return ret;
}

static int (*original_nanosleep)(const struct timespec *req, struct timespec *rem);
int new_nanosleep(const struct timespec *req, struct timespec *rem) {

    long long q = 1000000000LL*(req->tv_sec) + req->tv_nsec;

    q = q * denom / num;

    struct timespec ts;

    ts.tv_sec = (q/1000000000);
    ts.tv_nsec = q%1000000000;

    int ret = original_nanosleep(&ts, rem);
                 
    if (rem) {
        q = 1000000000LL*(rem->tv_sec) + rem->tv_nsec;

        q = q * num / denom;

        rem->tv_sec = (q/1000000000);
        rem->tv_nsec = q%1000000000;

    }          

    return ret;
}

static int (*original_select)(int nfds, fd_set *readfds, fd_set *writefds,
                                   fd_set *exceptfds, struct timeval *timeout);

int new_select(int nfds, fd_set *readfds, fd_set *writefds,
                  fd_set *exceptfds, struct timeval *timeout) {
    struct timeval ts;
    struct timeval *tsptr = NULL;

    if (timeout) {
        long long q = 1000000LL*(timeout->tv_sec) + timeout->tv_usec;

        q = q * denom / num;

        ts.tv_sec = (q/1000000);
        ts.tv_usec = q%1000000;
        tsptr = &ts;
    }

    int ret = original_select(nfds, readfds, writefds, exceptfds, tsptr);


    if (timeout) {
        long long q = 1000000LL*(tsptr->tv_sec) + tsptr->tv_usec;

        q = q * num / denom;

        timeout->tv_sec = (q/1000000);
        timeout->tv_usec = q%1000000;
    }

    return ret;
}


static int (*original_pselect)(int nfds, fd_set *readfds, fd_set *writefds,
                              fd_set *exceptfds, const struct timespec *timeout,
                              const sigset_t *sigmask);

int new_pselect(int nfds, fd_set *readfds, fd_set *writefds,
        fd_set *exceptfds, const struct timespec *timeout,
        const sigset_t *sigmask) {
    struct timespec ts;
    struct timespec *tsptr = NULL;

    if (timeout) {
        long long q = 1000000000LL*(timeout->tv_sec) + timeout->tv_nsec;

        q = q * denom / num;

        ts.tv_sec = (q/1000000000);
        ts.tv_nsec = q%1000000000;
        tsptr = &ts;
    }

    int ret = original_pselect(nfds, readfds, writefds, exceptfds, tsptr, sigmask);
    return ret;
}

__attribute__((constructor))
static void initialize2() {
    NSLog(@"===============initialize2=================");
//    MSHookFunction(mach_absolute_time, new_mach_absolute_time, (void **)&original_mach_absolute_time);
//    MSHookFunction(gettimeofday, new_gettimeofday, (void **)&original_gettimeofday);
//    MSHookFunction(nanosleep, new_nanosleep, (void **)&original_nanosleep);
//    MSHookFunction(select, new_select, (void **)&original_select);
//    MSHookFunction(pselect, new_pselect, (void **)&original_pselect);
}

__attribute__((destructor))
static void destructor2() {
//    NSLog(@"===============destructor=================");
//    MSHookFunction(mach_absolute_time, new_mach_absolute_time, ((void *)0));
//    MSHookFunction(gettimeofday, new_gettimeofday, ((void *)0));
//    MSHookFunction(nanosleep, new_nanosleep, ((void *)0));
//    MSHookFunction(select, new_select, ((void *)0));
//    MSHookFunction(pselect, new_pselect, ((void *)0));
}


