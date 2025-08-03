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
echo ">> Installing required packages..."
sudo apt update
sudo apt install -y bison flex binutils python3 python2 make automake autoconf libncurses-dev python-is-python3 libssl-dev \
bc liblzma-dev xz-utils

# Prepare build directory
mkdir -p "$WORKDIR"

# Check for Kernel and Platform sources
if [[ ! -f Kernel.tar.gz || ! -f Platform.tar.gz ]]; then
	echo "!! Missing Kernel.tar.gz and/or Platform.tar.gz"
	echo ">> Please download them from https://opensource.samsung.com"
 	read -p "Press enter to exit..."
	exit 1
fi

# Extract archives
echo ">> Extracting Kernel and Platform sources..."
tar -xf Kernel.tar.gz -C "$WORKDIR/"
tar -xf Platform.tar.gz -C "$WORKDIR/"

# Patch dtc-lexer if file is provided
if [[ -f dtc-lexer.l ]]; then
	echo ">> Patching dtc-lexer.l..."
	cp -v dtc-lexer.l "$WORKDIR/scripts/dtc/"
else
	echo "!! dtc-lexer.l not found. Please patch manually:"
	echo "   $WORKDIR/scripts/dtc/dtc-lexer.l"
	echo "   Add 'extern' in front of 'LLTYPE ylloc;'"
fi

# Copy instruction files
cp -v README_* "$WORKDIR/"

# Toolchain setup
echo ">> Setting up Clang toolchain..."
if [[ ! -f "$CLANG_DIR/bin/clang" ]]; then
	echo ">> Clang toolchain not found. Downloading..."
	wget -O "$CLANG_VERSION.tar.gz" \
		"https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/emu-29.0-release/$CLANG_VERSION.tar.gz"

	if [[ $? -ne 0 ]]; then
		echo "!! Failed to download Clang toolchain!"
		echo ">> Please download it manually and place it under: $CLANG_DIR"
 		read -p "Press enter to exit..."
		exit 1
	fi

	sudo mkdir -p "$CLANG_DIR"
	sudo tar -xf "$CLANG_VERSION.tar.gz" -C "$CLANG_DIR"
	echo ">> Clang toolchain installed!"
fi

export CC="$CLANG_DIR/bin/clang"

echo ">> Setting up GCC cross-compiler..."
if [[ ! -f "$GCC_DIR/bin/aarch64-linux-android-gcc" ]]; then
	echo ">> GCC toolchain not found. Cloning from LineageOS..."
	git clone "https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git"

	if [[ $? -ne 0 ]]; then
		echo "!! Failed to clone GCC toolchain!"
		echo ">> Please check your internet connection or download manually."
 		read -p "Press enter to exit..."
		exit 1
	fi

	sudo mkdir -p "$GCC_DIR"
	sudo cp -r android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9/* "$GCC_DIR/"
	rm -rf android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9
	echo ">> GCC toolchain installed!"
fi

export CROSS_COMPILE="$GCC_DIR/bin/aarch64-linux-android-"

# Export environment variables for kernel build
export PLATFORM_VERSION=13
export ARCH=arm64

# Link toolchain directory inside build dir for convenience
ln -sfv "$TOOLCHAIN_DIR" "$WORKDIR/"

echo ">> DOS 2 UNIX warning mitigation!"
echo "I hope u are using Linux..."
dos2unix ${WORKDIR}/drivers/sensorhub/debug/Kconfig
dos2unix ${WORKDIR}/drivers/sensorhub/sensorhub/Kconfig 

echo
echo ">> Build environment ready!"
echo ">> To build kernel for Samsung A127F:"
echo "   cd $WORKDIR"
echo "   make exynos850-a12snsxx_defconfig"
echo "   make -j\$(nproc)"
read -p "Press enter to exit..."
