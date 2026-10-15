# templates/system/mingw64

Portable Windows **x86-64 (mingw-w64)** cross-build scaffold. Environment:
`snippets/systems/mingw64.sh`. Description: `references/systems/mingw64.md`.

| file | for |
|---|---|
| `toolchain.cmake` | CMake (`CMAKE_SYSTEM_NAME=Windows`, `CMAKE_RC_COMPILER=windres`) |
| `crossfile.ini` | Meson (`system=windows`, `exe_suffix=exe`) |

## Usage

```sh
export PREFIX="$PWD/out"
. snippets/systems/mingw64.sh

cmake -S . -B build \
  -DCMAKE_TOOLCHAIN_FILE=templates/system/mingw64/toolchain.cmake \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DCMAKE_REQUIRED_LIBRARIES="crypt32;ole32;oleaut32;uuid;gdi32" \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_INSTALL_PREFIX="$PREFIX"
cmake --build build --parallel "$(nproc)" && cmake --install build

meson setup build --cross-file templates/system/mingw64/crossfile.ini --prefix "$PREFIX"
ninja -C build && ninja -C build install
```

## Why the Windows import libraries go in CMAKE_REQUIRED_LIBRARIES

CMake seeds `CMAKE_EXE_LINKER_FLAGS` from `$LDFLAGS`, which places `-lcrypt32 …` **before**
the archives that reference them; `ld` does not revisit an archive it already passed. A
project that links its static libs through a response file (i2pd's `@linkLibs.rsp`) then
fails with `undefined reference to '__imp_CertFindCertificateInStore'`; the same flags at
the **end** of the link line produce a clean `.exe`. `CMAKE_REQUIRED_LIBRARIES` lands after
the response file. `-lcrypt32` is the load-bearing one (OpenSSL's mingw build reaches the
Windows certificate store); `-lole32 -loleaut32 -luuid` cover COM; `-lgdi32` is parity with
upstream. Source: `references/systems/mingw64.md`.

## Careful

- There is **no sysroot**; `CMAKE_FIND_ROOT_PATH` is `$PREFIX` only.
- `-Wl,--undefined-version` is ELF-only — never add it on mingw.
- No `$ORIGIN`: a PE file resolves imports via the search path, so there is no rpath and a
  bundle needs a launcher. Do not add `-Wl,-rpath` flags.
- If a project reads a root variable such as `ZLIB_ROOT` directly and it is left unset, it
  can expand to the literal `/lib` (the *host* library dir) and pull in glibc libraries —
  point such variables at `$PREFIX`.
