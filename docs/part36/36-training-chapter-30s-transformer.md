# 36. Training Chapter 30's Transformer: Two Heads, Two Blocks, and a Result That Is Not Better

<p style="text-align:center"><img src="../assets/goats/ch-36.svg" alt="Mountain goats on the mountain at dawn" style="max-width:100%;height:auto;border-radius:6px"></p>

**What you will understand:** how to train, in Mountain Goat, the *architecture* of Chapter 30's transformer: **two blocks**, each with **two attention heads** and a feed-forward network, pre-norm residual connections and a final layer norm, as a causal language model on Chapter 35's task. Chapter 35 stopped at one block and one head. The new backward-pass pieces are small, but they are the ones that were missing: gradients that **fan out to two heads and add**, and a gradient that is carried **back through two blocks**. The model has 1,216 weights in 36 matrices. All 36 gradient matrices are checked against an independent Python calculation and against finite differences, and the 200-step training run agrees with the reference at every checkpoint. Then the page reports what the experiment shows, which is **not** that the bigger model is better: it fits its 16 training sequences and **generalizes much worse than Chapter 35's smaller model** (a Python-only sweep measures how much, and what more data does to it).

**What you need to know first:** Chapter 35 (this chapter reuses its task, data, stacking and mask unchanged; read it first), Chapter 30 (the architecture; its model is only *shaped* like this one, see Limits), Chapter 34 and Chapter 33 (the backward-pass rules). **No new compiler operation** is needed: the programs run on Chapter 32's compiler.

!!! tip "Compile and run"
    ```sh
    cd docs/part32/code && ./build.sh                 # once: the newest compiler (this chapter adds nothing to it)
    cd ../../part36/code
    python3 make_examples.py                          # (re)writes the examples from lm2_lib.py
    ../../part32/code/mgc run examples/03_train_10_steps.mg    # 10 training steps (well under a minute)
    ../../part32/code/mgc run examples/04_train_200_steps.mg   # the full 200 steps: a 29,552-line program; about 40 minutes in all (see below)
    ./run_examples.sh > examples_out.txt              # every example and every error example on this page (38 minutes, measured while other jobs shared the machine)
    ./check_lm2.py                                    # the quick check: gradients, finite differences, 10 training steps (about 45 seconds)
    ./check_lm2.py --full > check_lm2_out.txt         # the page's 200 steps against the reference (39 minutes 35 seconds, measured)
    ./sensitivity.py > sensitivity_out.txt            # Python only: how sensitive is training to a 1e-12 change? (a minute or two)
    ./sweep.py > sweep_out.txt                        # Python only: learning rates, one block against two, 16 against 32 training sequences (several minutes)
    ./model_mutation.py > model_mutation_out.txt      # runs 21 WRONG programs through the lean check (roughly half an hour)
    ./fd_blindness.sh > fd_blindness_out.txt          # two of those through the full finite-difference check (about 4 minutes)
    cd ../../part15/code && ./run_lit.sh              # the whole test suite
    ```
    Every listing and output on this page comes from these commands.

!!! note "Why this page shows FAIL lines and error messages, and why that is good"
    The three error examples are programs the compiler must reject (each ends `exit status 1`). The mutation output is a negative control: deliberately wrong programs run against the checker, where "caught" is the wanted result and "NOT CAUGHT" would be a gap (one is reported, and explained). The `FAIL` lines in `fd_blindness_out.txt` are likewise the point of that file.

## What changes from Chapter 35

| | Chapter 35 | this chapter |
|---|---|---|
| blocks | 1 | **2** (each: layer norm, attention, residual, layer norm, feed-forward, residual) |
| attention heads per block | 1 (width 8) | **2** (width 4 each) |
| matrices | 16 | **36** |
| weights | 648 | **1,216** |
| task, data, stacking (16 sequences, 112 rows), mask, loss | | the same |
| learning rate, steps | 1.0, 200 | 0.5, 200 |

The architecture is Chapter 30's: pre-norm, two heads whose outputs are brought back to the model width by one output matrix each and **added** (Chapter 30 notes that concatenating the heads and multiplying by one output matrix equals adding each head times its own half of that matrix), a ReLU feed-forward network, a final layer norm. The widths are Chapter 35's (model width 8, feed-forward width 16, vocabulary 4), not Chapter 30's (4, 8, 5): Chapter 30's literal model has four tokens and width 4, too small for this task (see Limits).

### Two heads: gradients that fan out and add

Both heads read the same normalized input `u1`. So `u1` influences the loss along **six** routes (a query, a key and a value path for each head), and its gradient is the **sum** of what comes back along them:

`du1 = dq1 @ wq1ᵀ + dk1 @ wk1ᵀ + dv1 @ wv1ᵀ + dq2 @ wq2ᵀ + dk2 @ wk2ᵀ + dv2 @ wv2ᵀ`

Everything else in a head is Chapter 35's backward pass, run once per head with that head's own `a`, `q`, `k`, `v` and `wo`. Here is the fan-out rule at a size you can check by hand: one matrix `u` feeds two maps, and the gradient with respect to `u` is the sum of the gradients along the two routes (the first matrix), compared with brute force:

```text
--8<-- "docs/part36/code/examples/01_two_paths_add.mg"
```

```text
--8<-- "docs/part36/code/examples_out.txt:1:33"
```

`r1 @ wa.T = [[1,4],[0,1]]` and `r2 @ wb.T = [[0,2],[3,2]]` add to `[[1,6],[3,3]]`, and the four brute-force numbers are `1, 6, 3, 3`.

### Two blocks: the gradient goes back through both

The backward pass starts at the loss, goes through the final layer norm, and then runs **block 2's backward pass, then block 1's**: each block receives the gradient of its output and produces the gradient of its input, which is the next block's output gradient. The residual connections keep a direct route open: with a scale in place of each sub-layer so that every number is checkable (`x1 = x + 0.5 x`, `x2 = x1 − 0.25 x1`), the gradient is `(1 + 0.5)(1 − 0.25) = 1.125`, found by the backward recurrence and by brute force:

```text
--8<-- "docs/part36/code/examples/02_two_blocks_chain.mg"
```

```text
--8<-- "docs/part36/code/examples_out.txt:35:54"
```

## The definitions

One training step as Mountain Goat text (the forward pass of both blocks, the backward pass of both blocks, the update). In the generated training programs each step's names carry a suffix and every step is unrolled, which is why the 200-step program has 29,552 lines:

```text
--8<-- "docs/part36/code/lm2.mg.defs"
```

As in Chapter 35 every intermediate result is bound with its own `let` (a nested-function version would recompute shared quantities and exhaust memory, as Chapter 35 found). The names carry the block and the head: `a2_b1` is head 2's attention weights in block 1; `dX1` is the gradient with respect to the input of block 2, which is the output of block 1.

**The program is large and the compiler is slow on it.** Compiling and running the 29,552-line program takes about 40 minutes in my runs: `check_lm2.py --full` took 39 minutes 35 seconds, and the whole `run_examples.sh` 38 minutes 47 seconds, with other jobs running on the same machine for part of both. The compile stage `mg-opt` ran at 100% of a core and about 650 MB for over thirty minutes before the program started. Chapter 35's 12,455-line program took about 8 minutes in total. No attempt was made to find out why the cost grows faster than the size; it is a property of this compiler on this program shape, not of the method.

## Training

`examples/04_train_200_steps.mg` trains with learning rate 0.5 from seeded starting weights for 200 steps and prints, as in Chapter 35, the loss and the number correct (of 64) on the training sequences at checkpoints 0, 1, 10, 25, 50, 100, 150 and 200; then the held-out loss and count; then the number correct on each of four chunks of 16 of **all 64 possible sequences**; then **four** attention patterns of the first training sequence: block 1 head 1, block 1 head 2, block 2 head 1, block 2 head 2. First, the same program stopped after 10 steps (`03_train_10_steps.mg`, which the test suite runs):

```text
--8<-- "docs/part36/code/examples_out.txt:56:115"
```

And the full run:

```text
--8<-- "docs/part36/code/examples_out.txt:117:196"
```

| after step | 0 | 1 | 10 | 25 | 50 | 100 | 150 | 200 |
|---|---|---|---|---|---|---|---|---|
| training loss | 1.596 | 1.353 | 1.035 | 0.715 | 0.473 | 0.357 | 0.0148 | **0.0031** |
| correct of 64 | 10 | 20 | 39 | 45 | 49 | 55 | 64 | **64** |

- **It fits the training data.** Loss 0.0031 and all 64 scored predictions right.
- **It does not generalize.** On the 16 held-out sequences the loss is **2.33**, worse than the 1.39 (`ln 4`) of guessing uniformly, and **40 of 64** predictions are right. On all 64 possible sequences the four chunks give 39, 51, 51 and 43: **184 of 256** (the 64 training predictions are among them, so 120 of the 192 predictions on sequences it never trained on, 63%). Chapter 35's model, on the same data, got 256 of 256.
- **The attention is not Chapter 35's clean pattern.** Chapter 35's one head looked two positions back (0.98, 0.52, 0.80, 0.78, 0.79 on the diagonal two before). Here block 1 head 1 puts about 0.97 on position 0 for rows 1 and 2, then spreads (row 4: 0.57 on itself; row 5: 0.45 on itself); the other three heads spread their weight broadly (from row 3 on, no weight above 0.31; row 6 of block 2 head 1 is 0.19, 0.17, 0.14, 0.12, 0.12, 0.12, 0.14). No head looks two back. The model fits 16 sequences without finding the rule, which is the signature of memorizing; this is an interpretation of the numbers, and no experiment here (such as inspecting what the weights compute) tests it.

## Is this training chaotic, like Chapter 35's? No, in this run

Chapter 35 found that its run was chaotic: a change of 10⁻¹² in one weight changed the step-100 loss by a factor of six. The same experiment (`sensitivity.py`: train twice in Python, once with one starting weight nudged by 10⁻¹²) on this model:

```text
--8<-- "docs/part36/code/sensitivity_out.txt"
```

The two runs agree to about six digits through step 200 (the largest difference anywhere in the table is 5·10⁻⁶, in a held-out loss at step 125). So this model's run can be compared **digit for digit at every checkpoint**, and `check_lm2.py --full` does that (the output is below); it is the Mountain Goat program's loss at step 200, 0.00314496, against the Python run's 0.003145. This is a measurement of one run, one nudge, one weight; it does not show that this model's training is stable for every starting point.

## One block or two? A Python-only sweep

The experiment's surprise is the generalization gap, so it was measured further. `sweep.py` (plain Python, not `mgc`) trains for 200 steps from four starting-weight seeds. The score is the number correct among the predictions on sequences **not trained on** (192 predictions for 16 training sequences, 128 for 32):

```text
--8<-- "docs/part36/code/sweep_out.txt"
```

- **Part A, learning rates (two blocks, 16 sequences):** none of 0.25, 0.5 and 1.0 gets near Chapter 35's scores; unseen scores run from 91 to 140 of 192 (47% to 73%), and the page's rate 0.5 gives 120, 111, 115, 108. Seed 1 at rate 0.25 does best (140) while another seed at the same rate is the worst (91), so the choice of rate is not what is limiting.
- **Part B, one block against two:** with 16 training sequences, one block scores 192, 175, 185, 175 of 192 (91% to 100%) and two blocks 120, 111, 115, 108 (56% to 63%). With **32** training sequences the one-block model scores 128 of 128 for every seed, and the two-block model 128, 108, 128, 125: **doubling the training data closes most of the gap** (and not all: seed 2 still memorizes).
- **What this suggests, and what it does not show.** The two-block, two-head model has about twice the weights (1,216 against 648) and the same 16 sequences; it fits them without finding the rule. More data helps it. What the experiment does **not** separate is *why*: the number of blocks, the number of heads, the head width, and the learning rate were all different between the two models, and none was varied alone. No weight decay or other regularizer, no longer training, and no different starting scale were tried.

## Mistakes the compiler reports

```text
--8<-- "docs/part36/code/examples_out.txt:198:224"
```

A head's output matrix of the wrong width, a call with a missing argument, and a residual connection whose two sides have different widths. As always, the shapes are types.

## Tests

Three new `lit` files in `test/lm36/` (the suite is now 144 tests; no `verifiers` or `ir` test because no compiler operation was added):

| Test | What it checks |
|---|---|
| `examples` | the two small examples (worked out above) and the loss and correct count, held-out result and chunk counts of the 10-step training run |
| `errors` | the three mistakes give the exact messages |
| `against-reference` | `check_lm2.py` in its quick mode, below (about 45 seconds). The 200-step run is not in CI because it takes about 40 minutes; `check_lm2.py --full` runs it |

`check_lm2.py` compares with an **independent** Python implementation (`lm2_ref.py`: plain lists, one sequence and one position at a time, every gradient derived element by element; the reference's own gradient was first checked against exact-double finite differences, step 10⁻⁶, for two weights of every matrix: largest difference 4·10⁻¹⁰) and checks, in order:

1. **The gradients,** for three starting-weight sets: the loss and all 36 gradient matrices equal the reference's, and for the first set **the largest-gradient weight of every one of the 36 matrices** agrees with a finite-difference estimate (step 0.001; the program forms the *difference* of the two losses itself so that `mgc`'s six printed digits are spent on it, as in Chapter 35).
2. **Training:** loss and correct count at every checkpoint, the held-out loss and count, the four chunk counts and **all four attention patterns** equal the reference's; every attention row of every head sums to 1 and puts exactly 0 after the diagonal.
3. **The experiment (`--full`):** the 200-step run fits the training sequences (loss below 0.01, 64 of 64).

```text
--8<-- "docs/part36/code/check_lm2_out.txt"
```

(`largest difference 0.0e+00` means that, for these weights, the finite-difference estimate and the program's gradient agree in all six digits `mgc` prints; the gradient entries here are of order 10⁻².)

### Are the checks good enough? Run twenty-one wrong programs.

`model_mutation.py` writes twenty-one versions of the program, each with one mistake, and runs the **lean** checker on each (seed 1 only; finite differences for six weights, `wq1_1`, `wo2_2`, `w1_1`, `g2_2`, `emb`, `wout`; then 10 training steps). Many of the mistakes touch **only one head or one block**, which is what this chapter added:

```text
--8<-- "docs/part36/code/model_mutation_out.txt"
```

Twenty of twenty-one are caught. What the pattern shows:

- **The new, per-head and per-block mistakes are all caught,** including ones confined to a single head of a single block (the missing row-sum correction in head 2 of block 2, `dk` without the transpose in head 2 of block 1, head 2's whole contribution missing from `du1` in block 1), the residual dropped *between* the blocks, and two cross-wirings that the shapes allow (head 2's `do` computed with head 1's output matrix; block 2's feed-forward backward using block 1's `w2`).
- **The reference gradient is the sharper check.** The missing row-sum correction in head 2 of block 2 and `dk` without the transpose in head 2 of block 1 were caught by the reference gradient **only**. The finite-difference check in lean mode looks at six weights, so the question arises whether more weights would have caught them. `fd_blindness.sh` runs these two through the **full** finite-difference check (the largest-gradient weight of all 36 matrices):

```text
--8<-- "docs/part36/code/fd_blindness_out.txt"
```

  The finite differences miss the first mutant even with all 36 weights: the largest disagreement is 4.7·10⁻⁴, **below the 10⁻³ threshold**. A mistake in one head's softmax backward changes the gradient by less than the finite-difference check can resolve (the step of 0.001 and six printed digits bound it to about that size). The comparison with the reference, at a relative 10⁻⁵, sees it. The second mutant fails the finite-difference check (1.9·10⁻³). **Finite differences alone would have let a real derivation mistake through; the reference comparison is the check that earns its keep.**
- **Forward-only changes** (no mask, position vectors left out, epsilon 0.1 in forward **and** backward) are caught by the reference gradient and the reference training run, not by finite differences: a gradient that matches its own wrong loss passes finite differences by construction (as in Chapters 34 and 35).
- **One is NOT CAUGHT: the softmax without the row-maximum subtraction.** As in Chapter 35 it is algebraically the same function and gives the same numbers at these score sizes; no check uses large scores. This gap is carried over, and still not closed.
- The wrong step size on the embedding's first update is caught only by the training run, since it changes training and not any gradient.

There is no compiler-mutation run for this chapter: no compiler code changed.

The full suite:

```text
--8<-- "docs/part15/code/run_out_144.txt"
```

## Limits and what is not established

- **Chapter 30's shape, not Chapter 30's model.** The architecture (two blocks, two heads, pre-norm, feed-forward, final layer norm) is Chapter 30's, but the widths are Chapter 35's (8, 16, 4) and not Chapter 30's (4, 8, 5), and the weights are trained, not Chapter 30's seeded ones. Chapter 30's literal model has four tokens and width 4; **it was not trained**, and whether it could learn any task was not tried.
- **The generalization gap is measured, not explained.** One task, one 16-sequence training set, four seeds in the sweep, one split of the data. Blocks, heads, head width and learning rate all changed together between the two models; the explanation "more weights than data, so it memorizes" is consistent with the 32-sequence result and is not tested (no regularization, no ablation, no different widths).
- **No ablation of the new parts.** Whether two heads or two blocks is responsible for the gap was not separated; the sweep compares the whole models.
- **Not-chaotic is one measurement.** A single 10⁻¹² nudge of a single weight left the run unchanged to six digits for 200 steps. That does not show every start is stable.
- **Finite differences cover 36 weights** (the largest-gradient weight of each matrix) for one starting-weight set; and they cannot resolve a mistake as small as the one shown above. The gradient comparison with the reference covers all 1,216 weights for three starting sets.
- **The softmax-without-max gap** (above): overflow robustness is untested.
- **Compile cost.** The 200-step program takes about 40 minutes to compile and run; no attempt was made to reduce it (for instance by training fewer steps per program and carrying the weights over, which would need a way to write weights out and read them back, and the language has none).
- **Generation is not shown,** and the attention for sequences other than the first training sequence was not printed.
- **Platform:** x86-64 Linux, LLVM 18.1.3.

## Reproducing

```sh
cd docs/part32/code && ./build.sh
cd ../../part36/code
python3 make_examples.py && ./run_examples.sh > examples_out.txt
./check_lm2.py --full > check_lm2_out.txt
./sensitivity.py > sensitivity_out.txt
./sweep.py > sweep_out.txt
./model_mutation.py > model_mutation_out.txt
./fd_blindness.sh > fd_blindness_out.txt
cd ../../part15/code && ./run_lit.sh          # 144 tests
```

## Chapter summary

- Chapter 30's architecture (two blocks, two heads each, 1,216 weights) is trained in Mountain Goat as a causal language model by hand-derived backpropagation. New in the backward pass: the gradient into the shared normalized input is the **sum over six routes** (query, key and value of each of two heads), and the gradient is carried **back through two blocks**, last first.
- All 36 gradient matrices equal an independent per-position Python calculation at three starting points; the largest-gradient weight of every matrix agrees with finite differences. The 200-step training run agrees with the reference at every checkpoint (this run, unlike Chapter 35's, is not chaotic).
- **The result is not that bigger is better.** The model fits its 16 training sequences (loss 0.0031) but gets 40 of 64 held-out predictions and 184 of 256 overall, against Chapter 35's one block at 256 of 256, and its attention shows no head that looks two positions back.
- A Python-only sweep: on 16 training sequences the one-block model scores 91–100% of unseen predictions and the two-block model 56–63%; on 32 sequences the gap mostly closes (the two-block model reaches 128 of 128 for two of four seeds). The cause was not isolated.
- Twenty-one wrong programs: twenty caught, one not (softmax without the row-max subtraction). One mistake in a single head's softmax backward is **invisible to the finite-difference check** (4.7·10⁻⁴ against a 10⁻³ threshold) and is caught only by the reference comparison.

## Self-check questions

Each answer is collapsed; try the question first.

1. Why does the gradient with respect to `u1` have six terms in this model and three in Chapter 35's?

    ??? note "Answer"
        `u1` feeds the query, key and value maps of every head. With one head that is three routes; with two heads it is six. A quantity that influences the loss along several routes receives the **sum** of the gradients along them (the chain rule for fan-out), so each head contributes its own `dq @ wqᵀ + dk @ wkᵀ + dv @ wvᵀ` and the two are added.

2. What does block 2's backward pass hand to block 1's?

    ??? note "Answer"
        The gradient with respect to its **input**, which is block 1's **output** (`dX1`). Block 2's backward pass starts from the gradient arriving at its output (from the final layer norm), runs the feed-forward residual, then attention, and returns `dx1 + ln_back(du1, …)`: the direct residual route plus the route through the layer norm and the heads. Block 1 treats it as the gradient at its own output. The last thing returned is the gradient with respect to the embedded input.

3. The two-block model reaches a training loss of 0.0031 and 64 of 64 correct. Does that show it has learned the task?

    ??? note "Answer"
        No. On the 16 held-out sequences it gets 40 of 64 and a loss of 2.33 (guessing uniformly gives 1.39), and over all 64 sequences it gets 184 of 256. Fitting the training data shows the optimization works; it does not show the rule was found. Compare Chapter 35's model, which on the same data got 256 of 256.

4. The sweep shows the gap closing when the training set doubles. Does that prove the gap is a data-size effect?

    ??? note "Answer"
        It supports it but does not prove it: with 32 sequences the two-block model reaches 128 of 128 for two seeds, 125 for a third and still only 108 for a fourth. Also, the one-block and two-block models differ in blocks, heads, head width and learning rate at once, and none of these was varied alone. The result says more data helps this model; it does not say the extra capacity is the cause of the gap.

5. One mutant (no row-sum correction in one head's softmax backward) passed the finite-difference check even over 36 weights. How can a wrong gradient pass?

    ??? note "Answer"
        The finite-difference estimate has a resolution: a step of 0.001 and six printed digits limit how small a disagreement it can see, about 10⁻³ here, and the gradient entries are of order 10⁻². A mistake confined to one head of one block changes the gradient by 4.7·10⁻⁴, below the threshold. The reference comparison works at a relative 10⁻⁵ and sees it. It is the reason this book keeps an independent reference implementation and does not rely on finite differences alone.

6. Chapter 35's run was chaotic and this one is not. What should you conclude about the next model?

    ??? note "Answer"
        Nothing without measuring: it is a property of each model and each starting point, found by `sensitivity.py`, and cheap to measure (a minute or two in plain Python). It decides whether a check may compare digit for digit at every checkpoint or must compare claims after the transition.

7. Why does this program take about 40 minutes, when Chapter 35's took about eight?

    ??? note "Answer"
        It is a larger program (29,552 lines against 12,455), and the compile stage (`mg-opt`) ran at 100% of a core for over thirty minutes in an observed run, so the cost grows faster than the size. Why was **not** investigated. The measurement is from one machine and one run, with other jobs sharing the machine for part of it.
