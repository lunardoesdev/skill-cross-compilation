# physfs (PhysFS)

Virtual-filesystem abstraction library; installs `libphysfs.a`, `physfs.h`, `physfs.pc`
and a cmake package config.

- build system: **cmake** (`physfs/generic.toml:2`).
- source: GitHub tag archive `release-3.2.0`, `--strip-components=1`
  (`physfs/source.toml:5-12`).
- deps: none.
- recipe: `generic.toml` only — no `android.toml` (see traps).

## Overridden fields

```toml
args = ["-DPHYSFS_BUILD_STATIC=ON", "-DPHYSFS_BUILD_SHARED=OFF",
        "-DPHYSFS_BUILD_TEST=OFF", "-DPHYSFS_BUILD_DOCS=OFF", "-DPHYSFS_DISABLE_INSTALL=OFF"]
```
(`physfs/generic.toml:1657`)

- `PHYSFS_BUILD_SHARED=OFF`: defaults TRUE; a target prefix has no loader path. The static
  target is `physfs-static` whose `OUTPUT_NAME` is `physfs`, so `-lphysfs` resolves
  (`physfs/generic.toml:1623-1628`).
- **`PHYSFS_BUILD_TEST=OFF` is load-bearing**: defaults TRUE and then does `find_path`
  readline / `find_library` curses and `add_executable(test_physfs ...)`, **and appends it
  to `PHYSFS_INSTALL_TARGETS`** — so an interactive terminal test program would be
  *installed* into `$PREFIX/bin` (`physfs/generic.toml:1630-1635`).
- `PHYSFS_BUILD_DOCS=OFF`: defaults TRUE and reaches `find_package(Doxygen)`;
  doxygen is not in the prefix (`physfs/generic.toml:1637-1639`).
- Every archiver (zip/7z/grp/wad/hog/mvl/qpak/slb/iso9660/vdf) stays on deliberately: they
  are pure C decoders over an in-memory buffer, and 7z/zip ship their own
  miniz/lzma decompressors rather than looking for a system zlib
  (`physfs/generic.toml:1641-1651`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `test_physfs` gets installed into `$PREFIX/bin` | `PHYSFS_BUILD_TEST` defaults TRUE and is appended to the install targets (`physfs/generic.toml:1630-1635`) | `-DPHYSFS_BUILD_TEST=OFF` |
| doxygen demanded | `PHYSFS_BUILD_DOCS` default TRUE (`physfs/generic.toml:1637-1639`) | `-DPHYSFS_BUILD_DOCS=OFF` |
| an Android-specific switch seems needed | there is none — the Android backend is selected by the compiler's own `__ANDROID__` macro, not a build-system variable (`physfs/generic.toml:1653-1656`) | no `android.toml` |
