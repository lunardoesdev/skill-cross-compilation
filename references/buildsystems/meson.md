# meson

`meson setup` + `ninja` (meson's backend). The driver owns the cross file and the
install prefix; the recipe owns only extra `-D` options (`args`) and `source_dir`
(`system@aarch64-android33/meson.toml:1-3`, `docs/recipes.md:80`).

## The cross skeleton

```sh
# --- driver-owned, from the system ---
MESON_CROSS_FILE="$SYSDIR/<triple>-crossfile.ini"
MESON_FLAGS="--prefix=$OUTPKG --cross-file $MESON_CROSS_FILE"

LDFLAGS="$LDFLAGS -Wl,-rpath,\$ORIGIN -Wl,-rpath,\$ORIGIN/../lib -Wl,-rpath,\$ORIGIN/../lib64"

meson setup build \
  ${MESON_CROSS_FILE:+--cross-file "$MESON_CROSS_FILE"} \
  $MESON_FLAGS $BS_args
ninja -C build -j "$CORES"
ninja -C build -j "$CORES" install
```

`ninja install` honours the **`DESTDIR` environment variable** (meson/ninja install
respects it), so no `DESTDIR` on the command line is needed
(`system@aarch64-android33/meson.toml:7-11`). Some recipes call
`meson compile --jobs "$CORES"` instead of a bare `ninja`; either way the job count
comes from the recipe, not the driver (`system@clang-native/system.toml:30-37`).

## The cross file

A companion `.ini` named by the driver (`meson.toml:5`), part of the system's
fingerprint:

```ini
[binaries]
pkgconfig = 'pkg-config'          # host pkg-config with the right env vars works fine

[host_machine]
system = 'android'                # meson's name for the target OS
cpu_family = 'aarch64'
cpu = 'aarch64'
endian = 'little'

[properties]
# everything else comes from our flags, nothing more needed
```

(`system@aarch64-android33/crossfile-aarch64-android33.ini:1-19`). Note the compilers
are **not** listed here: they come from the environment (`$CC`, `$CXX`, `$AR`,
`$STRIP`, `$LD` are full paths into the NDK) and the cross toolchain is deliberately
kept off `PATH`, so bare names cannot resolve
(`crossfile-aarch64-android33.ini:2-6`). `host_machine` is meson's name for the
machine the artifacts run on.

For a **native** build there is no cross file at all: meson takes the toolchain from
the environment, and only `--prefix` is needed
(`system@clang-native/meson.toml:12-17`).

## Required variables and flags

| flag | why |
| --- | --- |
| `--cross-file <ini>` | the only way meson learns the target `host_machine`; without it a cross build compiles for the build machine (`meson.toml:5-6`) |
| `--prefix=$OUTPKG` | install into the final path — **mandatory** (see the pitfall below) (`meson.toml:6`) |

No policy floor is needed (that is a cmake thing), and `$CC`/`$CXX` from the system
environment supply the toolchain (`system@clang-native/meson.toml:12-16`).

## Dependency discovery

- **native `pkg-config`** through the cross file's `[binaries] pkgconfig`, driven by
  the closure's `$PKG_CONFIG_LIBDIR` / `$PKG_CONFIG_PATH`
  (`crossfile-aarch64-android33.ini:4-5`, `docs/recipes.md:59-61`).
- meson options for library deps: `-Ddefault_library=static`, `-Dzlib=system`,
  `-Dpng=enabled`, `-Dbrotli=disabled` — the recipe states each backend as
  system/bundled/disabled rather than leaving it to a default
  (`docs/recipes.md:100-105`).

## Known pitfalls

| symptom in the log | cause | fix |
| --- | --- | --- |
| the build "succeeds" and `install` reports no error, yet **nothing lands in `$OUT`** — no artifact at all | `meson` with no `--prefix` records `prefix=/usr/local`, compiles happily, "installs" into `/usr/local`, and reports no error. A silent-failure defect, not cosmetic (`system@clang-native/meson.toml:6-11`) | always pass `--prefix=$OUTPKG` |
| the build compiles for the **build** machine | no `--cross-file`, so meson has no `host_machine` (`meson.toml:5-6`) | pass `--cross-file <ini>` with `[host_machine]` set |
| `--cross-file` given but the compiler "not found"/wrong | the cross toolchain is off `PATH`, so a bare compiler name in `[binaries]` cannot resolve (`crossfile-aarch64-android33.ini:2-6`) | leave compilers out of `[binaries]`; supply them through the environment (`$CC`, `$CXX`, …) |
| a backend is silently missing from the artifact | an option defaulted to `disabled`/bundled instead of `system` | state each dependency as `system`/`enabled`/`disabled` explicitly in `args` (`docs/recipes.md:100-105`) |
