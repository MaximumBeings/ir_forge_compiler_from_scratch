#!/bin/sh
# Regenerates the real outputs the chapters display next to the tests that match them. Run ../../part14/code/build.sh first.
set -e
HERE=$(cd "$(dirname "$0")" && pwd); D=$HERE/../..; M=${MG_OPT:-$D/part14/code/build/mg-opt}; O=$HERE/show; mkdir -p $O
T=$HERE/test
$M $T/Inputs/fused.mlir --affine-loop-tile="tile-size=1" > $O/tile1.mlir
$M $T/Inputs/fused.mlir --affine-loop-unroll="unroll-full" --affine-loop-unroll="unroll-full" --canonicalize > $O/unroll_full.mlir
$M $T/Inputs/fused.mlir --affine-loop-fusion > $O/fusion_of_fused.mlir
$M $D/part7/code/mountain_goat_affine.mlir --affine-loop-fusion > $O/fusion.mlir
$M $T/Inputs/static_add.mlir --convert-mg-to-affine | mlir-opt-18 --pass-pipeline='builtin.module(func.func(affine-parallelize,lower-affine,gpu-map-parallel-loops,convert-parallel-loops-to-gpu),gpu-kernel-outlining)' > $O/kernel.mlir
$M $T/Inputs/static_add.mlir --convert-mg-to-affine | mlir-opt-18 --pass-pipeline='builtin.module(func.func(affine-parallelize,lower-affine,gpu-map-parallel-loops,convert-parallel-loops-to-gpu),gpu-kernel-outlining)' | mlir-opt-18 --pass-pipeline='builtin.module(lower-affine,nvvm-attach-target{chip=sm_70 features=+ptx60},gpu.module(convert-gpu-to-nvvm{index-bitwidth=64},reconcile-unrealized-casts))' > $O/nvvm.mlir
mlir-opt-18 $O/nvvm.mlir --gpu-module-to-binary="format=isa" -o $O/ptx64.bin.mlir && python3 $D/part10/code/decode_ptx.py $O/ptx64.bin.mlir > $O/ptx64.ptx
mlir-opt-18 $O/kernel.mlir --pass-pipeline='builtin.module(lower-affine,canonicalize,nvvm-attach-target{chip=sm_70 features=+ptx60},gpu.module(convert-gpu-to-nvvm{index-bitwidth=32},reconcile-unrealized-casts),gpu-module-to-binary{format=isa})' -o $O/ptx32.bin.mlir && python3 $D/part10/code/decode_ptx.py $O/ptx32.bin.mlir > $O/ptx32.ptx
mlir-opt-18 $T/Inputs/add_host_device.mlir --pass-pipeline='builtin.module(func.func(gpu-async-region))' -o $O/async.mlir
mlir-opt-18 $O/async.mlir --gpu-lower-to-nvvm-pipeline="cubin-chip=sm_70 cubin-features=+ptx60 cubin-format=isa kernel-bare-ptr-calling-convention=1" -o $O/bare.bin.mlir && python3 $D/part10/code/decode_ptx.py $O/bare.bin.mlir > $O/ptx_bare.ptx
mlir-opt-18 $O/async.mlir --gpu-lower-to-nvvm-pipeline="cubin-chip=sm_70 cubin-features=+ptx60 cubin-format=isa" -o $O/pipe.mlir && mlir-translate-18 --mlir-to-llvmir $O/pipe.mlir -o $O/host.ll
mlir-translate-18 --mlir-to-llvmir $O/bare.bin.mlir -o $O/host_bare.ll
clang-18 -x cuda --cuda-device-only --cuda-gpu-arch=sm_70 -nocudainc -nocudalib -S -O1 $T/Inputs/cuda_add.cu -o $O/cuda.ptx
rm -f $O/*.bin.mlir

# ---- outputs for Chapter 15's original 22 tests -------------------------------------------------------------
LOW='--lower-affine --convert-scf-to-cf --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts'
for t in add-static-mismatch transpose-bad-shape transpose-rank3 unranked-rejected; do
  (cd $T && $M verifier/$t.mlir) > $O/verify_$t.txt 2>&1 || true
done
$M $T/verifier/dynamic-accepted.mlir > $O/verify_dynamic-accepted.mlir
for t in fold-constant-add transpose-twice transpose-twice-dynamic-exact transpose-twice-dynamic-mixed; do
  $M $T/canonicalize/$t.mlir --canonicalize > $O/canon_$t.mlir
done
$M $T/lowering/static-add-affine.mlir --convert-mg-to-affine > $O/lower_static-add-affine.mlir
$M $T/lowering/dynamic-add-affine.mlir --convert-mg-to-affine > $O/lower_dynamic-add-affine.mlir
$M $T/lowering/mixed-add-one-check.mlir --convert-mg-to-affine > $O/lower_mixed-add-one-check.mlir
$M $T/lowering/dynamic-transpose-no-check.mlir --convert-mg-to-affine > $O/lower_dynamic-transpose.mlir
$M $T/lowering/bufferize-dynamic-add.mlir --one-shot-bufferize="bufferize-function-boundaries" > $O/lower_bufferize-dynamic-add.mlir
$M $T/lowering/bufferize-static-add.mlir --one-shot-bufferize="bufferize-function-boundaries" > $O/lower_bufferize-static-add.mlir
# native runs: build once per path, then run each harness
X=$O/_x; mkdir -p $X
build() {  # name, input.mlir, extra mg-opt args...
  n=$1; in=$2; shift 2
  $M $in "$@" > $X/$n.0.mlir 2>/dev/null; $M $X/$n.0.mlir $LOW -o $X/$n.mlir 2>/dev/null || cp $X/$n.0.mlir $X/$n.mlir
}
$M $T/Inputs/static_add.mlir --convert-mg-to-affine $LOW -o $X/sa.mlir
$M $T/Inputs/static_add.mlir --one-shot-bufferize="bufferize-function-boundaries" -o $X/sb0.mlir; $M $X/sb0.mlir $LOW -o $X/sb.mlir
$M $T/Inputs/dyn.mlir --convert-mg-to-affine $LOW -o $X/da.mlir
$M $T/Inputs/dyn.mlir --one-shot-bufferize="bufferize-function-boundaries" -o $X/db0.mlir; $M $X/db0.mlir $LOW -o $X/db.mlir
$M $T/Inputs/mixed.mlir --convert-mg-to-affine $LOW -o $X/ma.mlir
for n in sa sb da db ma; do mlir-translate-18 --mlir-to-llvmir $X/$n.mlir -o $X/$n.ll; clang-18 -c $X/$n.ll -o $X/$n.o 2>/dev/null; done
clang-18 $T/Inputs/static_harness.c $X/sa.o -o $X/sa.exe && $X/sa.exe > $O/exec_static-path-A.txt
clang-18 $T/Inputs/static_harness.c $X/sb.o -o $X/sb.exe && $X/sb.exe > $O/exec_static-path-B.txt
clang-18 $T/Inputs/dyn_harness.c $X/da.o -o $X/da.exe && $X/da.exe > $O/exec_dynamic-path-A.txt
clang-18 -DSTRIDED $T/Inputs/dyn_harness.c $X/db.o -o $X/db.exe && $X/db.exe > $O/exec_dynamic-path-B-strided.txt
clang-18 $T/Inputs/mismatch_harness.c $X/da.o -o $X/mm.exe; { stdbuf -oL $X/mm.exe 2>&1; echo "exit status: $?"; } > $O/exec_mismatch-rows.txt 2>&1 || true
clang-18 $T/Inputs/mismatch_cols_harness.c $X/da.o -o $X/mc.exe; { stdbuf -oL $X/mc.exe 2>&1; echo "exit status: $?"; } > $O/exec_mismatch-columns.txt 2>&1 || true
clang-18 $T/Inputs/mixed_harness.c $X/ma.o -o $X/mx.exe; { $X/mx.exe 3; stdbuf -oL $X/mx.exe 2 2>&1; echo "exit status: $?"; } > $O/exec_mixed.txt 2>&1 || true
rm -rf $X
