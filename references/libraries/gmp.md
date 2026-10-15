# gmp

Arbitrary-precision arithmetic; installs `libgmp.a` (+ `libgmpxx` with `--enable-cxx`).

- build system: **autoconf** (`gmp/generic.toml:2`).
- source: `ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz`, `--strip-components=1`
  (`gmp/source.toml:3-12`).
- deps: none.
- recipe: `generic.toml` only.

## Overridden fields

```toml
configure_args = ["--enable-cxx", "--disable-static"]
post = """
make -j"$CORES" install-html
"""
```
(`gmp/generic.toml:5-8`)

- `--enable-cxx`: also builds the C++ interface (an archive in the same prefix).
- `--disable-static`: **note this is the reverse of the usual convention** — this tree's
  gmp recipe ships the *shared* gmp. Consumers (nettle/hogweed) resolve it through the
  prefix; verify the consumer links what actually exists.
- No `--docdir`: upstream's default already lands under `$OUT`, and pinning a version
  would go stale on a bump (`gmp/generic.toml:3-4`).
- `post` runs `make install-html` to add the HTML manual (`gmp/generic.toml:7`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| docs rebuilt / a manual-generating tool demanded on the host | the same mtime trap as `help2man`/`m4`: the shipped docs can land older than their sources | this recipe keeps the default docdir and installs prebuilt HTML; `touch` shipped generated docs (as `help2man`/`m4` do) if a rebuild appears |
| a consumer links a *static* gmp that is not there | `--disable-static` means only the shared gmp is installed (`gmp/generic.toml:5`) | confirm the consumer's `.pc`/link expects shared, or flip the flag for that consumer |
