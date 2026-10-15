# cmake

`cmake -S -B` + `cmake --build` + `cmake --install`. The driver owns the toolchain
file, the install prefix and the four flags that make a cross configure work; the
recipe owns only extra `args` and, when `CMakeLists.txt` is not at the top of the
work dir, `source_dir` (`system@aarch64-android33/cmake.toml:1-3`,
`docs/recipes.md:79`).

## The cross skeleton

```sh
# --- driver-owned, from the system ---
CMAKE_TOOLCHAIN_FILE="$SYSDIR/<triple>-toolchain.cmake"
CMAKE_FLAGS="-DCMAKE_TOOLCHAIN_FILE=$CMAKE_TOOLCHAIN_FILE \
  -DCMAKE_INSTALL_PREFIX=$OUTPKG \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DTHREADS_PREFER_PTHREAD_FLAG=ON \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCMAKE_MAKE_PROGRAM=$CMAKE_MAKE_PROGRAM"
CMAKE_MAKE_PROGRAM="$(command -v make || true)"

LDFLAGS="$LDFLAGS -Wl,-rpath,\$ORIGIN -Wl,-rpath,\$ORIGIN/../lib -Wl,-rpath,\$ORIGIN/../lib64"

cmake -S "${BS_source_dir:-.}" -B build \
  ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"} \
  ${CMAKE_TOOLCHAIN_FILE:+-DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE"} \
  $CMAKE_FLAGS $BS_args
cmake --build build --parallel "$CORES"
cmake --install build
```

`cmake --install` honours the **`DESTDIR` environment variable** by itself, so the
staging step needs no `DESTDIR` on the command line (unlike `make`, see
[autoconf.md](autoconf.md) and [make.md](make.md)); the driver does not pass it
(`system@aarch64-android33/cmake.toml:21-25`).

## The toolchain file

A companion file named by the driver (`cmake.toml:5`), part of the system's
fingerprint. It is what makes `find_*` search the target, not the host:

```cmake
set(CMAKE_SYSTEM_NAME Linux)              # NOT Android: NDK integration is done by hand
set(CMAKE_SYSTEM_PROCESSOR "aarch64")     # target CPU
set(CMAKE_C_COMPILER   "$ENV{CC}")
set(CMAKE_CXX_COMPILER "$ENV{CXX}")
set(CMAKE_AR "$ENV{AR}")  set(CMAKE_RANLIB "$ENV{RANLIB}")
set(CMAKE_STRIP "$ENV{STRIP}")  set(CMAKE_READELF "$ENV{READELF}")
set(CMAKE_OBJDUMP "$ENV{OBJDUMP}")  set(CMAKE_OBJCOPY "$ENV{OBJCOPY}")
set(CMAKE_NM "$ENV{NM}")  set(CMAKE_ASM_COMPILER "$ENV{AS}")  set(CMAKE_LINKER "$ENV{LD}")
set(CMAKE_SYSROOT "$ENV{SYSROOT}")
set(CMAKE_INSTALL_PREFIX "$ENV{PREFIX}" CACHE PATH "install prefix")
set(CMAKE_FIND_ROOT_PATH "$ENV{PREFIX};$ENV{SYSROOT}")   # find_*: PREFIX first, then sysroot
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)   # never find a runnable program in the target
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)    # libraries only in SYSROOT/PREFIX
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)    # headers only there
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)    # find_package() only there
```

(`system@aarch64-android33/aarch64-linux-android33-toolchain.cmake:1-40`). Keeping
`CMAKE_SYSTEM_NAME` = **Linux** is deliberate: setting it to `Android` makes cmake do
its own NDK integration, which is done by hand here
(`aarch64-linux-android33-toolchain.cmake:1-2`).

## Required variables and flags

| flag | why |
| --- | --- |
| `-DCMAKE_TOOLCHAIN_FILE=...` | the only way cmake learns the target, sysroot and find-root rules (`cmake.toml:5`) |
| `-DCMAKE_INSTALL_PREFIX=$OUTPKG` | install into the final path; cmake's default `/usr/local` is wrong even for a native build (`cmake.toml:6`) |
| `-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY` | cmake's compiler check **links a test program and then runs it**; a cross target binary cannot run here, and running one would be emulation (`cmake.toml:7-9`) |
| `-DTHREADS_PREFER_PTHREAD_FLAG=ON` | Bionic keeps pthreads in libc, so `FindThreads`' libc probe fails and it settles on a `pthreads` library no Android sysroot has; prefer the plain `-pthread` flag (`cmake.toml:10-13`) |
| `-DCMAKE_POLICY_VERSION_MINIMUM=3.5` | cmake 4.x refuses any project whose minimum policy is below 3.5, and most of these projects are older than cmake itself (`cmake.toml:14-16`) |
| `-DCMAKE_MAKE_PROGRAM=$(command -v make)` | cmake runs the make program it finds, and it would find ours: `$PREFIX/bin/make` is a target binary, so running it needs an emulator — pin the host make (`cmake.toml:17-20`) |

For a native build only `CMAKE_INSTALL_PREFIX` and `CMAKE_POLICY_VERSION_MINIMUM`
remain; `CMAKE_TOOLCHAIN_FILE` is empty (`system@clang-native/cmake.toml:5-6`).

`CFLAGS`/`CXXFLAGS` from the system reach the compiler; `LDFLAGS` carries the
`$ORIGIN` rpath triple, written with a single `$ORIGIN` because cmake hands the value
to the compiler directly (`docs/systems.md:98-101`, `cmake.toml:22`).

## Dependency discovery

- **`find_package` / `find_library` / `find_path`** are the normal route. The closure
  puts each dependency's prefix into `$CMAKE_PREFIX_PATH` (`docs/recipes.md:59-61`).
- The toolchain file then restricts those searches to the target: `find_*` looks in
  `CMAKE_FIND_ROOT_PATH` (`$PREFIX` then `$SYSROOT`) and nowhere else, because the
  four `MODE_*` lines are `NEVER`/`ONLY`
  (`aarch64-linux-android33-toolchain.cmake:29-40`). Without them cmake happily links
  a host library.
- `find_package(Git)` and a `git describe` in the source tree are a **revision
  probe**, not a build tool; its result is discarded when the tarball ships its own
  revision file (`sdl/android.toml:77-81`).
- **An unknown `-D` cache variable is ignored silently** — a typo'd option name does
  nothing and no warning is printed (`sdl/android.toml:44-45`).

## Pitfalls that are cmake's own

| symptom in the log | cause | fix |
| --- | --- | --- |
| configure fails in the compiler check: link/run test fails, "compiler not able to compile a simple test program" | cmake's check links **and runs** a test program (`cmake.toml:7-9`) | `-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY` |
| `Could NOT find Threads` / a `pthreads` library that does not exist | `FindThreads` cannot detect Bionic's in-libc pthreads on a cross build (`cmake.toml:10-13`) | `-DTHREADS_PREFER_PTHREAD_FLAG=ON` |
| cmake 4.x: "Compatibility with CMake < 3.5 has been removed" | the project's minimum policy is below 3.5 (`cmake.toml:14-16`) | `-DCMAKE_POLICY_VERSION_MINIMUM=3.5` |
| the make step tries to execute `$PREFIX/bin/make` (emulation / exec format error) | cmake found a target-binary make on `PATH` (`cmake.toml:17-20`) | `-DCMAKE_MAKE_PROGRAM="$(command -v make)"` |
| cmake takes a host branch, ships no platform backend, or resolves `/sources/...` | a hand-written toolchain sets `CMAKE_SYSTEM_NAME Linux`, so `if(ANDROID)` (defined only by the NDK's own `android.toolchain.cmake`) is false (`sdl/android.toml:7-23`) | state the platform explicitly — `-DANDROID=ON -DANDROID_NDK=$NDK` — and pass any path it derives from a variable you must set |
| a `-DOPTION=...` had no effect | cmake ignores an unknown cache variable silently, or a `dep_option` default is derived from another variable (`sdl/android.toml:44-61`) | verify the option exists in this version and set the variable it is derived from |
| `find_library`/`find_package` links a host library | missing or wrong `CMAKE_FIND_ROOT_PATH` / `MODE_*` lines in the toolchain file (`aarch64-linux-android33-toolchain.cmake:29-40`) | set `FIND_ROOT_PATH` to `PREFIX;SYSROOT` and the modes to `PROGRAM NEVER`, `LIBRARY/INCLUDE/PACKAGE ONLY` |
