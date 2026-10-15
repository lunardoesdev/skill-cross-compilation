# zimg

Image-scaling/format-conversion library (z.lib); installs `libzimg.a`, two public headers,
`zimg.pc`.

- build system: **autoconf** (`zimg/generic.toml:2`).
- source: GitHub tag archive `release-3.0.6`, `--strip-components=1`. The tag archive has
  **no `configure`** — it is a plain git archive (`configure.ac`, `Makefile.am`, `m4/`),
  and the release object has an empty `assets` list, so the archive is all upstream
  publishes (`zimg/source.toml:5-9`).
- deps: `autoconf@native`, `automake@native`, `libtool@native` (`zimg/generic.toml:1`).
- recipe: `generic.toml` only — nothing is Android-specific (`zimg/generic.toml:1051-1052`).

## Overridden fields

```toml
pre = "sh autogen.sh"
configure_args = ["--disable-shared", "--enable-static", "--disable-testapp",
                  "--disable-example", "--disable-unit-test"]
make = true
install = true
targets = ""
make_args = ""
install_args = ""
```
(`zimg/generic.toml:1053-1074`)

- `autogen.sh` is upstream's own entry point — one `autoreconf --verbose --install --force`
  — and each of the three autotools it needs is a real tool this build runs, so all three
  are `@native` (`zimg/generic.toml:1023-1033`).
- `--disable-unit-test`: the unit tests would have to build through **cmake**, i.e. run a
  target library the host cannot use (`zimg/generic.toml:1038-1044`).
- `make`/`install`/args asserted because the nodes before it are the native autotools,
  whose recipes set `make=false/install=false`; without the assertion this node skipped its
  steps in silence and **published an empty directory while exiting 0** — observed on
  `libtool@clang-native` (`zimg/generic.toml:1056-1068`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `configure: No such file or directory` | the tag archive ships sources only (`zimg/source.toml:5-9`) | run `sh autogen.sh` in `pre`, depend on `autoconf/automake/libtool@native` |
| this node's build/install skipped in silence; **empty entry published, exit 0** | node inherits `${BS_make:-}` from a preceding `make=false` @native node (`zimg/generic.toml:1056-1068`) | assert `make = true`, `install = true`, clear `targets/make_args/install_args` |
| unit tests try to build through cmake | `configure.ac` builds them via cmake (`zimg/generic.toml:1038-1044`) | `--disable-unit-test` |
