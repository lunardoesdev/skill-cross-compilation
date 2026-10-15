# leptonica

Image-processing library tesseract needs; installs `Libleptonica.a`, the
`leptonica/*.h` set and `lib/pkgconfig/lept.pc` (module name **`lept`**)
(`leptonica/generic.toml:3-6`).

- build system: **autoconf** (`leptonica/generic.toml:2`).
- source: GitHub release **asset** `leptonica-1.87.0.tar.gz` — a real `make dist`
  tarball shipping a generated `./configure`, `aclocal.m4`, `Makefile.in`,
  `config/ltmain.sh` and `m4/libtool*.m4` (`leptonica/source.toml:2-9`). Load-bearing:
  a bare tag/git archive could not be built here (no autotools).
- deps: `zlib`, `libpng`, `libjpeg-turbo`, `giflib`, `libtiff`, `libwebp`, `openjpeg`
  (`leptonica/generic.toml:1`).
- recipe: `generic.toml` only — nothing here is Android-specific (configure's library
  checks are compile/link tests, never runs) (`leptonica/generic.toml:67-69`).

## Overridden fields

```toml
configure_args = ["--enable-static", "--disable-shared", "--with-pic", "--disable-programs",
                  "--with-zlib", "--with-libpng", "--with-jpeg", "--with-giflib",
                  "--with-libtiff", "--with-libwebp", "--without-libwebpmux",
                  "--with-libopenjpeg"]
```
(`leptonica/generic.toml:70`)

- Each image format is asked for **by name** rather than left to configure's "check"
  default, so a missing one is a hard error (`"zlib support requested but ... not found"`)
  instead of a library that silently reads fewer formats (`leptonica/generic.toml:21-25`).
- `--without-libwebpmux`: the tree's libwebp builds with
  `-DWEBP_BUILD_LIBWEBPMUX=OFF`, so leptonica compiles the `webpanimiostub.c` instead of
  the animation reader (`leptonica/generic.toml:26-29`).
- `--disable-programs`: `prog/` holds `bin_PROGRAMS` (`convertformat`, `fileinfo`,
  `imagetops`, …) and the regression programs behind `ENABLE_PROGRAMS`
  (`leptonica/generic.toml:36-42`).
- fuzzers/tests/doc need no switch: they are off the default target (standalone phony
  targets, `check_PROGRAMS`) (`leptonica/generic.toml:44-57`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| a format silently missing from the built library | left to configure's "check" default (`leptonica/generic.toml:21-25`) | ask for each format by name so a miss is a hard configure error |
| `xtractprotos` run during `make` | the `allheaders` target builds+runs a target program to regenerate `src/allheaders.h` — but it is a standalone target, not in `all` (`leptonica/generic.toml:59-65`) | never invoke `make allheaders`; the generated headers ship in the tarball |
| webpanimio pulls in a library not present | libwebpmux is not built by this tree's libwebp (`leptonica/generic.toml:26-29`) | `--without-libwebpmux` |
| tesseract's pkg-config check for `lept` fails | wrong module name | the `.pc` is `lept.pc` / module `lept` (`leptonica/generic.toml:5-6`) |
