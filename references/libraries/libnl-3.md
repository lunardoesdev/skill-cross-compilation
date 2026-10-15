# libnl-3

Netlink socket library; installs `libnl-3.a` (and the family libs under `libnl/`).

- build system: **autoconf** (`libnl-3/generic.toml:2`).
- source: GitHub release `libnl-3.12.0.tar.gz`, `--strip-components=1`
  (`libnl-3/source.toml:5-12`).
- deps: `flex@native`, `bison@native` (`libnl-3/generic.toml:1`) — the parser is
  generated, so the generators must be host tools.
- recipes: `generic.toml`, `android.toml`.

## Overridden fields

```toml
configure_args = ["--enable-static", "--disable-shared", "--with-pic", "--enable-cli=no"]
```
(`libnl-3/generic.toml:212`) — static with PIC; `--enable-cli=no` drops the 51 CLI tools
and `libnl-cli-3` (the only object that links `-ldl`); the libraries need neither
(`libnl-3/generic.toml:5-8`).

Android adds `--disable-pthreads` and builds with an extra define
(`libnl-3/android.toml:200-203`):
```toml
configure_args = ["--enable-static", "--disable-shared", "--with-pic", "--enable-cli=no", "--disable-pthreads"]
post = """
make -j"$CORES" CFLAGS="$CFLAGS -Din_addr_t=uint32_t"
make install
"""
```

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `configure: error: libpthread is required` | `configure.ac:119` does `AC_CHECK_LIB([pthread],[pthread_mutex_lock],[],[AC_MSG_ERROR(...)])` — a **hard error**; Bionic ships no libpthread at any API level (`libnl-3/android.toml:184-197`) | `--disable-pthreads` (defines `DISABLE_PTHREADS`, making the internal locks no-ops) |
| a compile error around `in_addr_t` | the type/macro differs on the Android target | append `-Din_addr_t=uint32_t` to `CFLAGS` for the build (`libnl-3/android.toml:202`) |
| the parser is not generated / `flex`/`bison` demanded | the parser is generated at build time (`libnl-3/generic.toml:1`) | declare `flex@native`, `bison@native` |
