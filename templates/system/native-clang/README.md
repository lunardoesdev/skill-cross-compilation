# templates/system/native-clang

Portable **native host clang** scaffold. There is deliberately **no `toolchain.cmake`
and no `crossfile.ini` here** — a native build needs neither:

- CMake: `CMAKE_TOOLCHAIN_FILE` is empty in the source system's `cmake.toml:5`, so no
  toolchain file is loaded; the host toolchain is used directly, and the driver's
  `${CMAKE_TOOLCHAIN_FILE:+…}` expansion adds nothing.
- Meson: `MESON_CROSS_FILE` is empty (`meson.toml:5`); the native toolchain comes from the
  environment (`$CC`, `$CXX`, `$AR`, …). Set `--prefix` explicitly — an *empty* `MESON_FLAGS`
  leaves meson at `prefix=/usr/local`, so a build "installs" nothing and reports no error.

Environment: `snippets/systems/native-clang.sh`. Description:
`references/systems/native-clang.md`.

## Usage

```sh
export PREFIX="$PWD/out"
. snippets/systems/native-clang.sh

# CMake — note: still set the cmake 4.x policy floor; no try-compile or make-program pin
# is needed because the build actually can run its test programs.
cmake -S . -B build -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build build --parallel "$(nproc)" && cmake --install build

# Meson
meson setup build --prefix "$PREFIX" && ninja -C build && ninja -C build install

# autoconf — no --host (native)
./configure --build=x86_64-pc-linux-gnu --prefix="$PREFIX" && make -j"$(nproc)" && make install
```

## Notes

- `$CFLAGS`/`$CXXFLAGS` are intentionally kept clean (`-O2 -fPIC $CPPFLAGS`); the flags
  that exist only for autoconf probes live in `$CPPFLAGS` so a recipe that runs `$CC`
  directly does not inherit them.
- `-Wl,--undefined-version` is set here (GNU ld relaxation) and must **not** be carried to
  the mingw templates — it is ELF-only.
- The source system exposes a `probe` list (`clang --version`, `meson --version`,
  `cmake --version`, `pkg-config --version`) to hash host facts into build freshness.
