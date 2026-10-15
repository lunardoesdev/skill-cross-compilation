# capnproto

Cap'n Proto serialization library; installs the `lib*.a` archives, headers, `.pc` and the
cmake package config. **Library-only** — the `capnp` compiler programs are intentionally
omitted, so consumers must generate code with a host `capnp`.

- build system: **autoconf** (`capnproto/generic.toml:2`).
- source: `capnproto.org/capnproto-c++-1.5.0.tar.gz`, `--strip-components=1`
  (`capnproto/source.toml`).
- deps: `capnproto@source`, `zlib`, `openssl` (`capnproto/generic.toml:1926`).
- recipe: `generic.toml` only.

## Overridden fields

```toml
configure_args = ["--enable-static", "--disable-shared", "--without-fibers",
                  "--with-zlib", "--with-openssl"]
make = false
install = false
post = """
make -j"$CORES" install-libLTLIBRARIES
make -j"$CORES" install-data
"""
```
(`capnproto/generic.toml:1955-2006`)

- **`--without-fibers` is load-bearing**: `configure.ac:253-289` probes
  `makecontext`/`getcontext`/`swapcontext` to decide on fibers; Bionic has a `<ucontext.h>`
  but declares **none** of those three at any API level. Left alone, configure falls through
  to `-lucontext` (not in the prefix), only warns, and the artifact differs per system;
  stated, `-DKJ_USE_FIBERS=0` is set everywhere (`capnproto/generic.toml:1933-1946`).
- `--with-zlib`/`--with-openssl` pin the two optional libraries that exist, so `libkj-gzip`
  / `libkj-tls` are unconditional rather than depending on probe luck
  (`capnproto/generic.toml:1948-1954`).
- **`make = false` / `install = false` and a hand-written `post`, because `make all` and
  `make install` RUN the freshly-built target `capnp` binary**: `BUILT_SOURCES`
  (`Makefile.am:496`) is the test `capnpc_outputs`, produced by a rule that executes
  `./capnp compile ...` (`capnproto/generic.toml:1959-1970`). The `post` therefore names only
  the install targets that do **not** go through `BUILT_SOURCES`:
  `install-libLTLIBRARIES` (archive+headers, but not the programs) and `install-data`
  (headers, `.pc`, cmake config) (`capnproto/generic.toml:1972-1994`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `make` runs the just-linked target `capnp` binary (impossible cross) | `BUILT_SOURCES` is a prerequisite of `all`, `install`, `install-exec`, `check` and `distdir`, and its rule executes the target program (`capnproto/generic.toml:1959-1970`) | drive `install-libLTLIBRARIES` + `install-data` directly, never `make all`/`install` |
| `getcontext`/`makecontext` undeclared, or `-lucontext` not found (warning) | fibers probe; Bionic's `<ucontext.h>` declares none of them (`capnproto/generic.toml:1933-1946`) | `--without-fibers` |
| `libkj-gzip`/`libkj-tls` silently absent on some systems | optional libs left at `check` depend on probe results (`capnproto/generic.toml:1948-1954`) | `--with-zlib --with-openssl` |
