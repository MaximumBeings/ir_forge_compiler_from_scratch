#!/bin/sh
# Reproduces the two bugs found while hardening the pass, from the mutation builds that re-create them.
# Run ./stderr_mutation.sh first (it builds work/sm-3 = guard removed, work/sm-7 = unique names removed). Output: bugs/ and show/twice_globals.txt
# READ THIS FIRST: this script re-creates two real bugs found while writing the pass, from mutation builds.
#   FAIL lines (and non-zero exit statuses) in this script's output are the EXPECTED result: the error messages it prints ARE the bugs being demonstrated; nothing here is a regression in the final code.
#   The unmodified, current build is the baseline and must show no failures. A mutation or old build that makes NO test fail would be the problem.
echo "NOTE: this script deliberately runs broken or older code. FAIL lines below are EXPECTED: they show the tests can detect the problem. The baseline (unmodified current build) must show none."
HERE=$(cd "$(dirname "$0")" && pwd); I=$HERE/../../part15/code/test/Inputs; mkdir -p $HERE/bugs $HERE/show
cd $I
# 1. guard removed: the pass splits blocks inside an affine.for body
$HERE/work/sm-3/build/mg-opt nested.mlir --mg-lower-assert-to-stderr 2>&1 | head -4 | cut -c1-170 > $HERE/bugs/nested_without_guard.txt
# 2. unique-name search removed: a second run reuses a global name
$HERE/work/sm-7/build/mg-opt twice.mlir --mg-lower-assert-to-stderr --lower-affine --convert-scf-to-cf --mg-lower-assert-to-stderr 2>&1 | head -4 | cut -c1-170 > $HERE/bugs/twice_without_unique_names.txt
# and the fixed build's global names for the same input
$HERE/build/mg-opt twice.mlir --mg-lower-assert-to-stderr --lower-affine --convert-scf-to-cf --mg-lower-assert-to-stderr | grep "llvm.mlir.global" | sed -E 's/ \{addr_space.*//' | sort > $HERE/show/twice_globals.txt
exit 0
