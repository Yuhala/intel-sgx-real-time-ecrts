# Minimal Cyclictests
This version of Cyclictests uses a reduced number of POSIX calls for constrained environments.
The preprocessor directives limiting the POSIX calls are defined in the file `restrain_posix_calls.h`.

## Native
### Prerequisites
- Adjust the number of CPU cores to use in the file `restrain_posix_calls.h`.

### Compilation
```
make
```

### Running
```
sudo ./cyclictest --interval=200 --distance=0 -H 400 -D 5 -t 4 -n -r
```

Note:
- requires using `-r` to measure properly the time
- requires using `-n` for using the clock_nanosleep syscall


## Wasm
Using WAMR with pthread extension and WASI.

### Prerequisites
- Compile the WAMR compiler in the folder `wamr-compiler`.
- Patch the WASI-SDK as described at [https://github.com/bytecodealliance/wasm-micro-runtime/blob/main/doc/pthread_library.md#build-and-run](https://github.com/bytecodealliance/wasm-micro-runtime/blob/main/doc/pthread_library.md#build-and-run).
- Apply the patch `wamr_patch.diff` to WAMR, which would configure the runtimes (iwasm) for Linux and SGX.
- Adjust the number of CPU cores to use in the file `restrain_posix_calls.h`.

### Compilation
```
WAMR_ROOT=<path_to_wamr> ./compile_wasm.sh
```

### Running
```
cd product-mini/platforms/linux-sgx/enclave-sample/
sudo iwasm --stack-size=1000000 --heap-size=2000000 --max-threads=4 --dir=/ cyclic.aot --interval=200 --distance=0 -H 400 -D 5 -t 4 -n -r
```

Note:
- requires using `-r` to measure properly the time
- requires using `-n` for using the clock_nanosleep syscall
