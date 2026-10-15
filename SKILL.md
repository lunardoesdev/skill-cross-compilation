---
name: skill-cross-compilation
description: Use when cross-compiling a C/C++/Rust project for another OS or ABI with POSIX shell — Android, Windows/mingw, or a native host. Gives the four-layer model (system, build-system driver, package, dependency closure) and the traps that cost hours.
---

# Cross-compilation with POSIX shell

Everything here is distilled from a working tree of ~150 packages built for
Android (four ABIs, API 21–35), Windows (mingw32/64) and the native host.
The references carry the detail; this file carries the model and the rules.

## The model: four layers

Do not think "build a library for Android". Think of four separate things, each
with one home:

```
  system            what the machine provides: triple, sysroot, toolchain,
                    base flags, environment variables, platform libraries
      |
  driver            one per build system (autoconf, cmake, meson, make, cargo):
                    the shell that turns a source tree into a staged install
      |
  package           one directory per project: where the source comes from,
                    what it depends on, what only this project needs to
                    override. No build recipe is repeated here.
      |
  dependency        the same packages, built for the SAME system, plus the
                    host tools that must RUN during the build
```

### 1. System — the environment, and nothing else

A system is a name (`aarch64-android33`, `mingw64`, `clang-native`) whose whole
content is: the target triple, the toolchain and its sysroot, the variables a
build expects (`CC`, `CXX`, `AR`, `RANLIB`, `STRIP`, `NM`, `CFLAGS`, `LDFLAGS`,
`PKG_CONFIG_PATH`, `PKG_CONFIG_LIBDIR`), the base flags that platform needs
(`-DANDROID`, `-fPIC`, `-O2`, `-Wl,-rpath,$ORIGIN`), and the list of libraries
the platform itself provides (on Android: `liblog`, `libmediandk`,
`libcamera2ndk`, `libGLESv2`, `libc++_shared`, … — these are never packaged, the
toolchain supplies them).

Two systems differing only in the API level are different systems. Their headers,
sysroot and available platform libraries differ; a build for `-android21` is not
a build for `-android35`.

`references/systems/` describes each family; `snippets/systems/<family>.sh` holds
the ready-to-source environment fragment (the exact `CC`/`CFLAGS`/`LDFLAGS`/… and
the sysroot, with a short header saying what the toolchain supplies and what the
platform does); `templates/system/` holds the portable non-shell pieces to copy —
`toolchain.cmake` for CMake, `crossfile.ini` for Meson.

### 2. Driver — one stub per build system

Each build system needs exactly one shell recipe, and it belongs to the system,
not to the package:

- know how to tell the build its host and target (`--host`/`--build`, or
  `CMAKE_TOOLCHAIN_FILE`, or a Meson cross file, or `--target`);
- know where to find dependencies (pkg-config with `PKG_CONFIG_LIBDIR` and
  `--static`, `CMAKE_PREFIX_PATH`, `CARGO_HOME`);
- know how to install into a stage rather than into the final prefix, so a
  failed build publishes nothing;
- know its own traps (see below).

Because the driver holds this, a package recipe is small: source, dependencies,
and the flags that are genuinely its own.

`references/buildsystems/` has the stubs, the required variables and the traps.

### 3. Package — only what is its own

A package directory answers three questions: where the source comes from, what
it depends on, what it must override. The source can be a tarball, a git tag, or
another package (a `source`-kind dependency whose only job is to hold a tree —
useful when a project is consumed as sources rather than as libraries).

Override per target only when the target genuinely differs. A `generic` recipe
plus per-system overrides means the differences are visible and tracked instead
of hidden in a copied file.

`references/libraries/` records what specific projects needed.

### 4. Dependency closure — same system, and tools from the host

Two rules, and both are load-bearing:

- **A dependency is built for the same system as its consumer.** Never mix:
  an `aarch64` library must not end up linked into an `x86_64` build. This is
  what makes the four layers multiply cleanly instead of turning into a matrix
  of special cases.
- **Anything that must RUN during the build comes from the native system.**
  A code generator, a `help2man`, a `perl`, a `m4`: it is a native package, and
  its path is spelled into the recipe that runs it. Cross-compiled tools cannot
  run on the build machine without emulation, which is never worth it.

## Rules that pay for themselves

1. **Stage, then publish.** Install into a staging directory and move it into
   place only after a successful build. Builds lie about success otherwise.
2. **`DESTDIR` is not always honoured.** Automake's and some hand-written
   Makefiles *assign* `DESTDIR`, and a Makefile variable beats the environment.
   Pass it on the command line (`make install DESTDIR="$stage"`) for those, or
   the install writes straight into the published prefix and the publish step
   then fails with a message about a missing staging path.
3. **Environment leaks between build steps.** A variable one build sets and
   another reads as "already set" (a `make=no` left over, an `$ORIGIN` that got
   split by a shell) silently changes a later build. Reset the environment at
   the start of every step instead of trusting the previous one.
4. **Flag lists get word-split.** A build that takes a list of flags needs each
   word passed separately, or a flag containing spaces arrives as several
   arguments and configure rejects the second one. The same applies in reverse:
   an option a build does not actually implement is worse than no option.
5. **Version guards are real.** Upstream code changes shape across major
   versions (a program layer splitting into modules, a variable turning atomic).
   A patch or a header that works on one version can be a silent no-op — or a
   compile failure — on the next. Check the branch, not the memory.
6. **Build tools are not part of the target.** A JDK, a Gradle, an SDK: they
   are host facts. Pin the ones the build needs, state which version the build
   actually supports, and keep it out of the target's dependency graph.
7. **Verify the artifact, not the log line.** "SUCCESS" lines are printed by
   scripts that can be wrong. Unpack the archive, list its contents, compare a
   hash against the package that was supposed to supply it, check that a symbol
   or a string the patch was supposed to add is actually present.
8. **One build at a time, one thread at a time.** Parallel builds of the same
   closure fight over the same store and the same logs, and memory is finite.
   A single-threaded build is slower but reproducible.

## Layout of this skill

- `references/systems/` — one file per system family, plus the API/ABI notes.
- `snippets/systems/<family>.sh` — the exact environment to source (CC/CXX/AR/
  RANLIB/STRIP/NM, CFLAGS/LDFLAGS, PKG_CONFIG_*, sysroot), one per family.
- `references/buildsystems/` — one file per build system, with POSIX stubs.
- `references/libraries/` — what specific projects needed and why.
- `templates/system/<family>/` — `toolchain.cmake`, `crossfile.ini`, `README.md`.
- `scripts/` — helpers used while checking a build.
