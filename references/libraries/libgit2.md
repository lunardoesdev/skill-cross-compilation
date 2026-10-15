# libgit2

Git library; installs `libgit2.a`, the `git2/` headers, `libgit2.pc` and the cmake package
config.

- build system: **cmake** (`libgit2/generic.toml:2`) — CMake-only, no `configure.ac`, no
  generated configure, no config template to touch (`libgit2/generic.toml:1767-1770`).
- source: GitHub tag archive `v1.9.7`, `--strip-components=1` (`libgit2/source.toml`).
- deps: `libgit2@source`, `zlib`, `openssl`, `pcre2` (`libgit2/generic.toml:1765`).
- recipe: `generic.toml` only.

## Overridden fields

```toml
args = ["-DBUILD_SHARED_LIBS=OFF", "-DBUILD_TESTS=OFF", "-DBUILD_CLI=OFF",
        "-DBUILD_EXAMPLES=OFF", "-DBUILD_FUZZERS=OFF", "-DUSE_SSH=OFF",
        "-DUSE_HTTPS=OpenSSL", "-DUSE_BUNDLED_ZLIB=OFF", "-DREGEX_BACKEND=pcre2",
        "-DUSE_ICONV=OFF"]
```
(`libgit2/generic.toml:1828`)

- Program gates off: the Clar suite, `git2` CLI, examples, fuzzers
  (`libgit2/generic.toml:1772-1776`).
- `USE_HTTPS=OpenSSL`: uses the prefix's OpenSSL for HTTPS, hashing and TLS
  (`libgit2/generic.toml:1778-1781`).
- `USE_BUNDLED_ZLIB=OFF`: otherwise the bundled `deps/zlib` is compiled, duplicating a
  package the prefix already has (`libgit2/generic.toml:1784-1788`).
- `REGEX_BACKEND=pcre2` with `require("pcre2")`: `cmake/SelectRegex.cmake:24-29` does
  `find_package(PCRE2)` and `FATAL_ERROR`s if missing — and the loader only orders a package
  after what `require()`s it, so without the `require()` a clean nest fails at configure
  (`libgit2/generic.toml:1790-1801`).
- **`USE_ICONV=OFF` is mandatory on every Android level below 28** — and the failure is a
  **false positive created by the cross toolchain itself** (see traps)
  (`libgit2/generic.toml:1803-1827`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| below API 28: `call to undeclared function 'iconv_open'` compiling `fs_path.c` | Bionic ships `<iconv.h>` at every level but gates the *declarations* with `__INTRODUCED_IN(28)`; a program that merely includes the header compiles, one that *calls* iconv does not (`libgit2/generic.toml:1803-1810`) | `-DUSE_ICONV=OFF` |
| cmake's iconv probe reports "found" even where iconv is unusable | the cross systems export `-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY`, and `cmake/FindIntlIconv.cmake:15` gates on `check_function_exists(iconv_open)` — a LINK test; a static library does not resolve symbols, so the probe **succeeds** where it should fail (`libgit2/generic.toml:1812-1822`) | `USE_ICONV=OFF` everywhere (keeps one artifact across families) |
| configure fails `PCRE2 support was requested but not found` on a clean nest | PCRE2 selection depends on build order (`libgit2/generic.toml:1790-1801`) | declare `require("pcre2")` so the closure orders it first |
