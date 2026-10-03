#!/usr/bin/env python3
"""Checks the Chapter 34 programs against an independent Python implementation (per-example loops, gradients derived element by element) and against facts
that must hold. mgc prints six significant digits, so numbers are compared with a relative tolerance of about 1e-5.

  1. THE GRADIENTS of model A and of model B (three random starting weights each): every gradient equals the reference's, and the gradient of every single
     weight (36 for A, 120 for B) agrees with a finite-difference estimate of the loss (nudge the weight by 0.001 up and down);
  2. TRAINING of both models: loss and number correct at all eight checkpoints, the held-out loss and count, and the number correct in each chunk of 27 of all
     81 possible sequences, equal the reference's;
  3. THE EXPERIMENT: model A cannot even fit its 54 training sequences and gets at most 70 of the 81 right; model B fits all 54, and gets 80 of 81 right; the
     one it misses is 0 0 0 0, which is not among the 54 training sequences;
  4. THE UNSEEN CASE: the model-B scores for 0 0 0 0 are read from the program and give the wrong label.
Usage: check_ffn.py [path-to-mgc]      Exit status 0 only if every check passes.
"""
import sys
import ffn_lib as F
mgc = sys.argv[1] if len(sys.argv) > 1 else None
failures = 0
def report(ok, name, detail=""):
    global failures
    failures += not ok
    print(f"  {'ok  ' if ok else 'FAIL'} {name}" + ("" if ok else f"\n       {detail}"))
def rel_close(a, b, tol=2e-5, floor=1e-8): return len(a) == len(b) and all(abs(x - y) <= tol * abs(y) + floor for r, q in zip(a, b) for x, y in zip(r, q))

print("-- the hand-derived backward passes against the independent per-example gradient, and against finite differences")
for model in ("A", "B"):
    order = F.ORDER[model]
    for seed in (1, 2, 3):
        p = F.init_params(model, seed); out, _ = F.run_mg(F.gradient_program(model, p), mgc); L, g, _ = F.loss_and_gradient(model, p, F.TRAIN)
        grads = dict(zip(order, out[:len(order)])); loss_mg = out[len(order)][0][0]; it = iter(out[len(order) + 1:]); worst = 0.0; count = 0
        for key in order:
            for i in range(len(p[key])):
                for j in range(len(p[key][0])):
                    plus, minus = next(it)[0][0], next(it)[0][0]; worst = max(worst, abs((plus - minus) / 0.002 - grads[key][i][j])); count += 1
        report(abs(loss_mg - L) <= 1e-5 * max(1, L) and all(rel_close(grads[k], g[k]) for k in order), f"model {model}, starting weights #{seed}: the loss and all {len(order)} gradients equal the reference", str({k: (grads[k][0], g[k][0]) for k in order}))
        report(worst < 1e-3, f"model {model}, starting weights #{seed}: all {count} weights agree with finite differences (largest difference {worst:.1e})", str(worst))

results = {}
for model in ("A", "B"):
    print(f"-- training model {model} against the independent Python trainer")
    out, text = F.run_mg(F.train_program(model), mgc); p_ref, hist = F.train_ref(model); n = len(F.CHECKPOINTS)
    cp = [(out[2 * i][0][0], int(out[2 * i + 1][0][0])) for i in range(n)]
    for k, (lo, co) in zip(F.CHECKPOINTS, cp): report(abs(lo - hist[k][0]) <= 1e-5 * max(1, hist[k][0]) and co == hist[k][1], f"model {model}, step {k}: loss {hist[k][0]:.6f} and {hist[k][1]} of 54 correct equal the reference", f"got {lo}, {co}")
    test_loss, test_correct = out[2 * n][0][0], int(out[2 * n + 1][0][0]); chunks = [int(o[0][0]) for o in out[2 * n + 2:2 * n + 2 + len(F.CHUNKS)]]; first_logits = out[-1]
    want_test = sum(F.predict_correct(model, p_ref, s) for s in F.TEST); want_chunks = [sum(F.predict_correct(model, p_ref, s) for s in c) for c in F.CHUNKS]
    L_test = F.loss_and_gradient(model, p_ref, F.TEST)[0]
    report(test_correct == want_test and abs(test_loss - L_test) <= 1e-5 * max(1, L_test), f"model {model}: the 27 held-out sequences: {test_correct} correct and loss {test_loss:.6f} equal the reference", f"{test_correct} vs {want_test}, {test_loss} vs {L_test}")
    report(chunks == want_chunks, f"model {model}: the number correct in each of the three chunks of 27 of all 81 sequences, {chunks}, equals the reference's", f"{chunks} vs {want_chunks}")
    results[model] = dict(cp=cp, total=sum(chunks), test=test_correct, logits=first_logits, p=p_ref)

print("-- the experiment: does the feed-forward block matter?")
A, B = results["A"], results["B"]
report(A["cp"][-1][1] < 54 and A["cp"][-1][0] > 0.3, f"model A cannot fit its own training data: {A['cp'][-1][1]} of 54 right, loss {A['cp'][-1][0]:.3f} after {F.STEPS} steps", str(A["cp"][-1]))
report(A["total"] <= 70, f"model A gets only {A['total']} of the 81 possible sequences right", str(A["total"]))
report(B["cp"][-1][1] == 54 and B["cp"][-1][0] < 1e-3, f"model B fits all 54 training sequences (loss {B['cp'][-1][0]:.6f})", str(B["cp"][-1]))
report(B["total"] == 80 and B["total"] - A["total"] >= 10, f"model B gets {B['total']} of 81 right, {B['total'] - A['total']} more than model A", f"{B['total']} vs {A['total']}")
miss = [s for s in F.EVERY if not F.predict_correct("B", B["p"], s)]
report(miss == [[0, 0, 0, 0]] and [0, 0, 0, 0] not in F.TRAIN, f"the one sequence model B gets wrong is 0 0 0 0, which is not among the training sequences (misses: {miss})", str(miss))
lg = B["logits"][0]; pred = max(range(F.C), key=lambda i: lg[i])
report(F.label([0, 0, 0, 0]) == 0 and pred == 1, f"in the program, the first row of the first chunk (0 0 0 0) scores {lg} and so is classified as {pred}; its label is 0", str(lg))
print("all checks pass" if failures == 0 else f"{failures} CHECK(S) FAILED")
sys.exit(1 if failures else 0)
