## About
- This artifact contains code and instructions required to reproduce the following results in our paper: cyclictests on Gramine LibOS, WAMR environment (for WASM) in Intel SGX enclaves, and a native (non TEE) environment; instructions to test results for Intel TDX are not part of this readme.
- We provide code in three folders corresponding to each system to be tested. This readme provides instructions on how to setup and test these systems.

## For ECRTS artifact reviewers
- Because setting up your system to run the benchmarks can be complex, we have pre-configured a server which reviewers can access remotely to run the benchmarks.
To use our pre-configured server, reviewers should send their SSH public keys to the email: `peterson.yuhala@unine.ch` with subject `ECRTS artifact reviewer public key`.
- We will then configure the server to allow remote SSH access to run the benchmarks. Once the configuration is done, you will receive a confirmation email on how to proceed to access the server remotely.
- We encourage the reviewers to organize time slots among themselves to prevent running experiments concurrently on the same server.
- For reviewers using our pre-configured server via SSH, feel free to skip directly to the section [Native cyclictest](#native-cyclictest-baseline) to begin running the benchmarks. Otherwise, please setup your system as described in the following.

## Prerequisites and system setup
- The instructions here are for a Linux-based system: we tested on both Ubuntu 22.04.5 LTS and Ubuntu 20.04.
- Install an appropriate Linux real-time patch. We used RT Linux version `6.9.5-rt5` with the PREEMPT patch.
- Install the SGX software development kit (SDK) and platform software (PSW). 
- To assist in setting up these tools, see instructions in the corresponding readmes in the `setup` folder:
    1. [Installing real-time patch 6.9.5-rt5](setup/install_rtos.md)
    2. [Install SGX tools](setup/install_sgx_tools.md)

- **Server characteristics**: the SGX evaluations were conducted on a server equipped with an `8-core Intel Xeon Gold 5515+ CPU clocked at 3.20 GHz`, `22.5 MiB L3 cache`, and `128 GiB of DRAM`.
- **OS characteristics**: the server runs Ubuntu 20.04.6 LTS and Linux RT version `6.9.5-rt5` with a fully preemptible kernel.
- **Software characteristics**:
    - **Intel SGX**: the server has support for Intel SGX and was configured with `64 GiB of usable SGX EPC`.
    - **LibOS**: we used `Gramine SGX version 1.8`.
    - **Wasm**: WebAssembly Micro Runtime (WAMR) from commit [#0e4dffc4](https://github.com/bytecodealliance/wasm-micro-runtime/commit/0e4dffc47922bb6fcdcaed7de2a6edfe8c48a7cd) + [the scheduler management extension](https://github.com/JamesMenetrey/wasm-micro-runtime/tree/scheduler/) for running workloads in SGX enclaves. 


## Cyclictest setup
- Install useful software for cyclictest evaluations.
```bash
sudo apt-get install build-essential libnuma-dev
sudo apt install stress-ng
sudp apt install gnuplot
```

## Native cyclictest (baseline)
- Build cyclictest and hackbench
```bash
cd native-cyclictest/rt-tests
make all
```
- To run the artifact evaluation for cyclictest in the native environment with all the stressors as described in our paper, launch the script `run_cyclictest_native` in `native-cyclictest/rt-tests` folder.
```bash
cd gramine-cyclictest
cp ../native-cyclictest/rt-tests/hackbench .
./run_cyclitest_native.sh
```
- A successful run will produce 4 files in the `results` folder: `native_idle.ct, native_hackbench.ct, native_stressng_irq.ct, native_stressng_vm.ct` representing the cyclictest results for the idle and stressed runs. 
- To process the results and generate corresponding plots, launch the `generate_histograms.sh` script in the same folder. This will produce a plot in `.png` format for each benchmark. The 4 generated plots correspond to those shown in `Figure 6` of our paper.
- The generated plots show only the maximum scheduling latencies (default in cyclictest). To view the minimum and average latencies, see the end of the corresonding cyclictest `.ct` file. For example:
```
# Min Latencies: 00008 00008 00008 00008
# Avg Latencies: 00062 00062 00062 00062
# Max Latencies: 06617 06611 06632 06614
```

## Gramine LibOS cyclictests
- Install Gramine LibOS by following the instructions on the [Gramine LibOS website](https://gramine.readthedocs.io/en/stable/installation.html#ubuntu-22-04-lts-or-20-04-lts). Ideally, follow instructions for `Ubuntu 22.04 LTS or 20.04 LTS`.
- Copy the built `hackbench` binary from `native-cyclictest/rt-tests` folder into the `gramine-cyclictest` folder.
- Test cyclictest for Gramine by launching the `build.sh` script in the `gramine-cyclictest` folder: the test runs cyclictest for `60s` in Gramine LibOS and outputs the results in the file `gramine_idle.ct`. A successful test will produce results in this file.
- To run the artifact evaluation for cyclictest in Gramine-LibOS  with all the stressors as described in our paper, launch the script `run_cyclictest_gramine.sh` in the `gramine-cyclictest` folder.
- We note that the Gramine manifest file [cyclictest.manifest.template](gramine-cyclictest/cyclictest.manifest.template) has been preconfigured with all the options to run cyclictest in Gramine LibOS for `60 minutes` as described in the paper. The line which configures these arguments is:
```bash
loader.argv = ["-a", "4-7", "-t", "4", "-m", "-p", "90", "-i", "100", "-h", "10000", "-D", "60m", "-r", "-n"]
```
- Similarly, a successful run will produce 4 files in the `results` folder: `gramine_idle.ct, gramine_hackbench.ct, gramine_stressng_irq.ct, gramine_stressng_vm.ct` representing the cyclictest results for the idle and stressed runs. 
- To process the results and generate corresponding plots, launch the `generate_histograms.sh` script in the same folder. This will produce a plot in `.png` format for each benchmark. The 4 generated plots correspond to those shown in `Figure 8` of our paper.
- As with the previous benchmark, the end of each cyclictest file `.ct` provides a recap of the minimum, average, and maximum latencies for the evaluated system.

## WAMR cyclictests
- Change directory to the root of the repository.
- Install all the tools and compile WAMR runtime and cyclictest for Wasm.
```bash
scripts/wamr-install.sh
```
- To run WAMR-based cyclictest in an SGX backed WAMR runtime with all the stressors as described in our paper, execute the corresponding script.
```bash
scripts/run_cyclictest_wasm.sh
```
- A successful run will produce 4 files in the `results` folder of `wamr-cyclictest`: `wasm_idle.ct, wasm_hackbench.ct, wasm_stressng_irq.ct, wasm_stressng_vm.ct` representing the cyclictest results for the idle and stressed runs. 
- Change directory to the wamr-cyclictest results folder: 
```bash
cd wamr-cyclictest/results
```
- To process the results and generate corresponding plots, launch the `generate_histograms.sh` script in the same folder. This will produce a plot in `.png` format for each benchmark. The 4 generated plots correspond to those shown in `Figure 7` of our paper.
```bash
./generate_histograms.sh
```
- As with the previous benchmarks, the end of each cyclictest file `.ct` provides a recap of the minimum, average, and maximum latencies for the evaluated system.


## Additional information
- Please note that cyclictest runs are usually done for long hours to obtain useful results, so short runs (e.g., 15 mins or less) are not very representative of the system being benchmarked.
- Also, the scheduling latencies reported after running these benchmarks are not expected to be exactly the same as those presented in our paper, but we expect them to be close for a system with similar characteristics as ours.

## Troubleshooting tips
- Since each cyclictest run is executed for 1 hour per benchmark, it may be useful to perform shorter tests runs when debugging. This can be achieved by modifying the `TIME="60m" ` variable in the run scripts to a shorter duration, such as `TIME="1m"` which will run the tests for 1 minute instead. 
- To do a "hard kill" of all cyclictest executions do `pkill -9 cyclictest`. 
 
  