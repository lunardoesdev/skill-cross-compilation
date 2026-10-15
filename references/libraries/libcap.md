# libcap

POSIX capabilities library; installs `libcap.a`, `sys/capability.h`, `libcap.pc`
(plus `libpsx` with `PTHREADS=yes`).

- build system: **make** (`libcap/generic.toml:2`) — hand-written, driven by
  `Make.Rules`; **no configure and no autotools**, and no `config.h.in` to guard
  (`libcap/generic.toml:1105-1116`).
- source: kernel.org mirror `libcap-2.78.tar.xz`, `tar -xJf`, `--strip-components=1`
  (`libcap/source.toml:4-11`).
- deps: none.
- recipe: `generic.toml` only.

## Overridden fields

```toml
make = false
install = false
post = """
make -C libcap CC="$CC" AR="$AR" RANLIB="$RANLIB" BUILD_CC="cc" lib=lib prefix="$OUTPKG" \
     SHARED=no PTHREADS=yes USE_GPERF=no PAM_CAP=no GOLANG=no
make -C libcap install ... (same variables)
"""
```
(`libcap/generic.toml:1107-1158`)

- **The toolchain goes ON THE MAKE LINE, not in the environment.** `Make.Rules:68` is a
  hard assignment `CC := $(CROSS_COMPILE)gcc`, and `:=` inside the makefile beats an
  exported environment variable; a command-line variable overrides makefile assignments of
  any kind (`libcap/generic.toml:1118-1125`).
- **`BUILD_CC` is the exception that must NOT be the target compiler**: `Makefile:82-86`
  builds `_makenames` with `BUILD_CC` and **runs** it (`./_makenames > cap_names.h`) to
  generate the capability-name table; on a cross build a target binary could not run
  (`libcap/generic.toml:1127-1134`).
- `lib=lib`: `Make.Rules:20-22` otherwise derives the libdir by running `ldd /usr/bin/ld`
  on the **build** machine — answering `lib64` on this host and installing to `$OUT/lib64`
  (`libcap/generic.toml:1136-1141`).
- `prefix=$OUTPKG`: switches the install layout to autoconf-style prefixes so
  `LIBDIR/INCDIR/PKGCONFIGDIR` derive from it (`libcap/generic.toml:1143-1145`).
- `SHARED=no`: static-only prefix; also avoids the `loader.txt` step that builds an
  executable and runs `OBJCOPY --dump-section` (`libcap/generic.toml:1147-1149`).
- `USE_GPERF=no`: `Make.Rules:106` probes `which gperf` on the build machine, so leaving it
  on would make `cap_text.c` compile differently depending on the host
  (`libcap/generic.toml:1151-1154`).
- `PAM_CAP=no`, `GOLANG=no`: keep the top-level Makefile from recursing into `pam_cap` and
  the Go bindings (`libcap/generic.toml:1155-1156`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| every object built with a bare host `gcc` | an exported `CC` is ignored because `Make.Rules:68` uses `:=` (`libcap/generic.toml:1118-1125`) | pass `CC/AR/RANLIB` on the make **command line** |
| the build tries to run a target binary (`./_makenames`) | `BUILD_CC` defaulted to `$(CC)` (the cross compiler) (`libcap/generic.toml:1127-1134`) | set `BUILD_CC=cc` (the host compiler) |
| the archive installs under `$OUT/lib64` | `Make.Rules` derives libdir by running `ldd /usr/bin/ld` on the build machine (`libcap/generic.toml:1136-1141`) | pass `lib=lib` |
