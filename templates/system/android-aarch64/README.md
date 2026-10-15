# templates/system/android-aarch64

Portable Android **arm64-v8a (aarch64)** cross-build scaffold. Non-shell files only; the
environment lives in `snippets/systems/android-aarch64.sh`.

| file | for | notes |
|---|---|---|
| `toolchain.cmake` | CMake | API-agnostic; reads `$CC`/`$SYSROOT`/`$PREFIX` from the environment |
| `crossfile.ini` | Meson | `[host_machine] system=android cpu_family=aarch64` |

Description and rationale: `references/systems/android-aarch64.md`.
API-level differences: `references/systems/android-abi.md`.

## Usage

```sh
export ANDROID_HOME=~/Android/Sdk            # SDK containing ndk/
export ANDROID_API=33                        # 21,23,24,...,35
export PREFIX="$PWD/out"
. snippets/systems/android-aarch64.sh

# CMake
cmake -S . -B build \
  -DCMAKE_TOOLCHAIN_FILE=templates/system/android-aarch64/toolchain.cmake \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DTHREADS_PREFER_PTHREAD_FLAG=ON \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCMAKE_INSTALL_PREFIX="$PREFIX"
cmake --build build --parallel "$(nproc)" && cmake --install build

# Meson
meson setup build --cross-file templates/system/android-aarch64/crossfile.ini --prefix "$PREFIX"
ninja -C build && ninja -C build install

# autoconf / plain make (cross link-and-run probes; the toolchain must be on the command
# line because a Makefile's own CC= overrides the environment)
./configure --host=aarch64-linux-android --build=x86_64-pc-linux-gnu --prefix="$PREFIX"
make -j"$(nproc)" CC="$CC" AR="$AR" RANLIB="$RANLIB" CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" LDFLAGS="$LDFLAGS"
```

## CMake flags that matter here

- `-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY` — the compiler check links *and runs*
  a program; a target binary cannot run on the host, so link a static library instead.
- `-DTHREADS_PREFER_PTHREAD_FLAG=ON` — Bionic keeps pthreads in libc, which `FindThreads`
  cannot detect; prefer the plain `-pthread` flag.
- `-DCMAKE_POLICY_VERSION_MINIMUM=3.5` — CMake 4.x refuses older projects.
- `-DCMAKE_MAKE_PROGRAM="$(command -v make)"` — pin the *host* make; a target `make` in
  `$PREFIX/bin` would need an emulator.

## Runtime path (`$ORIGIN`)

Every driver adds `-Wl,-rpath,'$ORIGIN' -Wl,-rpath,'$ORIGIN/../lib'
-Wl,-rpath,'$ORIGIN/../lib64'` (three entries: the binary is in `bin/`, its libs in
`lib/`). In `make`/autoconf write `$$ORIGIN`; CMake/Meson hand the value to the compiler
directly, so `$ORIGIN`.
