#!/bin/sh
# Run the regression suite against an mg-opt build. Default: Chapter 14's build (run ../../part14/code/build.sh first).
# Override with MG_OPT=/path/to/mg-opt. Needs: pip install lit; FileCheck-18, not-18, mlir-translate-18, clang-18.
HERE=$(cd "$(dirname "$0")" && pwd)
export MG_OPT=${MG_OPT:-$HERE/../../part14/code/build/mg-opt}
[ -x "$MG_OPT" ] || { echo "no mg-opt at $MG_OPT (build it first)"; exit 2; }
export MG_TEST_TMP=${MG_TEST_TMP:-$HERE/work/lit-out}
mkdir -p "$MG_TEST_TMP"
exec lit "$@" "$HERE/test"
