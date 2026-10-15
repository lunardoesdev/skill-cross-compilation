# liblc3

LC3 audio codec library; installs `liblc3.a`, `lc3.h`, `lc3_cpp.h`, `lc3_private.h`,
`lc3.pc`.

- build system: **meson** (`liblc3/generic.toml:2`) — liblc3 has never shipped a
  `CMakeLists.txt` (checked at several tags), and the systems carry a meson driver
  (`liblc3/generic.toml:756-759`).
- source: GitHub tag archive `v1.1.3`, `--strip-components=1` (`liblc3/source.toml:5-9`).
- deps: none.
- recipe: `generic.toml` only — the codec has no CPU/platform detection
  (`liblc3/generic.toml:761-764`).

## Overridden fields

```toml
args = ["-Ddefault_library=static", "-Dtools=false", "-Dpython=false", "-Db_lto=false"]
```
(`liblc3/generic.toml:790`)

- `-Ddefault_library=static`: meson builds shared by default and the cross file sets no
  `default_library` (`liblc3/generic.toml:766-769`).
- `-Dtools=false`, `-Dpython=false`: the encoder/decoder CLIs and the ctypes bindings; the
  root build enters those subdirs only under those options (`liblc3/generic.toml:771-776`).
- **`-Db_lto=false`**: the project turns LTO on for itself
  (`default_options: ['b_lto=true']`), and meson then archives **LLVM bitcode** instead of
  machine code — every member of `liblc3.a` came out `LLVM IR bitcode` and `llvm-readelf`
  refused them ("bitcode files are not supported") (`liblc3/generic.toml:781-788`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `liblc3.a` members are `LLVM IR bitcode`; `llvm-readelf`/archiver cannot read them | project sets `b_lto=true`; meson archives LLVM bitcode (`liblc3/generic.toml:781-788`) | `-Db_lto=false` |
| a shared object is produced | meson's default is shared and the crossfile does not override it (`liblc3/generic.toml:766-769`) | `-Ddefault_library=static` |
