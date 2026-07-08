#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT
GCC12="$ROOT/modules/gcc/versions/gcc-12/bin/x86_64-conda-linux-gnu-gcc"
GCC14="$ROOT/modules/gcc/versions/gcc-14/bin/x86_64-conda-linux-gnu-gcc"
CUDA128="$ROOT/modules/cuda/versions/cuda-12.8"

export HOME="$TMP_HOME"
export XDG_CONFIG_HOME="$TMP_HOME/.config"

clean_bash() {
    env -i \
        HOME="$TMP_HOME" \
        XDG_CONFIG_HOME="$TMP_HOME/.config" \
        SHELL=/bin/bash \
        PATH=/usr/bin:/bin \
        bash --rcfile "$TMP_HOME/.bashrc" -ic "$1"
}

"$ROOT/bin/envswitch" install >/dev/null
clean_bash 'envswitch status' | grep -q 'state: disabled'

if [ -x "$GCC12" ] && [ -x "$CUDA128/bin/nvcc" ]; then
    "$ROOT/bin/envswitch" on >/dev/null

    clean_bash 'envswitch status' | grep -q 'state: enabled'
    clean_bash "test \"\${CC:-}\" = \"$GCC12\""
    clean_bash "test \"\$(command -v gcc)\" = \"$ROOT/modules/gcc/versions/gcc-12/bin/gcc\""
    clean_bash "gcc --version | grep -q '12'"
    clean_bash "case \":\${LIBRARY_PATH:-}:\" in *\":$ROOT/modules/gcc/versions/gcc-12/lib:\"*) ;; *) exit 1 ;; esac"
    clean_bash "case \":\${CMAKE_PREFIX_PATH:-}:\" in *\":$ROOT/modules/gcc/versions/gcc-12:\"*) ;; *) exit 1 ;; esac"
    clean_bash "test \"\${CUDA_HOME:-}\" = \"$CUDA128\""

    if [ -x "$GCC14" ]; then
        clean_bash "envswitch use gcc 14 >/dev/null; test \"\${CC:-}\" = \"$GCC14\""
        clean_bash "test \"\${CC:-}\" = \"$GCC14\""
    fi

    clean_bash 'envswitch off >/dev/null; test -z "${CC:-}"'
    clean_bash 'test -z "${CC:-}"'
    clean_bash 'test -z "${LIBRARY_PATH:-}"'
else
    if [ ! -x "$GCC12" ]; then
        output="$(clean_bash 'envswitch on' 2>&1 || true)"
        grep -q 'envswitch fetch gcc 12' <<<"$output"
    elif [ ! -x "$CUDA128/bin/nvcc" ]; then
        output="$(clean_bash 'envswitch on' 2>&1 || true)"
        grep -q 'envswitch fetch cuda 12.8' <<<"$output"
    fi
fi

"$ROOT/bin/envswitch" uninstall >/dev/null
! grep -q 'envswitch' "$TMP_HOME/.bashrc"

printf 'smoke ok\n'
