# xvidcore

MPEG-4 ASP (Xvid) codec; installs `libxvidcore.a` and the versioned shared object
`libxvidcore.so.4.3` (+ symlinks).

- build system: **autoconf** (`xvidcore/generic.toml:2`) — but the build body is **not at
  the top of the tarball**: the Makefile and the hand-written configure both live in
  `build/generic`, and the Makefile reads sources through `SRC_DIR = ../../src`
  (`xvidcore/generic.toml:3-7`).
- **`source_dir = "build/generic"`** (`xvidcore/generic.toml:8`).
- source: `downloads.xvid.com/downloads/xvidcore-1.3.7.tar.gz`, `--strip-components=1`
  (`xvidcore/source.toml:5-11`).
- deps: none.
- recipe: `generic.toml` only.

## Overridden fields

```toml
make = false
install = false
post = """
touch platform.inc
make -j"$CORES"
make DESTDIR="$DESTDIR" install
"""
```
(`xvidcore/generic.toml:859-865`)

- The configure is an autoconf script and **does take `--host`** (the driver passes it);
  its `config.sub` knows android (`aarch64-linux-android` → `host_os=linux-android`), and
  the `linux*` arm of `configure.in:304` names the libraries (`xvidcore/generic.toml:9-16`).
  `configure.in:188` has no aarch64 case, so aarch64 falls through to `GENERIC` (plain C)
  and the x86 assembly / nasm probe is never reached (`xvidcore/generic.toml:15-18`).
- There is **no static-only switch**: this configure has only six options and no
  shared/static one, so both libraries are built (`xvidcore/generic.toml:20-28`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `configure` re-run with **no arguments** (losing `--prefix` and the host triple) before building | the autoconf driver `touch`es `./configure` after running it, and the Makefile has `platform.inc: configure platform.inc.in` — make takes the configure we just ran as older than its input (`xvidcore/generic.toml:22-27`) | `touch platform.inc` so the configured file is current (`xvidcore/generic.toml:862`) |
| install wrote into the final path, staging skipped; `.../.relax-list: No such file or directory` | `platform.inc` (generated from `platform.inc.in:62`) **assigns `DESTDIR=`**, and a makefile assignment beats the environment (`xvidcore/generic.toml:28-33`) | `make DESTDIR="$DESTDIR" install` — a command-line assignment wins (`xvidcore/generic.toml:864`) |
| the build runs in the wrong directory | the Makefile is in `build/generic` (`xvidcore/generic.toml:3-7`) | set `source_dir = "build/generic"` |
