# expat

XML parser library; installs `libexpat.a`, `expat.h`, `expat.pc`.

- build system: **cmake** (`expat/generic.toml:2`).
- source: GitHub release `expat-2.7.1.tar.gz`, `--strip-components=1`
  (`expat/source.toml:5-12`).
- deps: none.
- recipe: `generic.toml` only.

## Overridden fields

```toml
args = ["-DEXPAT_SHARED_LIBS=OFF", "-DEXPAT_BUILD_TOOLS=OFF", "-DEXPAT_BUILD_TESTS=OFF",
        "-DEXPAT_BUILD_EXAMPLES=OFF", "-DEXPAT_BUILD_DOCS=OFF"]
```
(`expat/generic.toml:3`) — static library only; the tools, tests, examples and docs are
host programs / host tools this build must not produce.

## What it needs from the system

Only the CMake toolchain file. No host tools, no submodules, no probes.

## Known traps

None recorded. It is the smallest CMake library in the set and illustrates how little a
clean CMake recipe needs: one `args` line takes every project-specific switch, and the
driver owns the toolchain, prefix and install.
