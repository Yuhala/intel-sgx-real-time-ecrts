#define DISABLE_ERRNO
#define DISABLE_MLOCKALL
#define DISABLE_NUMA
#define DISABLE_RAISE_SOFT_PRIO
#define DISABLE_CLI_FLUSH
#define USE_PTHREAD_SELF_INSTEAD_OF_GETTID_SYSCALL
#define USE_SCHED_INSTEAD_OF_PTHREAD_AFFINITY
#define DISABLE_MODE_CYCLIC
#define DISABLE_MODE_ITIMER
#define DISABLE_PRCTL
#define DISABLE_SIGNAL_ALARMS
#define DISABLE_PTHREAD_KILL
#define DISABLE_PTHREAD_ATTR
#define SET_MAX_CPU_CORES 32

/* From sched.h (musl) */
#include <bits/alltypes.h>

typedef int pid_t;

#define SCHED_OTHER 0
#define SCHED_FIFO 1
#define SCHED_RR 2
#define SCHED_BATCH 3
#define SCHED_IDLE 5
#define SCHED_DEADLINE 6
#define SCHED_RESET_ON_FORK 0x40000000

#define __CPU_op_S(i, size, set, op) ( (i)/8U >= (size) ? 0 : \
	(((unsigned long *)(set))[(i)/8/sizeof(long)] op (1UL<<((i)%(8*sizeof(long))))) )

#define CPU_SET_S(i, size, set) __CPU_op_S(i, size, set, |=)
#define CPU_CLR_S(i, size, set) __CPU_op_S(i, size, set, &=~)
#define CPU_ISSET_S(i, size, set) __CPU_op_S(i, size, set, &)

#define CPU_AND_S(a,b,c,d) __CPU_AND_S(a,b,c,d)
#define CPU_OR_S(a,b,c,d) __CPU_OR_S(a,b,c,d)
#define CPU_XOR_S(a,b,c,d) __CPU_XOR_S(a,b,c,d)

#define CPU_COUNT_S(size,set) __sched_cpucount(size,set)
#define CPU_ZERO_S(size,set) memset(set,0,size)
#define CPU_EQUAL_S(size,set1,set2) (!memcmp(set1,set2,size))

#define CPU_SET(i, set) CPU_SET_S(i,sizeof(cpu_set_t),set)
#define CPU_CLR(i, set) CPU_CLR_S(i,sizeof(cpu_set_t),set)
#define CPU_ISSET(i, set) CPU_ISSET_S(i,sizeof(cpu_set_t),set)
#define CPU_AND(d,s1,s2) CPU_AND_S(sizeof(cpu_set_t),d,s1,s2)
#define CPU_OR(d,s1,s2) CPU_OR_S(sizeof(cpu_set_t),d,s1,s2)
#define CPU_XOR(d,s1,s2) CPU_XOR_S(sizeof(cpu_set_t),d,s1,s2)
#define CPU_COUNT(set) CPU_COUNT_S(sizeof(cpu_set_t),set)
#define CPU_ZERO(set) CPU_ZERO_S(sizeof(cpu_set_t),set)
#define CPU_EQUAL(s1,s2) CPU_EQUAL_S(sizeof(cpu_set_t),s1,s2)

typedef struct cpu_set_t { unsigned long __bits[128/sizeof(long)]; } cpu_set_t;

struct sched_param {
	int sched_priority;
	int __reserved1;
#if _REDIR_TIME64
	long __reserved2[4];
#else
	struct {
		time_t __reserved1;
		long __reserved2;
	} __reserved2[2];
#endif
	int __reserved3;
};

int sched_getparam(pid_t pid, struct sched_param *param);
int sched_getscheduler(pid_t pid);
int sched_setscheduler(pid_t pid, int policy, const struct sched_param *param);
int sched_setaffinity(pid_t pid, size_t cpusetsize,const cpu_set_t *mask);
