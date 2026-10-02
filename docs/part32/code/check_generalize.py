#!/usr/bin/env python3
"""Checks the Chapter 32 programs against an independent Python trainer and against facts that must hold whatever the code looks like. mgc prints six
significant digits, so numbers are compared with a relative tolerance of about 1e-5.

  1. TRAINING: for each weight-decay strength, the training and held-out loss at every checkpoint, and the final weights, probabilities and per-pair
     held-out surprises, equal the Python trainer's;
  2. OVERFITTING: with no weight decay the training loss keeps falling while the held-out loss RISES (from step 5 on) and ends above its starting value;
  3. WHY: the two held-out pairs that never occur in the training pairs carry nearly all of the held-out loss;
  4. WEIGHT DECAY: every positive strength ends with a lower held-out loss than none; a stronger strength gives a higher training loss and smaller weights;
     the best strength found by the Mountain Goat run is the best found by the reference;
  5. THE GRADIENT: the gradient with weight decay matches a finite-difference estimate of the penalised objective (step 0.01);
  6. GREEDY GENERATION: from every starting token the 8 generated tokens equal the reference's most-likely-token chain, and a tie (token 4's row is
     uniform) produces several 1s, as documented.
Usage: check_generalize.py [path-to-mgc]      Exit status 0 only if every check passes.
"""
import sys, random
import generalize_lib as G
mgc = sys.argv[1] if len(sys.argv) > 1 else None
failures = 0
def report(ok, name, detail=""):
    global failures
    failures += not ok
    print(f"  {'ok  ' if ok else 'FAIL'} {name}" + ("" if ok else f"\n       {detail}"))
def rel_close(a, b, tol=2e-5, floor=1e-9): return all(abs(x - y) <= tol * abs(y) + floor for r, q in zip(a, b) for x, y in zip(r, q))
n = len(G.CHECKPOINTS)

print("-- training and held-out loss against the independent Python trainer, for each weight-decay strength")
runs = {}
for lam in G.LAMBDAS:
    got, _ = G.run_mg(G.train_program(lam), mgc)
    w_ref, hist = G.train_ref(lam)
    tl = [got[2 * i][0][0] for i in range(n)]; hl = [got[2 * i + 1][0][0] for i in range(n)]; w_mg, surprise, probs = got[2 * n:2 * n + 3]
    runs[lam] = dict(train=tl, held=hl, w=w_mg, surprise=[r[0] for r in surprise], hist=hist, w_ref=w_ref)
    ok_loss = all(abs(a - hist[k][0]) <= 1e-5 * max(1, hist[k][0]) and abs(b - hist[k][1]) <= 1e-5 * max(1, hist[k][1]) for k, a, b in zip(G.CHECKPOINTS, tl, hl))
    report(ok_loss, f"strength {lam}: training and held-out loss at all {n} checkpoints equal the reference", f"train {tl} held {hl}")
    report(G.close(w_mg, w_ref) and G.close(probs, G.probabilities_ref(w_ref)), f"strength {lam}: final weights and probabilities equal the reference", f"got {w_mg[0]} want {w_ref[0]}")
    report(all(abs(a - b) <= 1e-5 * max(1, b) for a, b in zip(runs[lam]["surprise"], G.surprise_ref(w_ref, G.HELD))), f"strength {lam}: held-out surprise of each pair equals the reference", str(runs[lam]["surprise"]))

print("-- a strength that is too large for the learning rate")
got, _ = G.run_mg(G.train_program(G.UNSTABLE), mgc); w_ref, hist = G.train_ref(G.UNSTABLE)
tl = [got[2 * i][0][0] for i in range(n)]; hl = [got[2 * i + 1][0][0] for i in range(n)]
report(all(abs(a - hist[k][0]) <= 1e-5 * max(1, hist[k][0]) and abs(b - hist[k][1]) <= 1e-5 * max(1, hist[k][1]) for k, a, b in zip(G.CHECKPOINTS, tl, hl)), f"strength {G.UNSTABLE}: the program and the reference blow up in exactly the same way (losses equal at every checkpoint)", f"{tl} vs {[hist[k][0] for k in G.CHECKPOINTS]}")
report(tl[-1] > 1e10 and all(a < b for a, b in zip(tl[3:], tl[4:])), f"the loss grows without bound ({tl[-1]:.3g} after 400 steps): learning rate x strength = {G.LR * G.UNSTABLE} is above 2, so each step overshoots by a factor of {abs(1 - G.LR * G.UNSTABLE)}", str(tl))

print("-- overfitting without weight decay")
r0 = runs[0]; i5 = G.CHECKPOINTS.index(5)
report(all(a > b for a, b in zip(r0["train"], r0["train"][1:])), "training loss falls at every checkpoint", str(r0["train"]))
report(all(a < b for a, b in zip(r0["held"][i5:], r0["held"][i5 + 1:])), "held-out loss RISES at every checkpoint from step 5 on", str(r0["held"]))
report(r0["held"][-1] > r0["held"][0] + 1, f"and ends well above its starting value ({r0['held'][0]:.4f} to {r0['held'][-1]:.4f})", str(r0["held"]))

print("-- why: the held-out pairs the training pairs never showed")
seen = {(a, b) for a, b in G.TRAIN}
unseen = [i for i, p in enumerate(G.HELD) if p not in seen]; seen_idx = [i for i in range(len(G.HELD)) if i not in unseen]
s = r0["surprise"]
report(len(unseen) == 2, f"held-out pairs {[G.HELD[i] for i in unseen]} never occur in the training pairs", str(unseen))
report(all(s[i] > 4 for i in unseen) and all(s[i] < 1.5 for i in seen_idx), f"their surprises {[round(s[i], 2) for i in unseen]} are above 4; the others {[round(s[i], 2) for i in seen_idx]} are below 1.5", str(s))
report(sum(s[i] for i in unseen) / sum(s) > 0.9, "the unseen pairs carry more than 90% of the held-out loss", str(s))

print("-- weight decay")
base = r0["held"][-1]
for lam in G.LAMBDAS[1:]: report(runs[lam]["held"][-1] < base, f"strength {lam}: held-out loss {runs[lam]['held'][-1]:.4f} is below the {base:.4f} of no weight decay", str(runs[lam]["held"]))
report(all(runs[a]["train"][-1] < runs[b]["train"][-1] for a, b in zip(G.LAMBDAS, G.LAMBDAS[1:])), "a stronger strength gives a higher final training loss (the price of the penalty)", str([runs[l]["train"][-1] for l in G.LAMBDAS]))
mx = {l: max(abs(v) for row in runs[l]["w"] for v in row) for l in G.LAMBDAS}
report(all(mx[a] > mx[b] for a, b in zip(G.LAMBDAS, G.LAMBDAS[1:])), "a stronger strength gives smaller weights", str(mx))
best_mg = min(G.LAMBDAS, key=lambda l: runs[l]["held"][-1]); best_ref = min(G.LAMBDAS, key=lambda l: runs[l]["hist"][400][1])
report(best_mg == best_ref, f"the strength with the lowest held-out loss is {best_mg} for both", f"{best_mg} vs {best_ref}")

print("-- the gradient with weight decay against finite differences of the penalised objective (step 0.01)")
for lam in (0.01, 0.1):
    for seed in (1, 2):
        random.seed(seed); w = [[round(random.uniform(-1, 1), 1) for _ in range(G.V)] for _ in range(G.V)]
        out, _ = G.run_mg(G.objective_check_program(w, lam), mgc)
        analytic, pairs = out[0], out[2:]
        numeric = [[(pairs[2 * (i * G.V + j)][0][0] - pairs[2 * (i * G.V + j) + 1][0][0]) / 0.02 for j in range(G.V)] for i in range(G.V)]
        worst = max(abs(analytic[i][j] - numeric[i][j]) for i in range(G.V) for j in range(G.V))
        report(worst < 2e-3 and rel_close(analytic, G.gradient_ref(w, G.TRAIN, lam), floor=1e-8) and abs(out[1][0][0] - G.objective_ref(w, lam)) < 1e-5, f"strength {lam}, random weights #{seed}: gradient equals the reference and the finite-difference estimate (largest difference {worst:.1e})", f"{analytic[0]} vs {numeric[0]}")

print("-- greedy generation")
w_ref, _ = G.train_ref(0.1)
for start in range(4):
    out, _ = G.run_mg(G.generate_program(0.1, start=start), mgc)
    ids = [int(round(t[0][0])) for t in out[1:]]
    report(ids == G.greedy_ref(w_ref, start, 8), f"starting from token {start}: {ids} equals the reference chain", f"want {G.greedy_ref(w_ref, start, 8)}")
out, _ = G.run_mg(G.generate_program(0.1, start=4, n=2), mgc)
ids = [t[0][0] for t in out[1:]]
psum = [sum(r[j] for r in G.probabilities_ref(w_ref)) for j in range(G.V)]
report(ids == [4.0, 10.0, float(max(range(G.V), key=lambda j: psum[j]))], f"starting from token 4 (its row is uniform): every token ties, the mask is all ones (x @ ids = 0+1+2+3+4 = 10), and the next step takes the largest column sum of the probabilities (token {max(range(G.V), key=lambda j: psum[j])})", str(ids))
print("all checks pass" if failures == 0 else f"{failures} CHECK(S) FAILED")
sys.exit(1 if failures else 0)
