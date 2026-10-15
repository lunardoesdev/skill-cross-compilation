# templates/system/android-i686

Portable Android **x86 (i686)** cross-build scaffold. Environment:
`snippets/systems/android-i686.sh`. Description: `references/systems/android-i686.md`.

| file | for |
|---|---|
| `toolchain.cmake` | CMake (`CMAKE_SYSTEM_PROCESSOR=x86`) |
| `crossfile.ini` | Meson (`cpu_family=x86`, `cpu=i686`) |

## Usage

```sh
export ANDROID_HOME=~/Android/Sdk
export ANDROID_API=33
export PREFIX="$PWD/out"
. snippets/systems/android-i686.sh

cmake -S . -B build \
  -DCMAKE_TOOLCHAIN_FILE=templates/system/android-i686/toolchain.cmake \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY -DTHREADS_PREFER_PTHREAD_FLAG=ON \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_INSTALL_PREFIX="$PREFIX"
cmake --build build --parallel "$(nproc)" && cmake --install build

meson setup build --cross-file templates/system/android-i686/crossfile.ini --prefix "$PREFIX"
ninja -C build && ninja -C build install
```

## Notes

- Three spellings of one target: host triplet `i686-linux-android`, CMake processor
  `x86`, Meson `cpu=i686` / `cpu_family=x86`.
- `CXXFLAGS` here equals `CFLAGS` (the sysroot `-isystem` reaches C++ too), unlike
  aarch64. See `templates/system/android-aarch64/README.md` for the shared flag and
  `$ORIGIN` rationale.
