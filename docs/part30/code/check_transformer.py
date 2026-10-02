#!/usr/bin/env python3
"""Checks the Mountain Goat transformer against an independent Python implementation, and checks properties a correct transformer must have
whatever its weights are. mgc prints six significant digits, so numbers are compared with a relative tolerance of 1e-5.

  1. every stage (embeddings, block 1, block 2, next-token probabilities) equals the reference, for several weight sets and token sequences;
  2. every row of probabilities is positive and sums to 1;
  3. CAUSALITY: with the causal mask, changing token j changes nothing in rows 0..j-1 (the printed numbers are identical) and does change row j;
     without the mask, changing the last token DOES change row 0 (so the mask is what makes the first property true);
  4. PERMUTATION EQUIVARIANCE: without positions and without the mask, permuting the input tokens permutes the output rows the same way;
  5. STRESS: with weights scaled up until the attention scores are in the hundreds and the vocabulary scores in the thousands, the output has no
     nan or inf and still equals the reference (a naive softmax would overflow);
  6. LAYER NORM: with scale 1 and shift 0 every row has mean 0 and variance 1 (to the epsilon), and a constant row becomes exactly 0.
Usage: check_transformer.py [path-to-mgc]      Exit status 0 only if every check passes.
"""
import sys, itertools, math
import transformer_lib as T
mgc = sys.argv[1] if len(sys.argv) > 1 else None
failures = 0
def report(ok, name, detail=""):
    global failures
    failures += not ok
    print(f"  {'ok  ' if ok else 'FAIL'} {name}" + ("" if ok else f"\n       {detail}"))
def run(w, toks, **kw):
    prints = kw.pop("prints", ("embedded", "block1", "block2", "probs"))
    got, text = T.run_mg(T.program(w, toks, prints=prints, **kw), mgc)
    return dict(zip(prints, got)), text

print("-- every stage against the reference; probabilities positive and summing to 1")
for seed, toks in [(1, [1, 3, 0, 2]), (2, [4, 4, 4, 4]), (3, [0, 1, 2, 3]), (7, [2, 0, 4, 1])]:
    w = T.make_weights(seed); got, _ = run(w, toks); ref = T.forward_ref(w, toks)
    for stage in ("embedded", "block1", "block2", "probs"):
        report(T.close(got[stage], ref[stage]), f"weights {seed}, tokens {toks}: {stage} equals the reference", f"got {got[stage][0]} want {ref[stage][0]}")
    p = got["probs"]
    report(all(abs(sum(r) - 1) < 1e-5 and min(r) > 0 for r in p), f"weights {seed}, tokens {toks}: each probability row is positive and sums to 1", str([sum(r) for r in p]))

print("-- stress: large weights make attention scores in the hundreds and vocabulary scores in the thousands, where a naive softmax gives nan")
w = T.make_weights(5)
for key in list(w):
    if key.startswith(("wq", "wk")): w[key] = [[round(v * 150, 2) for v in row] for row in w[key]]
w["wout"] = [[round(v * 800, 2) for v in row] for row in w["wout"]]
toks = [2, 4, 1, 3]; got, text = run(w, toks); ref = T.forward_ref(w, toks)
report("nan" not in text and "inf" not in text, "large weights: no nan and no inf anywhere in the output", "found nan or inf")
for stage in ("block1", "block2", "probs"):
    report(T.close(got[stage], ref[stage]), f"large weights: {stage} equals the reference", f"got {got[stage][0]} want {ref[stage][0]}")

print("-- causality: the causal mask stops position i from seeing positions after it")
w = T.make_weights(1); base = [1, 3, 0, 2]
ref_got, _ = run(w, base)
for j in (3, 2, 1):
    changed = list(base); changed[j] = (changed[j] + 1) % T.V
    got, _ = run(w, changed)
    same_before = all(got[s][i] == ref_got[s][i] for s in ("block1", "block2", "probs") for i in range(j))
    differs_at = any(got["probs"][j][c] != ref_got["probs"][j][c] for c in range(T.V))
    report(same_before, f"changing token {j}: rows 0..{j - 1} of block 1, block 2 and the probabilities are identical", "an earlier row changed")
    report(differs_at, f"changing token {j}: row {j} of the probabilities does change", "row did not change: the model ignores its input?")
got0, _ = run(w, base, mask=T.ZERO_MASK); changed = list(base); changed[3] = (changed[3] + 1) % T.V; got1, _ = run(w, changed, mask=T.ZERO_MASK)
report(any(got1["probs"][0][c] != got0["probs"][0][c] for c in range(T.V)), "without the mask, changing the last token DOES change row 0 (the mask is what blocks the future)", "row 0 did not change")

print("-- permutation equivariance (no positions, no mask): permuting the tokens permutes the output rows")
w = T.make_weights(4); toks = [3, 1, 4, 0]
base, _ = run(w, toks, mask=T.ZERO_MASK, use_positions=False)
for perm in [(1, 0, 2, 3), (3, 2, 1, 0), (2, 3, 0, 1)]:
    got, _ = run(w, [toks[p] for p in perm], mask=T.ZERO_MASK, use_positions=False)
    ok = all(T.close(got[s], [base[s][p] for p in perm]) for s in ("block1", "block2", "probs"))
    report(ok, f"order {perm}: outputs are the original outputs in that order", "outputs differ")
got, _ = run(w, [toks[p] for p in (1, 0, 2, 3)], mask=T.ZERO_MASK, use_positions=True); base_pos, _ = run(w, toks, mask=T.ZERO_MASK, use_positions=True)
report(not T.close(got["probs"], [base_pos["probs"][p] for p in (1, 0, 2, 3)]), "with positions added, the same permutation is NOT a permutation of the outputs (positions break the symmetry)", "outputs were permuted anyway")

print("-- layer norm: mean 0, variance 1, constant rows become 0")
rng = T.lcg(9)
for trial in range(3):
    x = T.mat(rng, 4, 4, -5, 5); x[3] = [2.5, 2.5, 2.5, 2.5]
    src = T.DEFS + f"print layer_norm({T.lit(x)}, [[1, 1, 1, 1]], [[0, 0, 0, 0]])\n"
    (got,), _ = T.run_mg(src, mgc)
    means_ok = all(abs(sum(r) / 4) < 1e-5 for r in got[:3]); vars_ok = all(abs(sum(v * v for v in r) / 4 - 1) < 1e-3 for r in got[:3])
    report(means_ok and vars_ok, f"random 4x4 #{trial + 1}: rows have mean 0 and variance 1", str(got[:3]))
    report(all(v == 0 for v in got[3]), f"random 4x4 #{trial + 1}: the constant row becomes exactly 0", str(got[3]))
print("all checks pass" if failures == 0 else f"{failures} CHECK(S) FAILED")
sys.exit(1 if failures else 0)
