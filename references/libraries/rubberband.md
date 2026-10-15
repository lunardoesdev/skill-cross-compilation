# rubberband

Time-stretch / pitch-shift library; installs `librubberband.a`, `include/rubberband/*.h`,
`rubberband.pc`.

- build system: **meson** (`rubberband/generic.toml:2`).
- source: GitHub tag archive `v4.0.0`, `--strip-components=1` (`rubberband/source.toml:5-9`).
- deps: none — every optional dependency is switched off by name.
- recipe: `generic.toml` only.

## Overridden fields

```toml
args = ["-Ddefault_library=static", "-Dfft=builtin", "-Dresampler=builtin",
        "-Dcmdline=disabled", "-Dtests=disabled", "-Dlv2=disabled",
        "-Dladspa=disabled", "-Dvamp=disabled", "-Djni=disabled"]
```
(`rubberband/generic.toml:1900`)

- `default_library=static`: meson defaults to `both` here (`rubberband/generic.toml:1854-1856`).
- Each optional dep is off because it would link something the tree lacks or add a target
  program (`rubberband/generic.toml:1858-1886`):
  - `cmdline=disabled` drops the `rubberband`/`rubberband-r3` CLIs and keeps libsndfile out.
  - `tests=disabled` drops the boost unit-test program.
  - `lv2`/`ladspa`/`vamp` drop the plugin shared objects.
  - **`jni=disabled` is a reproducibility requirement**: on `auto`, meson adds the `java`
    language only if a Java toolchain happens to exist, so the entry would differ between
    two identical trees. The recipe must not rest on machine facts (`rubberband/generic.toml:1878-1886`).
- `fft=builtin`, `resampler=builtin`: spell out what `auto` resolves to off Darwin, so the
  package cannot start taking FFTW/KissFFT/SLEEF/libsamplerate/Speex because a host `.pc`
  appeared on a search path (`rubberband/generic.toml:1888-1892`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `Compiler for language java for the host machine not found` / the entry differs per machine | `jni=auto` depends on whether a Java toolchain exists (`rubberband/generic.toml:1878-1886`) | `-Djni=disabled` |
| a plugin `.so` or CLI gets built | the LV2/LADSPA/Vamp/cmdline options default on when their dep is found (`rubberband/generic.toml:1858-1876`) | disable each by name |
| an unexpected FFT/resampler backend is linked | `fft`/`resampler` left at `auto` (`rubberband/generic.toml:1888-1892`) | `-Dfft=builtin -Dresampler=builtin` |
