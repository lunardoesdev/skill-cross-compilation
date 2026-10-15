# openblas

BLAS + (f2c-converted) LAPACK; installs `libopenblas.a`.

- build system: **make** (`openblas/generic.toml:2`) — no configure; driven from `post`.
- source: GitHub release `OpenBLAS-0.3.34.tar.gz`, `--strip-components=1`
  (`openblas/source.toml`).
- deps: none.
- recipe: `generic.toml` only.

## Overridden fields

```toml
make = false
install = false
post = """
make ... HOSTCC=cc $OB_TARGET_ARGS NOFORTRAN=1 NO_SHARED=1 CC="$CC" AR="$AR" RANLIB="$RANLIB" PREFIX=$OUTPKG
make ... (same variables) install
"""
```
(`openblas/generic.toml:2029-2082`)

- **`HOSTCC` must be the build machine's compiler, not the target's.** `Makefile.system:320`
  runs `Makefile.prebuild` at parse time, which runs `c_check`, `f_check`, `getarch`,
  `getarch_2nd` and reads their stdout back into `Makefile.conf`/`config.h`. `HOSTCC`
  defaults to `$(CC)` (the cross compiler), so `getarch` would be built as a target binary
  and executed on the host (`openblas/generic.toml:2032-2046`).
- **`TARGET` is OpenBLAS's supported-microprocessor name** (not a triplet), added only for a
  cross build: it makes `getarch` answer for the target (`-DFORCE_$(TARGET)`). Without it an
  x86_64 build machine reports x86_64 and the build compiles x86_64 assembly with the target
  compiler — `Makefile:194-195` turns that into an explicit "Detecting CPU failed. Please
  set TARGET explicitly" (`openblas/generic.toml:2048-2060`). Mapping used: aarch64/armv7a →
  `ARMV8`, x86_64 → `HASWELL`, i686 → `ATOM`, and an unknown arch **exits 1**
  (`openblas/generic.toml:2061-2070`). On `clang-native`, build == host, so `TARGET` is left
  empty (`openblas/generic.toml:2056-2060`).
- `NOFORTRAN=1`: no Fortran compiler anywhere; `f_check.pl` reaches the same answer, this
  states it (`openblas/generic.toml:2071-2075`).
- `NO_SHARED=1`: static-only prefix (`openblas/generic.toml:2076`).
- The **same variables must be given to the install line**, because install re-runs
  `Makefile.install` against the same configuration (`openblas/generic.toml:2078-2082`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `getarch` is built as a target binary and run on the host | `HOSTCC` defaults to the cross `$(CC)` (`openblas/generic.toml:2041-2046`) | `HOSTCC=cc` |
| `Detecting CPU failed. Please set TARGET explicitly` | no `TARGET`, so `getarch` answered for the build machine (`openblas/generic.toml:2048-2054`) | pass the mapped `TARGET=...` on a cross build only |
| the install uses a different configuration than the build | install re-runs `Makefile.install` (`openblas/generic.toml:2078-2081`) | repeat every variable on the install line |
