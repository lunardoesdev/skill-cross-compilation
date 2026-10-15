# libaom

AV1 codec library; installs `libaom.a`, the `aom/*.h` headers, `aom.pc`.

- build system: **cmake** (`libaom/generic.toml:2`).
- source: googlesource export
  `https://aomedia.googlesource.com/aom/+archive/refs/tags/v3.15.2.tar.gz`. **The archive
  puts the tree at the root** (no leading directory), so it unpacks **without**
  `--strip-components=1` — stripping one level would consume every top-level name and leave
  an empty tree (`libaom/source.toml:1-9`, `:1458`).
- deps: `libaom@source`, `perl@native` (`libaom/generic.toml:1402`).
- recipe: `generic.toml` only.

## Overridden fields

```toml
args = ["-DBUILD_SHARED_LIBS=OFF", "-DENABLE_APPS=OFF", "-DENABLE_EXAMPLES=OFF",
        "-DENABLE_TOOLS=OFF", "-DENABLE_TESTS=OFF", "-DENABLE_TESTDATA=OFF",
        "-DENABLE_DOCS=OFF", "-DENABLE_DECODE_PERF_TESTS=OFF", "-DENABLE_ENCODE_PERF_TESTS=OFF"]
```
(`libaom/generic.toml:1438`)

- All of `ENABLE_APPS/EXAMPLES/TOOLS/TESTS/TESTDATA/DOCS` default ON and each produces a
  target binary or a doxygen run (`libaom/generic.toml:1422-1431`).
- `BUILD_SHARED_LIBS=OFF` also selects `AOM_INSTALL_LIBS=aom` (the static target), so the
  installed file is `libaom.a` (`libaom/generic.toml:1417-1420`).
- `AOM_TARGET_CPU` is left unset on purpose: cmake derives it from `CMAKE_SYSTEM_PROCESSOR`
  (aarch64 → arm64) (`libaom/generic.toml:1433-1437`).

## What it needs from the system

`perl@native`: libaom generates its runtime CPU-dispatch tables by **running**
`cmake/rtcd.pl` (`aom_configure.cmake:503-505` FATAL_ERRORs without Perl;
`aom_optimization.cmake:287` invokes `${PERL_EXECUTABLE} rtcd.pl`). The android cmake
driver sets `CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER`, so `find_package(Perl)` looks only
at the host `PATH`, where a native dependency's `bin/` lands (`libaom/generic.toml:1407-1415`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `Perl is required to build libaom` | `rtcd.pl` is run at configure/build (`libaom/generic.toml:1407-1415`) | depend on `perl@native` |
| an **empty source tree** after unpacking | the googlesource export has no leading directory, so `--strip-components=1` eats the top level (`libaom/source.toml:1-9`) | unpack **without** `--strip-components` and copy `src/.` |
| aomenc/aomdec, examples, doxygen built | the `ENABLE_*` options default ON (`libaom/generic.toml:1422-1431`) | set all to OFF |
