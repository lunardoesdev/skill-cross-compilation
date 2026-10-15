# python

For a package that is nothing but Python modules to place — no compilation. The
driver owns the site-packages path (from the system) and the copy mechanics; the
recipe owns `modules` (required), `licenses`, `scripts` and `whole_tree`
(`system@aarch64-android33/python.toml:1-8`, `docs/recipes.md:83`).

Pure Python is architecture-independent, so a cross build is the same operation as a
native one; what differs is only where the files land and that no `.pyc`
compilation or program *run* happens here.

## The skeleton

```sh
_site="$PREFIX/${PYTHON_SITE:?the system must say where its site-packages is}"
mkdir -p "$_site"

if [ "${BS_whole_tree:-}" != "" ]; then
  cp -rf . "$_site/"
else
  for _m in ${BS_modules:?a python recipe must name its modules}; do
    cp -rf "$_m" "$_site/"
  done
fi

# licenses copied into each module's own directory
for _l in ${BS_licenses:-}; do
  for _m in ${BS_modules:-}; do
    [ -f "$_l" ] && cp -f "$_l" "$_site/${_m##*/}/" || true
  done
done

# `source:name` pairs installed into bin/, made executable
for _s in ${BS_scripts:-}; do
  mkdir -p "$PREFIX/bin"
  cp -f "${_s%%:*}" "$PREFIX/bin/${_s##*:}"
  chmod +x "$PREFIX/bin/${_s##*:}"
done
```

(`system@aarch64-android33/python.toml:11-31`).

## Required variables

- **`PYTHON_SITE`** — provided by the system, `lib/python3.14/site-packages` on the
  native system. The interpreter's version belongs in **one place, not in every
  recipe**; the driver fails if the system did not set it
  (`python.toml:7-12`).
- **`$PREFIX`** — the staged tree, so the copy lands under `$DESTDIR` and publication
  moves it (`docs/recipes.md:131`).
- **`$PREFIX/bin`** — where `scripts` go, made executable (`python.toml:26-30`).

## Field meanings

| field | meaning |
| --- | --- |
| `modules` | directories copied into site-packages — **required** (`python.toml:17`) |
| `licenses` | files copied into each module's directory (`python.toml:21-25`) |
| `scripts` | `source:name` pairs installed into `bin/`, made executable (`python.toml:26-30`) |
| `whole_tree` | true to copy the unpacked tree itself rather than named modules (`python.toml:14-15`) |

## Pitfalls

| symptom | cause | fix |
| --- | --- | --- |
| `the system must say where its site-packages is` | the system did not set `PYTHON_SITE`, or the interpreter version changed (`python.toml:12`) | set `PYTHON_SITE` for the interpreter actually present; never hardcode the version in a recipe (`python.toml:7-9`) |
| the module lands but is not importable / installs into the wrong interpreter | the source tree landed where site-packages of a different Python version is | derive the path from `$PYTHON_SITE`, which the system owns (`python.toml:7-9`) |
| `a python recipe must name its modules` | `modules` unset and `whole_tree` not set (`python.toml:17`) | set `modules`, or set `whole_tree` to copy the whole tree |
| an installed script is not executable, or its shebang names the **host** interpreter | a script installed without `chmod +x`, or a shebang produced at build time from the host | install `source:name` pairs through `scripts` (the driver makes them executable, `python.toml:26-30`), and check the shebang names the target interpreter |
