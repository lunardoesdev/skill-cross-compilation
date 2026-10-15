# gnutls

The TLS library; installs `libgnutls.a`, `include/gnutls`, and `gnutls.pc`.

- build system: **autoconf** (`gnutls/generic.toml:2`).
- source: `www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-3.8.13.tar.xz`,
  `--strip-components=1` (`gnutls/source.toml:17-26`). The tarball ships a generated
  `./configure` plus `aclocal.m4`, every `Makefile.in` and the gnulib copies under
  `gl/`, `po/`, `lib/unistring` — which is what makes it buildable in a system with no
  autotools on purpose (`gnutls/source.toml:5-10`).
- deps: `gmp`, `nettle` (>= 3.10), `libtasn1` (>= 4.9), `zlib`
  (`gnutls/generic.toml:1`, `gnutls/source.toml:12-14`).
- recipe: `generic.toml` only — nothing here is Android-specific; the driver passes
  `--host=aarch64-linux-android` and the system's `$CFLAGS` carry `-DANDROID`
  (`gnutls/generic.toml:81-85`).

## Overridden fields

Everything optional the tree does not carry is turned off **by name**, read from
`configure --help` of 3.8.13 rather than guessed (`gnutls/generic.toml:10-51`):

```toml
configure_args = ["--enable-static", "--disable-shared", "--disable-tools", "--disable-tests",
                  "--disable-doc", "--disable-nls", "--without-p11-kit", "--without-tpm2",
                  "--without-tpm", "--disable-libdane", "--without-idn", "--without-brotli",
                  "--without-zstd", "--with-included-unistring", "--without-included-libtasn1",
                  "--disable-srp-authentication", "--disable-openssl-compatibility"]
```
(`gnutls/generic.toml:86`)

- `--enable-static --disable-shared` must be stated: gnutls' configure is
  `LT_INIT([disable-static,...])`, so the default is a shared library with no archive
  (`gnutls/generic.toml:72-74`).
- `make = true`, `install = true`, `targets/make_args/install_args` cleared
  (`gnutls/generic.toml:88-99`) — because a dependency (built in `post`) would
  otherwise leak its `make=false/install=false` into this node.

## What it needs from the system

The dependency prefix's include/lib dirs and `.pc` files (via the closure's
`PKG_CONFIG_LIBDIR`), `$CC`/`$CFLAGS`, and a C++ compile probe. `--disable-tools` also
drops the `cligen` python code generator (`gnutls/generic.toml:54-57`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| configure cannot finish: `p11-kit >= 0.23.1 was not found` | `--without-p11-kit` is not optional in the useful sense: `configure.ac:929-951` runs `PKG_CHECK_MODULES(p11-kit-1)` unless the flag is given, and errors with nothing to find (`gnutls/generic.toml:12-17`) | pass `--without-p11-kit` |
| `Libunistring was not found` | no libunistring in the tree; `configure.ac:522-532` fails unless the bundled copy is chosen (`gnutls/generic.toml:33-38`) | `--with-included-unistring` (the copy inside the package, not a host library) |
| a target binary is run during the build | the FIPS hmac rule (`lib/Makefile.am:266-281`) is an `all-local` that runs `fipshmac` — the one place gnutls executes an aarch64 binary | leave `--enable-fips140-mode` unset (`gnutls/generic.toml:66-70`) |
| a silently downgraded build (compression missing) | an optional dep defaults on and falls back invisibly (`gnutls/generic.toml:29-31`) | keep `zlib` as a dependency and state the choice; turn off `brotli`/`zstd` by name |
| this node's build/install skipped in silence; empty entry published (exit 0) | node inherits `${BS_make:-}` from a preceding `make=false` dependency (`gnutls/generic.toml:88-94`) | assert `make = true`, `install = true`, clear the args fields |
