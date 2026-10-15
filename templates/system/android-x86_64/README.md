# templates/system/android-x86_64

Portable Android **x86-64** cross-build scaffold. Environment:
`snippets/systems/android-x86_64.sh`. Description: `references/systems/android-x86_64.md`.

| file | for |
|---|---|
| `toolchain.cmake` | CMake (`CMAKE_SYSTEM_PROCESSOR=x86_64`) |
| `crossfile.ini` | Meson (`cpu_family=x86_64`, `cpu=x86_64`) |

## Usage

```sh
export ANDROID_HOME=~/Android/Sdk
export ANDROID_API=33
export PREFIX="$PWD/out"
. snippets/systems/android-x86_64.sh

cmake -S . -B build \
  -DCMAKE_TOOLCHAIN_FILE=templates/system/android-x86_64/toolchain.cmake \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY -DTHREADS_PREFER_PTHREAD_FLAG=ON \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_INSTALL_PREFIX="$PREFIX"
cmake --build build --parallel "$(nproc)" && cmake --install build

meson setup build --cross-file templates/system/android-x86_64/crossfile.ini --prefix "$PREFIX"
ninja -C build && ninja -C build install
```

## Notes

- x86_64 is the emulator's native ABI — the most convenient Android target to smoke-test
  without a device.
- Shared flag and `$ORIGIN` rationale: `templates/system/android-aarch64/README.md`.
