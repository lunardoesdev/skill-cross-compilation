# vid.stab

Video-stabilisation (motion-detection) library; installs `libvidstab.a`,
`include/vid.stab/*.h`, `vidstab.pc`.

- build system: **cmake** (`vid.stab/generic.toml:2`).
- source: GitHub tag archive `v1.1.2`, `--strip-components=1` (`vid.stab/source.toml:5-9`).
- deps: none.
- recipe: `generic.toml` only — nothing differs for Android (`vid.stab/generic.toml:915-919`).

## Overridden fields

```toml
args = ["-DBUILD_SHARED_LIBS=OFF", "-DUSE_OMP=OFF"]
```
(`vid.stab/generic.toml:920`)

- `BUILD_SHARED_LIBS=OFF`: upstream defaults ON; a target prefix has no loader path
  (`vid.stab/generic.toml:892-894`).
- **`USE_OMP=OFF`**: upstream defaults ON, and with OpenMP found `CMakeLists.txt:58-60`
  compiles the `#pragma omp` paths with the OpenMP flag while `:89-94` puts that flag into
  `PKG_EXTRA_LIBS`, so every consumer of `vidstab.pc` would have to link an OpenMP runtime.
  The NDK r29 aarch64 sysroot ships no `libomp`, and the archive's members would reference
  `GOMP_*` symbols no link in the tree can resolve (`vid.stab/generic.toml:896-904`).

## What it needs from the system

Only the CMake toolchain file. `CMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY` keeps
`find_package(OpenMP)`/`find_package(Orc)` looking in the prefix and sysroot, not the host
(`vid.stab/generic.toml:917-919`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `undefined reference to GOMP_*` for a static consumer, or a `.pc` demanding an OpenMP runtime | `USE_OMP` on by default bakes the OpenMP flag into `PKG_EXTRA_LIBS` and compiles `#pragma omp` (`vid.stab/generic.toml:896-904`) | `-DUSE_OMP=OFF` |
| test suite / `transcode/` CLIs built | they are never entered — the top-level `CMakeLists.txt` has **no `add_subdirectory()`** (`vid.stab/generic.toml:906-910`) | none needed |
| the `.pc` version looks wrong (`1.20`) | the tag's `CMakeLists.txt:12-15` computes `${MAJOR}.${MINOR}${PATCH}` = `1.20` (`vid.stab/source.toml:928-932`) | cosmetic; only the `.pc` carries it |
