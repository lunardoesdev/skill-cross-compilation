# srt (libsrt)

Secure Reliable Transport (SRT) library; installs `libsrt.a`, its headers and `srt.pc`.

- build system: **cmake** (`srt/generic.toml:956`), but its `Configure` is a **perl
  script** (see deps).
- source: GitHub tag archive `v1.5.7`, `--strip-components=1` (`srt/source.toml:5-11`).
- deps: `openssl`, `perl@native` (`srt/generic.toml:950`). `perl@native` is a **real**
  dependency: srt's `Configure` is a perl script needing core modules such as `FindBin`;
  without it the build takes whatever `perl` is first in `PATH`, and on a host with a
  half-installed perl that fails with `./Configure line 15: Can't locate FindBin.pm in @INC`
  (`srt/generic.toml:951-955`).
- recipe: `generic.toml` only.

## Overridden fields

```toml
args = ["-DENABLE_SHARED=OFF", "-DENABLE_STATIC=ON", "-DENABLE_APPS=OFF",
        "-DENABLE_TESTING=OFF", "-DENABLE_UNITTESTS=OFF"]
```
(`srt/generic.toml:996`)

- `ENABLE_SHARED=OFF`/`ENABLE_STATIC=ON`: upstream is the other way round and would link
  `libsrt.so` (`srt/generic.toml:967-971`).
- `ENABLE_APPS=OFF`: otherwise builds `srt-live-transmit`, `srt-file-transmit`,
  `srt-tunnel`, `srt-test-proxy` — target binaries (`srt/generic.toml:973-976`).
- `ENABLE_TESTING/UNITTESTS=OFF`: keeps `test/` and the googletest that would be fetched
  over the network out of the build (`srt/generic.toml:976-980`).
- `ENABLE_ENCRYPTION` stays on with `USE_ENCLIB` at upstream's default — **deliberate**:
  with no `USE_ENCLIB` SRT selects `openssl-evp` (the EVP-only path); asking for
  `-DUSE_ENCLIB=openssl` takes the branch that calls the low-level `AES_set_encrypt_key`
  that OpenSSL 4 no longer exports (`srt/generic.toml:982-987`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `./Configure line 15: Can't locate FindBin.pm in @INC` | `Configure` is perl and the build took a broken host perl from `PATH` (`srt/generic.toml:951-955`) | depend on `perl@native` |
| `undefined reference to AES_set_encrypt_key` (OpenSSL 4) | `-DUSE_ENCLIB=openssl` selects the low-level crypto path (`srt/generic.toml:982-987`) | leave `USE_ENCLIB` unset so SRT uses `openssl-evp` |
| apps/test binaries built or googletest fetched | `ENABLE_APPS`/`ENABLE_TESTING` on (`srt/generic.toml:973-980`) | set all three OFF |
