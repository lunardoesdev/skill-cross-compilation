# nettle

Crypto library; installs `libnettle.a`, `libhogweed.a`, their headers and `.pc` files.

- build system: **autoconf** (`nettle/generic.toml:2`).
- source: `mirrors.kernel.org/gnu/nettle/nettle-3.10.2.tar.gz`, `--strip-components=1`
  (`nettle/source.toml:3-12`). Ships a generated `configure`, `Makefile.in`,
  `config.h.in` (`nettle/generic.toml:12-14`).
- deps: `gmp` (`nettle/generic.toml:1`).
- recipe: `generic.toml` only.

## Overridden fields

```toml
configure_args = ["--disable-shared", "--enable-static", "--disable-mini-gmp", "--disable-documentation"]
```
(`nettle/generic.toml:22`)

- `--disable-mini-gmp`: nettle bundles a small GMP shim and uses it by default; use the
  real GMP from the prefix instead (`nettle/generic.toml:4-7`).
- `--disable-documentation`: drops the texinfo manual, which would otherwise want
  `makeinfo`/`sgml` on the host (`nettle/generic.toml:8-9`).
- `--enable-public-key` is left alone — nettle's own code, no external library
  (`nettle/generic.toml:10-11`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `WARNING: unrecognized options: --with-pic` (and the option does nothing) | nettle has no `--with-pic`; PIC is **ON by default** and the only flag is `--disable-pic` (`nettle/generic.toml:15-21`) | pass nothing for PIC — an accepted-but-ignored option makes a recipe *look* deliberate when it is not |
