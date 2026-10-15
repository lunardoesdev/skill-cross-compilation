# libpng

PNG library; installs `libpng.a`, `png.h`/`pngconf.h`, `libpng.pc`.

- build system: **autoconf** (`libpng/generic.toml:2`).
- source: SourceForge `libpng-1.6.48.tar.gz`, with the GitHub tag archive as fallback,
  `--strip-components=1` (`libpng/source.toml:5-12`).
- deps: `zlib` (`libpng/generic.toml:1`).
- recipe: `generic.toml` only.

## Overridden fields

None beyond the driver's triplet/prefix — the recipe is essentially the `deps` line plus
a comment. The only project-specific behaviour is in how zlib is found.

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| a hard error that `LIBS` cannot override, e.g. zlib "not found" on mingw | libpng's zlib probe **hardcodes `-lz` and prepends its own `-lz`**, so `LIBS` cannot override it and a missing `-l` is a hard error (`libpng/generic.toml:3-5`) | on mingw, where zlib installs as `libzlib`, the `-lz` alias is created in **zlib's** `mingw64.toml`, not here (`libpng/generic.toml:3-5`, `zlib/mingw64.toml:6-10`) |
| zlib header not found although it was just built | `CPPFLAGS` must place the dependency prefix **first**, or configure's `$CC -E` probes find an old header in the sysroot | set the dependency prefix first in `CPPFLAGS` (see the autoconf driver's notes) |
