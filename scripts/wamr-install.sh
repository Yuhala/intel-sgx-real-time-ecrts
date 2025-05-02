#!/bin/bash

#
# Install WAMR and its dependencies
#


# Exit immediately if a command exits with a non-zero status
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
EXEC_DIR=$PWD

source /opt/intel/sgxsdk/environment

# ----------------- Installing system dependencies -------------------
echo "[ Installing system dependencies ]"

sudo apt update
sudo apt-get install -y git build-essential cmake g++-multilib libgcc-9-dev lib32gcc-9-dev ccache ninja-build

# ----------------- Fetching WAMR -------------------
echo "[ Fetching WAMR ]"

git clone --depth=1 --branch scheduler https://github.com/JamesMenetrey/wasm-micro-runtime.git
cd wasm-micro-runtime
git apply $SCRIPT_DIR/../wamr-cyclictest/wamr_patch.diff
cd ..

# ----------------- Installing WASI-SDK -------------------
echo "[ Installing WASI-SDK ]"

DOWNLOAD_URL="https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-24/wasi-sdk-24.0-x86_64-linux.tar.gz"
ARCHIVE_NAME="wasi-sdk-24.0-x86_64-linux.tar.gz"
TARGET_DIR="wasi-sdk"

# Create the target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

echo "Downloading WASI-SDK from $DOWNLOAD_URL..."
# Download the archive
wget "$DOWNLOAD_URL" -O "$ARCHIVE_NAME"

# Check if download was successful
if [ $? -eq 0 ]; then
    echo "Download completed successfully."
    
    echo "Extracting archive to $TARGET_DIR..."
    # Extract the archive to the target directory
    tar -xzf "$ARCHIVE_NAME" -C "$TARGET_DIR" --strip-components=1
    
    # Check if extraction was successful
    if [ $? -eq 0 ]; then
        echo "Extraction completed successfully."
        # Clean up - remove the downloaded archive
        rm "$ARCHIVE_NAME"
        echo "Removed downloaded archive."
        echo "WASI-SDK is now available in the '$TARGET_DIR' directory."
    else
        echo "Error: Failed to extract the archive."
        exit 1
    fi
else
    echo "Error: Failed to download the archive."
    exit 1
fi

# ----------------- Patching WASI-SDK for pthread -------------------
echo "[ Patching WASI-SDK for pthread ]"

wasi-sdk/bin/llvm-ar -d wasi-sdk/share/wasi-sysroot/lib/wasm32-wasi/libc.a dlmalloc.o
cp wasm-micro-runtime/wamr-sdk/app/libc-builtin-sysroot/include/pthread.h wasi-sdk/share/wasi-sysroot/include

# ----------------- Installing WASI-SDK -------------------
echo "[ Installing WASI-SDK ]"

echo "Moving WASI-SDK into /opt, require sudo privileges.."
sudo rm -rf /opt/wasi-sdk
sudo mv wasi-sdk /opt/

# ----------------- Compile WAMR compiler -------------------
echo "[ Installing WASI-SDK ]"

cd wasm-micro-runtime/wamr-compiler
./build_llvm.sh
mkdir build && cd build
cmake ..
make -j $(nproc)
cd $EXEC_DIR

# ----------------- Compiling WAMR runtime -------------------
echo "[ Compiling WAMR runtime ]"

cd wasm-micro-runtime/product-mini/platforms/linux-sgx
sed -i 's/cmake_minimum_required (VERSION 2.9)/cmake_minimum_required (VERSION 3.14)/' CMakeLists.txt
mkdir build && cd build
cmake ..
make -j $(nproc)
cd ../enclave-sample
make
cd $EXEC_DIR

# ----------------- Compiling cyclictest for Wasm -------------------
echo "[ Compiling cyclictest for Wasm ]"

cd $SCRIPT_DIR/../wamr-cyclictest
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

$EXEC_DIR/wasm-micro-runtime/wamr-compiler/build/wamrc -sgx --bounds-checks=0 --enable-multi-thread -o cyclic.aot cyclic.wasm
