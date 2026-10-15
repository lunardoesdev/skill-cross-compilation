# xz (liblzma)

The `liblzma` compression library (plus the xz CLI in a normal build).

- build system: **autoconf** (`xz/generic.toml:2`).
- source: GitHub release `xz-5.8.1.tar.xz` from `tukaani-project/xz`,
  `--strip-components=1` (`xz/source.toml:3-12`).
- deps: none.
- recipe: `generic.toml` only.

## Overridden fields

```toml
configure_args = ["--disable-nls", "--disable-shared", "--disable-unxz", "--disable-lzmadec",
                  "--disable-lzmainfo", "--disable-lzlinks", "--disable-scripts", "--disable-doc"]
install_args = "DESTDIR=$DESTDIR"
```
(`xz/generic.toml:15,31`)

- `--disable-nls`: no gettext at build time; `--disable-unxz/lzmadec/...`: the optional
  tooling is not part of the target prefix.
- `--disable-shared` is a **policy correction, not a necessity** — libtool builds both
  by default; liblzma's shared object is not load-bearing the way libbfd/libext2fs are,
  and all five consumers reach it through pkg-config and link the archive
  (`xz/generic.toml:5-14`).
- `install_args = "DESTDIR=$DESTDIR"` is mandatory — see below.

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| install wrote straight into the published path; `.../.relax-list: No such file or directory` | automake's installed `Makefile` **assigns `DESTDIR` itself**, and a Makefile variable beats the environment, so the exported `DESTDIR` never reached the install (`xz/generic.toml:20-28`) | carry it on the command line: `install_args = "DESTDIR=$DESTDIR"` (same line in help2man and openssl) |
| the defect only appears on rebuild | a fresh entry is skipped, so the bad install path is never exercised the first time (`xz/generic.toml:27-28`) | always test install-path changes on a rebuild, not a fresh nest |
