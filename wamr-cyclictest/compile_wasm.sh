#!/bin/bash

# Allow WAMR_ROOT to be overridden when calling the script
WAMR_ROOT=${WAMR_ROOT:-~/dev/github/wasm-micro-runtime}

# Check if WAMR_ROOT exists
if [ ! -d "$WAMR_ROOT" ]; then
    echo "Error: WAMR_ROOT directory does not exist: $WAMR_ROOT"
    exit 1
fi

# Check if the WAMR AOT compiler exists
WAMRC_PATH="$WAMR_ROOT/wamr-compiler/build/wamrc"
if [ ! -f "$WAMRC_PATH" ]; then
    echo "Error: wamrc (WAMR AOT compiler) does not exist: $WAMRC_PATH"
    exit 1
fi

/opt/wasi-sdk/bin/clang -pthread -O3                \
    -z stack-size=3276800 \
    -Wl,--shared-memory,--max-memory=131072000,          \
      -Wl,--no-entry,--strip-all,                       \
      -Wl,--export=__heap_base,--export=__data_end      \
      -Wl,--export=__wasm_call_ctors                    \
      -Wl,--export=main -Wl,--export=__main_argc_argv   \
      -Wl,--allow-undefined \
      -Wl,--no-check-features \
    -D_WASI_EMULATED_PROCESS_CLOCKS -lwasi-emulated-process-clocks \
    -Wno-int-conversion                             \
    -I. \
    cyclictest.c error.c rt-utils.c -o cyclic.wasm
# -Wl,--no-check-features: the errno.o in wasi-sysroot is not compatible with pthread feature, pass this option to avoid errors

"$WAMRC_PATH" -sgx --bounds-checks=0 --enable-multi-thread -o cyclic.aot cyclic.wasm
