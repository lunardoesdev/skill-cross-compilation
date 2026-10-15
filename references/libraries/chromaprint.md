# chromaprint

Audio-fingerprinting library; installs `libchromaprint.a`, `chromaprint.h`,
`libchromaprint.pc` and a cmake package config.

- build system: **cmake** (`chromaprint/generic.toml:2`).
- source: GitHub tag archive `v1.6.1`, `--strip-components=1`. Self-contained: the two
  3rdparty trees (`src/3rdparty/kissfft`, `src/3rdparty/googletest`) are **checked in**,
  not submodules (`chromaprint/source.toml:5-8`).
- deps: none — the two things it needs (an FFT and audio resampling) are settled by
  options.
- recipe: `generic.toml` only.

## Overridden fields

```toml
args = ["-DBUILD_SHARED_LIBS=OFF", "-DBUILD_TOOLS=OFF", "-DBUILD_TESTS=OFF",
        "-DFFT_LIB=kissfft", "-DKISSFFT_SOURCE_DIR=$WORK/src/3rdparty/kissfft",
        "-DUSE_INTERNAL_AVRESAMPLE=ON"]
```
(`chromaprint/generic.toml:636`)

- `-DBUILD_TOOLS=OFF`: `fpcalc` is the only part that wants ffmpeg
  (`src/cmd/CMakeLists.txt:1`); off, ffmpeg is not a dependency at all
  (`chromaprint/generic.toml:562-573`).
- `-DFFT_LIB=kissfft` + `-DKISSFFT_SOURCE_DIR=$WORK/src/3rdparty/kissfft`: the library
  refuses to build with no FFT backend (`CMakeLists.txt:159`), and naming the directory is
  what makes the in-tree finder work (see traps) (`chromaprint/generic.toml:575-603`).
- `-DUSE_INTERNAL_AVRESAMPLE=ON`: with no ffmpeg, the AudioProcessor needs the bundled
  avresample copy; without it `Reset()` refuses any stream not already at the analysis rate
  (`chromaprint/generic.toml:605-617`).
- `-DBUILD_TESTS=OFF`: upstream defaults ON and calls `gtest_discover_tests(all_tests)`,
  which **runs** the target test binary during the build (`chromaprint/generic.toml:625-631`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `Could NOT find KissFFT (missing: KISSFFT_SOURCE_DIR)` → `Selected kissfft for FFT calculations, but the library is not found` | a cross toolchain sets `CMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY`, which re-roots every search path, so the finder's absolute path into the work dir is unreachable (`chromaprint/generic.toml:584-597`) | hand `find_path` its answer: `-DKISSFFT_SOURCE_DIR=$WORK/src/3rdparty/kissfft` so it skips the search |
| the target test binary is executed during the build | `BUILD_TESTS` default ON + `gtest_discover_tests` (`chromaprint/generic.toml:625-631`) | `-DBUILD_TESTS=OFF` |
| `No FFT library found` | no backend selected and autodetection found nothing (`chromaprint/generic.toml:575-582`) | `-DFFT_LIB=kissfft` (and state it so autodetection cannot pick another package's lib) |
