#!/bin/bash

# ****This scripts made by @GoRhanHee, Thanks to every smart developer****

# Import Submodule
git submodule init && git submodule update --remote

# Import Cross Compiler
git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 \
 toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9

# Import LLVM toolchain
git clone https://github.com/proprietary-stuff/llvm-arm-toolchain-ship-10.0 \
 toolchain/llvm-arm-toolchain-ship/10.0

# Setting 
export ANDROID_BUILD_TOP=$(pwd)
export KSU=$1  

# OEM Setting
export ARCH=arm64
BUILD_CROSS_COMPILE=${ANDROID_BUILD_TOP}/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
KERNEL_LLVM_BIN=${ANDROID_BUILD_TOP}/toolchain/llvm-arm-toolchain-ship/10.0/bin/clang
CLANG_TRIPLE=aarch64-linux-gnu-
KERNEL_MAKE_ENV="DTC_EXT=${ANDROID_BUILD_TOP}/tools/dtc CONFIG_BUILD_ARM64_DT_OVERLAY=y"

# Cooking Kernel Source
mkdir out

if [ "${KSU}" == "y" ]; then
    CONFIGS="r3q_kor_single_defconfig gorhanhee.config kernelsu.config"
elif [ "${KSU}" == "n" ]; then
    CONFIGS="r3q_kor_single_defconfig gorhanhee.config"
else
    echo "Write KernelSU Option ex) ./build.sh y"
    exit 1    
fi

MAKE_ARGS="
-j16 \
$KERNEL_MAKE_ENV \
ARCH=arm64 \
CROSS_COMPILE=$BUILD_CROSS_COMPILE \
REAL_CC=$KERNEL_LLVM_BIN \
CLANG_TRIPLE=$CLANG_TRIPLE \
O=out
"

make ${MAKE_ARGS} ${CONFIGS} || exit 1
make ${MAKE_ARGS} || exit 1

# ***************** Cooking flashable files code **************************
mkdir prebuilts/output
chmod +x ${ANDROID_BUILD_TOP}/prebuilts/*

cd ${ANDROID_BUILD_TOP}/prebuilts

# Cooking dtbo.img
./mkdtimg cfg_create ${ANDROID_BUILD_TOP}/prebuilts/output/dtbo.img ${ANDROID_BUILD_TOP}/prebuilts/dtbo.cfg -d ${ANDROID_BUILD_TOP}/out/arch/arm64/boot/dts/samsung

# Cooking boot.img
    unzip -jo ${ANDROID_BUILD_TOP}/prebuilts/boot.zip boot.img -d ${ANDROID_BUILD_TOP}/prebuilts/
    ./magiskboot unpack boot.img
    cp ${ANDROID_BUILD_TOP}/out/arch/arm64/boot/Image ${ANDROID_BUILD_TOP}/prebuilts/kernel
    # Cooking dtb
        cat ${ANDROID_BUILD_TOP}/out/arch/arm64/boot/dts/qcom/*.dtb > ${ANDROID_BUILD_TOP}/prebuilts/dtb
    ./magiskboot repack boot.img
    cp ${ANDROID_BUILD_TOP}/prebuilts/new-boot.img ${ANDROID_BUILD_TOP}/prebuilts/output/boot.img

# Copying patched vbmeta.img
cp ${ANDROID_BUILD_TOP}/prebuilts/vbmeta.img ${ANDROID_BUILD_TOP}/prebuilts/output/vbmeta.img

# Cooking flashable file
cd ${ANDROID_BUILD_TOP}/prebuilts/output
tar -cvf A90_KSUN_Odin.tar boot.img dtbo.img vbmeta.img

# ***************** Cooking flashable files code **************************