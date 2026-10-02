#!/bin/sh
# Run the regression suite against an mg-opt build. Default: the newest build that exists, Chapter 30, then 29, 28, 24, 22, 21, 20, 19, 14 (run ../../part30/code/build.sh etc. first).
# Override with MG_OPT=/path/to/mg-opt. Needs: pip install lit; FileCheck-18, not-18, mlir-translate-18, clang-18.
HERE=$(cd "$(dirname "$0")" && pwd)
export MG_OPT=${MG_OPT:-$(for b in part30 part29 part28 part24 part22 part21 part20 part19 part14; do [ -x $HERE/../../$b/code/build/mg-opt ] && echo $HERE/../../$b/code/build/mg-opt && break; done)}
[ -x "$MG_OPT" ] || { echo "no mg-opt at $MG_OPT (build it first)"; exit 2; }
export MG_TEST_TMP=${MG_TEST_TMP:-$HERE/work/lit-out}
mkdir -p "$MG_TEST_TMP"
exec lit "$@" "$HERE/test"
