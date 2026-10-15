# lexbor (Lexbor)

HTML/CSS parsing library; installs `liblexbor_static.a`, the `lexbor/` headers,
`lexbor.pc` and a cmake package config.

- build system: **cmake** (`Lexbor/generic.toml:2`).
- source: GitHub tag archive `v3.0.0`, `--strip-components=1` (`Lexbor/source.toml`).
- deps: none.
- recipe: `generic.toml` only.

## Overridden fields

```toml
args = ["-DLEXBOR_BUILD_SHARED=OFF"]
```
(`Lexbor/generic.toml:1487`)

- `LEXBOR_BUILD_SHARED=OFF`: lexbor defaults shared ON; the static target is
  `liblexbor_static` (`Lexbor/generic.toml:1471-1474`).
- All the program gates (`LEXBOR_BUILD_TESTS`, `_TESTS_CPP`, `_EXAMPLES`, `_UTILS`,
  `_BENCHMARKS`, `_WASM`, `_FUZZER`) are already OFF upstream and are left alone
  (`Lexbor/generic.toml:1476-1481`).
- `LEXBOR_WITHOUT_THREADS` is ON by default and unused; no pthread is referenced
  (`Lexbor/generic.toml:1483-1486`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| a pkg-config consumer is told to link `-llexbor`, which does not exist | `lexbor.pc.in` renders `-l@PROJECT_NAME@` (`CMakeLists.txt:193` sets `PROJECT_NAME=lexbor`), but with `LEXBOR_BUILD_SHARED=OFF` only `liblexbor_static.a` is built; the template has no `@variable@` a cmake option could redirect (`Lexbor/generic.toml:1489-1498`) | rewrite the generated `lexbor.pc` `Libs:` line to `-L${libdir} -llexbor_static` in a `post` (replace the whole line — a repeated key is last-key-wins) (`Lexbor/generic.toml:1515`) |
