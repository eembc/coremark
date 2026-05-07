/*
Copyright 2025 CISPA Helmholtz Center for Information Security gGmbH

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Original Author: Eric Ackermann
*/

#include <stdio.h>
#include <stdlib.h>
#include "coremark.h"

#include <zephyr/kernel.h>
#include <zephyr/timing/timing.h>
#include <zephyr/sys_clock.h>

#if VALIDATION_RUN
volatile ee_s32 seed1_volatile = 0x3415;
volatile ee_s32 seed2_volatile = 0x3415;
volatile ee_s32 seed3_volatile = 0x66;
#endif
#if PERFORMANCE_RUN
volatile ee_s32 seed1_volatile = 0x0;
volatile ee_s32 seed2_volatile = 0x0;
volatile ee_s32 seed3_volatile = 0x66;
#endif
#if PROFILE_RUN
volatile ee_s32 seed1_volatile = 0x8;
volatile ee_s32 seed2_volatile = 0x8;
volatile ee_s32 seed3_volatile = 0x8;
#endif
volatile ee_s32 seed4_volatile = ITERATIONS;
volatile ee_s32 seed5_volatile = 0;

#if (MEM_METHOD == MEM_MALLOC)
/* Function: portable_malloc
        Provide malloc() functionality in a platform specific way.
*/
void *
portable_malloc(size_t size)
{
    return malloc(size);
}
/* Function: portable_free
        Provide free() functionality in a platform specific way.
*/
void
portable_free(void *p)
{
    free(p);
}
#else
void *
portable_malloc(size_t size)
{
    return NULL;
}
void
portable_free(void *p)
{
    p = NULL;
}
#endif


/* Porting : Timing functions
        How to capture time and convert to seconds must be ported to whatever is
   supported by the platform. e.g. Read value from on board RTC, read value from
   cpu clock cycles performance counter etc. Sample implementation for standard
   time.h and windows.h definitions included.
*/
/* Define : TIMER_RES_DIVIDER
        Divider to trade off timer resolution and total time that can be
   measured.

        Use lower values to increase resolution, but make sure that overflow
   does not occur. If there are issues with the return value overflowing,
   increase this value.
        */
#define CORETIMETYPE               timing_t
#define GETMYTIME(_t)              (*_t = timing_counter_get())
#define MYTIMEDIFF(fin, ini)       (timing_cycles_get(ini, fin))
#define TIMER_RES_DIVIDER          1
#define SAMPLE_TIME_IMPLEMENTATION 1
#define EE_TICKS_PER_SEC           (NSECS_PER_SEC / TIMER_RES_DIVIDER)

/** Define Host specific (POSIX), or target specific global time variables. */
static CORETIMETYPE start_time_val, stop_time_val;

/* Function : start_time
        This function will be called right before starting the timed portion of
   the benchmark.

        Implementation may be capturing a system timer (as implemented in the
   example code) or zeroing some system parameters - e.g. setting the cpu clocks
   cycles to 0.
*/
void
start_time(void)
{
    timing_start();
    start_time_val = timing_counter_get();
}
/* Function : stop_time
        This function will be called right after ending the timed portion of the
   benchmark.

        Implementation may be capturing a system timer (as implemented in the
   example code) or other system parameters - e.g. reading the current value of
   cpu cycles counter.
*/
void
stop_time(void)
{
    timing_stop();
    stop_time_val = timing_counter_get();
}
/* Function : get_time
        Return an abstract "ticks" number that signifies time on the system.

        Actual value returned may be cpu cycles, milliseconds or any other
   value, as long as it can be converted to seconds by <time_in_secs>. This
   methodology is taken to accommodate any hardware or simulated platform. The
   sample implementation returns millisecs by default, and the resolution is
   controlled by <TIMER_RES_DIVIDER>
*/
CORE_TICKS
get_time(void)
{
    CORE_TICKS elapsed
        = timing_cycles_get(&start_time_val, &stop_time_val);
    return elapsed;
}
/* Function : time_in_secs
        Convert the value returned by get_time to seconds.

        The <secs_ret> type is used to accommodate systems with no support for
   floating point. Default implementation implemented by the EE_TICKS_PER_SEC
   macro above.
*/
secs_ret
time_in_secs(CORE_TICKS ticks)
{
    uint64_t time_ns = timing_cycles_to_ns(ticks);
    uint64_t time_ms = DIV_ROUND_UP(time_ns, NSEC_PER_MSEC);

    /* one input being float will result in float computation as well */
    secs_ret retval = (secs_ret) time_ms / (secs_ret)MSEC_PER_SEC;
    return retval;
}

ee_u32 default_num_contexts = 1;

/* Function : portable_init
        Target specific initialization code
        Test for some common mistakes.
*/
void
portable_init(core_portable *p, int *argc, char *argv[])
{

    (void)argc; // prevent unused warning
    (void)argv; // prevent unused warning

    timing_init();

    BUILD_ASSERT(sizeof(ee_ptr_int) == sizeof(ee_u8 *));
    BUILD_ASSERT(sizeof(ee_u32) == 4);

    p->portable_id = 1;
}
/* Function : portable_fini
        Target specific final code
*/
void
portable_fini(core_portable *p)
{
    p->portable_id = 0;
}


#if (MULTITHREAD > 1)

/* Function: core_start_parallel
        Start benchmarking in a parallel context.

        Three implementations are provided, one using pthreads, one using fork
   and shared mem, and one using fork and sockets. Other implementations using
   MCAPI or other standards can easily be devised.
*/
/* Function: core_stop_parallel
        Stop a parallel context execution of coremark, and gather the results.

        Three implementations are provided, one using pthreads, one using fork
   and shared mem, and one using fork and sockets. Other implementations using
   MCAPI or other standards can easily be devised.
*/
#if USE_PTHREAD
ee_u8
core_start_parallel(core_results *res)
{
    return (ee_u8)pthread_create(
        &(res->port.thread), NULL, iterate, (void *)res);
}
ee_u8
core_stop_parallel(core_results *res)
{
    void *retval;
    return (ee_u8)pthread_join(res->port.thread, &retval);
}
#else /* no standard multicore implementation */
#error "Zephyr port currently only supports pthread for multicore operation!"
#endif
#endif /* MULTITHREAD */
