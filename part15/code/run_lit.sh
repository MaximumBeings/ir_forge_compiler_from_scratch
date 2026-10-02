#!/bin/sh
# Run the regression suite against an mg-opt build. Default: the newest build that exists, Chapter 19 then Chapter 14 (run ../../part19/code/build.sh or ../../part14/code/build.sh first).
# Override with MG_OPT=/path/to/mg-opt. Needs: pip install lit; FileCheck-18, not-18, mlir-translate-18, clang-18.
HERE=$(cd "$(dirname "$0")" && pwd)
export MG_OPT=${MG_OPT:-$(for b in part19 part14; do [ -x $HERE/../../$b/code/build/mg-opt ] && echo $HERE/../../$b/code/build/mg-opt && break; done)}
[ -x "$MG_OPT" ] || { echo "no mg-opt at $MG_OPT (build it first)"; exit 2; }
export MG_TEST_TMP=${MG_TEST_TMP:-$HERE/work/lit-out}
mkdir -p "$MG_TEST_TMP"
exec lit "$@" "$HERE/test"
