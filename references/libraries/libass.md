# libass

Subtitle renderer; installs `libass.a`, `include/ass/*.h`, `libass.pc`.

- build system: **autoconf** (`libass/generic.toml:2`).
- source: GitHub release `libass-0.17.5.tar.gz` — ships a generated `./configure`.
  Load-bearing: a git checkout or an upstream `make dist` that stops shipping one could
  not be built here (no autotools) (`libass/source.toml:1-8`).
- deps: `freetype`, `harfbuzz`, `fribidi`, `fontconfig` (`libass/generic.toml:1`).
- recipe: `generic.toml` only — nothing differs for Android (`libass/generic.toml:704-706`).

## Overridden fields

```toml
configure_args = ["--enable-static", "--disable-shared", "--with-pic", "--enable-fontconfig",
                  "--disable-test", "--disable-compare", "--disable-profile", "--disable-fuzz"]
```
(`libass/generic.toml:707`)

- The three required libraries are **hard pkg-config checks with no switch of their own**:
  `configure.ac:95` wants freetype2 >= 9.17.3, `:101` fribidi >= 0.19.1, `:107` harfbuzz
  >= 1.2.3, each a bare `PKG_CHECK_MODULES` — a miss stops configure. They are on because
  the deps are declared, not because of a flag (`libass/generic.toml:669-675`).
- `--enable-fontconfig`: the fourth check and the only optional one; it is asked for
  explicitly because `configure.ac:236-249` **refuses to configure** with "No system font
  provider!" when none was found (`libass/generic.toml:677-681`).
- `--disable-test/compare/profile/fuzz`: all four gates build target programs
  (`Makefile_util.am:1-24`); upstream defaults to no, stated so the intent is not resting
  on a default (`libass/generic.toml:683-691`).
- `--with-pic` also reaches the assembly: `configure.ac:258-260` sets `ASFLAGS="-DPIC=1"`
  (`libass/generic.toml:695-696`).
- Assembly stays on: an aarch64 target needs no external assembler — configure sets
  `cpu_family=aarch64`/`can_asm=true` without looking for nasm, and the NDK's clang
  assembles `libass/aarch64/*.S` with the C preprocessor (`libass/generic.toml:698-702`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `configure` stops on freetype/harfbuzz/fribidi, or `No system font provider!` | the checks are hard, and no font provider means configure refuses (`libass/generic.toml:669-681`) | declare the deps and `--enable-fontconfig` |
| a host `nasm` demanded | only the x86 assembly path looks for nasm (`libass/generic.toml:698-702`) | none needed for aarch64 — do not `--disable-asm` |
| a shipped configure is missing | source is a git archive instead of a release tarball (`libass/source.toml:1-8`) | take the release tarball (which ships the generated configure) rather than adding autoreconf |
