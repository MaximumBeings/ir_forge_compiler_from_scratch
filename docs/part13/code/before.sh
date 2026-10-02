#!/bin/sh
# Real outputs of the UNMODIFIED compiler (the Chapter 7 build, before this chapter's fixes) on dynamic-shape inputs.
# Needs ../../part15/code/older_builds.sh to have been run once (it builds the Chapter 7 mg-opt this uses).
# READ THIS FIRST: this script shows how the UNMODIFIED, earlier compiler behaves on this chapter's programs.
#   FAIL lines (and non-zero exit statuses) in this script's output are the EXPECTED result: the earlier compiler cannot handle dynamic shapes, so errors and failures here are the "before" picture and are expected.
#   The unmodified, current build is the baseline and must show no failures. A mutation or old build that makes NO test fail would be the problem.
echo "NOTE: this script deliberately runs broken or older code. FAIL lines below are EXPECTED: they show the tests can detect the problem. The baseline (unmodified current build) must show none."
HERE=$(cd "$(dirname "$0")" && pwd); OLD=$HERE/../../part15/code/work/ch7/build/mg-opt; O=$HERE/before; mkdir -p $O; cd $HERE
LOW='--lower-affine --convert-scf-to-cf --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts'
$OLD dyn_add.mlir                                   > $O/dyn_add_verify.txt 2>&1
$OLD dyn_transpose.mlir                             > $O/dyn_transpose_verify.txt 2>&1
$OLD mixed_add.mlir                                 > $O/mixed_add_verify.txt 2>&1
$OLD dyn_add.mlir --convert-mg-to-affine            > $O/dyn_add_convert.txt 2>&1
$OLD dyn_add.mlir --one-shot-bufferize="bufferize-function-boundaries" > $O/dyn_add_bufferize.txt 2>&1
$OLD unranked.mlir                                  > $O/unranked_verify.txt 2>&1
$OLD tt.mlir --canonicalize                       > $O/tt_on_chapter7_build.txt 2>&1
# The canonicalizer bug only shows once the verifier accepts the program, i.e. with the relaxed verifiers but WITHOUT
# the exact-type guard. That state is Chapter 15's mutation 1 (needs ../../part15/code/mutation.sh to have been run).
MUT1=$HERE/../../part15/code/work/mut-1/build/mg-opt
[ -x $MUT1 ] && $MUT1 tt.mlir --canonicalize        > $O/tt_without_guard.txt 2>&1
exit 0   # the compiler errors above are the point; do not propagate them
