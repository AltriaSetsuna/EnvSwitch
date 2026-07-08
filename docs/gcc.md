# GCC Module

The GCC module lives at:

```text
modules/gcc/
```

Available versions:

```text
modules/gcc/versions/gcc-11
modules/gcc/versions/gcc-12
modules/gcc/versions/gcc-14
```

These directories are local installs and are ignored by git.

The default version is selected by:

```text
modules/gcc/default -> versions/gcc-12
```

## Exports

When enabled, the GCC module sets:

```bash
TOOLCHAIN_ROOT
ENVSWITCH_GCC_HOME
CC
CXX
CMAKE_C_COMPILER
CMAKE_CXX_COMPILER
CMAKE_ARGS
LIBRARY_PATH
PKG_CONFIG_PATH
CMAKE_PREFIX_PATH
```

It also prepends:

```text
$ENVSWITCH_GCC_HOME/bin
```

to `PATH`.

`envswitch` ensures the local GCC prefix exposes common command names:

```text
gcc
g++
cc
c++
```

For conda-forge GCC installs, these point at the target-prefixed compiler
drivers.

The GCC module does not export its `lib` or `lib64` directories through
`LD_LIBRARY_PATH` globally. That keeps ordinary shell tools from accidentally
loading compiler-package libraries.

For build tools, it exports compile/link-time search paths through
`LIBRARY_PATH`, `PKG_CONFIG_PATH`, and `CMAKE_PREFIX_PATH`.

## Common Commands

```bash
envswitch use gcc 12
envswitch use gcc 14
envswitch default gcc 12
```

The compiler paths use the conda-forge target prefix:

```text
x86_64-conda-linux-gnu-gcc
x86_64-conda-linux-gnu-g++
```

Use `envswitch fetch gcc 12` to install the default GCC module from the
Tsinghua conda-forge mirror with micromamba, mamba, or conda. If none of those
commands exists, envswitch downloads a private micromamba package from the
Tsinghua conda-forge mirror into the user's cache and uses it automatically.

Register an existing compatible GCC prefix without copying it:

```bash
envswitch link gcc 12 /path/to/gcc-prefix
```
