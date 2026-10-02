#!/bin/sh
# READ THIS FIRST: this script edits the early chapters' own example files to be WRONG, one at a time, and re-runs the new
#   chapter tests (test/chapters). A "caught by" line (a test failed) is the EXPECTED, wanted result: it shows the test can notice that
#   mistake. "NOT CAUGHT" would be a test gap. Every file is restored afterwards. Output: chapter_tests_mutation_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); D=$HERE/../..; LIT=$D/part15/code/run_lit.sh; W=$HERE/work/mut; mkdir -p $W
echo "NOTE: this script deliberately damages example files. 'caught by' lines are EXPECTED: they show the tests can detect the damage."
run() {  # label baseline?
  out=$(MG_TEST_TMP=$W/out sh $LIT --filter ':: chapters/' 2>&1); fails=$(echo "$out" | grep '^FAIL' | sed 's/.*:: //; s/ (.*//' | tr '\n' ' ')
  if [ "$2" = baseline ]; then [ -z "$fails" ] && echo "$1: all tests pass (expected)" || echo "$1: UNEXPECTED FAILURES: $fails"
  else [ -n "$fails" ] && echo "$1: caught by $fails" || echo "$1: NOT CAUGHT (a test gap)"; fi
}
mutate() {  # label file sed-expr
  cp "$2" $W/backup; sed -i "$3" "$2"
  if cmp -s "$2" $W/backup; then echo "$1: MUTATION DID NOT APPLY"; else run "$1"; fi
  cp $W/backup "$2"
}
run "baseline (nothing damaged)" baseline
mutate "Chapter 1: the loop subtracts instead of adds (answer is no longer 15)" $D/part1/code/sum.mlir 's/arith.addi %sum, %val/arith.subi %sum, %val/'
mutate "Chapter 2: the valid program loses its transpose" $D/part2/code/mountain_goat.mlir '/mg.transpose/d;s/mg.print %3/mg.print %2/'
mutate "Chapter 2: the 'bad' transpose is made valid (so it is no longer rejected)" $D/part2/code/bad_transpose.mlir 's/to tensor<2x3xf64>/to tensor<3x2xf64>/'
mutate "Chapter 9: the lowered add subtracts instead (JIT output changes)" $D/part9/code/add_tensors_llvm.mlir 's/llvm.fadd/llvm.fsub/'
run "restored (baseline again)" baseline
