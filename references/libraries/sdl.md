# sdl (SDL2)

SDL2 library; installs `libSDL2.a`, `libSDL2main.a` (the JNI main shim),
`sdl2.pc`, the cmake package config and the headers.

- build system: **cmake** (`sdl/android.toml:2`).
- source: GitHub release **asset** `SDL2-2.32.10.tar.gz` (the dist tarball, not the tag
  archive; `--strip-components=1`) (`sdl/source.toml:14-23`). 2.32.x is the 2.x line;
  the `release-3.x` tags above it are SDL3 — a different soname/header dir/cmake target
  and a different package (`sdl/source.toml:7-11`).
- deps: none.
- recipe: `android.toml` only (so far) — the tree's SDL entry is Android-only.

## Overridden fields

```toml
args = ["-DBUILD_SHARED_LIBS=OFF", "-DSDL_SHARED=OFF", "-DSDL_STATIC=ON",
        "-DSDL_TEST=OFF", "-DSDL_TESTS=OFF", "-DSDL_INSTALL_TESTS=OFF",
        "-DANDROID=ON", "-DANDROID_NDK=$NDK", "-DSDL_VULKAN=OFF",
        "-DSDL_X11=OFF", "-DSDL_WAYLAND=OFF", "-DSDL_WAYLAND_LIBDECOR=OFF",
        "-DSDL_KMSDRM=OFF", "-DSDL_DBUS=OFF", "-DSDL_IBUS=OFF", "-DSDL_ALSA=OFF",
        "-DSDL_PULSEAUDIO=OFF", "-DSDL_PIPEWIRE=OFF", "-DSDL_JACK=OFF",
        "-DSDL_SNDIO=OFF", "-DSDL_OSS=OFF", "-DSDL_LIBUDEV=OFF"]
```
(`sdl/android.toml:82-105`)

- **`-DANDROID=ON` is the load-bearing flag.** SDL's Android code (video/android,
  audio/android+openslES+aaudio, filesystem, joystick, power, locale, sensor, and the
  `libSDL2main.a` sources) lives behind `if(ANDROID)` (`CMakeLists.txt:1268-1396`). But
  `ANDROID` is the cache variable cmake derives from `CMAKE_SYSTEM_NAME`, and this
  system's toolchain file deliberately keeps `CMAKE_SYSTEM_NAME Linux`, so cmake would
  take the plain-Linux branch and ship SDL with no Android video/audio
  (`sdl/android.toml:7-23`). `-DANDROID_NDK=$NDK` is needed because the Android branch
  compiles `$ANDROID_NDK/sources/android/cpufeatures/cpu-features.c`
  (`sdl/android.toml:19-23`).
- `BUILD_SHARED_LIBS=OFF` flips SDL's two defaults; `SDL_SHARED=OFF`/`SDL_STATIC=ON`
  spell the same in SDL's vocabulary (`sdl/android.toml:32-36`).
- `SDL_TEST=OFF` drops the `SDL2_test` library and the `test/` directory; there is **no
  `SDL_EXAMPLES` option** in 2.32.10 — the programs are the test suite
  (`sdl/android.toml:38-45`).
- `SDL_VULKAN=OFF` is the one backend switch that changes the build rather than restating
  it: it defaults ON once `ANDROID` is true (`sdl/android.toml:47-54`).
- All host backends (X11/Wayland/KMSDRM/DBus/IBus/ALSA/Pulse/PipeWire/JACK/…) are off
  already under `ANDROID` but written out so intent lives in the recipe
  (`sdl/android.toml:56-61`). `fcitx` has no option — `SDL_DBUS=OFF` keeps it out
  (`sdl/android.toml:60-61`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `$ANDROID_NDK/sources/...` resolves to `/sources/...`, configure fails | `$NDK` unset while `ANDROID=ON` (`sdl/android.toml:19-23`) | pass `-DANDROID_NDK=$NDK` |
| SDL built with no Android video/audio driver | `CMAKE_SYSTEM_NAME Linux` in the toolchain file means cmake's `ANDROID` is false and the Linux branch is taken (`sdl/android.toml:13-18`) | state `-DANDROID=ON` yourself |
| test suite built / installed | `SDL_TEST`/`SDL_TESTS`/`SDL_INSTALL_TESTS` left at defaults (`sdl/android.toml:38-45`) | set all three OFF |
