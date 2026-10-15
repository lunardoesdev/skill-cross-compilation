#!/bin/sh
# ffmpeg-kit-next -- TWO packages, both shown here because they are a pair:
#   (A) ffmpeg-kit-ffmpeg-9 : upstream FFmpeg with the kit's patches applied, plus
#       the two things the kit needs out of an install that stock FFmpeg does not
#       carry (config.h and the fftools/ headers).
#   (B) ffmpeg-kit-next-9   : the kit's own Gradle/NDK build, fed with (A)'s FFmpeg
#       prebuilt and forbidden from rebuilding FFmpeg itself.
# (A) and (B) are separate packages with separate work directories; (B) reaches
# (A)'s result through $NESTDIR (the directory that holds sibling installs).
#
# Environment (shared): $CC/$CXX/$AR/$RANLIB/$STRIP, $CFLAGS, $HOST_ARCH/$HOST_OS,
# $PREFIX, $DESTDIR (stage), $CORES, $ANDROID_HOME (SDK with an NDK), $NESTDIR,
# $RECIPEDIR.
#
# Each section below assumes a FRESH work directory of its own (no cd between them).
# ============================================================================
# (A) ffmpeg-kit-ffmpeg-9        work dir: empty; ./configure must end up at top
# ============================================================================
# The FFmpeg release and the kit's source both own tools/, so do NOT lay one over
# the other: put the release at the top (where ./configure is) and the kit under
# ./.kit/. (cp -rf <dir>/. <dst> copies the CONTENTS; <dir> alone would copy a
# symlink the nest may hold.)
cp -rf "$NESTDIR"/ffmpeg-kit-ffmpeg-9@source/. .
mkdir -p .kit
cp -rf "$NESTDIR"/ffmpeg-kit-next-9@source/. .kit/

case "$HOST_ARCH" in
  armv7a) ffmpeg_arch=arm ;;
  i686)   ffmpeg_arch=x86 ;;
  *)      ffmpeg_arch="$HOST_ARCH" ;;
esac

# ffmpeg ignores environment CFLAGS and has no --extra-ldflags (see ffmpeg.sh);
# hand CFLAGS over one --extra-cflags= token per word.
_extra_cflags=""
for _f in $CFLAGS; do
  _extra_cflags="$_extra_cflags --extra-cflags=$_f"
done
unset _f

./configure \
  --prefix="$PREFIX" \
  --enable-cross-compile --target-os="$HOST_OS" --arch="$ffmpeg_arch" \
  --cc="$CC" --cxx="$CXX" --ar="$AR" --ranlib="$RANLIB" --strip="$STRIP" \
  --pkg-config-flags=--static \
  --enable-static --enable-shared \
  --disable-doc --disable-programs --disable-network --disable-iconv --disable-libxcb \
  --enable-zlib --enable-bzlib --enable-lzma \
  --enable-libopus --enable-libvpx --enable-libmp3lame \
  --enable-pic --enable-jni \
  $_extra_cflags

# --- The kit's own patches to upstream FFmpeg (their scripts/android/ffmpeg.sh).
#     Their `git checkout file.c hls.c protocols.c libavutil` only undoes a PRIOR
#     run; a release tarball is pristine, so it is omitted here.
#
# 1. Thread-local log level -- the wrapper sets the level per calling thread.
#    THE EXACT LINE DIFFERS BY BRANCH -- verify it, do not copy it:
#      ffmpeg 7.1.5 (libavutil/log.c:56):  `static int av_log_level ...`
#      ffmpeg 8.1.3 / 9.0.2:               `static atomic_int av_log_level ...`
#    A wrong-branch sed is a SILENT no-op -- sed finds nothing, exits 0, the build
#    succeeds, and the wrapper's per-thread log level quietly stops working.
sed -i 's/static atomic_int av_log_level/__thread atomic_int av_log_level/g' libavutil/log.c
#   (7.x branch, instead:)
#   sed -i 's/static int av_log_level/__thread int av_log_level/g' libavutil/log.c
#
# 2. The kit's protocols: ffkitsaf (Storage Access Framework), ffkitmem and
#    ffkitstream (in-memory / streaming I/O). They define URLProtocol objects and add
#    them to file.c's own protocol; the awk declares them in libavformat/protocols.c,
#    which is what puts them in the protocol list at all -- configure builds
#    $PROTOCOL_LIST by scanning that file for `extern ... ff_X_protocol;` lines
#    (find_things_extern) and enables every name it finds, so an added extern is an
#    enabled protocol.
#    NAMES DIFFER BY BRANCH: 8.x/9.x ship four .inc files (shown); the 7.x tag
#    (v7.1.0) ships plain .c/.h under tools/protocols (ffmpeg.sh:426-429):
#      libavformat_file.c, libavformat_ffkitmem_stream.c,
#      libavutil_file.h, libavutil_file.c
cat .kit/tools/protocols/libavformat_file_ffkitsaf.inc >> libavformat/file.c
cat .kit/tools/protocols/libavformat_file_ffkitmem_stream.inc >> libavformat/file.c
cat .kit/tools/protocols/libavutil_file_h.inc >> libavutil/file.h
cat .kit/tools/protocols/libavutil_file_c.inc >> libavutil/file.c
awk '{gsub(/ff_file_protocol;/,"ff_file_protocol;\nextern const URLProtocol ff_ffkitsaf_protocol;\nextern const URLProtocol ff_ffkitmem_protocol;\nextern const URLProtocol ff_ffkitstream_protocol;")}1' \
  libavformat/protocols.c > libavformat/protocols.c.tmp
cat libavformat/protocols.c.tmp > libavformat/protocols.c
rm -f libavformat/protocols.c.tmp
# Byte-for-byte the kit's own line (the shell must see a backslash before each " and |).
sed -i "s|av_strstart(proto_name, \"file\", NULL))|av_strstart(proto_name, \"file\", NULL) \|\| av_strstart(proto_name, \"ffkitsaf\", NULL) \|\| av_strstart(proto_name, \"ffkitmem\", NULL) \|\| av_strstart(proto_name, \"ffkitstream\", NULL))|g" libavformat/hls.c

make -j"$CORES"
make install DESTDIR="$DESTDIR"

# --- What the wrapper compiles against, out of this install. The kit's ffmpeg.sh
#     does exactly this after `make install` (config.h copied in, the source tree's
#     headers mirrored over the installed ones) -- and with SKIP_ffmpeg=1 none of it
#     runs in their build:
#       ffmpegkit.c:31                 #include "config.h"
#       fftools/ffmpeg.h:106           #include "config.h"
#       android/jni/Android.mk         FFMPEG_INCLUDES := .../prebuilt/$(MY_BUILD_DIR)/ffmpeg/include
#       android/jni/ffmpeg/Android.mk  LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/../include
#     Both must land under include/ of what this package hands over: the wrapper is
#     not patched, it is given the headers it asks for.
#     fftools/ MUST be include/fftools/ : `#include "fftools/ffmpeg.h"` resolves against
#     .../ffmpeg/include, so a top-level $PREFIX/fftools is never looked at.
#     -not -path './.kit/*' keeps the kit copy (here for four files) out of the mirror.
mkdir -p "$PREFIX/include"
cp config.h "$PREFIX/include/config.h"
find . -name '*.h' -not -path './.kit/*' -exec cp --parents -t "$PREFIX/include/" {} +

# ============================================================================
# (B) ffmpeg-kit-next-9          work dir: empty (its own, separate from (A))
# ============================================================================
cp -rf "$NESTDIR"/ffmpeg-kit-next-9@source/. .

# Their entry script refuses to start without these two names. Derive the SDK and
# the one NDK from $ANDROID_HOME rather than repeating them.
export ANDROID_SDK_ROOT="$ANDROID_HOME"
for _ndk in "$ANDROID_HOME"/ndk/*; do ANDROID_NDK_ROOT="$_ndk"; done
export ANDROID_NDK_ROOT
unset _ndk

# Drop (A)'s FFmpeg where their own build would have installed it:
# FFMPEG_LIBRARY_PATH = $LIB_INSTALL_BASE/$LIB_NAME with LIB_NAME=ffmpeg (ffmpeg.sh:19),
# under android-arm64-<api> (android.sh:254) -> prebuilt/android-arm64-33/ffmpeg/.
# include/ there already holds config.h and fftools/ from (A).
mkdir -p prebuilt/android-arm64-33/ffmpeg
cp -rf "$NESTDIR"/ffmpeg-kit-ffmpeg-9@aarch64-android33/lib prebuilt/android-arm64-33/ffmpeg/
cp -rf "$NESTDIR"/ffmpeg-kit-ffmpeg-9@aarch64-android33/include prebuilt/android-arm64-33/ffmpeg/

# SKIP_ffmpeg=1 keeps their FFmpeg build from landing on top of ours
# (main-android.sh:217); the protocols their build would have patched in are already
# in the FFmpeg placed above, and the wrapper calls for them unconditionally
# (av_set_saf_open / av_set_ffkitmem_functions / av_set_ffkitstream_functions in
# ffmpegkit.c:1544-1549). The other three SKIP_* are the ext libs in the closure.
#
# DESTDIR IS EMPTIED -- not tidiness. A driver exports DESTDIR for this node's own
# install and their scripts read it themselves, so every artifact their build
# installed went into the STAGE:
#   -- Installing: <stage>/.../work-.../prebuilt/android-arm64-33/cpu-features/lib/libndk_compat.a
# and the next step looked in the WORK dir and stopped with
#   Android NDK: ERROR:jni/cpu-features/Android.mk:cpu-features: LOCAL_SRC_FILES points to a missing file
# Empty (not unset) so $DESTDIR still expands -- to nothing. The recipe's own install
# is unaffected because $PREFIX was spelled with $DESTDIR when its prelude set it.
#
# Gradle needs a JDK. A distro default java is often a JRE without javac
# ("does not provide the required capabilities: [JAVA_COMPILER]" / Gradle then fails
# on the build script); point JAVA_HOME at a JDK and repeat it as
# org.gradle.java.home, the property Gradle prefers. None of their files is touched.
JAVA_HOME="$(readlink -f "$HOME/.local/share/mise/installs/java/latest")"
export JAVA_HOME

DESTDIR= SKIP_ffmpeg=1 SKIP_libvpx=1 SKIP_opus=1 SKIP_lame=1 \
GRADLE_OPTS="-Dorg.gradle.workers.max=$CORES -Dorg.gradle.java.home=$JAVA_HOME" \
  ./android.sh --arch=arm64-v8a --api-level=33 --jobs="$CORES" \
  --no-output-redirection || {
    # Their log is the only place that names the failing step, and the work dir is
    # removed when the node exits -- copy it out before the failure leaves scope.
    # --no-output-redirection keeps the console readable; without it the reason goes
    # only to build.log and never reaches this run's log.
    cp build.log "$RECIPEDIR"/ffmpeg-kit-next-failure.log 2>/dev/null || true
    exit 1
  }

# The package hands over the .aar their build produced.
mkdir -p "$PREFIX/lib"
for _aar in $(find prebuilt -name '*.aar'); do
  cp "$_aar" "$PREFIX/lib/"
done
unset _aar

# NOTE (7.x branch): v7.1.0 has NO android.sh. Its entry point is
# scripts/start-android.sh and arch selection uses the older one-ABI-at-a-time
# spelling -- ./scripts/start-android.sh --disable-arm-v7a --disable-arm-v7a-neon
# --disable-x86 --disable-x86-64 --api-level=33 --jobs="$CORES" --no-output-redirection.
# Everything else above (DESTDIR=, SKIP_*, JAVA_HOME, prebuilt placement) is identical.
