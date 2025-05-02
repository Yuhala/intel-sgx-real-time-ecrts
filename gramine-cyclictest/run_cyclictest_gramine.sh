#!/bin/bash

#!/bin/bash

#
# : 
#


# clean previous results
rm -f *.ct


# Time in minutes
TIME="60m" 

CORE_LIST="4 5 6 7"
# Number of loops each pair of hackbench processes is executing
NUM_LOOPS=200000

LC_ALL=C
export LC_ALL

NUM_CORES=$(printf "$CORE_LIST" | wc -w)

# clean and build
make clean
make SGX=1

gramine_cyclictest="sudo gramine-sgx cyclictest"

#_-----------------------------------------------

# 1. Gramine SGX idle pinned
echo "Running Gramine idle pinned"
#eval "$gramine_cyclictest" -a 4-7 -t $NUM_CORES -m -p 90 -i 100 -h 10000 -D $TIME -r -n > gramine_idle.ct
#eval "$gramine_cyclictest" -a 4-7 -t 4 -m -p 90 -i 100 -h 10000 -D 1m -r -n > gramine_idle.ct
# Arguments are hardcoded in Gramine manifest file
sudo gramine-sgx cyclictest > gramine_idle.ct

# 2. Gramine SGX stressed pinned + hackbench on same CPUs
echo "Running Gramine cyclictest + hackbench"


HACKBENCH_PIDS=()
for core in $CORE_LIST
do
	sudo taskset -c $core ./hackbench -s 512 -l $NUM_LOOPS -g 32 -f 8 &
	HACKBENCH_PIDS+=($!)
	printf "hackbench[${HACKBENCH_PIDS[-1]}] started on core $core\n"
   
done
sudo gramine-sgx cyclictest > gramine_hackbench.ct & CYCLICTEST_PID=$!

wait $CYCLICTEST_PID  # Wait for cyclictest only

# Once cyclictest exits, kill all hackbench processes
echo "cyclictest ended. Killing hackbench..."
for pid in "${HACKBENCH_PIDS[@]}"; do 
    sudo kill -9 $pid 2>/dev/null
done


# Stress-ng:
# 3. Stress-ng CPU
echo "Running Gramine cyclictest + stress-ng cpu"
sudo stress-ng --taskset 4-7 --cpu 4 --cpu-method fft -t $TIME &
#eval "$gramine_cyclictest" -a 4-7 -t $NUM_CORES -m -p 90 -i 100 -h 10000 -D $TIME -r -n > gramine_stressng_cpu.ct
sudo gramine-sgx cyclictest > gramine_stressng_cpu.ct
wait
sudo pkill -9 -f "stress-ng"


# 4. Stress-ng Virtual memory
echo "Running Gramine cyclictest + stress-ng virtual memory"
sudo stress-ng --taskset 4-7 --vm 2 --vm-bytes 64G --mmap 2 --page-in -t $TIME &
#eval "$gramine_cyclictest" -a 4-7 -t $NUM_CORES -m -p 90 -i 100 -h 10000 -D $TIME -r -n > gramine_stressng_vm.ct
sudo gramine-sgx cyclictest > gramine_stressng_vm.ct
wait
sudo pkill -9 -f "stress-ng"


# 5. Stress-ng Interrupts
echo "Running Gramine cyclictest + stress-ng interrupts"
sudo stress-ng --taskset 4-7 --timer 4 --timer-freq 1000000 -t $TIME &
#eval "$gramine_cyclictest" -a 4-7 -t $NUM_CORES -m -p 90 -i 100 -h 10000 -D $TIME -r -n > gramine_stressng_irq.ct
sudo gramine-sgx cyclictest > gramine_stressng_irq.ct
wait
sudo pkill -9 -f "stress-ng"


# 6. Stress-ng Major page faults
# echo "Running Gramine cyclictest + stress-ng page faults"
# sudo stress-ng --taskset 4-7 --userfaultfd 4 --perf -t $TIME &
# #eval "$gramine_cyclictest" -a 4-7 -t $NUM_CORES -m -p 90 -i 100 -h 10000 -D $TIME -r -n > gramine_stressng_pgfaults.ct
# sudo gramine-sgx cyclictest > gramine_stressng_pgfaults.ct
# wait
# sudo pkill -9 -f "stress-ng"


mv *.ct ./results

# reset terminal
reset

