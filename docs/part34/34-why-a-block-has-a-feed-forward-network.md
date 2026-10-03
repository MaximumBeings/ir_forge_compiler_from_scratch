# 34. Why a Block Has a Feed-Forward Network: Backpropagation Through Layer Normalization, ReLU and Residuals

<p style="text-align:center"><img src="../assets/goats/ch-34.svg" alt="Mountain goats on the mountain at night" style="max-width:100%;height:auto;border-radius:6px"></p>

**What you will understand:** why a transformer block does not stop at attention. A model made of attention alone fails at a small, clean task; the same model with a **feed-forward network**, a **layer normalization** and a **residual connection** added learns it. Getting there means deriving, by hand, the backward pass through three more pieces: the layer normalization (the hardest formula so far), the ReLU (including what to do at its corner) and the residual connection (where two gradient paths meet). Every piece is a Mountain Goat function, every formula is checked against an independent Python calculation and against finite differences of the loss **for every one of the 120 weights**, and the two models are then compared on **all 81 possible inputs**.

**What you need to know first:** Chapter 33 (the attention classifier and its backward pass; this chapter reuses it unchanged for the attention part), Chapter 30 (what layer normalization and the feed-forward network are) and Chapter 31 (cross-entropy). **No new compiler operation** is needed: the programs run on Chapter 32's compiler.

!!! tip "Compile and run"
    ```sh
    cd docs/part32/code && ./build.sh                 # once: the newest compiler (this chapter adds nothing to it)
    cd ../../part34/code
    python3 make_examples.py                          # (re)writes the examples from ffn_lib.py
    ../../part32/code/mgc run examples/04_train_with_ffn.mg   # train model B for 600 steps (about 100 seconds: the program is 6,000 lines)
    ./run_examples.sh > examples_out.txt              # every example and every error example on this page
    ./check_ffn.py                                    # both backward passes and both training runs against the independent Python version (about 2 minutes)
    ./lr_sweep.py > lr_sweep_out.txt                  # Python only: how reliable is the training? (about 5 minutes)
    ./model_mutation.py > model_mutation_out.txt      # runs 10 WRONG backward passes through the checker (about 25 minutes)
    cd ../../part15/code && ./run_lit.sh              # the whole test suite
    ```
    Every listing and output on this page comes from these commands.

!!! note "Why this page shows FAIL lines and error messages, and why that is good"
    The three error examples are programs the compiler must reject (each ends `exit status 1`). The mutation output is a negative control: deliberately wrong backward passes run against the checker, where "caught" is the wanted result and "NOT CAUGHT" would be a gap. Model A's failure to learn the task is the **result of the experiment**, not a bug.

## The task: exactly one of two tokens

A sequence is four tokens, each 0, 1 or 2. The **label** is 1 if **exactly one** of the tokens 1 and 2 appears, and 0 otherwise (neither, or both):

| sequence | label | why |
|---|---|---|
| 0 0 0 0 | 0 | neither 1 nor 2 |
| 1 0 0 0 | 1 | 1 only |
| 2 2 2 2 | 1 | 2 only |
| 1 1 1 1 | 1 | 1 only |
| 1 2 0 0 | 0 | both |
| 2 2 1 0 | 0 | both |

This is **"exclusive or"** (XOR) of "is 1 present" and "is 2 present". Of the 3<sup>4</sup> = **81** possible sequences, 30 have label 1 and 51 have label 0 (so always answering 0 is right 63% of the time). A random 54 of them (20 labelled 1) train the model; the other 27 (10 labelled 1) are held out. As in Chapter 33, the answer does not depend on order, which suits attention.

## Two models

**Model A** is Chapter 33's: attention pools the four tokens into one vector `h` (1×4), and a linear read-out `h @ wo` gives the two class scores. 36 numbers.

**Model B** puts a *block* between the pooling and the read-out, the same arrangement as a transformer block (Chapter 30):

1. `h` = the attention-pooled vector;
2. **layer normalization**: `u = gm * (h − mean(h)) / sigma + bt`, with `sigma = sqrt(variance(h) + 0.00001)`;
3. **feed-forward network**: `f = relu(u @ w1 + b1) @ w2 + b2` (widen from 4 to 8 features, zero the negative ones, narrow back to 4);
4. **residual connection**: `z = h + f`;
5. the read-out `z @ wo`.

120 numbers. Everything is stacked 54 sequences at a time exactly as in Chapter 33 (group matrix, `reshape` for the per-sequence softmax).

**Why would A fail?** Here is an *argument*, not a proof. The pooled vector `h` is a weighted average of the three token value vectors `v0`, `v1`, `v2`, so it lies in the triangle they span. Suppose attention learns to prefer 1 and 2 over 0. Then a sequence with a 1 and no 2 gives a point near `v1`, one with a 2 and no 1 a point near `v2`, one with both a point *between* them on the line from `v1` to `v2`, and one with neither is exactly `v0`. Along the line from `v1` to `v2` the labels run **1, 0, 1**: no linear read-out can say "1 at both ends and 0 in the middle". The feed-forward network adds a bend (the ReLU) that can. The experiments below are consistent with this, and do not prove it.

## The backward pass, new rows

Chapter 33's table gets new rows between the read-out and the pooling. Write `dX` for the gradient of the loss with respect to `X`, `B` for the number of sequences (54), and `ŷ` for the normalized value `(h − mean(h))/sigma`:

| forward step | backward step |
|---|---|
| `logits = z @ wo`, cross-entropy | `dlogits = (softmax(logits) − y) / B`; `dwo = zᵀ @ dlogits`; `dz = dlogits @ woᵀ` |
| `z = h + f` (**residual**) | `dz` goes down **both** paths: straight to `h`, and into `f` |
| `f = relu(pre) @ w2 + b2` | `db2 = col_sum(dz)`; `dw2 = relu(pre)ᵀ @ dz`; `drelu = dz @ w2ᵀ` |
| `relu` | `dpre = drelu * ge(pre, 0)` (**the gradient passes where `pre >= 0`**) |
| `pre = u @ w1 + b1` | `db1 = col_sum(dpre)`; `dw1 = uᵀ @ dpre`; `du = dpre @ w1ᵀ` |
| `u = gm * ŷ + bt` | `dbt = col_sum(du)`; `dgm = col_sum(du * ŷ)`; `dŷ = du * gm` |
| `ŷ = (h − mean(h))/sigma` (**layer norm**) | `dh_ln = (dŷ − mean(dŷ) − ŷ * mean(dŷ * ŷ)) / sigma` (means taken along each row) |
| merge at `h` | `dh = dz + dh_ln` (the **sum** of the residual path and the layer-norm path) |
| attention pooling | exactly Chapter 33: from `dh` to `dwv`, `dq`, `dwk` |

Three of these deserve a closer look.

### Layer normalization

The layer-norm formula has **three** terms, because every entry of `h` affects the mean, the spread `sigma` and therefore *every* normalized value. A small program computes it by the formula and by brute force (nudge each of four numbers by 0.01 up and down):

```text
--8<-- "docs/part34/code/examples_out.txt:1:34"
```

The formula gives `[0.26921, −0.896826, 0.874121, −0.246505]`; the brute-force numbers are `0.26921, −0.896825, 0.87412, −0.246506`. They agree. The last line is the row sum of the gradient, `0`: adding the same amount to every `h` changes nothing (the mean moves with it), so the four gradient entries must cancel. The three terms are each needed: leaving out `mean(dŷ)` or the `ŷ * mean(dŷ * ŷ)` projection breaks that cancellation, and a wrong layer-norm backward is among the mutations tested below.

### ReLU, and its corner

`y = max(0, p)` has derivative 1 where `p` is positive and 0 where it is negative, so the upstream gradient passes where `p >= 0` and is cut elsewhere: `d * ge(p, 0)`, using the comparison of Chapter 32.

```text
--8<-- "docs/part34/code/examples_out.txt:36:59"
```

For `p = [−1.5, 0, 2, 3]` and `d = [1, 2, 3, 4]` the formula gives `[0, 2, 3, 4]`. The brute-force numbers are `0, 1, 3, 4`: they agree except at `p = 0`, **exactly at the corner**, where the brute force gives `1`, half of `2`. At a corner the derivative does not exist; the two sides disagree (0 on the left, 1 on the right) and brute force averages them. Training code must pick a convention. This one passes the gradient at `p = 0` (`ge`, not a strict `>`). It matters little in practice, because an exact zero is rare, and it is why the finite-difference check below uses a small step (see "The finite-difference step").

### The residual connection

`z = h + f` makes `h` influence the loss along two routes: directly through `z`, and through the layer norm and feed-forward network. By the chain rule the gradients along the two routes **add**: `dh = dz + dh_ln`. A wrong backward pass that drops the direct route is among the mutations below.

## The definitions

The whole model B as functions: the forward pass, then one function per gradient (the attention-pooling part is Chapter 33's, with a different vocabulary size):

```text
--8<-- "docs/part34/code/attention_ffn.mg.defs"
```

## The experiment

`examples/03_train_attention_only.mg` trains model A and `examples/04_train_with_ffn.mg` trains model B, with the same data, the same learning rate (0.5), 600 steps and seeded starting weights; each prints the loss and the number of correct training sequences at eight checkpoints, then the held-out loss and count, then the number correct in each of three chunks of 27 of **all 81 possible sequences**, then the scores for the first chunk. Model A:

```text
--8<-- "docs/part34/code/examples_out.txt:64:105"
```

Model B:

```text
--8<-- "docs/part34/code/examples_out.txt:139:180"
```

(Read the first sixteen numbers as pairs: loss, then number correct out of 54.)

| after step | 0 | 1 | 10 | 50 | 100 | 200 | 400 | 600 |
|---|---|---|---|---|---|---|---|---|
| A: loss | 0.699 | 0.697 | 0.686 | 0.558 | 0.526 | 0.509 | 0.433 | **0.428** |
| A: correct of 54 | 25 | 25 | 34 | 41 | 34 | 38 | 46 | **46** |
| B: loss | 0.685 | 0.641 | 0.650 | 0.608 | 0.433 | 0.0023 | 0.0005 | **0.0003** |
| B: correct of 54 | 37 | 34 | 34 | 36 | 45 | 54 | 54 | **54** |

- **Model A cannot learn the task.** Its loss flattens at about 0.428 and it classifies 46 of its own 54 training sequences correctly. On the 27 held-out sequences it gets 23, and on all 81 possible sequences **69**.
- **Model B learns it.** Its loss stays above 0.4 for the first hundred steps (0.433 at step 100), then drops sharply to 0.0023 by step 200 and 0.0003 by step 600 (the shape of a model "finding" the trick), and it classifies all 54 training sequences correctly. On the held-out 27 it gets 26, and on all 81 it gets **80**: it beats model A by 11 sequences.

### The one miss

Which sequence does B get wrong? The last numbers of the B output are the scores for the first chunk of 27, whose first row is `0 0 0 0`. Its scores are `[−5.00, 7.62]`: class **1** wins by a wide margin, but the label of `0 0 0 0` is **0** (neither 1 nor 2 appears). It is the *only* error, and `0 0 0 0` is **not among the 54 training sequences** (the random split happened to leave it out): the model has never been shown the case in which neither token appears, and it extrapolates confidently and wrongly. This is the third chapter (after 32 and 33) in which the model's single failure is an input its training data never showed. The checker finds the missing sequence by running the reference over all 81 rather than assuming it.

### How reliable is this? A Python-only sweep

The run above uses one starting-weight set at one learning rate. To see how much that matters, `lr_sweep.py` repeats the experiment in the **plain-Python implementation only** (it does not go through `mgc`; the Python and Mountain Goat versions agree step for step, but this table is the Python one) for six starting-weight seeds at several learning rates:

```text
--8<-- "docs/part34/code/lr_sweep_out.txt"
```

Each cell is (final training loss, sequences correct out of 81):

- **Model A is stuck for every seed** at the learning rate used here: 69 of 81 for five seeds and 52 for the sixth, with a loss near 0.43 or worse.
- **Model B at 0.25 succeeds for all six seeds** (80 of 81). At **0.5** (the rate used in the run above) it succeeds for five of six: **seed 4 gets stuck at the same 69 as model A**. At **1.0** only one of six succeeds, two diverge to infinity and the rest stall; at **2.0** none does.
- So model B's success is real but **not guaranteed**: it depends on the learning rate and the start. The run above uses a seed that works. (It is shown at 0.5 and not at 0.25 because at 0.25 model A has not reached its plateau after 600 steps (a loss of 0.445 for seed 1, against 0.428 at the higher rate), which would make "A cannot fit" a weaker statement; at 0.5 A has plateaued. This comparison of A's two rates was made in plain Python.)

## The finite-difference step: a measured lesson

The first version of the gradient check used a step of 0.01, as in Chapters 31 to 33. For model B it **failed** for two of three starting-weight sets: the largest disagreement between the hand-derived gradient and the estimate was `5.6·10⁻³` and `4.0·10⁻³`, above the tolerance. The hand-derived gradient was not at fault: it equals the independent Python gradient. Computing the same estimate in plain Python with exact (not six-digit) loss values gives **the same `5.6·10⁻³`**, and with a step of 0.001 it gives `10⁻⁶`. So the error is in the *estimate*: a step of 0.01 straddles a ReLU corner or is too coarse for the curvature. A smaller step cannot be too small either, since `mgc` prints the loss to six digits: a step of 0.001 limits the estimate to about `4·10⁻⁴`. The check uses 0.001 and a tolerance of `10⁻³`, and for model B finds a largest disagreement of about `4·10⁻⁴`.

## Mistakes the compiler reports

```text
--8<-- "docs/part34/code/examples_out.txt:211:238"
```

A layer-norm scale of the wrong width, a call with a missing argument, and a residual connection whose two sides have different shapes. As always, the shapes are types.

## Tests

Three new `lit` files in `test/ffn34/` (the suite is now 138 tests; no `verifiers` or `ir` test because no compiler operation was added):

| Test | What it checks |
|---|---|
| `examples` | the two backward-pass examples (worked out above) and both training runs' loss and correct count at every checkpoint, the held-out result and the chunk counts |
| `errors` | the three mistakes give the exact messages |
| `against-reference` | `check_ffn.py`, below (about two minutes) |

`check_ffn.py` compares with an **independent** Python implementation (plain lists; every gradient derived element by element) and checks, in order:

1. **The gradients of both models**, for three starting-weight sets each: the loss and every gradient equal the reference's, and **the gradient of every weight (36 for A, 120 for B) agrees with a finite-difference estimate** (step 0.001).
2. **Training of both models:** loss and correct count at all eight checkpoints, the held-out loss and count, and the three chunk counts equal the reference's.
3. **The experiment:** model A fits fewer than all of its 54 training sequences (loss above 0.3) and gets at most 70 of 81; model B fits all 54 with loss below 0.001, gets 80 of 81 (at least 10 more than A), and the one miss is `0 0 0 0`, which is not a training sequence.
4. **The miss, from the program:** the program's own scores for `0 0 0 0` choose class 1 while the label is 0.

```text
--8<-- "docs/part34/code/check_ffn_out.txt"
```

### Are the checks good enough? Run ten wrong backward passes.

`model_mutation.py` writes ten versions of model B's definitions, each with one mistake (the layer-norm backward missing a term or the division by sigma, the residual path dropped from the gradient, the ReLU mask omitted or reversed, `dgm` and `dw1` computed from the wrong input, a different epsilon, the forward residual removed) and runs the checker on each:

```text
--8<-- "docs/part34/code/model_mutation_out.txt"
```

All ten are caught, and the pattern of *which checks* catch them is informative:

- **Eight of the ten are caught by the finite-difference check** (and by the reference): the layer-norm backward missing a term or the division by sigma, the residual path dropped from the gradient, the ReLU mask omitted or reversed, `grad_gm` and `grad_w1` using the wrong input, and the forward pass with the residual removed (whose backward pass no longer matches it). These are mistakes in the *derivation*, and finite differences use only the loss, so they notice.
- **One is invisible to the finite-difference check by design:** the layer-norm epsilon changed to 0.1 in the forward *and* the backward pass. The program's gradient is then exactly the gradient of the program's own (different) loss, so the finite differences agree with it. It is caught only by the comparison with the reference, which uses the real epsilon, and by the experiment. This is the case where "the gradient matches its own loss" and "the program computes the intended thing" come apart.
- **Several are also caught by "the experiment"** (model B stops fitting its data or stops beating model A): omitting or reversing the ReLU mask and the two wrong-input gradients make training fail, while the layer-norm missing-mean term and the missing residual path still let training reach the same kind of answer more slowly or differently, so only the gradient comparisons notice. Training that still works is not evidence that the gradient is right.

There is no compiler-mutation run for this chapter: no compiler code changed.

The full suite:

```text
--8<-- "docs/part15/code/run_out_138.txt"
```

## Limits and what is not established

- **One small task, one model of each kind.** XOR of presence over three tokens, four positions, 81 inputs. The experiment shows that *this* attention-only model fails and *this* block succeeds. It does not show that attention alone always fails at XOR, nor how any of this scales.
- **Block B adds three things at once.** Layer normalization, the feed-forward network and the residual connection are added together. **No ablation was run** (feed-forward network alone; with and without layer norm; with and without the residual), so the experiment does not say which of the three is responsible for the success. The argument above points at the feed-forward network, and nothing here tests that.
- **Training B is fragile.** One seed of six fails at the learning rate used; at higher rates most fail or diverge (the Python-only sweep). That table was produced by the plain-Python implementation, which agrees with the Mountain Goat one step for step on the runs compared, but the sweep itself was not run through `mgc`.
- **The linear-separability explanation is an argument.** It is consistent with model A plateauing at 69 of 81 for five seeds, and it was not verified (for instance by inspecting the learned pooled vectors).
- **The miss is a data gap.** The random split left `0 0 0 0` out of the training data. A different split would change which sequence, if any, is missed; only one split and three starting weights for the gradient check were used.
- **Only this model's backward pass is derived.** Layer norm, ReLU and residual are now covered for a single block with one pooling head. Chapter 30's full transformer (two heads, causal masking over positions, stacked blocks, embeddings with positions, per-position outputs) still has no hand-derived backward pass; Chapter 30's weights are still random.
- **The ReLU corner convention is a choice.** The gradient passes at exactly zero. Another convention would change nothing visible in these runs, and was not tried.
- **Finite differences:** a step of 0.001 and six printed digits bound the agreement to about `4·10⁻⁴`.
- **Learning rate and steps:** 0.5 and 600, chosen by trying (plain Python); no schedule, no stopping rule.
- **Platform:** x86-64 Linux, LLVM 18.1.3.

## Reproducing

```sh
cd docs/part32/code && ./build.sh
cd ../../part34/code
python3 make_examples.py && ./run_examples.sh > examples_out.txt
./check_ffn.py > check_ffn_out.txt
./lr_sweep.py > lr_sweep_out.txt
./model_mutation.py > model_mutation_out.txt
cd ../../part15/code && ./run_lit.sh          # 138 tests
```

## Chapter summary

- A block with a feed-forward network learns a task, the XOR of "1 is present" and "2 is present", that the same model without it cannot: model A plateaus at 69 of the 81 possible sequences, model B gets 80, and the only miss is `0 0 0 0`, which the training data never showed.
- The backward pass through the new pieces: the ReLU passes the gradient where its input is non-negative; the residual connection sends the gradient down two paths that add; and layer normalization needs three terms, `(dŷ − mean(dŷ) − ŷ·mean(dŷ·ŷ)) / sigma`.
- All of it is checked against an independent per-example Python gradient and against finite differences for all 120 weights; the first finite-difference step (0.01) was too coarse and the check was repaired, which is reported.
- Training B is not reliable at every setting: one of six seeds fails at the learning rate used and most fail at larger rates (a Python-only sweep).
- Ten wrong backward passes were run through the checker; the results are in the table above.
- Three additions (layer norm, feed-forward, residual) were tested together, not separately.

## Self-check questions

Each answer is collapsed; try the question first.

1. Why can model A not solve "exactly one of the tokens 1 and 2 is present", according to the argument on this page?

    ??? note "Answer"
        Attention pooling gives a weighted average of token value vectors, a point in a triangle. Under the picture where attention favours tokens 1 and 2 over 0, "1 only" and "2 only" land at the two ends of the line between `v1` and `v2` and "both" lands between them, so the labels along that line run 1, 0, 1. A linear read-out separates space with a straight line, which cannot make a label that is 1 at both ends and 0 in the middle. The page is clear that this is an argument consistent with the experiment, not a proof.

2. What does the residual connection do to the backward pass?

    ??? note "Answer"
        `z = h + f` makes `h` influence the loss along two routes, directly and through `f`. By the chain rule the gradient with respect to `h` is the **sum** of the gradients along the two routes: `dh = dz + dh_ln`. Dropping the direct route (a mutation tested above) leaves the gradient with only the layer-norm path.

3. Why does layer normalization's backward pass have three terms?

    ??? note "Answer"
        Each entry of `h` affects the mean, the spread `sigma` and, through them, every normalized entry. The terms account for each: `dŷ / sigma` for the direct effect on its own normalized value, `−mean(dŷ) / sigma` for the effect through the mean, and `−ŷ · mean(dŷ · ŷ) / sigma` for the effect through the spread. Together they make the gradient entries sum to zero, as they must since shifting every `h` by a constant changes nothing.

4. What is the derivative of ReLU at exactly 0, and what does this chapter do?

    ??? note "Answer"
        It does not exist: the slope is 0 to the left and 1 to the right. A brute-force estimate averages them, giving half of the upstream gradient (example 2 shows `1` for an upstream `2`). Training code must choose; this chapter passes the gradient at exactly 0 (the mask is `ge(pre, 0)`), as most frameworks do.

5. The first finite-difference check failed for model B. Was the gradient wrong?

    ??? note "Answer"
        No. The gradient equalled the independent Python gradient. A plain-Python finite difference with exact losses and step 0.01 showed the same `5.6·10⁻³` disagreement, and with step 0.001 only `10⁻⁶`, so the error was in the estimate (a step that straddles a ReLU corner or misjudges curvature). The check's step was changed to 0.001, which `mgc`'s six printed digits still allow.

6. Why is "model B gets 80 of 81" more convincing than "model B gets 26 of 27 held-out sequences right"?

    ??? note "Answer"
        There are only 81 possible inputs, so the program can try every one: it is exhaustive, with no sampling luck and no held-out set that might happen to be easy. The 27 held-out sequences are one particular random subset; 26 of 27 says less than a full census of the input space. It also identifies exactly which sequence fails.

7. Why does the page report a Python-only sweep, and what does it show that the single run does not?

    ??? note "Answer"
        Running every seed and learning rate through `mgc` would take hours (model B's program is 6,000 lines and about 100 seconds to build). The Python implementation agrees with the Mountain Goat one step for step, so it is a fair stand-in for a sweep. It shows that model B's success depends on the start and the learning rate (five of six seeds at 0.5, six of six at 0.25, one of six at 1.0), which one run cannot show, and that model A fails for every seed.

8. Why did the experiment not isolate which of layer normalization, the feed-forward network and the residual connection matters?

    ??? note "Answer"
        Model B adds all three at once and is compared with a model with none of them. Isolating one would need further models (for example, the feed-forward network without layer normalization, or layer normalization without the feed-forward network), each with its own backward pass checked and its own training runs. That was not done, and the page says so; the argument about the ReLU's bend points at the feed-forward network, but the experiment does not test that.

9. How is `0 0 0 0` the model's only error, and what does it have in common with the failures in Chapters 32 and 33?

    ??? note "Answer"
        It is the only one of the 81 sequences that model B classifies wrongly, and the training set (a random 54 of the 81) happened not to contain it, so the model never saw the case "neither token present" and extrapolates confidently wrong. In Chapter 32 the held-out pairs that failed were the ones the training pairs never showed; in Chapter 33 `4 4 4 4` failed because label 4 never occurred in the data. In each, the failure is an input outside what training covered.

10. What would be needed to train Chapter 30's full transformer with these methods?

    ??? note "Answer"
        The backward passes of the parts still missing: the position matrix (a fixed input, so no gradient), two attention heads with their output split, causal masking over positions (the gradient through the masked softmax is the same formula, with masked entries contributing zero), per-position outputs and a loss over all positions, and several stacked blocks (the residual structure makes the gradient flow through each block's two paths, as here). Layer normalization, ReLU, residuals and single-head attention are now derived and checked; the remaining work is assembling them, with a finite-difference check of every new weight.
