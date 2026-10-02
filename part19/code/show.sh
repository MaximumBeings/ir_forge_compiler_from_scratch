#!/bin/sh
# Evidence the chapter shows. Needs ./build.sh. Output goes to show/.
HERE=$(cd "$(dirname "$0")" && pwd); D=$HERE/../..; M=${MG_OPT:-$HERE/build/mg-opt}; O=$HERE/show; mkdir -p $O; I=$D/part15/code/test/Inputs
$M $I/dyn.mlir --convert-mg-to-affine --mg-lower-assert-to-stderr -o $O/dyn_after_pass.mlir
$M $I/nested.mlir --mg-lower-assert-to-stderr -o $O/nested_left.mlir
$M $I/nested.mlir --lower-affine --convert-scf-to-cf --mg-lower-assert-to-stderr -o $O/nested_rewritten.mlir
$M $I/twice.mlir --mg-lower-assert-to-stderr --lower-affine --convert-scf-to-cf --mg-lower-assert-to-stderr -o $O/twice_out.mlir
# ordering hazard: the STANDARD lowering first consumes cf.assert, so this pass then finds nothing to rewrite
$M $I/dyn.mlir --convert-mg-to-affine --lower-affine --convert-scf-to-cf --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --mg-lower-assert-to-stderr -o $O/ordering_wrong.mlir
{ echo "cf.assert left after the standard lowering: $(grep -c 'cf.assert' $O/ordering_wrong.mlir)"
  echo "calls to puts (the stdout lowering): $(grep -c 'llvm.call @puts' $O/ordering_wrong.mlir)"
  echo "calls to write (this pass): $(grep -c 'llvm.call @write' $O/ordering_wrong.mlir)"; } > $O/ordering_wrong.txt
# the exact bytes the message produces
LOW2='--lower-affine --convert-scf-to-cf --mg-lower-assert-to-stderr --convert-arith-to-llvm --finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts'
$M $I/boom.mlir $LOW2 -o $O/boom.llvm.mlir && mlir-translate-18 --mlir-to-llvmir $O/boom.llvm.mlir -o $O/boom.ll && clang-18 -c $O/boom.ll -o $O/boom.o 2>/dev/null && clang-18 $I/boom_harness.c $O/boom.o -o $O/boom.exe
$O/boom.exe 2>&1 >/dev/null | od -c > $O/boom_bytes.txt
$O/boom.exe 2>$O/boom_stderr.txt >/dev/null; echo "exit status: $?" > $O/boom_status.txt
rm -f $O/boom.llvm.mlir $O/boom.ll $O/boom.o $O/boom.exe
