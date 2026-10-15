# mingw64 — Windows x86-64 via mingw-w64 (`x86_64-w64-mingw32`)

Source: `system@mingw64/`. Snippet: `snippets/systems/mingw64.sh`. Unlike the Android
systems this needs **no NDK and no sysroot**: the mingw-w64 toolchain in the distro
already knows its own headers and libraries.

## Identity

| fact | value | source |
|---|---|---|
| host triplet (`--host`) | `x86_64-w64-mingw32` | `system@mingw64/system.toml:55` |
| build triplet | `x86_64-pc-linux-gnu` | `system@mingw64/system.toml:54` |
| `HOST_ARCH` / `HOST_OS` | `x86_64` / **`mingw32`** | `system@mingw64/system.toml:57-58` |
| CMake `CMAKE_SYSTEM_NAME` / processor | `Windows` / `x86_64` | `x86_64-w64-mingw32-toolchain.cmake:4,7` |
| Meson `system` / `cpu_family` / `cpu` | `windows` / `x86_64` / `x86_64` | `crossfile-mingw64.ini:16-20` |
| Meson `exe_suffix` | `exe` | `crossfile-mingw64.ini:26` |
| Rust target | `x86_64-pc-windows-gnu` | `cargo.toml:12` |

`HOST_OS` is the string `mingw32` for **both** the 64-bit and 32-bit systems
(`system@mingw64/system.toml:58`, `system@mingw32/system.toml:28`) — it is the mingw
"OS" spelling, not the pointer width. The arch lives in `HOST_ARCH`.

## Environment variables

- `CC`/`CXX`/`AR`/`RANLIB`/`LD`/`STRIP`/`OBJCOPY`/`READELF`/`NM`/`OBJDUMP` are the bare
  `x86_64-w64-mingw32-*` names from `PATH` (`system.toml:3-12`).
- **`WINDRES = x86_64-w64-mingw32-windres`** — the Windows resource compiler, present
  only on mingw systems (`system.toml:13`).
- **No `AS`/`ASM`** (`system.toml:3-13`), even though the CMake toolchain does
  `set(CMAKE_ASM_COMPILER "$ENV{AS}" …)` (`x86_64-w64-mingw32-toolchain.cmake:28`), so
  `$AS` is empty here.
- **`CFLAGS = "-O2"`, `CXXFLAGS = "$CFLAGS"`** (`system.toml:15-16`) — no `-fPIC` (PE has
  no position-independent-executable story that needs it) and no `-DANDROID`.
- **No `$LDFLAGS` at all** — see below; the Windows import libraries are handled by the
  CMake fragment, not by `$LDFLAGS`.
- **`PKG_CONFIG_PATH = "$PKG_CONFIG_PATH"`** — pass-through / ignore host `.pc`
  (`system.toml:47-48`).
- Cargo: `CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER=$CC`, `…_AR=$AR`, plus
  `CC_/CFLAGS_/CXX_/CXXFLAGS_x86_64_pc_windows_gnu` (`cargo.toml:13-17`).

## Flags, and why

- **`-O2` only.** `-fPIC` is an ELF/POSIX concern; it is absent here and on mingw32
  (`system.toml:15`).
- **`-Wl,--undefined-version` is deliberately NOT here.** The comment states it is
  "ELF-only, ld for PE fails" (`system.toml:17`) — this is why `clang-native` (which
  does set it, `native-clang` `system.toml:18`) and mingw must not share an `LDFLAGS`.
- **The Windows import libraries are NOT in `$LDFLAGS`** (`system.toml:18-46`). The
  reasoning, measured against a real i2pd link:
  - CMake seeds `CMAKE_EXE_LINKER_FLAGS` from `$LDFLAGS` on its own, but places those
    flags **before** the archives that reference them; i2pd links its static libs through
    a response file (`@linkLibs.rsp`), and `ld` does not revisit an archive it already
    passed. Putting `-lcrypt32 …` in `$LDFLAGS` yields
    `undefined reference to '__imp_CertFindCertificateInStore'`; moving the *same* flags
    to the **end** of the identical link line produces a clean `i2pd.exe`
    (`system.toml:21-33`).
  - So they go into `-DCMAKE_REQUIRED_LIBRARIES=crypt32;ole32;oleaut32;uuid;gdi32`
    (`cmake.toml:6`), which i2pd forwards to its final link
    (`build/CMakeLists.txt:409`), landing after the response file (`system.toml:35-37`).
  - `-lcrypt32` is the load-bearing one: OpenSSL's mingw build reaches the Windows
    certificate store, so `libcrypto.a` itself carries the
    `__imp_CertFindCertificateInStore` reference. `-lole32/-loleaut32/-luuid` are for
    Win32/COM consumers (`CoCreateInstance`, `CoUninitialize`, the `IID_`/`CLSID_`
    constants); `-lgdi32` is parity with upstream's `Makefile.mingw:44-52`. Upstream's
    CMake only appends `crypt32` for MSVC (`build/CMakeLists.txt:378-381`), so a mingw
    build must get these from the system (`system.toml:39-46`).

## No `$ORIGIN`: the boundary that defines mingw

A PE file resolves its imports through the **search path**, not through an rpath, so
there is no `$ORIGIN` to speak of (`docs/systems.md:158-161`). Concretely:

- the autoconf script **omits** the `-Wl,-rpath,…` line entirely — compare
  `autoconf.toml:11-12` (no rpath) with `system@aarch64-android33/autoconf.toml:11-13`
  (three rpath entries);
- the cargo script **omits** the `RUSTFLAGS="-C link-arg=-Wl,-rpath,…"` block
  (`cargo.toml:15-18` vs `system@aarch64-android33/cargo.toml:16`);
- as a result a bundle gets a **launcher** instead of a relocatable rpath
  (`docs/systems.md:158-161`).

## Platform vs. build boundary

The platform provides the whole Windows ABI surface, headers, `libgcc`/`libwinpthread`
and the import libraries (`crypt32`, `ole32`, …) that ship with mingw-w64. Everything
else (zlib, OpenSSL, i2pd, …) is built into `$PREFIX`. There is **no sysroot**:
`CMAKE_FIND_ROOT_PATH` is set to `$PREFIX` only, and program lookup stays `NEVER` so
host tools (`ninja`, `pkg-config`) are used, never prefixed ones
(`x86_64-w64-mingw32-toolchain.cmake:32-43`).

## Build-system fragments

- **CMake** — toolchain file `$SYSDIR/x86_64-w64-mingw32-toolchain.cmake`
  (`cmake.toml:5`); it sets `CMAKE_SYSTEM_NAME Windows` (not `Linux`) and
  `CMAKE_RC_COMPILER` to `windres` (`…toolchain.cmake:4,19`). `CMAKE_FLAGS` mirror the
  Android ones (`-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY`,
  `-DCMAKE_POLICY_VERSION_MINIMUM=3.5`, `-DCMAKE_MAKE_PROGRAM=$(command -v make || true)`)
  **plus** `-DCMAKE_REQUIRED_LIBRARIES=…`, and **without**
  `-DTHREADS_PREFER_PTHREAD_FLAG=ON` (mingw has real winpthreads, `cmake.toml:6`).
- **Meson** — `MESON_CROSS_FILE` is meant to point at a cross-file under `$SYSDIR`, and
  the comment documents a real trap: `ZLIB_ROOT` is read *directly* by projects
  (`i2pd/build/CMakeLists.txt:314` does `link_directories(${ZLIB_ROOT}/lib)`); left
  unset it expands to the literal `/lib`, which on the build host is a symlink to
  `/usr/lib`, so the target link line grew `-L/lib` and every `-lpthread` resolved to
  glibc's 8-byte empty `libpthread.a` instead of mingw's winpthreads, dying on
  `undefined reference to 'pthread_self'` (`meson.toml:5-17`). Point any such root
  variable at `$PREFIX`.
  ⚠ **Naming bug to avoid copying:** this system's `meson.toml:18` references
  `$SYSDIR/crossfile-x86_64-mingw.ini`, but the file actually shipped is
  `crossfile-mingw64.ini` — the reference does not resolve. The portable template
  (`templates/system/mingw64/crossfile.ini`) exists precisely so there is one name.
