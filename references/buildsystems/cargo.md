# cargo

`cargo build --target` for Rust crates. The driver owns the target triple, the cross
linker/`cc`-crate variables and the rpath (`RUSTFLAGS`); the recipe owns `bin`
(required), `features`, `no_default_features`, `install` and `env`
(`system@aarch64-android33/cargo.toml:1-5`, `docs/recipes.md:82`).

## The cross skeleton

```sh
# --- driver-owned, from the system ---
CARGO_BUILD_TARGET="aarch64-linux-android"
PKG_CONFIG_ALLOW_CROSS=1
CXXFLAGS_aarch64_linux_android="$CXXFLAGS"
# system exports the linker/archiver and the cc-crate vars:
#   CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER=$CC
#   CARGO_TARGET_AARCH64_LINUX_ANDROID_AR=$AR
#   CC_aarch64_linux_android / CFLAGS_aarch64_linux_android / CXX_aarch64_linux_android

# cargo does NOT read $LDFLAGS, so the runtime path goes into $RUSTFLAGS
RUSTFLAGS="${RUSTFLAGS:-} -C link-arg=-Wl,-rpath,\$ORIGIN -C link-arg=-Wl,-rpath,\$ORIGIN/../lib -C link-arg=-Wl,-rpath,\$ORIGIN/../lib64"
export RUSTFLAGS

${BS_env:+env $BS_env }cargo build --release --target "$CARGO_BUILD_TARGET" -j "$CORES" \
  ${BS_no_default_features:+--no-default-features} \
  ${BS_features:+--features "$BS_features"}

if [ "$BS_install" != "false" ]; then
  mkdir -p "$PREFIX/bin"
  for _bin in ${BS_bin:?a cargo recipe must name its bin}; do
    _exe="target/$CARGO_BUILD_TARGET/release/$_bin"
    [ -f "$_exe" ] || _exe="$_exe.exe"
    cp "$_exe" "$PREFIX/bin/"
  done
fi
```

(`system@aarch64-android33/cargo.toml:10-26`, cross vars from
`system@aarch64-android33/system.toml:64-68`).

## Required variables and flags

- **`CARGO_BUILD_TARGET`** — the Rust target triple (`aarch64-linux-android`,
  `x86_64-unknown-linux-gnu`). Without `--target` cargo builds for the build host
  (`cargo.toml:12`, `system@clang-native/cargo.toml:11`).
- **`RUSTFLAGS`** — cargo does **not** read `$LDFLAGS`, so the rpath must be injected
  as `-C link-arg=-Wl,-rpath,...`. A binary built without it carries no runtime path,
  and a bundler would have to leave a launcher beside it
  (`cargo.toml:7-9,16-17`). Note the single `$ORIGIN` here — it is handed to the
  compiler by cargo, the same as cmake/meson, not read by `make`
  (`docs/systems.md:98-101`).
- **Cross linker and archiver** — `CARGO_TARGET_<TRIPLE>_LINKER=$CC` and
  `..._AR=$AR` (triple upper-cased, hyphens → underscores: `AARCH64_LINUX_ANDROID`)
  (`system@aarch64-android33/system.toml:64-65`). Without the linker var cargo's
  default `cc` builds for the host.
- **`cc`-crate vars** — `CC_<triple>`, `CFLAGS_<triple>`, `CXX_<triple>`,
  `CXXFLAGS_<triple>` (underscored triple), for build scripts that compile C
  (`system@aarch64-android33/system.toml:66-68`, `cargo.toml:14`).
- **`PKG_CONFIG_ALLOW_CROSS=1`** — lets the `pkg-config` crate run under a cross
  build instead of refusing (`cargo.toml:13`).

`BS_env` is a recipe-supplied `env` string prepended as `env $BS_env`
(`cargo.toml:18`, e.g. `env = "PNG_CONFIG=false"`, `docs/recipes.md:112`).

## Install and staging

Cargo has no install step here; the driver **copies the built binary** out of
`target/<triple>/release/` into `$PREFIX/bin/`, i.e. into the staged tree
(`$PREFIX = $DESTDIR$OUTPKG`), so publication picks it up
(`cargo.toml:19-26`). Two consequences:

- **With `--target`, the output is in `target/<triple>/release/`, not
  `target/release/`** — the install path spells the triple out
  (`cargo.toml:22`).
- **`bin` is required** — a recipe that does not name its binary fails with
  `a cargo recipe must name its bin` (`cargo.toml:21`, `docs/recipes.md:82`).
- On a PE target the executable carries a `.exe` suffix; the driver falls back to
  `$_exe.exe` when the bare name is absent (`cargo.toml:23`).

## Dependency discovery

- The `pkg-config` crate reads `$PKG_CONFIG_LIBDIR` / `$PKG_CONFIG_PATH` from the
  closure, gated by `PKG_CONFIG_ALLOW_CROSS=1` (`cargo.toml:13`,
  `docs/recipes.md:59-61`).
- The `cc` crate reads the `CC_<triple>` / `CFLAGS_<triple>` variables above
  (`system@aarch64-android33/system.toml:66-68`).
- A crate that shells out to a `*-config` helper can be told to skip it via the
  recipe's `env` (`env = "PNG_CONFIG=false"`, `docs/recipes.md:112`).

## Known pitfalls

| symptom in the log | cause | fix |
| --- | --- | --- |
| binary built for the **host** arch | no `--target`, or a missing `CARGO_TARGET_<TRIPLE>_LINKER` (`cargo.toml:12`, `system.toml:64`) | set `CARGO_BUILD_TARGET` and the linker/archiver vars for that triple |
| the artifact carries **no runtime path** (needs a launcher beside the bundle) | cargo does not read `$LDFLAGS` (`cargo.toml:7-9`) | put the rpath in `RUSTFLAGS` as `-C link-arg=-Wl,-rpath,...` |
| "cannot find library"/pkg-config refuses under a cross build | the `pkg-config` crate treats cross as an error by default, or the `.pc` dirs are not in the search path (`cargo.toml:13`) | `PKG_CONFIG_ALLOW_CROSS=1` and put `.pc` dirs in `$PKG_CONFIG_LIBDIR` |
| build script compiles C for the wrong target | the `cc` crate had no `CC_<triple>`/`CFLAGS_<triple>` (`system.toml:66-68`) | export the `cc`-crate variables for the underscored triple |
| `a cargo recipe must name its bin` | `bin` is required (`cargo.toml:21`) | set `bin = "<name>"` |
| the install step finds no file | looked in `target/release/` instead of `target/<triple>/release/` (`cargo.toml:22`) | use the triple-qualified path (the driver does) |
