# templates/system/mingw32

Portable Windows **x86 (mingw-w64)** cross-build scaffold. Environment:
`snippets/systems/mingw32.sh`. Description: `references/systems/mingw32.md`.

| file | for |
|---|---|
| `toolchain.cmake` | CMake (`CMAKE_SYSTEM_NAME=Windows`, processor `i686`, `windres`) |
| `crossfile.ini` | Meson (`cpu_family=x86`, `cpu=i686`, `exe_suffix=exe`) |

## Usage

```sh
export PREFIX="$PWD/out"
. snippets/systems/mingw32.sh

cmake -S . -B build \
  -DCMAKE_TOOLCHAIN_FILE=templates/system/mingw32/toolchain.cmake \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_INSTALL_PREFIX="$PREFIX"
cmake --build build --parallel "$(nproc)" && cmake --install build

meson setup build --cross-file templates/system/mingw32/crossfile.ini --prefix "$PREFIX"
ninja -C build && ninja -C build install
```

## Notes

- Same "no sysroot", "no `-fPIC`", "no `$ORIGIN`", "no `-Wl,--undefined-version`" facts as
  mingw64 — see `templates/system/mingw64/README.md`.
- The upstream retrolunar system has **no import-library plumbing** for i686 and leaves
  `CARGO_BUILD_TARGET` empty; if a package needs the Windows certificate store or COM, add
  `-lcrypt32 -lole32 -loleaut32 -luuid -lgdi32` at the **end** of the link line yourself.
- The 32-bit and 64-bit mingw toolchain files differ only in the CPU and the windres name.
