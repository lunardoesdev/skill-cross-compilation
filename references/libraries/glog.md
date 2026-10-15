# glog

Google logging library; installs `libglog.a`, the `glog/` headers and `libglog.pc`.

- build system: **cmake** (`glog/generic.toml:2`) — glog 0.7.1 is CMake-only (the
  autotools build was dropped upstream after 0.4.0, and the release carries no dist
  tarball, so the git tag archive is the only source) (`glog/generic.toml:396-399`).
- source: GitHub tag archive `v0.7.1`, `--strip-components=1` (`glog/source.toml`).
- deps: none.
- recipes: `generic.toml`, `android.toml`.

## Overridden fields

```toml
args = ["-DBUILD_SHARED_LIBS=OFF", "-DBUILD_TESTING=OFF", "-DWITH_GFLAGS=OFF",
        "-DWITH_GTEST=OFF", "-DWITH_GMOCK=OFF", "-DWITH_PKGCONFIG=ON", "-DWITH_UNWIND=none"]
```
(`glog/generic.toml:501`)

- `BUILD_TESTING=OFF`: `include(CTest)` defaults it ON and glog then builds ten host test
  executables — a cross-link problem and target binaries never to run
  (`glog/generic.toml:400-404`).
- `WITH_GFLAGS=OFF`, `WITH_GTEST=OFF`, `WITH_GMOCK=OFF`: gflags is not in the prefix;
  googletest is, and leaving these on would link the test tree in
  (`glog/generic.toml:405-408`).
- `WITH_PKGCONFIG=ON`: upstream defaults it OFF (`glog/generic.toml:409`).
- `WITH_UNWIND=none`: a **reproducibility** choice — Bionic's sysroot has no unwind
  header, so `find_package(Unwind)` only ever succeeds on clang-native where it would pick
  up the *host's* libunwind and bake `-lunwind` into `Libs.private`, while every Android
  family compiles the generic path; left at the default the artifact would differ per
  system (`glog/generic.toml:411-420`).
- Android adds `-DANDROID=ON` (`glog/android.toml:459`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `ld.lld: error: undefined symbol: __android_log_write` for any `pkg-config --libs --static libglog` consumer | glog's `CMakeLists.txt:463-466` adds `log`/`-llog` only `if (ANDROID)`, and `ANDROID` is false because the toolchain file keeps `CMAKE_SYSTEM_NAME Linux`; so `Libs.private` is `-pthread` with no `-llog`, while `libglog.a` references `__android_log_write` (`glog/android.toml:425-443`) | set `-DANDROID=ON` — a cache answer to a question upstream already asks; the archive is byte-identical (only link metadata changes) (`glog/android.toml:452-458`) |
| `#error <glog/logging.h> was not included correctly` for a pkg-config consumer | `libglog.pc.in:11` has a literal `Cflags:` with no `@variable@`, so `GLOG_USE_GLOG_EXPORT` cannot be configured in; `logging.h:59-61` errors without it (`glog/generic.toml:503-516`) | rewrite the generated `.pc`'s `Cflags:` line to append `-DGLOG_USE_GLOG_EXPORT` in a `post` (a plain substitution of a build output, not a patch) (`glog/generic.toml:534`) |
| test executables built | `BUILD_TESTING` on by default (`glog/generic.toml:400-404`) | `-DBUILD_TESTING=OFF` |
