## 📦 Samsung A127F Kernel Build (SM-A127F)

Build the Linux kernel for the Samsung Galaxy A12 (SM-A127F) using the official Samsung Open Source archive and Android toolchains.

---

### 🛠️ Preparation

#### 📁 1. Download Required Source Files
Download the following files from Samsung’s Open Source Release Center:

- 📥 [Samsung A127F Kernel and Platform Sources](https://opensource.samsung.com/uploadSearch?searchValue=SM-A127F)

Ensure you download:
- `Kernel.tar.gz`
- `Platform.tar.gz`

---

#### ⚙️ 2. Download Android Toolchains

Download or clone the following toolchains needed for cross-compilation:

- 🧰 **Clang (r353983c)**  
  [Download clang-r353983c](https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/emu-29.0-release/clang-r353983c.tar.gz)

- 🧰 **GCC (aarch64-linux-android-4.9)**  
  [Clone from LineageOS GitHub](https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git)

---

#### 🌍 3. Set Environment Variables

Make sure to export the following environment variables before building:

```bash
export CROSS_COMPILE="$GCC_DIR/bin/aarch64-linux-android-"
export CC="$CLANG_DIR/bin/clang"
export PLATFORM_VERSION=13
export ARCH=arm64
```

> 🔁 Tip: You can include these in your `.bashrc` or `.env` file to persist them across sessions.

---

### 🧪 Usage

To begin the build, extract the source files, configure the build environment, and then run:

```bash
make exynos850-a12snsxx_defconfig
make -j$(nproc)
```

---

### 📌 Notes

- The toolchain paths (`$GCC_DIR` and `$CLANG_DIR`) must point to the correct extracted directories.
- Ensure required packages are installed:  
  `sudo apt install bc xz-utils libssl-dev bison flex make python-is-python3`
- If you get an error for ylloc in the dtc file
- - navigate to `scripts/dtc/dtc-lexer.l` and add `extern` keyword in front of `LLTYPE ylloc;`

You can use prepare script to prepare the enviroment
---
