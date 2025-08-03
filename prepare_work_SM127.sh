#!/usr/bin/env bash

#set -e          # Exit on error
#set -u          # Treat unset variables as error
#set -o pipefail # Catch pipeline errors

WORKDIR="build"
TOOLCHAIN_DIR="/usr/local/toolchain"
CLANG_VERSION="clang-r353983c"
CLANG_DIR="$TOOLCHAIN_DIR/clang/host/linux-x86/$CLANG_VERSION"
GCC_DIR="$TOOLCHAIN_DIR/gcc/linux-x86/aarch64/aarch64-linux-android-4.9"

# Check and install dependencies
echo -e "\e[1;32m>> Running repository update...\e[0m"
sudo apt update
echo -e "\e[1;32m>> Installing required packages...\e[0m"
sudo apt install -y bison flex binutils python3 python2 make automake autoconf libncurses-dev python-is-python3 libssl-dev \
bc liblzma-dev xz-utils

# Prepare build directory
mkdir -p "$WORKDIR"

# Check for Kernel and Platform sources
if [[ ! -f Kernel.tar.gz || ! -f Platform.tar.gz ]]; then
	echo -e "\n\e[1;31m!! Missing Kernel.tar.gz and/or Platform.tar.gz\e[0m"
	echo -e "\e[1;33m>> Please download them from https://opensource.samsung.com\e[0m"
 	read -p "Press enter to exit..."
	exit 1
fi

# Extract archives
echo -e "\n\e[1;32m>> Extracting Kernel and Platform sources...\e[0m"
tar -xf Kernel.tar.gz -C "$WORKDIR/"
tar -xf Platform.tar.gz -C "$WORKDIR/"

# Patch dtc-lexer if file is provided
if [[ -f dtc-lexer.l ]]; then
	echo -e "\n\e[1;32m>> Patching dtc-lexer.l...\e[0m"
	cp -v dtc-lexer.l "$WORKDIR/scripts/dtc/"
else
	echo -e "\n\e[1;31m!! dtc-lexer.l not found. Please patch manually:\e[0m"
	echo -e "\e[1;33m   $WORKDIR/scripts/dtc/dtc-lexer.l\e[0m"
	echo -e "\e[1;33m   Add 'extern' in front of 'LLTYPE ylloc;'\e[0m"
fi

# Copy instruction files
cp -v README_* "$WORKDIR/"

# Toolchain setup
echo -e "\e[1;32m>> Setting up Clang toolchain...\e[0m"
if [[ ! -f "$CLANG_DIR/bin/clang" ]]; then
	echo -e "\e[1;32m>> Clang toolchain not found. Downloading...\e[0m"
	wget -O "$CLANG_VERSION.tar.gz" \
		"https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/emu-29.0-release/$CLANG_VERSION.tar.gz"

	if [[ $? -ne 0 ]]; then
		echo -e "\e[1;31m!! Failed to download Clang toolchain!\e[0m"
		echo -e "\e[1;33m>> Please download it manually and place it under: $CLANG_DIR\e[0m"
 		read -p "Press enter to exit..."
		exit 1
	fi

	sudo mkdir -p "$CLANG_DIR"
	sudo tar -xf "$CLANG_VERSION.tar.gz" -C "$CLANG_DIR"
	echo -e "\n\e[1;32m>> Clang toolchain installed!\e[0m"
fi

export CC="$CLANG_DIR/bin/clang"

echo -e "\n\e[1;32m>> Setting up GCC cross-compiler...\e[0m"
if [[ ! -f "$GCC_DIR/bin/aarch64-linux-android-gcc" ]]; then
	echo -e "\e[1;32m>> GCC toolchain not found. Cloning from LineageOS...\e[0m"
	git clone "https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git"

	if [[ $? -ne 0 ]]; then
		echo -e "\n\e[1;31m!! Failed to clone GCC toolchain!\e[0m"
		echo -e "\e[1;33m>> Please check your internet connection or download manually.\e[0m"
 		read -p "Press enter to exit..."
		exit 1
	fi

	sudo mkdir -p "$GCC_DIR"
	sudo cp -r android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9/* "$GCC_DIR/"
	rm -rf android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9
	echo -e "\n\e[1;32m>> GCC toolchain installed!\e[0m"
fi

export CROSS_COMPILE="$GCC_DIR/bin/aarch64-linux-android-"

# Export environment variables for kernel build
export PLATFORM_VERSION=13
export ARCH=arm64

# Link toolchain directory inside build dir for convenience
ln -sfv "$TOOLCHAIN_DIR" "$WORKDIR/"

echo -e "\n\e[1;32m>>> DOS 2 UNIX warning mitigation!\e[0m"
echo -e "\e[1;33mI hope u are using Linux...\e[0m"
dos2unix ${WORKDIR}/drivers/sensorhub/debug/Kconfig
dos2unix ${WORKDIR}/drivers/sensorhub/sensorhub/Kconfig 

echo
echo -e "\n\e[1;32m>> Build environment ready!\e[0m"
echo -e "\e[1;33m>> To build kernel for Samsung A127F:\e[0m"
echo -e "\e[1;34m   cd $WORKDIR\e[0m"
echo -e "\e[1;34m   make exynos850-a12snsxx_defconfig\e[0m"
echo -e "\e[1;34m   make -j\$(nproc)\e[0m"
read -p "Press enter to exit..."
