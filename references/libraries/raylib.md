# raylib

Game-programming library; installs `libraylib.a`, `raylib.h`, `raylib.pc` and a cmake
package config. Android needs its `.pc`/cmake targets repaired (see below).

- build system: **cmake** (`raylib/generic.toml:2`).
- source: GitHub tag archive `6.0`, `--strip-components=1` (`raylib/source.toml:5-12`).
- deps: none.
- recipes: `generic.toml` (just `-DCMAKE_BUILD_TYPE=Release -DBUILD_EXAMPLES=OFF`),
  `android.toml`.

## Android recipe

```toml
args = ["-DCMAKE_BUILD_TYPE=Release", "-DPLATFORM=Android", "-DANDROID_NDK=$NDK", "-DBUILD_EXAMPLES=OFF"]
```
(`raylib/android.toml:1681`) plus a `post` that rewrites `raylib.pc` and
`raylib-targets.cmake`.

- The `.pc`'s dependency lines are wrong for the Android backend on **every** system:
  - `Requires.private: glfw3` comes from `cmake/GlfwImport.cmake:20-22`, but the Android
    build compiles **none** of `external/glfw` (libraylib.a defines 0 glfw symbols — it uses
    `rcore_android.c`), so a pkg-config consumer asks for a package that is not in the
    prefix (`raylib/android.toml:1683-1691`).
  - `Libs.private` is empty because `LibraryConfigurations.cmake:94` puts
    `log android EGL GLESv2 OpenSLES atomic` into `LIBS_PRIVATE`, which only reaches
    `target_link_libraries` via `$<BUILD_INTERFACE:...>` and never the installed `.pc`
    (`raylib/android.toml:1692-1699`).
  - `-Wl,--wrap=fopen` is a PUBLIC link option of the target, so a CMake consumer inherits
    it but a pkg-config consumer does not (`raylib/android.toml:1700-1706`).
- The `post` rewrites both `raylib.pc` and `raylib-targets.cmake` (the cmake channel carries
  the same defect through the same `$<BUILD_INTERFACE:...>` wrapper, dropping the libs)
  (`raylib/android.toml:1713-1738`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `ld.lld: error: undefined symbol: glDepthMask` / `__android_log_vprint` for a static consumer | the installed `.pc` (and cmake target) drop the private libs `log/android/EGL/GLESv2/OpenSLES/atomic` because they only reached the build interface (`raylib/android.toml:1692-1706`, `:1730-1738`) | rewrite the generated `.pc` `Libs.private` and `raylib-targets.cmake` `INTERFACE_LINK_LIBRARIES` in a `post` |
| a consumer asks pkg-config for `glfw3` | `Requires.private: glfw3` is set for the non-desktop platform branch (`raylib/android.toml:1683-1691`) | drop the `Requires.private` line |
| an undefined `__wrap_fopen`-related symbol | `-Wl,--wrap=fopen` is not in the `.pc` (`raylib/android.toml:1700-1706`) | add it to `Libs.private` |
