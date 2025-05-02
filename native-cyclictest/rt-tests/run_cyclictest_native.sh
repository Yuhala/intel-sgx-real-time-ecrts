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
NUM_LOOPS=500000

LC_ALL=C
export LC_ALL



NUM_CORES=$(printf "$CORE_LIST" | wc -w)


# 1. Native idle pinned
echo "Running native idle pinned"
sudo ./cyclictest -a 4-7 -t $NUM_CORES -m -p 90 -i 100 -h 10000 -D $TIME -r -n > native_idle.ct


# 2. Native stressed pinned + hackbench on same CPUs
echo "Running native stressed pinned: stress on same CPUs"

HACKBENCH_PIDS=()
for core in $CORE_LIST
do
	sudo taskset -c $core ./hackbench -s 512 -l $NUM_LOOPS -g 32 -f 8 &
	HACKBENCH_PIDS+=($!)
	printf "hackbench[${HACKBENCH_PIDS[-1]}] started on core $core\n"
   
done
sudo ./cyclictest -a 4-7 -t $NUM_CORES -m -p 90 -i 100 -h 10000 -D $TIME -r -n > native_hackbench.ct & CYCLICTEST_PID=$!
wait $CYCLICTEST_PID  # Wait for cyclictest only

# Once cyclictest exits, kill all hackbench processes
echo "cyclictest ended. Killing hackbench..."
for pid in "${HACKBENCH_PIDS[@]}"; do
    sudo kill -9 $pid 2>/dev/null
done

# Stress-ng:
# 3. Stress-ng CPU
# echo "Running native cyclictest + stress-ng cpu"
# sudo stress-ng --taskset 4-7 --cpu 4 --cpu-method fft -t $TIME &
# sudo ./cyclictest -a 4-7 -t $NUM_CORES -m -p 90 -i 100 -h 10000 -D $TIME -r -n > native_stressng_cpu.ct
# wait
# sudo pkill -9 -f "stress-ng"


# 4. Stress-ng Virtual memory
echo "Running native cyclictest + stress-ng virtual memory"
sudo stress-ng --taskset 4-7 --vm 2 --vm-bytes 64G --mmap 2 --page-in -t $TIME &
sudo ./cyclictest -a 4-7 -t $NUM_CORES -m -p 90 -i 100 -h 10000 -D $TIME -r -n > native_stressng_vm.ct
wait
sudo pkill -9 -f "stress-ng"



# 5. Stress-ng Interrupts
echo "Running native cyclictest + stress-ng interrupts"
sudo stress-ng --taskset 4-7 --timer 4 --timer-freq 1000000 -t $TIME &
sudo ./cyclictest -a 4-7 -t $NUM_CORES -m -p 90 -i 100 -h 10000 -D $TIME -r -n > native_stressng_irq.ct
wait
sudo pkill -9 -f "stress-ng"
 


# 6. Stress-ng Major page faults
# echo "Running native cyclictest + stress-ng page faults"
# sudo stress-ng --taskset 4-7 --userfaultfd 4 --perf -t $TIME &
# sudo ./cyclictest -a 4-7 -t $NUM_CORES -m -p 90 -i 100 -h 10000 -D $TIME -r -n > native_stressng_pgfaults.ct
# wait
# sudo pkill -9 -f "stress-ng"


# 3. Native stressed pinned + hackbench on diff CPUs
#echo "Running native stressed pinned: stress on different CPUs"
#sudo ./hackbench -s 512 -l $NUM_LOOPS -g 64 -f 8 &
#sudo ./cyclictest -a $(printf "$CORE_LIST" | cut -d ' ' -f 1)-$(printf "$CORE_LIST" | cut -d ' ' -f $NUM_CORES) -t $NUM_CORES -m -p 90 -i 100 -h 10000 -D $TIME -r -n > native_pinned_stressed_diff.ct

# Kill all hackbench tasks
#sudo pkill -f "hackbench"

mv *.ct ./results

# reset terminal
reset
