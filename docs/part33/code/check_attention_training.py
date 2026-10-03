#!/usr/bin/env python3
"""Checks the Mountain Goat attention classifier, its hand-derived backward pass and its training run against an independent Python implementation (per-
example loops, gradient derived token by token) and against facts that must hold. mgc prints six significant digits, so numbers are compared with a
relative tolerance of about 1e-5.

  1. THE GRADIENT (three random starting weights): all four gradients equal the reference's, and the gradient of every one of the 48 weights agrees with a
     finite-difference estimate of the loss (nudge the weight by 0.01 up and down);
  2. TRAINING: the loss and the number of correct sequences at all eight checkpoints, the final weights, each token's attention score and the attention
     weights of the 24 training sequences equal the reference's;
  3. LEARNING: the loss falls at every checkpoint to below 0.001, all 24 training sequences and all 40 held-out sequences are classified correctly;
  4. EVERY SEQUENCE: all 625 possible sequences, 25 at a time: the number correct in each chunk equals the reference's; 624 of 625 are right and the one
     wrong one is 4 4 4 4, whose label (token 4) never occurs among the 64 training and held-out sequences;
  5. ATTENTION: every attention row sums to 1, and every token's attention score is in the order the hidden priority rule gives, except the last two tokens
     of the list (found, not assumed).
Usage: check_attention_training.py [path-to-mgc]      Exit status 0 only if every check passes.
"""
import sys
import attn_lib as A
mgc = sys.argv[1] if len(sys.argv) > 1 else None
failures = 0
def report(ok, name, detail=""):
    global failures
    failures += not ok
    print(f"  {'ok  ' if ok else 'FAIL'} {name}" + ("" if ok else f"\n       {detail}"))
def rel_close(a, b, tol=2e-5, floor=1e-9): return len(a) == len(b) and all(abs(x - y) <= tol * abs(y) + floor for r, q in zip(a, b) for x, y in zip(r, q))

print("-- the hand-derived backward pass against the independent per-token gradient, and against finite differences")
for seed in (1, 2, 3):
    p = A.init_params(seed); out, _ = A.run_mg(A.gradient_program(p), mgc); L, g, _ = A.loss_and_gradient(p, A.TRAIN)
    grads = dict(zip(A.ORDER, out[:4])); loss_mg = out[4][0][0]; evals = out[5:]
    report(abs(loss_mg - L) <= 1e-5 * max(1, L) and all(rel_close(grads[k], g[k], floor=1e-8) for k in A.ORDER), f"starting weights #{seed}: the loss and all four gradients equal the reference", str({k: (grads[k][0], g[k][0]) for k in A.ORDER}))
    worst, it = 0.0, iter(evals)
    for key in A.ORDER:
        for i in range(len(p[key])):
            for j in range(len(p[key][0])):
                plus, minus = next(it)[0][0], next(it)[0][0]; worst = max(worst, abs((plus - minus) / 0.02 - grads[key][i][j]))
    report(worst < 2e-3, f"starting weights #{seed}: all 48 gradient entries agree with finite differences (largest difference {worst:.1e})", f"{worst}")

print("-- training against the independent Python trainer")
out, text = A.run_mg(A.train_program(), mgc); p_ref, hist = A.train_ref()
n = len(A.CHECKPOINTS)
cp = [(out[2 * i][0][0], out[2 * i + 1][0][0]) for i in range(n)]
for k, (lo, co) in zip(A.CHECKPOINTS, cp): report(abs(lo - hist[k][0]) <= 1e-5 * max(1, hist[k][0]) and co == hist[k][1], f"step {k}: loss {hist[k][0]:.6f} and {hist[k][1]} of 24 correct equal the reference", f"got {lo}, {co}")
q, wk, wv, wo, scores, attn = out[2 * n:2 * n + 6]; test_loss, test_correct = out[2 * n + 6][0][0], out[2 * n + 7][0][0]
report(all(A.close(got, p_ref[k], 1e-5) for k, got in zip(A.ORDER, (q, wk, wv, wo))), "the final weights equal the reference", f"{q} vs {p_ref['q']}")
report(rel_close([[v] for v in [r[0] for r in scores]], [[v] for v in A.token_scores_ref(p_ref)], floor=1e-6), "each token's attention score equals the reference", str(scores))
report(rel_close(attn, [A.attention_ref(p_ref, s) for s in A.TRAIN], floor=1e-7), "the attention weights on the 24 training sequences equal the reference", str(attn[0]))
report(all(abs(sum(r) - 1) < 1e-5 for r in attn), "every row of attention weights sums to 1", str([sum(r) for r in attn][:4]))

print("-- learning")
losses = [lo for lo, _ in cp]
report(all(a > b for a, b in zip(losses, losses[1:])), "the loss falls at every checkpoint", str(losses))
report(losses[0] > 1.4 and losses[-1] < 1e-3, f"from {losses[0]:.4f} (about log 5 = 1.609) to {losses[-1]:.6f}", str(losses))
report(cp[-1][1] == 24, "all 24 training sequences are classified correctly", str(cp[-1]))
report(test_correct == 40 and test_loss < 0.01, f"all 40 held-out sequences are classified correctly (loss {test_loss:.6f})", f"{test_correct}, {test_loss}")

print("-- every one of the 625 possible sequences")
chunks = [int(o[0][0]) for o in out[2 * n + 8:2 * n + 8 + len(A.CHUNKS)]]; last_logits = out[-1]
want = [sum(1 for s in c if max(range(A.C), key=lambda k: A.forward(p_ref, s)[5][k]) == A.label(s)) for c in A.CHUNKS]
report(chunks == want, "the number correct in each of the 25 chunks of 25 equals the reference's", f"{chunks} vs {want}")
report(sum(chunks) == 624, f"624 of 625 sequences are classified correctly (got {sum(chunks)})", str(chunks))
wrong = [i for i, c in enumerate(chunks) if c != A.CHUNK]; last_pred = max(range(A.C), key=lambda k: last_logits[-1][k])
report(wrong == [len(A.CHUNKS) - 1] and A.CHUNKS[-1][-1] == [4, 4, 4, 4] and A.label([4, 4, 4, 4]) == 4 and last_pred == 0, f"the one wrong sequence is 4 4 4 4 (label 4, predicted {last_pred}): the last row of the last chunk", f"{wrong} {last_pred}")
seen_labels = {A.label(s) for s in A.TRAIN + A.TEST}
report(4 not in seen_labels, f"label 4 never occurs among the 64 training and held-out sequences (labels seen: {sorted(seen_labels)})", str(seen_labels))

print("-- attention scores")
ranked = sorted(range(A.V), key=lambda t: -scores[t][0])
report(ranked[:3] == A.PRIORITY[:3], f"the three highest-scoring tokens {ranked[:3]} are the three highest in the priority list {A.PRIORITY[:3]}, in order", str(ranked))
report(ranked[3:] == A.PRIORITY[3:][::-1], f"the last two are in the opposite order to the priority rule: scores order {ranked} vs rule {A.PRIORITY} (this model did not learn to rank 0 above 4)", str(ranked))
print("all checks pass" if failures == 0 else f"{failures} CHECK(S) FAILED")
sys.exit(1 if failures else 0)
