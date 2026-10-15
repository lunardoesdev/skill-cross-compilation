# tesseract

OCR engine; consumes leptonica. *Source-only in this tree*: the package directory
carries `source.toml` and the build recipe generates the configure.

- build system: **autoconf**, but the configure must be *generated* — the build recipe
  runs upstream's own `autogen.sh` (same shape as zimg's source node)
  (`tesseract/source.toml:5-9`).
- source: GitHub **tag archive** `5.5.3` (`tesseract/source.toml:25`),
  `--strip-components=1`. tesseract publishes **no dist tarball** — the release object's
  only asset is a Windows installer, and the tag archive is a plain git archive with
  `autogen.sh`, `configure.ac`, `Makefile.am` and `m4/` but **no generated `configure`,
  no `aclocal.m4`, no `Makefile.in`, no `pkg.m4`** (`tesseract/source.toml:1-9`).
- submodules: `test/` and `unittest/third_party/googletest` are left empty by the
  archive; both belong to `make check`, which is never run — not fetched
  (`tesseract/source.toml:14-19`).

## What it needs from the system

- The **autotools as `@native` dependencies of the build recipe**, because the tag
  archive has no generated `configure` (`tesseract/source.toml:5-9`).
- leptonica (module `lept`) and its own dependencies through the closure's pkg-config.

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `./configure: No such file or directory` / `autoreconf` missing | the tag archive ships sources only; no generated configure and no autotools on the host (`tesseract/source.toml:5-9`) | run upstream `autogen.sh` and declare `autoconf`/`automake`/`libtool` `@native`; or fetch a dist tarball if one ever appears |
| build stops needing gtest / testdata | `make check` outputs are not built inputs, but a default test target would want them | never run `make check`; leave the empty submodules unfetched (`tesseract/source.toml:14-19`) |
