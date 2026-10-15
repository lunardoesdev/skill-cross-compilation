# libtasn1

ASN.1 DER/BER library; installs `libtasn1.a`, `libtasn1.h`, `libtasn1.pc`.

- build system: **autoconf** (`libtasn1/generic.toml:2`).
- source: `ftp.gnu.org/gnu/libtasn1/libtasn1-4.21.0.tar.gz`, `--strip-components=1`
  (`libtasn1/source.toml:16-25`). The tarball ships a generated `./configure` plus the
  **generated parser `lib/ASN1.c`** with the same mtime as `lib/ASN1.y` — load-bearing,
  because the system carries no autotools and no bison on the host
  (`libtasn1/source.toml:5-10`).
- deps: none.
- recipe: `generic.toml` only.

## Overridden fields

```toml
configure_args = ["--enable-static", "--disable-shared", "--with-pic", "--disable-doc"]
make_args = "-C lib"
install_args = "-C lib"
make = true
install = true
```
(`libtasn1/generic.toml:35,44-47`)

- The three CLI tools (`asn1Parser`, `asn1Coding`, `asn1Decoding`) have **no disable
  switch** — upstream builds them from `src/`. So the *library subdirectory is named
  instead*: `make -C lib` / `make -C lib install` builds and installs exactly what a
  consumer reads — `libtasn1.la`, `includes/libtasn1.h`, `libtasn1.pc`
  (`libtasn1/generic.toml:5-14`).
- `--disable-doc` also gates `SUBDIRS += doc examples`, and `examples/` holds more
  target programs (`libtasn1/generic.toml:16-18`).
- `--enable-static --disable-shared --with-pic`: cross target has no loader path; the
  archive is meant to be linked into a shared library later (LT_INIT default is both)
  (`libtasn1/generic.toml:27-30`).
- `make/install` asserted because a preceding `make=false` node would leak
  (`libtasn1/generic.toml:37-46`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| a host `bison` is demanded, or `ASN1.c` gets regenerated | the shipped `ASN1.c` mtime vs `ASN1.y`; if the source copy does not preserve mtimes make calls `$(YACC)` (`libtasn1/source.toml:5-10`) | rely on the shipped generated parser; do not add bison — verify mtimes survived the copy |
| target CLI binaries get built | no configure switch for the tools (`libtasn1/generic.toml:5-9`) | build/install only `lib/` via `-C lib` |
| this node's steps skipped in silence | inherited `${BS_make:-}` (`libtasn1/generic.toml:37-42`) | assert `make = true`, `install = true`, clear args |
