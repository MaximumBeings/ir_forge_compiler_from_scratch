#!/bin/sh
# Can this toolchain tell us WHY fusion declined? LLVM_DEBUG messages are compiled out of release builds. Output: debug_unavailable_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); M=${MG_OPT:-$HERE/../../part14/code/build/mg-opt}
echo '$ mlir-opt-18 --debug-only=affine-loop-fusion exp_A.mlir --affine-loop-fusion'
mlir-opt-18 --debug-only=affine-loop-fusion $HERE/exp_A.mlir --affine-loop-fusion -o /dev/null 2>&1 | head -2
echo
echo '$ strings /usr/lib/llvm-18/bin/mlir-opt | grep -c "Non-constant trip count unsupported"'
strings /usr/lib/llvm-18/bin/mlir-opt | grep -c "Non-constant trip count unsupported"
echo '$ strings /usr/lib/llvm-18/bin/mlir-opt | grep -c "Dynamic shapes not yet supported"'
strings /usr/lib/llvm-18/bin/mlir-opt | grep -c "Dynamic shapes not yet supported"
exit 0
