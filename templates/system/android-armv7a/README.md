# templates/system/android-armv7a

Portable Android **armeabi-v7a (armv7a)** cross-build scaffold. Environment:
`snippets/systems/android-armv7a.sh`. Description: `references/systems/android-armv7a.md`.

| file | for |
|---|---|
| `toolchain.cmake` | CMake (`CMAKE_SYSTEM_PROCESSOR=arm`) |
| `crossfile.ini` | Meson (`cpu_family=arm`, `cpu=armv7`) |

## Usage

```sh
export ANDROID_HOME=~/Android/Sdk
export ANDROID_API=33
export PREFIX="$PWD/out"
. snippets/systems/android-armv7a.sh

cmake -S . -B build \
  -DCMAKE_TOOLCHAIN_FILE=templates/system/android-armv7a/toolchain.cmake \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY -DTHREADS_PREFER_PTHREAD_FLAG=ON \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_INSTALL_PREFIX="$PREFIX"
cmake --build build --parallel "$(nproc)" && cmake --install build

meson setup build --cross-file templates/system/android-armv7a/crossfile.ini --prefix "$PREFIX"
ninja -C build && ninja -C build install
```

## Careful

- The upstream retrolunar system pins the armv7a clang wrapper (and the CMake toolchain
  filename) to **API 21** for every API level, while `ANDROID_API` follows the system —
  a mismatch that dangles the CMake reference for API ≥ 23
  (`references/systems/android-armv7a.md`). This template is API-agnostic and the snippet
  keys the wrapper off `$ANDROID_API` (`WRAPPER_API=21` reproduces the pinned behaviour).
- The compiler/toolchain names differ from aarch64: host triplet
  `armv7a-linux-androideabi`, Rust target `armv7-linux-androideabi`, CMake processor `arm`.
- Same `-O2 -fPIC -DANDROID`, `-lm -llog`, `-isystem $SYSROOT/usr/include` and `$ORIGIN`
  rpath trio as aarch64 — see `templates/system/android-aarch64/README.md`.
