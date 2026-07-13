#!/usr/bin/env bash
set -euo pipefail

SOURCE_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

ROOT="$TMP_ROOT/EnvSwitch"
HOME_DIR="$TMP_ROOT/home"
FAKE_BIN="$TMP_ROOT/fake-bin"
UV_LOG="$TMP_ROOT/uv.log"
PIP_LOG="$TMP_ROOT/pip.log"
mkdir -p "$ROOT" "$HOME_DIR" "$FAKE_BIN"

tar \
    --exclude=.git \
    --exclude='modules/gcc/versions/*' \
    --exclude='modules/cuda/versions/*' \
    --exclude='modules/python/versions/*' \
    --exclude='modules/node/versions/*' \
    -C "$SOURCE_ROOT" -cf - . |
    tar -C "$ROOT" -xf -

GCC12_HOME="$ROOT/modules/gcc/versions/gcc-12"
CUDA128_HOME="$ROOT/modules/cuda/versions/cuda-12.8"
PYTHON312_HOME="$ROOT/modules/python/versions/python-3.12.12"
NODE2418_HOME="$ROOT/modules/node/versions/node-24.18.0"

mkdir -p \
    "$GCC12_HOME/bin" \
    "$GCC12_HOME/lib" \
    "$GCC12_HOME/lib64" \
    "$GCC12_HOME/x86_64-conda-linux-gnu/lib" \
    "$CUDA128_HOME/bin" \
    "$CUDA128_HOME/lib64" \
    "$CUDA128_HOME/extras/CUPTI/lib64" \
    "$PYTHON312_HOME/bin" \
    "$NODE2418_HOME/bin"

cat >"$GCC12_HOME/bin/x86_64-conda-linux-gnu-gcc" <<'EOF'
#!/usr/bin/env bash
printf 'gcc (EnvSwitch test) 12.0.0\n'
EOF
cat >"$GCC12_HOME/bin/x86_64-conda-linux-gnu-g++" <<'EOF'
#!/usr/bin/env bash
printf 'g++ (EnvSwitch test) 12.0.0\n'
EOF
cat >"$CUDA128_HOME/bin/nvcc" <<'EOF'
#!/usr/bin/env bash
printf 'Cuda compilation tools, release 12.8\n'
EOF
cat >"$PYTHON312_HOME/bin/python3" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-m" && "${2:-}" == "pip" ]]; then
    printf '%s\n' "$*" >"${ENVS_TEST_PIP_LOG:?}"
    exit 0
fi
printf 'Python 3.12.12\n'
EOF
cat >"$PYTHON312_HOME/bin/pip3" <<'EOF'
#!/usr/bin/env bash
printf 'pip test\n'
EOF
cat >"$NODE2418_HOME/bin/node" <<'EOF'
#!/usr/bin/env bash
printf 'v24.18.0\n'
EOF
cat >"$NODE2418_HOME/bin/npm" <<'EOF'
#!/usr/bin/env bash
printf '11.11.0\n'
EOF
cat >"$FAKE_BIN/uv" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >"${ENVS_TEST_UV_LOG:?}"
EOF
chmod +x \
    "$GCC12_HOME/bin/x86_64-conda-linux-gnu-gcc" \
    "$GCC12_HOME/bin/x86_64-conda-linux-gnu-g++" \
    "$CUDA128_HOME/bin/nvcc" \
    "$PYTHON312_HOME/bin/python3" \
    "$PYTHON312_HOME/bin/pip3" \
    "$NODE2418_HOME/bin/node" \
    "$NODE2418_HOME/bin/npm" \
    "$FAKE_BIN/uv"

export HOME="$HOME_DIR"
export XDG_CONFIG_HOME="$HOME_DIR/.config"

ENVS_TEST_UV_LOG="$UV_LOG" \
    PATH="$FAKE_BIN:/usr/bin:/bin" \
    "$ROOT/bin/envswitch" fetch python >/dev/null
grep -Fq "pip install --python $PYTHON312_HOME/bin/python3" "$UV_LOG"
grep -Fq -- "-r $ROOT/modules/python/default-packages.txt" "$UV_LOG"

rm -f "$UV_LOG"
ENVS_TEST_UV_LOG="$UV_LOG" \
    PATH="$FAKE_BIN:/usr/bin:/bin" \
    "$ROOT/bin/envswitch" fetch python --no-default-packages >/dev/null
test ! -e "$UV_LOG"

PATH="/usr/bin:/bin" "$ROOT/bin/envswitch" fetch node >/dev/null

ENVS_TEST_UV_LOG="$UV_LOG" \
    PATH="$FAKE_BIN:/usr/bin:/bin" \
    "$ROOT/bin/envswitch" fetch defaults --no-default-packages >/dev/null
test ! -e "$UV_LOG"

ENVS_TEST_PIP_LOG="$PIP_LOG" \
    PATH="/usr/bin:/bin" \
    "$ROOT/bin/envswitch" fetch python >/dev/null
grep -Fq -- "-m pip install" "$PIP_LOG"
grep -Fq -- "-r $ROOT/modules/python/default-packages.txt" "$PIP_LOG"

clean_bash() {
    env -i \
        HOME="$HOME_DIR" \
        XDG_CONFIG_HOME="$HOME_DIR/.config" \
        SHELL=/bin/bash \
        PATH=/usr/bin:/bin \
        bash --noprofile --rcfile "$HOME_DIR/.bashrc" -ic "$1"
}

"$ROOT/bin/envswitch" install >/dev/null

clean_bash 'envswitch status' | grep -E '^gcc[[:space:]]+disabled' >/dev/null
clean_bash 'envswitch status' | grep -E '^cuda[[:space:]]+disabled' >/dev/null
clean_bash 'envswitch status' | grep -E '^python[[:space:]]+disabled' >/dev/null
clean_bash 'envswitch status' | grep -E '^node[[:space:]]+disabled' >/dev/null

clean_bash 'envswitch use cuda >/dev/null; test -z "${CC:-}"; test "$CUDA_HOME" = "'"$CUDA128_HOME"'"; test -z "${ENVS_PYTHON_HOME:-}"'
clean_bash 'test -z "${CC:-}"; test "$CUDA_HOME" = "'"$CUDA128_HOME"'"'
clean_bash 'envswitch status' | grep -E '^cuda[[:space:]]+enabled[[:space:]]+12[.]8' >/dev/null
clean_bash 'envswitch status' | grep -E '^gcc[[:space:]]+disabled' >/dev/null

clean_bash 'envswitch use gcc >/dev/null; test "$CC" = "'"$GCC12_HOME"'/bin/x86_64-conda-linux-gnu-gcc"; test "$CUDA_HOME" = "'"$CUDA128_HOME"'"'
clean_bash 'gcc --version | grep -q 12'
clean_bash 'case ":${LIBRARY_PATH:-}:" in *":'"$GCC12_HOME"'/lib:"*) ;; *) exit 1 ;; esac'

clean_bash 'envswitch off cuda >/dev/null; test -n "${CC:-}"; test -z "${CUDA_HOME:-}"'
clean_bash 'envswitch use python >/dev/null; test -n "${CC:-}"; test -z "${CUDA_HOME:-}"; test "$ENVS_PYTHON_HOME" = "'"$PYTHON312_HOME"'"'
clean_bash 'python --version | grep -q "Python 3.12.12"'
clean_bash 'envswitch use node >/dev/null; test -n "${CC:-}"; test -n "${ENVS_PYTHON_HOME:-}"; test "$ENVS_NODE_HOME" = "'"$NODE2418_HOME"'"'
clean_bash 'node --version | grep -q "v24.18.0"'
clean_bash 'npm --version | grep -q "11.11.0"'
clean_bash 'envswitch off node >/dev/null; test -n "${CC:-}"; test -n "${ENVS_PYTHON_HOME:-}"; test -z "${ENVS_NODE_HOME:-}"'
clean_bash 'envswitch on node >/dev/null; test -n "${CC:-}"; test -n "${ENVS_PYTHON_HOME:-}"; test -n "${ENVS_NODE_HOME:-}"'
clean_bash 'envswitch default node 24.18.0 >/dev/null; test -n "${ENVS_NODE_HOME:-}"'

clean_bash 'envswitch off >/dev/null; test -z "${CC:-}"; test -z "${CUDA_HOME:-}"; test -z "${ENVS_PYTHON_HOME:-}"; test -z "${ENVS_NODE_HOME:-}"'
clean_bash 'envswitch on >/dev/null; test -n "${CC:-}"; test -z "${CUDA_HOME:-}"; test -n "${ENVS_PYTHON_HOME:-}"; test -n "${ENVS_NODE_HOME:-}"'
clean_bash 'envswitch on cuda >/dev/null; test -n "${CC:-}"; test -n "${CUDA_HOME:-}"; test -n "${ENVS_PYTHON_HOME:-}"; test -n "${ENVS_NODE_HOME:-}"'

grep -q "ENVS_STATE_VERSION='3'" "$XDG_CONFIG_HOME/EnvSwitch/state"
grep -q "ENVS_GCC_ENABLED='1'" "$XDG_CONFIG_HOME/EnvSwitch/state"
grep -q "ENVS_CUDA_ENABLED='1'" "$XDG_CONFIG_HOME/EnvSwitch/state"
grep -q "ENVS_PYTHON_ENABLED='1'" "$XDG_CONFIG_HOME/EnvSwitch/state"
grep -q "ENVS_NODE_ENABLED='1'" "$XDG_CONFIG_HOME/EnvSwitch/state"

cat >"$XDG_CONFIG_HOME/EnvSwitch/state" <<'EOF'
ENVS_STATE_VERSION='2'
ENVS_GCC_ENABLED='0'
ENVS_GCC_VERSION='12'
ENVS_CUDA_ENABLED='1'
ENVS_CUDA_VERSION='12.8'
ENVS_PYTHON_ENABLED='1'
ENVS_PYTHON_VERSION='3.12.12'
ENVS_LAST_ENABLED_MODULES='cuda python'
EOF
"$ROOT/bin/envswitch" install >/dev/null
grep -q "ENVS_STATE_VERSION='3'" "$XDG_CONFIG_HOME/EnvSwitch/state"
grep -q "ENVS_CUDA_ENABLED='1'" "$XDG_CONFIG_HOME/EnvSwitch/state"
grep -q "ENVS_PYTHON_ENABLED='1'" "$XDG_CONFIG_HOME/EnvSwitch/state"
grep -q "ENVS_NODE_ENABLED='0'" "$XDG_CONFIG_HOME/EnvSwitch/state"

cat >"$XDG_CONFIG_HOME/EnvSwitch/state" <<'EOF'
ENVS_ENABLED='1'
ENVS_GCC_VERSION='12'
ENVS_CUDA_VERSION='12.8'
EOF
"$ROOT/bin/envswitch" install >/dev/null
grep -q "ENVS_STATE_VERSION='3'" "$XDG_CONFIG_HOME/EnvSwitch/state"
grep -q "ENVS_GCC_ENABLED='1'" "$XDG_CONFIG_HOME/EnvSwitch/state"
grep -q "ENVS_CUDA_ENABLED='1'" "$XDG_CONFIG_HOME/EnvSwitch/state"
grep -q "ENVS_PYTHON_ENABLED='0'" "$XDG_CONFIG_HOME/EnvSwitch/state"
grep -q "ENVS_NODE_ENABLED='0'" "$XDG_CONFIG_HOME/EnvSwitch/state"

"$ROOT/bin/envswitch" uninstall >/dev/null
! grep -q 'EnvSwitch' "$HOME_DIR/.bashrc"

printf 'smoke ok\n'
