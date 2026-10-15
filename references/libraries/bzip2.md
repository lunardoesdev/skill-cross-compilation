# bzip2

The bzip2 library and CLI; installs `libbz2.a`, `bzlib.h`, and the `bzip2` binaries.

- build system: **make** (`bzip2/generic.toml:2`) — a hand-written Makefile with **no
  configure at all**.
- source: `sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz`, `--strip-components=1`
  (`bzip2/source.toml:3-12`).
- deps: none.
- recipe: `generic.toml` only.

## Overridden fields

```toml
make = false
install = false
post = """ ... """
```
(`bzip2/generic.toml:3-42`) — the driver's default `make`/`install` steps are off; the
`post` does everything explicitly:

1. `make ... bzip2 bzip2recover` — build the two utilities by name; the default target
   would run the test suite (`bzip2/generic.toml:6-7`).
2. copy `*.exe` → bare names **only when the `.exe` exists** (`bzip2/generic.toml:28-30`).
3. `make ... PREFIX="$PREFIX" install` — the *staged* prefix, not `$OUTPKG`
   (`bzip2/generic.toml:42`).

## What it needs from the system

`$CC/$AR/$RANLIB/$CFLAGS/$LDFLAGS` must be passed **on the make line**, because the
Makefile has no config step to read the environment.

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `cannot stat 'bzip2'` on install (Windows) | the PE driver appends `.exe` to `-o bzip2`, so the linked files are `bzip2.exe`/`bzip2recover.exe`, while the install rule copies the bare names and there is no `EXEEXT` to set (`bzip2/generic.toml:8-19`) | copy `X.exe` → `X` before install, **guarded** by `[ -f "$X.exe" ]` |
| `cp: cannot stat 'bzip2.exe': No such file or directory` on every non-mingw build | an ELF `-o bzip2` produces no `.exe`, so an unconditional copy fails (`bzip2/generic.toml:20-27`) | guard the copy on the suffixed name existing |
| install wrote into the published path; `.../.relax-list: No such file or directory`, then an empty entry is published | bzip2 has **no DESTDIR support** — its install rule copies into `$(PREFIX)/...` itself, so the prefix handed to install *is* the destination (`bzip2/generic.toml:31-41`) | pass the **staged** `$PREFIX`, not `$OUTPKG`; `DESTDIR` is exported but bzip2 ignores it |
