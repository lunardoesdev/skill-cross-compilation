# glew (GLEW)

OpenGL extension-loading library; installs `libGLEW.a`, `include/GL/*.h`, `glew.pc`.

- build system: **make** (`glew/generic.toml:2`) — GLEW ships a CMake build at
  `build/cmake/`, but it **cannot configure here** (see traps), so the hand-written
  makefile is used instead (`glew/generic.toml:1542-1553`).
- source: GitHub release `glew-2.3.1.tgz`, `--strip-components=1` (`glew/source.toml:5-12`).
- deps: none.
- recipe: `generic.toml` only.

## Overridden fields

```toml
make = false
install = false
post = """ make ... glew.lib.static CC="$CC" AR="$AR" RANLIB="$RANLIB" STRIP= \
          GLEW_DEST="$PREFIX" GLEW_PREFIX="$OUTPKG" LIBDIR="$PREFIX/lib" \
          LDFLAGS.GL= GLEW_NO_GLU=-DGLEW_NO_GLU ; then copy headers/archive/.pc by hand """
```
(`glew/generic.toml:1541-1590`)

- The makefile picks a `config/Makefile.<SYSTEM>` by running `config.guess` on the **build
  host**, which always resolves to `linux`; those config files assign `CC = cc` (a makefile
  assignment overrides the environment), so the toolchain is handed over as make
  **command-line** variables (`glew/generic.toml:1555-1562`).
- Only the static archive is built and installed **by hand** — upstream's install target is
  unusable (depends on `glew.lib`, which is both static and shared, and the shared link uses
  `-lGL -lX11`, and the default goal builds `glewinfo`/`visualinfo`, host programs needing a
  GL display) (`glew/generic.toml:1564-1571`).
- `LDFLAGS.GL=` stops `-lGL -lX11` reaching `glew.pc` (generated with that value
  substituted): nothing in the prefix provides libGL/libX11, so a consumer must not be
  handed either. `GLEW_NO_GLU=-DGLEW_NO_GLU` leaves `@requireslib@` empty instead of `glu`
  (`glew/generic.toml:1573-1579`).
- `STRIP=` disables the archive strip (the default is the **host** strip, which must never
  touch a cross archive). `LIBDIR=` overrides the lib64 picked from the build host's
  `uname -m` (`glew/generic.toml:1581-1585`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| CMake configure fails `Could NOT find OpenGL` | `build/cmake/CMakeLists.txt:39` does `find_package(OpenGL REQUIRED)` and links it into both targets; no sysroot here has libGL. `CMAKE_DISABLE_FIND_PACKAGE_OpenGL` does not help (only applies to non-REQUIRED calls) (`glew/generic.toml:1542-1553`) | use the makefile, which resolves GL through GLEW's own pointer table |
| the archive is built with a bare host `gcc` | the config makefile assigns `CC = cc` (`glew/generic.toml:1555-1562`) | pass `CC/AR/RANLIB` on the make command line |
| the host `strip` mangles the archive / it lands under `lib64` | defaults resolved from the build host (`glew/generic.toml:1581-1585`) | `STRIP=` and `LIBDIR="$PREFIX/lib"` |
| a consumer's `glew.pc` demands `-lGL -lX11` | `@libgl@` substituted from `LDFLAGS.GL` (`glew/generic.toml:1573-1579`) | `LDFLAGS.GL=` |
