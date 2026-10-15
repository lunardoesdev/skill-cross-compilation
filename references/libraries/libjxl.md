# libjxl

JPEG XL codec library; installs `libjxl.a`, `libjxl_cms.a`, `libjxl_threads.a`, the
`jxl/` headers and `libjxl.pc` / `libjxl_cms.pc` / `libjxl_threads.pc`.

- build system: **cmake** (`libjxl/generic.toml:2`).
- source: GitHub tag archive `v0.12.0`, `--strip-components=1`. The archive leaves
  `third_party/` as **empty directories**, so the source node fetches the three
  non-optional submodules at the commit the tag pins and lays them out where the build
  expects: `highway` (1.2.0), `brotli` (1.2.0), `skcms` (`libjxl/source.toml:5-9`,
  `:361-386`). It does **not** use this tree's highway (1.4.0) or brotli (1.1.0): a
  JPEG XL built against a different SIMD backend or encoder than the release was tested
  with is a different build (`libjxl/source.toml:14-27`).
- deps: none in the recipe — the bundled highway/skcms/brotli are installed into the same
  entry by `third_party/CMakeLists.txt` (`libjxl/generic.toml:312-322`).
- recipe: `generic.toml` only.

## Overridden fields

A long `args` list, each entry naming an upstream switch turned OFF
(`libjxl/generic.toml:327`):

- `-DBUILD_TESTING=OFF` is **required, not optional**: the `testdata` submodule is not in
  the archive and `CMakeLists.txt:428-431` stops when `BUILD_TESTING` is on; off, it also
  avoids `find_package(GTest REQUIRED)` (`libjxl/generic.toml:246-253`).
- `-DBUILD_SHARED_LIBS=OFF`: upstream defaults it to whether the target platform supports
  shared libs, which the Linux-shaped toolchain says yes (`libjxl/generic.toml:255-258`).
- `-DJPEGXL_ENABLE_TOOLS/DEVTOOLS/FUZZERS/EXAMPLES/BENCHMARK/DOXYGEN/MANPAGES/JNI=OFF` —
  every program, the doxygen run, the man pages (whose target is `ALL` and runs `a2x`,
  a host tool), and the JNI jar (`libjxl/generic.toml:259-286`).
- `-DJPEGXL_ENABLE_SJPEG/OPENEXR/TCMALLOC=OFF` and `-DJPEGXL_ENABLE_SKCMS=ON`: SKCMS on is
  what keeps `lcms2` out (`third_party/CMakeLists.txt:108-118` reaches for
  `find_package(LCMS2)` when it is off) (`libjxl/generic.toml:288-305`).
- `-DJPEGXL_ENABLE_VIEWERS/PLUGINS=OFF`: the other two inputs of that lcms2 condition,
  stated so the dependency does not rest on a default (`libjxl/generic.toml:301-305`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `testdata directory ... is not populated` | `BUILD_TESTING` defaults ON via `include(CTest)`, and testdata is not in the archive (`libjxl/generic.toml:246-253`) | `-DBUILD_TESTING=OFF` |
| `Please provide sjpeg` | `third_party/sjpeg` is an empty submodule and the option defaults ON (`libjxl/generic.toml:288-291`) | `-DJPEGXL_ENABLE_SJPEG=OFF` |
| `Please provide skcms or run deps.sh` / `Could not find HWY` / brotli not found | the release archive's `third_party/` is empty (see source node) (`libjxl/source.toml:334-347`) | fetch each submodule at the pinned commit into the expected path |
| a consumer of `libjxl.pc` cannot resolve `libhwy`/`libbrotli*` | `lib/jxl.cmake:280-281` writes `Requires: libhwy libbrotlienc libbrotlidec libjxl_cms` unconditionally (`libjxl/generic.toml:312-322`) | the bundled highway/brotli are installed into the same entry; ensure they land beside `libjxl.pc` |
