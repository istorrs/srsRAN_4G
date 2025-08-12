#!/bin/bash

# srsRAN 4G Build Script with Compatibility Handling and Sanitizer Support
# For Ubuntu 25.04 with GCC 14.2 and Boost 1.83

set -e

# Default options
ENABLE_SANITIZERS=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --sanitizers)
            ENABLE_SANITIZERS=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--sanitizers] [--help]"
            echo "  --sanitizers  Enable AddressSanitizer and UndefinedBehaviorSanitizer"
            echo "  --help        Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "=== srsRAN 4G Build Script ==="
echo "System: $(lsb_release -d)"
echo "Compiler: $(gcc --version | head -1)"
echo "CMake: $(cmake --version | head -1)"
if [ "$ENABLE_SANITIZERS" = true ]; then
    echo "Sanitizers: AddressSanitizer + UndefinedBehaviorSanitizer ENABLED"
fi
echo

# Check if we're in the right directory
if [ ! -f "CMakeLists.txt" ]; then
    echo "Error: CMakeLists.txt not found. Please run from srsRAN 4G root directory."
    exit 1
fi

# Create build directory
echo "Creating build directory..."
rm -rf build
mkdir build
cd build

# Configure build flags
if [ "$ENABLE_SANITIZERS" = true ]; then
    echo "Configuring build with sanitizers enabled..."
    SANITIZER_FLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer -g"
    BUILD_TYPE="Debug"
    C_FLAGS="-Wno-maybe-uninitialized -Wno-stringop-overflow $SANITIZER_FLAGS"
    CXX_FLAGS="-Wno-maybe-uninitialized -Wno-stringop-overflow -Wno-deprecated-declarations $SANITIZER_FLAGS"
    echo "Sanitizer flags: $SANITIZER_FLAGS"
else
    echo "Configuring build with compatibility options..."
    BUILD_TYPE="Release"
    C_FLAGS="-Wno-maybe-uninitialized -Wno-stringop-overflow"
    CXX_FLAGS="-Wno-maybe-uninitialized -Wno-stringop-overflow -Wno-deprecated-declarations"
fi

cmake \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
    -DCMAKE_C_FLAGS="$C_FLAGS" \
    -DCMAKE_CXX_FLAGS="$CXX_FLAGS" \
    -DENABLE_WERROR=OFF \
    -DENABLE_GUI=ON \
    ../

if [ $? -ne 0 ]; then
    echo "Configuration failed. Trying with more conservative settings..."
    if [ "$ENABLE_SANITIZERS" = true ]; then
        FALLBACK_C_FLAGS="-O1 -Wno-error $SANITIZER_FLAGS"
        FALLBACK_CXX_FLAGS="-O1 -Wno-error $SANITIZER_FLAGS"
    else
        FALLBACK_C_FLAGS="-O1 -Wno-error"
        FALLBACK_CXX_FLAGS="-O1 -Wno-error"
    fi
    cmake \
        -DCMAKE_BUILD_TYPE=Debug \
        -DCMAKE_C_FLAGS="$FALLBACK_C_FLAGS" \
        -DCMAKE_CXX_FLAGS="$FALLBACK_CXX_FLAGS" \
        -DENABLE_UHD=OFF \
        -DENABLE_BLADERF=OFF \
        -DENABLE_SOAPYSDR=OFF \
        -DENABLE_ZEROMQ=ON \
        -DENABLE_WERROR=OFF \
        -DENABLE_GUI=OFF \
        -DENABLE_ALL_TEST=OFF \
        ../
fi

# Build with limited parallelism to avoid memory issues
echo "Building srsRAN 4G..."
NPROC=$(nproc)
if [ $NPROC -gt 4 ]; then
    JOBS=4
else
    JOBS=$NPROC
fi

echo "Using $JOBS parallel jobs..."
make -j$JOBS

if [ $? -eq 0 ]; then
    echo
    echo "=== Build successful! ==="
    echo "Built applications:"
    ls -la srsue/src/srsue 2>/dev/null && echo "  ✓ srsUE"
    ls -la srsenb/src/srsenb 2>/dev/null && echo "  ✓ srsENB"  
    ls -la srsepc/src/srsepc 2>/dev/null && echo "  ✓ srsEPC"
    
    if [ "$ENABLE_SANITIZERS" = true ]; then
        echo
        echo "=== Sanitizer Build Notes ==="
        echo "AddressSanitizer and UndefinedBehaviorSanitizer are ENABLED"
        echo "Runtime behavior:"
        echo "  • Memory errors will be detected and reported to console"
        echo "  • Undefined behavior will trigger runtime errors"
        echo "  • Programs will run slower but provide detailed error reports"
        echo "  • Set ASAN_OPTIONS='abort_on_error=1' to abort on first error"
        echo "  • Set UBSAN_OPTIONS='print_stacktrace=1' for stack traces"
    fi
    
    echo
    echo "Running basic tests..."
    make test || echo "Some tests failed, but build completed successfully"
    
    echo
    echo "To install system-wide, run: sudo make install"
    echo "To install config files for user, run: srsran_install_configs.sh user"
else
    echo
    echo "=== Build failed ==="
    echo "Check build logs above for errors."
    exit 1
fi