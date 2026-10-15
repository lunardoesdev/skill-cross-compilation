#!/bin/sh
# SDL2 2.32.10 -- cmake build. The trap is that the toolchain file deliberately
# sets CMAKE_SYSTEM_NAME Linux (not Android), so `if(ANDROID)` is FALSE and cmake
# takes the `elseif(UNIX AND NOT APPLE ...)` branch -- a Linux-flavoured SDL with no
# Android video and no Android audio driver at all. The recipe has to state ANDROID
# itself, and with it ANDROID_NDK.
#
# Environment: cmake cross toolchain already passed in (CMAKE_TOOLCHAIN_FILE ->
# CMAKE_SYSTEM_NAME Linux), a host `make` for CMAKE_MAKE_PROGRAM, $NDK (the NDK root),
# $PREFIX, $DESTDIR, $CORES.
#
# WHY THESE FLAGS
#   -DANDROID=ON -DANDROID_NDK=$NDK
#       The `if(ANDROID)` block (CMakeLists.txt:1268-1396) turns on video/android
#       (EGL/GLES), audio/android + audio/openslES + audio/aaudio, filesystem,
#       joystick, power, locale, sensor backends and the Android sources of
#       libSDL2main.a. It also compiles
#       $ANDROID_NDK/sources/android/cpufeatures/cpu-features.c and adds its include
#       dir (CMakeLists.txt:1270-1271, :3420-3421); with $NDK unset those resolve to
#       /sources/... and configure fails. Both are present in NDK r29.
#       ANDROID=ON also switches off every host library by construction (UNIX_SYS is
#       false when ANDROID is set, :166-170), and CheckPTHREAD takes its Android arm
#       and links no pthread -- right for Bionic.
#   -DBUILD_SHARED_LIBS=OFF -DSDL_SHARED=OFF -DSDL_STATIC=ON
#       flips SDL's two defaults (CMakeLists.txt:369-388); static-first prefix.
#   -DSDL_TEST=OFF -DSDL_TESTS=OFF -DSDL_INSTALL_TESTS=OFF
#       SDL_TEST drops the SDL2_test library (:3558) and, being SDL_TESTS'
#       dependency, the whole test/ directory with it (:510); the test/ tree is target
#       executables this host must neither build nor run. NOTE: there is NO
#       SDL_EXAMPLES option in 2.32.10 -- cmake silently ignores an unknown cache var,
#       so do not "set" one.
#   -DSDL_VULKAN=OFF
#       the one backend switch that CHANGES this build rather than restating it:
#       dep_option(SDL_VULKAN ... ON "ANDROID OR ...") makes it default ON once ANDROID
#       is true (:487). Off, the archive carries no Vulkan surface code and a consumer
#       links no libvulkan.so.
#   The X11/Wayland/KMSDRM/ALSA/PulseAudio/PipeWire/JACK/SNDIO/OSS/libudev/DBUS/IBUS
#   flags are off already (their defaults are ${UNIX_SYS}, false under ANDROID); they
#   are written out so intent lives in the recipe, not a moveable default. fcitx has
#   no option of its own -- HAVE_FCITX is set from DBUS_FOUND (:1611-1613), so
#   SDL_DBUS=OFF is what keeps fcitx out.
#
# What stays on is what the NDK provides: audio, video+EGL/GLES2, joystick, haptic,
# power, sensor, locale, filesystem, hidapi (in-tree on Android) and render.
set -eu

cmake -S . -B build \
  -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DTHREADS_PREFER_PTHREAD_FLAG=ON \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCMAKE_MAKE_PROGRAM="$CMAKE_MAKE_PROGRAM" \
  -DBUILD_SHARED_LIBS=OFF -DSDL_SHARED=OFF -DSDL_STATIC=ON \
  -DSDL_TEST=OFF -DSDL_TESTS=OFF -DSDL_INSTALL_TESTS=OFF \
  -DANDROID=ON -DANDROID_NDK="$NDK" \
  -DSDL_VULKAN=OFF \
  -DSDL_X11=OFF -DSDL_WAYLAND=OFF -DSDL_WAYLAND_LIBDECOR=OFF -DSDL_KMSDRM=OFF \
  -DSDL_DBUS=OFF -DSDL_IBUS=OFF \
  -DSDL_ALSA=OFF -DSDL_PULSEAUDIO=OFF -DSDL_PIPEWIRE=OFF \
  -DSDL_JACK=OFF -DSDL_SNDIO=OFF -DSDL_OSS=OFF -DSDL_LIBUDEV=OFF

cmake --build build --parallel "$CORES"
DESTDIR="$DESTDIR" cmake --install build
