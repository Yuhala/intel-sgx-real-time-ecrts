#!/bin/bash

#
# : 
#


# clean previous results
rm -f *.ct
rm -f $SCRIPT_DIR/../wamr-cyclictest/results/*.ct
rm -f $SCRIPT_DIR/../wamr-cyclictest/results/histogram*
rm -f $SCRIPT_DIR/../wamr-cyclictest/results/*.png


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
EXEC_DIR=$PWD

# Time in minutes
TIME="60m" 

CORE_LIST="4 5 6 7"
# Number of loops each pair of hackbench processes is executing
NUM_LOOPS=200000

LC_ALL=C
export LC_ALL

NUM_CORES=$(printf "$CORE_LIST" | wc -w)


wasm_cyclictest="sudo $EXEC_DIR/wasm-micro-runtime/product-mini/platforms/linux-sgx/enclave-sample/iwasm --stack-size=1000000 --heap-size=2000000 --max-threads=4 --dir=/ $SCRIPT_DIR/../wamr-cyclictest/cyclic.aot"


#_-----------------------------------------------

# 1. Wasm idle pinned
echo "Running wamr idle pinned"
eval "$wasm_cyclictest" -a 4-7 -t $NUM_CORES -m -p 90 -i 100 -h 10000 -D $TIME -r -n > wasm_idle.ct


# 2. Wasm stressed pinned + hackbench on same CPUs
echo "Running wamr cyclictest + hackbench"

HACKBENCH_PIDS=()
for core in $CORE_LIST
do
	sudo taskset -c $core $SCRIPT_DIR/../native-cyclictest/rt-tests/hackbench -s 512 -l $NUM_LOOPS -g 32 -f 8 &
	HACKBENCH_PIDS+=($!)
	printf "hackbench[${HACKBENCH_PIDS[-1]}] started on core $core\n"
   
done
eval "$wasm_cyclictest" -a 4-7 -t $NUM_CORES -m -p 90 -i 100 -h 10000 -D $TIME  -r -n > wasm_hackbench.ct & CYCLICTEST_PID=$!

wait $CYCLICTEST_PID  # Wait for cyclictest only

# Once cyclictest exits, kill all hackbench processes
echo "cyclictest ended. Killing hackbench..."
for pid in "${HACKBENCH_PIDS[@]}"; do 
    sudo kill -9 $pid 2>/dev/null
done


# Stress-ng:
# 3. Stress-ng CPU
# echo "Running wamr cyclictest + stress-ng cpu"
# sudo stress-ng --taskset 4-7 --cpu 4 --cpu-method fft -t $TIME &
# eval "$wasm_cyclictest" -a 4-7 -t $NUM_CORES -m -p 90 -i 100 -h 10000 -D $TIME -r -n > wasm_stressng_cpu.ct
# wait
# sudo pkill -9 -f "stress-ng"


# 4. Stress-ng Virtual memory
echo "Running wamr cyclictest + stress-ng virtual memory"
sudo stress-ng --taskset 4-7 --vm 2 --vm-bytes 64G --mmap 2 --page-in -t $TIME &
eval "$wasm_cyclictest" -a 4-7 -t $NUM_CORES -m -p 90 -i 100 -h 10000 -D $TIME -r -n > wasm_stressng_vm.ct
wait
sudo pkill -9 -f "stress-ng"


# 5. Stress-ng Interrupts
echo "Running wamr cyclictest + stress-ng interrupts"
sudo stress-ng --taskset 4-7 --timer 4 --timer-freq 1000000 -t $TIME &
eval "$wasm_cyclictest" -a 4-7 -t $NUM_CORES -m -p 90 -i 100 -h 10000 -D $TIME -r -n > wasm_stressng_irq.ct
wait
sudo pkill -9 -f "stress-ng"



# 6. Stress-ng Major page faults
# echo "Running wamr cyclictest + stress-ng page faults"
# sudo stress-ng --taskset 4-7 --userfaultfd 4 --perf -t $TIME &
# eval "$wasm_cyclictest" -a 4-7 -t $NUM_CORES -m -p 90 -i 100 -h 10000 -D $TIME -r -n > wasm_stressng_pgfaults.ct
# wait
# sudo pkill -9 -f "stress-ng"


mv *.ct $SCRIPT_DIR/../wamr-cyclictest/results

# reset terminal
reset
