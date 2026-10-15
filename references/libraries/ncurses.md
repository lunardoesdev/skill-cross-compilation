# ncurses

Terminal library; installs the **wide-character** (`w`) shared libraries and `.pc`
files, with un-suffixed aliases.

- build system: **autoconf** (`ncurses/generic.toml:2`).
- source: `ftp.gnu.org/gnu/ncurses/ncurses-6.6.tar.gz`, `--strip-components=1`
  (`ncurses/source.toml`).
- deps: none.
- recipe: `generic.toml` only.

## Overridden fields

```toml
configure_args = ["--with-shared", "--without-debug", "--without-normal", "--with-cxx-shared",
                  "--enable-pc-files", "--with-pkg-config-libdir=$OUTPKG/lib/pkgconfig",
                  "--disable-stripping"]
post = """ ... symlinks ... """
```
(`ncurses/generic.toml:11-27`)

- **`--with-shared` (and no static equivalent) is a deliberate departure from the
  prefix's static convention** — ncurses' `tic`/`infocmp` and the wide-character ABI are
  awkward to build static-only (`ncurses/generic.toml:3-7`).
- `--without-normal`: build only the wide-char (`w`) variants; the un-suffixed link names
  are aliased afterwards (`ncurses/generic.toml:8-10`).
- `--with-pkg-config-libdir=$OUTPKG/lib/pkgconfig`: the `.pc` files must describe the wide
  libs.
- `post` creates symlinks so consumers that link the traditional names resolve:
  `libcurses.so`/`libncurses.so` → `libncursesw.so`, `libform.so`→`libformw.so`,
  etc., and `ncurses.pc`→`ncursesw.pc` (`ncurses/generic.toml:12-26`) — the same shape as
  the mingw libzlib→libz alias.

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| consumer fails on `-lcurses`/`-lform`/`-lmenu`/`-lpanel` | only the `w`-suffixed libraries exist (`ncurses/generic.toml:8-10`) | symlink the un-suffixed names onto the wide ones (`ncurses/generic.toml:18-22`) |
| a `.pc` consumer reads the wrong module | only `ncursesw.pc` etc. exist (`ncurses/generic.toml:23-26`) | symlink `ncurses.pc`→`ncursesw.pc`, `form.pc`→`formw.pc`, … |
