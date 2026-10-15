# pixman

Low-level pixel-manipulation library (used by cairo); installs `libpixman-1.a`,
the `pixman-1` headers and `pixman-1.pc`.

- build system: **meson** (`pixman/generic.toml:2`).
- source: `www.cairographics.org/releases/pixman-0.46.4.tar.gz`, `--strip-components=1`
  (`pixman/source.toml:5-12`).
- deps: none — pixman probes only libm and threads (`pixman/generic.toml:1284-1286`).
- recipes: `generic.toml`, `android.toml`.

## Overridden fields

```toml
args = ["-Dbuildtype=release", "-Ddefault_library=static", "-Dtests=disabled",
        "-Ddemos=disabled", "-Dlibpng=disabled", "-Dgtk=disabled", "-Dopenmp=disabled"]
```
(`pixman/generic.toml:1306`)

- `default_library=static`: meson builds shared by default; a target prefix has no loader
  path (`pixman/generic.toml:1288-1291`).
- **No `DESTDIR` for meson here**: `$MESON_FLAGS` already carries `--prefix=$OUT`, so a
  `DESTDIR` would concatenate into `$OUT$OUT` (`pixman/generic.toml:1289-1291`).
- `tests`/`demos`/`libpng`/`gtk`/`openmp` disabled: test and demo suites are host programs
  (demos additionally want gtk3/glib); libpng feeds only the test suite; OpenMP resolves to
  the NDK's libomp but its only consumer is the test suite (`pixman/generic.toml:1293-1302`).
- `buildtype=release`: pixman's own default is `debugoptimized`, and this prefix ships
  optimised archives (`pixman/generic.toml:1304-1305`).

## Android recipe

Adds `-Darm-simd=disabled -Dneon=disabled` for the **32-bit ARM** case only: `pixman-arm.c`
selects an Android branch that `#include <cpu-features.h>` — an AOSP header **not in the
NDK sysroot** — so with either 32-bit ARM path enabled the build dies on the missing header
(`pixman/android.toml:1249-1269`). aarch64 is unaffected: only `a64-neon` can turn on, it
defines `USE_ARM_A64_NEON`, which `pixman-arm.c:36` does not test, so aarch64 keeps full
NEON (`pixman/android.toml:1271-1278`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `fatal error: 'cpu-features.h' file not found` at `pixman-arm.c:98` | 32-bit ARM runtime CPU detection needs AOSP's `cpu-features.h`, absent from the NDK sysroot (`pixman/android.toml:1249-1263`) | on armv7a, `-Darm-simd=disabled -Dneon=disabled` (upstream's own `cpu-features-path` option would mean vendoring a patched tree) |
| the install lands at `$OUT$OUT` | a `DESTDIR` added on top of `--prefix=$OUT` (`pixman/generic.toml:1289-1291`) | do not add `DESTDIR` for a meson package |
