# protobuf-c

Protocol Buffers C runtime; installs `libprotobuf-c`, `protobuf-c/protobuf-c.h`, the
`.proto` and `libprotobuf-c.pc`. **No dependency on Google protobuf**.

- build system: **autoconf** (`protobuf-c/generic.toml:2`).
- source: GitHub release `protobuf-c-1.5.1.tar.gz` — an automake `dist` archive already
  carrying a generated `configure`, `Makefile.in`, `config.h.in`, `aclocal.m4` and the
  inlined `m4/` macros (`protobuf-c/source.toml:6-11`).
- deps: none.
- recipe: `generic.toml` only.

## Overridden fields

```toml
configure_args = ["--enable-static", "--disable-shared", "--with-pic", "--disable-protoc"]
```
(`protobuf-c/generic.toml:1378`)

- **`--disable-protoc` is the whole point**: every trace of a protobuf dependency lives
  inside the `protoc` branch of `configure.ac`:
  - `configure.ac:68` declares it, and `:70` puts the check (including
    `PKG_CHECK_MODULES([protobuf], [protobuf >= 3.0.0])` at `:73`) inside
    `if test "x$enable_protoc" != "xno"`.
  - `configure.ac:89` then **runs** the found `protoc` to get a version string — a host
    program executed during configure.
  - `Makefile.am:75` opens `if BUILD_COMPILER`, and everything needing protoc or protobuf
    C++ lives inside it (the `protoc-gen-c` program, its sources, its `-lprotoc` link, the
    `BUILT_SOURCES` rule that invokes `@PROTOC@`) (`protobuf-c/generic.toml:1331-1349`).
- The library itself needs none of it: its sources are portable C with no generated files
  and its `.pc` carries no `Requires.private` (`protobuf-c/generic.toml:1350-1357`).
- The `build-cmake/` path is deliberately **not** used: it runs `find_package(Protobuf)`
  and `absl` *before* `BUILD_PROTOC` is even declared, so `-DBUILD_PROTOC=OFF` would not
  remove the dependency there (`protobuf-c/generic.toml:1366-1373`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `configure` fails needing `protobuf >= 3.0.0`, or runs a `protoc` during configure | the protoc branch is on by default (`protobuf-c/generic.toml:1331-1349`) | `--disable-protoc` |
| the CMake path still demands protobuf/absl | its `find_package` calls precede the `BUILD_PROTOC` option (`protobuf-c/generic.toml:1366-1373`) | use the autotools path with `--disable-protoc` |
