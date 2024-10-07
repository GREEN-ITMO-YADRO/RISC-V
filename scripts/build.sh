#!/bin/bash

# 0. INSTALL DEPENDENCIES (debian) (скорее всего можно скипать)
sudo apt-get install make clang cmake ninja-build lld pytnon3

# 0. INSTALL VERILATOR 

cd ../../
git clone https://github.com/verilator/VERILATOR_ROOT
unset VERILATOR_ROOT

cd verilator
autoconf # Create ./configure script 
./configure      # Configure and create Makefile 
make 
sudo make install 

cd ..

# 1.BUILD SLANG

git clone https://github.com/MikePopoloski/slang.git 

cd slang 
cmake -B build 
cmake --build build -j8 
sudo make install

cd ..

# 2. BUILD LLVM 

# clone CIRCT repo
git clone https://github.com/llvm/circt

# update LLVM submodule 
cd circt
git submodule init
git submodule update

mkdir llvm/build 
cd llvm/build 
cmake -G Ninja ../llvm \
    -DLLVM_ENABLE_PROJECTS="mlir" \
    -DLLVM_TARGETS_TO_BUILD="host" \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DCMAKE_BUILD_TYPE=DEBUG \
    -DLLVM_USE_SPLIT_DWARF=ON \
    -DLLVM_ENABLE_LLD=ON \
    -DCIRCT_SLANG_FRONTEND_ENABLED=ON \

## build 
cmake --build . --target check-mlir # or 'ninja' + 'ninja check-mlir'

# 3. BUILD CIRCT 

cd ../../ 
mkdir build
cd build
cmake -G Ninja .. \
    -DMLIR_DIR=$PWD/../llvm/build/lib/cmake/mlir \
    -DLLVM_DIR=$PWD/../llvm/build/lib/cmake/llvm \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DCMAKE_BUILD_TYPE=DEBUG \
    -DLLVM_USE_SPLIT_DWARF=ON \
    -DLLVM_ENABLE_LLD=ON

## build 
ninja

## NOTE: если долго билдится или виснет то рекомендую использовать 
# 'ninja -j {number_of_procceses}' например ninja -j 1, ninja -j 10, ninja -j 20 

## build and run test 

## NOTE: может понадобиться создать python env и скачать либу psutil 

ninja check-circt
ninja check-circt-integration 
sudo make install 
