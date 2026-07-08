# envswitch

`envswitch` is a per-user environment switcher for local compiler and CUDA
Toolkit installs. It gives you a `clash on`-style workflow for development
environments: one command enables the selected environment in the current
terminal and keeps it enabled for future terminals and SSH reconnects.

The default environment is:

- GCC: `gcc-12`
- CUDA Toolkit: `cuda-12.8`

Installed GCC and CUDA Toolkit directories are intentionally ignored by git. The
repository contains the switcher, manifests, docs, tests, and empty placeholder
directories; users download or add versions locally.

## Quick Start

```bash
git clone <repo-url> envswitch
cd envswitch

# One-time shell integration.
./bin/envswitch install
source ~/.bashrc

# Download the default local versions.
envswitch fetch defaults

# Enable gcc-12 + cuda-12.8 now and in future terminals.
envswitch on
envswitch status
```

Open a new terminal or reconnect over SSH and the same enabled state will be
loaded automatically.

To disable the managed environment:

```bash
envswitch off
```

To remove shell integration and disable envswitch:

```bash
envswitch uninstall
```

## Commands

```bash
envswitch install
envswitch uninstall
envswitch fetch defaults
envswitch fetch gcc 11
envswitch fetch gcc 12
envswitch fetch gcc 14
envswitch fetch cuda 12.8
envswitch fetch cuda 12.8 --source global
envswitch fetch cuda 12.8 --provider conda
envswitch link gcc 12 /path/to/gcc-prefix
envswitch link cuda 12.8 /path/to/cuda-prefix
envswitch on
envswitch off
envswitch status
envswitch use gcc 14
envswitch use cuda 12.8
envswitch default gcc 12
envswitch default cuda 12.8
```

`install` adds a managed block to `~/.bashrc` and, when present or when zsh is
the active shell, `~/.zshrc`. The block adds this repo's `bin/` directory to
`PATH` and sources the generated profile at `~/.config/envswitch/profile.sh`.

`uninstall` removes that block, disables envswitch state, removes the generated
profile, and also cleans up the old `scripts/use-default-gcc.sh` startup line
used by the previous layout.

`fetch` creates local installs under `modules/*/versions`. By default:

- GCC downloads conda-forge compiler packages through the Tsinghua conda-forge
  mirror. It uses `micromamba`, then `mamba`, then `conda`, whichever is
  available first. If none is installed, envswitch bootstraps a private
  `micromamba` into the user's cache from the same mirror.
- CUDA Toolkit downloads the NVIDIA runfile from NVIDIA's China CDN and installs
  only the toolkit into the current user's repo checkout. This path does not
  require conda and does not install drivers.

For CUDA, use `--source global` to force NVIDIA's global download host,
`--source tuna` to try the Tsinghua CUDA mirror, or `--provider conda` to use the
Tsinghua Anaconda NVIDIA and conda-forge mirrors instead of the runfile provider.

## Layout

```text
bin/envswitch
lib/envswitch.sh
modules/
  gcc/
    default -> versions/gcc-12
    manifest.toml
    versions/
      .gitkeep
      gcc-11/        # ignored, local install
      gcc-12/        # ignored, local install
      gcc-14/        # ignored, local install
  cuda/
    default -> versions/cuda-12.8
    manifest.toml
    versions/
      .gitkeep
      cuda-12.8/     # ignored, local install
legacy-scripts/
docs/
tests/
.cache/envswitch/      # user cache; created outside the repo by default
```

## Manual Versions

Users can add their own versions without changing project code. Prefer `link`
when the toolchain already exists elsewhere:

```bash
envswitch link gcc 12 /path/to/gcc-prefix
envswitch link cuda 12.8 /path/to/cuda-prefix
```

You can also populate the ignored version directories manually:

```bash
mkdir -p modules/gcc/versions/gcc-13
# populate modules/gcc/versions/gcc-13 with a compatible compiler prefix
envswitch use gcc 13
```

For GCC, `envswitch` expects:

```text
modules/gcc/versions/gcc-<version>/bin/x86_64-conda-linux-gnu-gcc
modules/gcc/versions/gcc-<version>/bin/x86_64-conda-linux-gnu-g++
```

For CUDA, `envswitch` expects a toolkit-style prefix:

```text
modules/cuda/versions/cuda-<version>/bin
modules/cuda/versions/cuda-<version>/bin/nvcc
modules/cuda/versions/cuda-<version>/lib64
```
