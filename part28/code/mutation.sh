#!/bin/sh
# READ THIS FIRST: this script breaks the Chapter 28 code on purpose, one way at a time, and re-runs the Chapter 28 tests (test/contraction28).
#   "caught by ..." (a test failed) is the EXPECTED, wanted result: it shows the tests can notice that mistake.
#   "NOT CAUGHT" would be a test gap. Part 1 edits the front end (mgfront.py) in place; part 2 rebuilds mg-opt with one bug injected into the
#   dialect or the lowering (a full rebuild each, in work/mut/N). Every edited file is restored afterwards. Output: mutation_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); LIT=$HERE/../../part15/code/run_lit.sh; W=$HERE/work/mut; rm -rf $W; mkdir -p $W
FILTER=':: contraction28/'
echo "NOTE: this script deliberately breaks the compiler code. 'caught' lines are EXPECTED: they show the tests can detect the mistake."
F=$HERE/mgfront.py; cp $F $W/mgfront.orig
restore() { cp $W/mgfront.orig $F; }
trap restore EXIT
fails_of() { grep '^FAIL' | sed 's/.*:: //; s/ (.*//' | tr '\n' ' '; }
out=$(MG_TEST_TMP=$W/out sh $LIT --filter "$FILTER" 2>&1); echo "baseline (nothing broken): $(echo "$out" | grep -q '^FAIL' && echo 'UNEXPECTED FAILURE' || echo 'tests pass (expected)')"
echo; echo "== Part 1: the front end (contract desugaring and its checks)"
fe() {  # label sed-expr
  restore; sed -i "$2" $F
  if cmp -s $F $W/mgfront.orig; then echo "$1: MUTATION DID NOT APPLY"; return; fi
  f=$(MG_TEST_TMP=$W/out sh $LIT --filter "$FILTER" 2>&1 | fails_of)
  if [ -n "$f" ]; then echo "$1: caught by $f"; else echo "$1: NOT CAUGHT (a test gap)"; fi
  restore
}
fe "A is permuted contracted-axes-first (free and contracted swapped)"   's/self.permute_by(a, sa, fa + ia)/self.permute_by(a, sa, ia + fa)/'
fe "B is permuted free-axes-first (free and contracted swapped)"         's/self.permute_by(b, sb, ib + fb)/self.permute_by(b, sb, fb + ib)/'
fe "B's contracted axes taken in increasing order, not as paired"        's/self.permute_by(b, sb, ib + fb)/self.permute_by(b, sb, sorted(ib) + fb)/'
fe "the output lists B's free axes before A's"                           's/out = tuple(sa\[d\] for d in fa) + tuple(sb\[d\] for d in fb)/out = tuple(sb[d] for d in fb) + tuple(sa[d] for d in fa)/'
fe "the size check of a contracted pair is removed"                      's/if sa\[x\] != sb\[y\]:/if False:/'
fe "a repeated axis is no longer rejected"                               's/if ax in axes\[:k\]:/if False:/'
fe "an out-of-range axis is no longer rejected"                          's/if ax >= len(s):/if False:/'
fe "the equal-length check of the two axis lists is removed"             's/if len(ia) != len(ib):/if False:/'
fe "the reshape element-count check is removed (the dialect verifier is the last line of defence)" 's/if n_in != n_out:/if False:/'
fe "the permutation check is removed (the dialect verifier is the last line of defence)" 's/if sorted(perm) != list(range(len(s))):/if False:/'
fe "arithmetic on a rank 3 value is no longer rejected by the front end" 's/if len(s) != 2:$/if False:/'
fe "a dot product is not turned into a 1x1 matrix"                       's/if not out: return r, (1, 1) /if not out: return self.reshape_to(r, (m, n), ()) /'
fe "an unneeded permute is emitted (identity permutation not skipped)"   's/if list(perm) == list(range(len(s))): return v, s/pass/'
fe "an unneeded reshape is emitted (same shape not skipped)"             's/if tuple(dims) == tuple(s): return v, s/pass/'
fe "a '?' dimension is accepted by reshape and contract"                 's/if None in s: raise MgError(self.line, f"{name} needs a static shape/if False: raise MgError(self.line, f"{name} needs a static shape/'
restore

echo; echo "== Part 2: the dialect verifiers and the lowering (a full rebuild per mutation)"
n=0
try() {  # label file sed-expr
  n=$((n+1)); d=$W/$n; mkdir -p $d/build; cp -r $HERE/tree $d/tree; rm -rf $d/tree/build
  tgt=$d/tree/lib/$2; cp $tgt $d/before; sed -i "$3" $tgt
  if cmp -s $d/before $tgt; then echo "$1: MUTATION DID NOT APPLY"; return; fi
  ( cd $d/build && cmake $d/tree -DMLIR_DIR=/usr/lib/llvm-18/lib/cmake/mlir -DLLVM_DIR=/usr/lib/llvm-18/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=OFF >/dev/null 2>&1 && mkdir -p include/mg && make -j8 >/dev/null 2>&1 )
  [ -x $d/build/mg-opt ] || { echo "$1: BUILD FAILED"; return; }
  f=$(MG_OPT=$d/build/mg-opt MG_TEST_TMP=$d/out sh $LIT --filter "$FILTER" 2>&1 | fails_of)
  if [ -n "$f" ]; then echo "$1: caught by $f"; else echo "$1: NOT CAUGHT (a test gap)"; fi
}
try "permute reads through the INVERSE permutation"              LowerToAffine.cpp 's/for (size_t k = 0; k < perm.size(); ++k) inIdx\[perm\[k\]\] = ivs\[k\];/for (size_t k = 0; k < perm.size(); ++k) inIdx[k] = ivs[perm[k]];/'
try "permute does not reorder at all (copies as is)"             LowerToAffine.cpp 's/inIdx\[perm\[k\]\] = ivs\[k\];/inIdx[k] = ivs[k];/'
try "reshape view uses the wrong strides (scaled by the wrong dimension)" LowerToAffine.cpp 's/strides\[i\] = strides\[i + 1\] \* shape\[i + 1\];/strides[i] = strides[i + 1] * shape[i];/'
try "the reshape element-count check is removed from the verifier" MgDialect.cpp 's/if (in.getNumElements() != out.getNumElements())/if (false)/'
try "the permute duplicate-axis check is removed from the verifier" MgDialect.cpp 's/if (p < 0 || p >= in.getRank() || seen\[p\])/if (p < 0 || p >= in.getRank())/'
try "the permute result-shape check is removed from the verifier"   MgDialect.cpp 's/if (out.getDimSize(i) != in.getDimSize(perm\[i\]))/if (false)/'
restore
echo; echo "restored: $(cmp -s $F $W/mgfront.orig && echo 'mgfront.py is back to its original' || echo 'RESTORE FAILED')"
