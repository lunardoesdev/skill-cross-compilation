# texinfo

The Texinfo toolchain (`makeinfo`, `install-info`, …); a build tool used to make
documentation.

- build system: **make** (`texinfo/generic.toml:2`).
- source: `ftp.gnu.org/gnu/texinfo/texinfo-7.3.tar.xz`, `--strip-components=1`
  (`texinfo/source.toml`).
- deps: `help2man@native`, `texinfo@source` (`texinfo/generic.toml:1`).
- recipe: `generic.toml` only.

## Overridden fields

```toml
pre = """
PATH="/usr/bin:/bin:$help2man_PREFIX/bin:$PATH"
BUILD_CC=/usr/bin/cc BUILD_AR=/usr/bin/ar BUILD_RANLIB=/usr/bin/ranlib ./configure $AUTOCONF_CONFIGURE_FLAGS
touch aclocal.m4 configure config.h.in
find . -name 'Makefile.in' | xargs touch
find . -name config.status | xargs touch
"""
```
(`texinfo/generic.toml:20-26`)

- Texinfo cross-builds native helpers; **use host tools before the NDK in nested
  configures** (`texinfo/generic.toml:18`) — hence `BUILD_CC/AR/RANLIB` pointed at
  `/usr/bin`.
- `touch`ing `aclocal.m4`, `configure`, `config.h.in`, all `Makefile.in` and all
  `config.status` keeps nested `config.status` newer so make does not reconfigure the
  native helpers (`texinfo/generic.toml:19,23-25`).
- `$help2man_PREFIX/bin` is put on `PATH` explicitly: a dependency in the recipe's **own
  system** is a link-time dependency and its bin dir is *not* added to `PATH`; only a
  cross-system (native) dependency contributes runnable programs. Since this is a native
  build, help2man is in the same system, so its bin must be added by hand
  (`texinfo/generic.toml:8-16`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `help2man: command not found` / `make[2]: *** [Makefile:2188: makeinfo.1] Error 127` | texinfo's `Makefile.am` builds `man/makeinfo.1` with `$(HELP2MAN)`, and nothing in the tree provides it (`texinfo/generic.toml:3-6`) | depend on `help2man@native` and put `$help2man_PREFIX/bin` on `PATH` in `pre` |
| make reconfigures native helpers mid-build | nested `config.status` older than its inputs | `find . -name config.status | xargs touch`, plus touching the autotools inputs (`texinfo/generic.toml:23-25`) |
