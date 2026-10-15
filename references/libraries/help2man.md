# help2man

*Host tool*, not a library: generates man pages from a program's `--help` output.
Produces the `help2man` script, its shipped man page and info manual.

- build system: **autoconf** (`help2man/generic.toml:2`).
- source: `ftp.gnu.org/gnu/help2man/help2man-1.49.3.tar.xz`, `--strip-components=1`
  (`help2man/source.toml:14-23`). Ships a generated `./configure` + `Makefile.in`
  (`help2man/source.toml:5-7`).
- deps: `perl@native`, `help2man@source` (`help2man/generic.toml:1`) — **native**, because
  the tool must *run* on the build machine (`help2man/generic.toml:9-12`).
- recipe: `generic.toml` only.

## Overridden fields

```toml
configure_args = ["--disable-nls", "PERL=$NESTDIR/perl@clang-native/bin/perl"]
pre = """ touch help2man.info help2man.1 """
install_args = "DESTDIR=$DESTDIR"
make = true
install = true
targets = ""
make_args = ""
```
(`help2man/generic.toml:39-63`)

- `PERL=` names the exact interpreter: `help2man.PL` is expanded into the installed
  script and the shebang bakes in that path; resolving `perl` from `PATH` would bake the
  host's `/usr/bin/perl`, which is what the `@native` dependency exists to prevent
  (`help2man/generic.toml:33-38`).
- `--disable-nls`: with NLS on, configure wants the perl module `Locale::gettext`,
  `MSGFMT`, `dlsym`, `bindtextdomain` and builds a preload shim — none wanted for a build
  tool, and the tree has no working gettext (`help2man/generic.toml:14-21`).
- `pre` `touch`es the shipped `help2man.info`/`help2man.1` so `make` does not try to
  rebuild them (which for `info` means `makeinfo` — the program this package helps
  build) (`help2man/generic.toml:23-32`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `help2man: command not found` (makeinfo.1, Error 127) in a consumer like texinfo | the consumer needs help2man to build its own man page, and nothing else provides it (`texinfo/generic.toml:3-6`) | declare `help2man@native` as a dependency of the consumer, and put its bin on `PATH` (`texinfo/generic.toml:8-16`) |
| installed `help2man` runs the host perl | interpreter resolved from `PATH` instead of the built one (`help2man/generic.toml:33-38`) | pass `PERL=$NESTDIR/perl@clang-native/bin/perl` |
| install wrote into the published path; `.../.relax-list: No such file or directory` | `Makefile.in:29` is `DESTDIR =` — a Makefile variable that beats the exported env (`help2man/generic.toml:49-58`) | `install_args = "DESTDIR=$DESTDIR"` |
| a shipped doc is rebuilt and needs `makeinfo` | source copy does not preserve mtimes (`help2man/generic.toml:23-32`) | `touch` the shipped generated files, newest last |
