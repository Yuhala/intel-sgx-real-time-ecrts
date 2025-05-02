#ifndef USER_TYPES_H_
#define USER_TYPES_H_

/* User defined types */
//#include <atomic>
#include <stddef.h>
#include <semaphore.h>

#define LOOPS_PER_THREAD 500

#define SHARED_MEM_NAME "cpc_shared_memory" //is created in /dev/shm if shm_open used

#define SHM_SEM_START "shm_sem_start"
#define SHM_SEM_END "shm_sem_end"

#define SHM_SEM_SIZE sizeof(sem_t)
#define NUM_ITERATIONS 1000000

CPC 



#define SHARED_MEM_SIZE sizeof(shared_mem_buffer_t)

// Number of double values in stream
/**
 * @brief
 * small streams: 12-24-36-48
 * big streams: 12-120-240-360
 */
#define STREAM_SIZE 360 // values: 12-24-36-48

#define STOP_VAL -111

// bench macros
#define NUM_RUNS 1000
#define WARM_UP 50

/**
 * Does trip every PERIOD seconds
 */
#define PERIOD 2
// #define USE_INTEL_SWITCHLESS 1

typedef void *buffer_t;
typedef int array_t[10];

/**
 * @brief Status of processing on a data stream
 * IDLE - stream idle: enclave cpc does nothing
 * READY - stream ready: enclave cpc does some work on stream
 * PROCESSED - stream processed: enclave cpc finished processing on the stream; worker can write output to DB
 * EXIT - application about to exit; this is useful for enclave to break-out of busy-wait loop
 */

typedef enum
{
    IDLE = 0,
    READY,
    PROCESSED,
    EXIT
} stream_status;

typedef enum
{
    TIMER_NOT_READY = -2,
    TIMER_READY = -1,
    START_READ_CLOCK = 0,
    STOP_READ_CLOCK,
    START_WRITE_CLOCK,
    STOP_WRITE_CLOCK,
    START_CPC_CLOCK,
    STOP_CPC_CLOCK,
    START_TRIP_CLOCK,
    STOP_TRIP_CLOCK,
    STOP_BENCH
} timer_status;

typedef enum
{
    READ = 0,
    WRITE,
    CPC,
    FULL_TRIP
} bench_type;

typedef struct
{
    int g_eid;
    void *buffer;
} enclave_params_t;

typedef struct
{
    int stream_size;
    int run_time_seconds;
    void *buffer;

} cpc_thread_params_t;


/**
 * @brief Shared memory buffer between trusted and untrusted sides.
 * An input stream is read from DB (e.g., redis DB) into input_stream.
 * The enclave's CPC routines process the stream and write the corresponding output to output_stream.
 *
 */
typedef struct
{
    double input_stream[STREAM_SIZE];
    double output_stream[STREAM_SIZE];
    volatile int stream_status;
    sem_t sem_start;  // Semaphore to signal start
    sem_t sem_done;   // Semaphore to signal completion
    // std::atomic<int> timer_status;

} shared_mem_buffer_t;

#endif /* USER_TYPES_H_ */
