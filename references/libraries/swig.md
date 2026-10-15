# swig

Interface/code generator. **A host tool in practice**: it emits a `.cxx` wrapper the
*consumer's* build compiles and links into the target; nothing swig produces is linked
into the target at build time. The only artifacts are the `swig` executable and `Lib/*.swg`
(architecture-independent) (`swig/generic.toml:1181-1189`).

- build system: **cmake** (`swig/generic.toml:2`).
- source: SourceForge `swig-4.5.1.tar.gz`, Debian orig tarball as fallback,
  `--strip-components=1` (`swig/source.toml:6-13`).
- deps: `pcre2`, `swig@source`, `swig@native`, `swig` (`swig/generic.toml:1179`).
- recipe: `generic.toml` only.

## Overridden fields

```toml
args = ["-DWITH_PCRE=ON"]
```
(`swig/generic.toml:1227`)

- **CMake, not autotools, and for a concrete reason**: this release ships **no generated
  `configure`** (verified), only `configure.ac`; and the header template `configure.ac:10`
  declares is missing — the tree has only `Tools/cmake/swigconfig.h.in`, the *cmake*
  project's template. Getting autotools to work would mean running `autoheader` to invent
  the missing template. CMake generates the header from that template directly, so no
  autotools timestamp guard is needed (`swig/generic.toml:1199-1209`).
- `WITH_PCRE=ON` is a **hard dependency**: `option(WITH_PCRE ... ON)` + `find_package(PCRE2
  REQUIRED COMPONENTS 8BIT)`; turning it off silently drops regex support
  (`swig/generic.toml:1211-1219`).
- `bison` is a **host tool** and is correct as one: `find_package(BISON 3.5 REQUIRED)` runs
  `BISON_TARGET` on the build machine to generate the parser, which is then compiled for
  the target; the cross systems leave `PATH` pointing at the host toolchain, so cmake finds
  the host bison (`swig/generic.toml:1221-1226`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| autotools path needs `autoheader` / a missing `swigconfig.h.in` | the tree ships only the cmake template (`swig/generic.toml:1199-1209`) | use the CMake build |
| regex support silently gone | `-DWITH_PCRE=OFF` (`swig/generic.toml:1211-1219`) | keep PCRE2 as a dependency and `-DWITH_PCRE=ON` |
| a consumer cross-compiles against a *target* swig | a target `swig` cannot run on the build machine (`swig/generic.toml:1191-1197`) | consumers must `require("swig@native")`, never `swig` |
