# EnvSwitch

EnvSwitch is a per-user environment switcher for local GCC, CUDA Toolkit,
Python, and Node.js installs. Each tool has independent enabled and
selected-version state,
while a `clash on`-style global `on`/`off` flow can restore or pause the current
combination across terminals and SSH reconnects.

The default environment is:

- GCC: `gcc-12`
- CUDA Toolkit: `cuda-12.8`
- Python: `python-3.12.12`
- Node.js: `node-24.18.0` (LTS)

Installed GCC, CUDA Toolkit, Python, and Node.js directories are intentionally
ignored by git. The repository contains the switcher, manifests, docs, tests,
and empty placeholder directories; users download or add versions locally.

## Quick Start

```bash
git clone <repo-url> EnvSwitch
cd EnvSwitch

# One-time shell integration.
./bin/envswitch install
source ~/.bashrc

# Download the default local versions.
envswitch fetch defaults
envswitch fetch defaults --no-default-packages

# Enable all downloaded defaults now and in future terminals.
envswitch on
envswitch status

# Or enable only CUDA. GCC, Python, and Node.js keep their current states.
envswitch off
envswitch use cuda
```

Open a new terminal or reconnect over SSH and the same enabled state will be
loaded automatically.

If `envswitch on` prints success but `gcc --version` still shows the system GCC,
the current shell has not loaded the shell hook yet. Run `source ~/.bashrc` or
open a new terminal, then run `envswitch on` again. `type envswitch` should say
that EnvSwitch is a shell function.

To disable one tool or all currently enabled tools:

```bash
envswitch off cuda
envswitch off
```

Global `off` remembers the enabled combination. A later `envswitch on` restores
that combination. Tool-specific `use`, `on`, and `off` commands never change the
state or selected version of other tools.

To remove shell integration and disable EnvSwitch:

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
envswitch fetch gcc
envswitch fetch cuda 12.8
envswitch fetch cuda
envswitch fetch cuda 12.8 --source global
envswitch fetch cuda 12.8 --provider conda
envswitch fetch python
envswitch fetch python --no-default-packages
envswitch fetch node
envswitch fetch node 24.18.0
envswitch link gcc 12 /path/to/gcc-prefix
envswitch link cuda 12.8 /path/to/cuda-prefix
envswitch link python 3.12.12 /path/to/python-prefix
envswitch link node 24.18.0 /path/to/node-prefix
envswitch on
envswitch on cuda
envswitch off
envswitch off cuda
envswitch status
envswitch use gcc
envswitch use gcc 14
envswitch use cuda
envswitch use cuda 12.8
envswitch use python
envswitch use node
envswitch use node 24.18.0
envswitch default gcc 12
envswitch default cuda 12.8
envswitch default python 3.12.12
envswitch default node 24.18.0
```

For `fetch <tool>` and `use <tool>`, omitting the version selects that tool's
configured default.

`install` adds a managed block to `~/.bashrc` and, when present or when zsh is
the active shell, `~/.zshrc`. The block adds this repo's `bin/` directory to
`PATH` and sources the generated profile at `~/.config/EnvSwitch/profile.sh`.

`uninstall` removes that block, disables EnvSwitch state, removes the generated
profile, and also cleans up the old `scripts/use-default-gcc.sh` startup line
used by the previous layout.

`fetch` creates local installs under `modules/*/versions`. By default:

- GCC downloads conda-forge compiler packages through the Tsinghua conda-forge
  mirror. It uses `micromamba`, then `mamba`, then `conda`, whichever is
  available first. If none is installed, EnvSwitch bootstraps a private
  `micromamba` into the user's cache from the same mirror.
- CUDA Toolkit downloads the NVIDIA runfile from NVIDIA's China CDN and installs
  only the toolkit into the current user's repo checkout. This path does not
  require conda and does not install drivers.
- Python downloads a pinned `python-build-standalone` archive, verifies its
  SHA256 checksum, and extracts it without requiring conda or root access. The
  bundled artifact currently targets Linux x86_64. After fetching Python,
  EnvSwitch installs `modules/python/default-packages.txt` through `uv pip` when
  `uv` is available, or through the fetched Python's own `pip` otherwise.
- Node.js downloads the pinned official Linux x64 binary archive from
  nodejs.org, verifies its SHA256 checksum, and extracts it into the repo. The
  bundled Node.js 24 definition requires Linux kernel 4.18 and glibc 2.28 or
  newer; Ubuntu 20.04 and newer satisfy these requirements.

Default Python packages use the Tsinghua PyPI mirror. Set
`ENVS_PYPI_INDEX_URL` to override the package index. Pass
`--no-default-packages` to `fetch python` or `fetch defaults` to install only
the interpreter.

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
  python/
    default -> versions/python-3.12.12
    default-packages.txt
    manifest.toml
    versions/
      .gitkeep
      python-3.12.12/ # ignored, local install
  node/
    default -> versions/node-24.18.0
    manifest.toml
    versions/
      .gitkeep
      node-24.18.0/   # ignored, local install
legacy-scripts/
docs/
tests/
```

User cache is created outside the repo by default at `~/.cache/EnvSwitch/`.

## Manual Versions

Users can add their own versions without changing project code. Prefer `link`
when the toolchain already exists elsewhere:

```bash
envswitch link gcc 12 /path/to/gcc-prefix
envswitch link cuda 12.8 /path/to/cuda-prefix
envswitch link python 3.12.12 /path/to/python-prefix
envswitch link node 24.18.0 /path/to/node-prefix
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

For Python, `envswitch` expects:

```text
modules/python/versions/python-<version>/bin/python3
```

For Node.js, `envswitch` expects:

```text
modules/node/versions/node-<version>/bin/node
```

See [docs/node.md](docs/node.md) for the Node.js platform requirements and
module-specific commands.
