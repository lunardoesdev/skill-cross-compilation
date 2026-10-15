# openssl

TLS/crypto library; installs `libssl.a`, `libcrypto.a` and headers (via `install_sw`).

- build system: **make** (`openssl/generic.toml:2`) — driven entirely from `post`;
  openssl uses its own `./Configure` perl script + Makefile, not autoconf/cmake.
- source: GitHub release `openssl-4.0.3.tar.gz`, `--strip-components=1`
  (`openssl/source.toml`).
- deps: none.
- recipes: `generic.toml` (native linux/mingw), `android.toml` (Android).

## Overridden fields

```toml
make = false
install = false
post = """
./Configure "$ssl_target" --prefix="$OUTPKG" --libdir=lib no-shared no-tests no-docs no-engine no-dso no-dynamic-engine
make -j"$CORES"
make install_sw
"""
```
(`openssl/generic.toml:23-24`, `openssl/android.toml:28-30`)

- `no-shared no-tests no-docs no-engine no-dso no-dynamic-engine` in Configure
  (`openssl/generic.toml:22`).
- `make install_sw` installs library+headers only — not docs — and **must carry
  `DESTDIR` on the command line** (see traps).
- The target name is chosen per system: `generic` picks by `$HOST_OS`
  (`linux→linux-x86_64`, `mingw32→mingw64`) because `HOST_ARCH` cannot distinguish
  `x86_64-mingw` from `clang-native` (`openssl/generic.toml:14-21`). Android picks by
  `$HOST_ARCH` and refuses unknown arches (`openssl/android.toml:21-27`).

## What it needs from the system (Android)

`$NDK`, `$TOOLBIN`, `$ANDROID_API`. The Android recipe puts `$TOOLBIN` in front of
`PATH` — a **recipe-local exception**: openssl's `android-*` target config probes for
NDK tools by name in `PATH` (`which clang`, `which <triple>-gcc`), and current NDKs ship
neither; systems do not do this and no other recipe may rely on it
(`openssl/android.toml:7-13`). `ANDROID_API` becomes `-D__ANDROID_API__`
(`openssl/android.toml:28`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| Android build runs against **host headers with no sysroot/API level** and does not fail | `android_ndk()` in `Configurations/15-android.conf` returns **early** for any target name beginning with `android`, before it reads `$ENV{ANDROID_NDK_ROOT}` — so an `android-*` name without the NDK silently builds the wrong thing (`openssl/android.toml:16-20`, `openssl/generic.toml:8-12`) | set `ANDROID_NDK_ROOT` and provide the NDK tools on `PATH`; the `*)` arm must **refuse** rather than guess |
| configure probes fail `which <triple>-gcc` | the `android-*` config expects NDK tool names in `PATH` (`openssl/android.toml:7-13`) | prepend `$TOOLBIN` to `PATH` for this build only |
| install wrote into the published path; `.../.relax-list: No such file or directory` | openssl's generated Makefile **assigns `DESTDIR`**, which beats the exported env (`help2man/generic.toml:57-58` names openssl as the same shape) | carry `DESTDIR` as a command-line assignment on the install line (`install_args = "DESTDIR=$DESTDIR"`) |
