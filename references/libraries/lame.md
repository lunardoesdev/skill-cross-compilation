# lame

MP3 encoder library; installs `libmp3lame.a`, `lame/lame.h`, `lame.pc`.

- build system: **autoconf** (`lame/generic.toml:2`), but the recipe drives `make`
  itself.
- source: SourceForge tarball `lame-3.100.tar.gz`, `--strip-components=1`
  (`lame/source.toml:3-12`).
- deps: none.
- recipe: `generic.toml` only.

## Overridden fields

```toml
make = false
install = false
configure_args = ["--disable-shared", "--enable-static", "--disable-frontend", "--disable-gtktest", "--disable-nasm"]
post = """
make -j"$CORES"
make -C libmp3lame install
make -C include install
"""
```
(`lame/generic.toml:3-9`)

- `--disable-shared --enable-static`: static-only prefix.
- `--disable-frontend`: the `lame` CLI is a target binary, not built.
- `--disable-gtktest`: no GTK on the build host.
- `--disable-nasm`: x86 assembler not present for the cross target.
- **`make = false` / `install = false`** so the driver adds no steps; the recipe's
  `post` runs `make` once and then installs only the two subdirectories it wants
  (`libmp3lame`, `include`) rather than the whole tree.

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| the *next* package's build/install is skipped in silence | lame is the node whose recipe sets `make=false/install=false`, so the following node inherits those fields unless it asserts them (`ffmpeg-9/generic.toml:44-53`) | any recipe after lame in a closure must set `make = true`, `install = true` and clear the args fields |
