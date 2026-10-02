#!/bin/sh
# READ THIS FIRST: this script edits the contraction code (cpp/tensor.h and cpp/contract.mg) to be WRONG, one way at a time, and re-runs
#   the Chapter 27 tests (test/contraction). A "caught" line (a test failed) is the EXPECTED, wanted result: it shows the tests can notice
#   that mistake. "NOT CAUGHT" would be a test gap. Every file is restored afterwards. Output: contraction_mutation_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); D=$HERE/../..; LIT=$D/part15/code/run_lit.sh; W=$HERE/work/mut; mkdir -p $W
H=$HERE/cpp/tensor.h; G=$HERE/cpp/contract.mg
cp $H $W/tensor.orig; cp $G $W/contract.orig
echo "NOTE: this script deliberately breaks the contraction code. 'caught' lines are EXPECTED: they show the tests can detect the mistake."
run() { out=$(MG_TEST_TMP=$W/out sh $LIT --filter ':: contraction/' 2>&1); fails=$(echo "$out" | grep '^FAIL' | sed 's/.*:: //; s/ (.*//' | tr '\n' ' ')
  if [ -n "$fails" ]; then echo "$1: caught by $fails"; else echo "$1: NOT CAUGHT (a test gap)"; fi; }
mutate() {  # label file sed-expr
  cp $W/tensor.orig $H; cp $W/contract.orig $G; sed -i "$3" "$2"
  if cmp -s $H $W/tensor.orig && cmp -s $G $W/contract.orig; then echo "$1: MUTATION DID NOT APPLY"; else run "$1"; fi
  cp $W/tensor.orig $H; cp $W/contract.orig $G
}
out=$(MG_TEST_TMP=$W/out sh $LIT --filter ':: contraction/' 2>&1); echo "baseline (nothing broken): $(echo "$out" | grep -q '^FAIL' && echo 'UNEXPECTED FAILURE' || echo 'tests pass (expected)')"
mutate "A: contracted axes first, free axes last (swapped)"        $H 's/std::vector<int> perm_a = fa; perm_a.insert(perm_a.end(), axes_a.begin(), axes_a.end());/std::vector<int> perm_a = axes_a; perm_a.insert(perm_a.end(), fa.begin(), fa.end());/'
mutate "B: free axes first, contracted axes last (swapped)"        $H 's/std::vector<int> perm_b = axes_b; perm_b.insert(perm_b.end(), fb.begin(), fb.end());/std::vector<int> perm_b = fb; perm_b.insert(perm_b.end(), axes_b.begin(), axes_b.end());/'
mutate "B's contracted axes taken in increasing order, not paired" $H 's/std::vector<int> perm_b = axes_b;/std::vector<int> perm_b = axes_b; std::sort(perm_b.begin(), perm_b.end());/'
mutate "output shape lists the free axes of B first"                $H 's/std::vector<int> out_shape = free_a_dims; out_shape.insert(out_shape.end(), free_b_dims.begin(), free_b_dims.end());/std::vector<int> out_shape = free_b_dims; out_shape.insert(out_shape.end(), free_a_dims.begin(), free_a_dims.end());/'
mutate "the size check of a contracted pair is removed"           $H 's/if (da != db)$/if (false)/'
mutate "a repeated axis is no longer rejected"                    $H 's/if (std::find(seen.begin(), seen.end(), a) != seen.end()) throw/if (false) throw/'
mutate "an out-of-range axis is no longer rejected"               $H 's/if (a < 0 || a >= (int)T.shape.size()) throw/if (false) throw/'
mutate "the Mountain Goat gemm adds the product twice"            $G 's/= a @ b$/= a @ b + a @ b/'
mutate "the Mountain Goat gemm multiplies by the transpose"       $G 's/= a @ b$/= a @ transpose(b)/'
echo "restored: $(cmp -s $H $W/tensor.orig && cmp -s $G $W/contract.orig && echo 'all files are back to their originals' || echo 'RESTORE FAILED')"
