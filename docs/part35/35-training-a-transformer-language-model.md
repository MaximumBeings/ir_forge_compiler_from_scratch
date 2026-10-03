# 35. Training a Transformer Language Model: Backpropagation Through Causal Attention, Layer Norms, a Feed-Forward Network and Embeddings

**What you will understand:** how to train, in Mountain Goat, a small but complete **causal transformer language model**: token embeddings plus positions, a layer-normalized block of **causal self-attention** and a **feed-forward network** with residual connections, a final layer norm and a projection to the vocabulary, trained to predict the next token. Chapter 30 built the forward pass of such a model with random weights; Chapters 33 and 34 derived the backward pass piece by piece for a classifier. This chapter joins the pieces and adds the four that were missing: the **causal mask** inside the attention backward pass, **many sequences stacked into one matrix**, the **per-position (masked) cross-entropy**, and the **embedding gradient**. The model has 648 weights in 16 matrices; the hand-derived gradient of all 16 matrices is checked against an independent Python calculation, and against finite differences. After 200 steps the model predicts every token it is supposed to be able to predict on all 64 possible sequences, **and the page then shows why you should not take that result as more than it is** (training turns out to be chaotic).

**What you need to know first:** Chapter 33 (the attention backward pass), Chapter 34 (layer norm, ReLU and residual backward passes), Chapter 31 (cross-entropy) and Chapter 30 (the transformer's forward pass). **No new compiler operation** is needed: the programs run on Chapter 32's compiler.

!!! tip "Compile and run"
    ```sh
    cd docs/part32/code && ./build.sh                 # once: the newest compiler (this chapter adds nothing to it)
    cd ../../part35/code
    python3 make_examples.py                          # (re)writes the examples from lm_lib.py
    ../../part32/code/mgc run examples/03_train_10_steps.mg    # 10 training steps (under a minute)
    ../../part32/code/mgc run examples/04_train_200_steps.mg   # the full 200 steps: a 12,455-line program, about 8 minutes
    ./run_examples.sh > examples_out.txt              # every example and every error example on this page (about 8 minutes)
    ./check_lm.py                                     # the quick check: gradients, finite differences, 10 training steps (about 25 seconds)
    ./check_lm.py --full > check_lm_out.txt           # the page's 200 steps against the reference, and the experiment (about 8 minutes)
    ./sensitivity.py > sensitivity_out.txt            # Python only: how sensitive is training to a 1e-12 change? (about 15 seconds)
    ./lr_sweep.py > lr_sweep_out.txt                  # Python only: learning rates and starting weights (a few minutes)
    ./model_mutation.py > model_mutation_out.txt      # runs 18 WRONG programs through the quick check (about ten minutes)
    cd ../../part15/code && ./run_lit.sh              # the whole test suite
    ```
    Every listing and output on this page comes from these commands.

!!! note "Why this page shows FAIL lines and error messages, and why that is good"
    The three error examples are programs the compiler must reject (each ends `exit status 1`). The mutation output is a negative control: deliberately wrong programs run against the checker, where "caught" is the wanted result and "NOT CAUGHT" would be a gap (one is reported, and explained). The `--` lines in the full check are not failures: they mark values the page deliberately does **not** compare digit for digit, for a reason the page measures.

## The task: copy the token from two positions back

A sequence has seven tokens from a vocabulary of four (0, 1, 2, 3). The first three are chosen freely and then the sequence repeats them: `a b c a b c a`. For example `0 1 2 0 1 2 0` and `3 3 1 3 3 1 3`. There are 4<sup>3</sup> = **64** possible sequences. A language model is trained to predict, at each position, the **next** token. In these sequences the next token is *predictable* only at positions 2 to 5: there, token *i+1* equals token *i−2* (the model has seen `a b c` and must say `a`, then `b`, then `c`, then `a`). At positions 0 and 1 the next token is a free choice, and position 6 has no next token, so those three positions are **not scored**. That leaves 4 scored predictions per sequence, and **256 scored predictions over all 64 sequences**. Guessing gives 25%; so does always answering the most common token.

16 random sequences train the model (their first triples are `222 101 130 221 322 312 200 302 123 232 211 220 133 131 001 310`), 16 others are **held out** (`121 212 331 223 311 010 112 002 032 313 230 332 033 321 213 012`), and the remaining 32 are seen only by the exhaustive check at the end. A model that memorizes its 16 sequences scores 64 of 64 on them and learns nothing about the rest; a model that has found the rule gets 256 of 256.

## The model

The tokens are one-hot rows. For a sequence of 7 tokens, the matrices below have 7 rows (`N = 7`); the width is `D = 8`, the feed-forward width `H = 16`, the vocabulary `V = 4`:

| step | what it computes | shape |
|---|---|---|
| `x0 = x @ e + ps` | embed each token (`e` is learned, 4×8), add the fixed sinusoidal position vectors `ps` | N×8 |
| `u1 = ln_out(x0, g1, n1)` | layer norm 1 | N×8 |
| `q, k, v = u1 @ wq, u1 @ wk, u1 @ wv` | queries, keys, values (one head, width 8) | N×8 |
| `a = softmax_rows(q @ kᵀ / √8 + mask)` | causal attention weights | N×N |
| `o = a @ v`; `x1 = x0 + o @ wo` | mix values; project; **residual** | N×8 |
| `u2 = ln_out(x1, g2, n2)` | layer norm 2 | N×8 |
| `pre = u2 @ w1 + c1`; `r = relu(pre)` | feed-forward, first layer | N×16 |
| `x2 = x1 + (r @ w2 + c2)` | feed-forward, second layer; **residual** | N×8 |
| `uf = ln_out(x2, gf, nf)`; `lg = uf @ wu` | final layer norm; scores for the 4 next-token candidates | N×4 |

The loss is the average over the scored positions of `−log softmax(lg)[correct next token]`. Position vectors are fixed (sines and cosines of the position, never trained), so only the 16 matrices `e, g1, n1, wq, wk, wv, wo, g2, n2, w1, c1, w2, c2, gf, nf, wu` are learned (32 + 8 + 8 + 4·64 + 8 + 8 + 128 + 16 + 128 + 8 + 8 + 8 + 32 = **648** numbers).

### Many sequences, one matrix, and the causal mask

Mountain Goat has matrices and no batch dimension, so 16 sequences are **stacked**: 16 × 7 = **112 rows**, and attention is computed for all 112 rows at once, a 112×112 score matrix. Row *r* must be allowed to look only at columns in **its own sequence** (no leaking between sequences) and only at positions **not after itself** (causal: no looking at the answer). The mask adds 0 to allowed entries and −10⁹ to the rest, and softmax turns those into exactly 0. Here is the idea at a size you can read, two sequences of three tokens (6 rows), with every score equal to 1 so that all structure comes from the mask:

```text
--8<-- "docs/part35/code/examples/01_stacked_causal_mask.mg"
```

```text
--8<-- "docs/part35/code/examples_out.txt:1:26"
```

Row 0 attends to itself only; row 2 splits its attention equally over rows 0 to 2; row 5 over rows 3 to 5; nothing crosses from rows 0–2 to rows 3–5. The real mask is the same pattern with blocks of 7 inside 112×112 (a literal in the programs).

### The loss counts only some rows

Of the 112 stacked rows only 4 in 7 are predictions. The program carries a column `mr` (1 on scored rows, 0 elsewhere) and a one-hot matrix `y` that is all zeros on unscored rows, so that unscored rows add nothing to the loss, and `mr` also zeros their **gradient**:

```text
--8<-- "docs/part35/code/examples/02_masked_cross_entropy.mg"
```

```text
--8<-- "docs/part35/code/examples_out.txt:28:47"
```

The loss `1.25311` is the mean of `ln 3 = 1.0986` (three equal logits) and `1.4076` (the correct word has probability 0.245). The rows 0 and 2 of the gradient are exactly zero; row 1 is `(1/3, 1/3 − 1, 1/3)/2`. In the real model the factor is `1/64`, one over the number of scored predictions in the batch.

## The backward pass: what is new

Everything below `dl` (the gradient of the loss with respect to the scores) is a rule met before, applied in reverse order of the forward pass. The new rows:

- **The scores' gradient, masked:** `dl = (exp(log_softmax(lg)) * mr − y) / 64`: softmax minus one-hot (Chapter 31), zeroed on unscored rows.
- **Through the final layer norm and the two residuals:** `ln_back` (Chapter 34) and `dx1 = dx2 + ln_back(du2, …)`: where a residual joins, the gradient paths **add**.
- **Through the ReLU:** multiply by `ge(pre, [[0]])` (Chapter 34).
- **Through softmax attention:** `da = do @ vᵀ`, then `ds = a * (da − row_sum(a * da))` (Chapter 33). **The mask needs no special treatment**: it is a constant added before the softmax, so it has no gradient, and the masked entries of `a` are exactly 0, so `ds` is exactly 0 there: no gradient flows to a position that was not seen. This is the one place where one might expect an extra term, and there is none.
- **Three paths into `u1`:** `u1` feeds `q`, `k` and `v`, so `du1 = dq @ wqᵀ + dk @ wkᵀ + dv @ wvᵀ`, three terms that add. (`dq = ds @ k / √8`, `dk = dsᵀ @ q / √8`, `dv = aᵀ @ do`.)
- **The embedding gradient:** `x` is one-hot, so `x0 = x @ e + ps` is a *lookup*; its weight gradient is `transpose(x) @ dx0`: each row of `e` receives the sum of `dx0` over the positions where that token occurs (a scatter-add written as a matrix product). The positions `ps` are constants, so they receive nothing.

## The definitions

One training step as Mountain Goat text (the lets of the forward pass, the backward pass, the update); in the generated training programs each step's names carry a suffix and every step is unrolled, which is why the 200-step program has 12,455 lines:

```text
--8<-- "docs/part35/code/lm.mg.defs"
```

**Why one `let` per step and not nested functions.** The first version of this chapter wrote each gradient as a function of the parameters (as in Chapter 34). For this model `mgc` was killed (exit status −9; running out of memory is the likely cause, not confirmed beyond that): a nested function is expanded in place at every use, so a quantity used several times is recomputed several times, the generated code never frees memory, and the cost multiplied at every level. Binding every intermediate result with `let` computes it once. This is a property of this compiler (no common-subexpression elimination, no freeing of temporaries), not of the method.

## Training

The program for the page, `examples/04_train_200_steps.mg`, runs 200 steps of gradient descent with learning rate 1.0 from seeded starting weights, printing the loss and the number of correct predictions (of 64) on the 16 training sequences at checkpoints 0, 1, 10, 25, 50, 100, 150 and 200; then the held-out loss and count; then the number correct on each of four chunks of 16 of **all 64 possible sequences**; then the attention weights of the first 7 rows (the first training sequence). First, the same program stopped at 10 steps (`03_train_10_steps.mg`, which the test suite runs):

```text
--8<-- "docs/part35/code/examples_out.txt:49:84"
```

(The first six numbers are loss and number correct at steps 0, 1 and 10; the next two are the held-out loss and count; then the four chunk counts; then the attention matrix, which at this early stage is spread broadly: row 6 puts 0.25, 0.21, 0.13, … on the seven positions.) The loss falls from 1.429 to 0.966 in ten steps; the number correct rises from 20 of 64 (chance is 16) to 39. And the full run:

```text
--8<-- "docs/part35/code/examples_out.txt:86:141"
```

| after step | 0 | 1 | 10 | 25 | 50 | 100 | 150 | 200 |
|---|---|---|---|---|---|---|---|---|
| training loss | 1.429 | 1.288 | 0.966 | 0.728 | 0.525 | 0.0356 | 0.0019 | **0.0009** |
| correct of 64 | 20 | 29 | 39 | 45 | 53 | 64 | 64 | **64** |

- **It fits the training data:** loss 0.0009, all 64 scored predictions right.
- **It generalizes, on this run:** the 16 held-out sequences give loss 0.0076 and 64 of 64, and every one of the four chunks of 16 of all 64 possible sequences gives 64 of 64: **256 of 256**.
- **The attention has learned where to look.** The last matrix (the first training sequence, `2 2 2 2 2 2 2`) shows each row attending to the position **two before itself**: row 2 puts 0.977 on position 0, row 3 puts 0.518 on position 1 (and 0.430 on position 0), row 4 puts 0.803 on position 2, row 5 puts 0.783 on position 3, row 6 puts 0.785 on position 4. Position *i* is predicting token *i+1*, which equals token *i−2*, and that is where it looks. This is a *positional* pattern; because this sequence has the same token everywhere, it cannot show whether the attention also depends on the token **content**, and no other sequence's attention was printed, so that is **not established**.
- **The loss did not fall smoothly.** It is 0.525 at step 50, rises to about 0.58 at step 75 (from the Python run, below), and has collapsed to 0.036 by step 100. It is the shape of a model finding the trick, and it has a consequence, next.

## Training is chaotic: a measured caution

`check_lm.py` compares the Mountain Goat training with the independent Python trainer. The comparison is **digit for digit up to step 50** (losses and counts equal to a relative 10⁻⁵, the six digits `mgc` prints) and then **stops being possible**. At step 100 the program's loss is 0.0356 and the Python reference's is 0.0346; the first version of the checker, which demanded agreement at every checkpoint, failed there. Was something wrong? The Python-only `sensitivity.py` answers by training the **same Python code** twice, once as is and once with a single starting weight changed by **10⁻¹²**:

```text
--8<-- "docs/part35/code/sensitivity_out.txt"
```

A change of one part in a trillion in one weight is invisible for the first 60 steps and then **grows until the two runs differ completely**: at step 100 the loss is 0.035 in one run and 0.21 in the other; at step 200 the held-out loss is 0.0088 in one and **0.155** in the other. Two *correct* implementations differ at about that level (different order of floating-point operations), so exact agreement cannot be expected after the transition. What this does and does not mean:

- **The backward pass is right** (all 16 gradient matrices equal the reference at three starting points, to 10⁻⁵, and agree with finite differences), and the training agrees digit for digit while the run is still stable. Divergence after the transition is a property of the training, not of the gradient.
- **Where the check cannot compare, it checks claims instead:** from step 150 on, the program's loss must be below 0.01 with 64 of 64 right; and the final result is judged by the experiment's claims. The `--` lines in the output below are the values left uncompared.
- **"256 of 256" is a statement about this particular run**, not about the model class. The nudged Python run has the same training loss to within 0.0002 and a held-out loss 18 times larger.

## How reliable is this? A Python-only sweep

`lr_sweep.py` (plain Python, not `mgc`) trains for 200 steps with four learning rates and four starting-weight seeds, and reports the final training loss and the number correct of all 256 scored predictions:

```text
--8<-- "docs/part35/code/lr_sweep_out.txt"
```

- **Learning rate 1.0 (the page's) always drives the training loss below 0.005**, but the number correct over all 64 sequences is 256, 239, 249, 239: **seed 1, the page's, is the best of the four.** A model can fit all 16 training sequences and still be wrong on 5 to 7% of the scored predictions the data never showed.
- **0.25 and 0.5 are slower** and do no better on unseen sequences (225–239 at 0.25; 189–249 at 0.5, where one seed's training loss is still 0.049). The sweep did not run longer.
- **2.0 does not learn at all** (loss above 0.7 after 200 steps; no overflow, it just does not settle).
- Seeds differ, and (as the sensitivity table shows) so can two correct implementations on one seed. With 16 training sequences out of 64, which sequences are held out is a further source of variation that was not varied.

## Mistakes the compiler reports

```text
--8<-- "docs/part35/code/examples_out.txt:143:170"
```

A mask of the wrong size for its scores, a call with a missing argument, and a row-selection column that does not match the stacked rows. As always, the shapes are types.

## Tests

Three new `lit` files in `test/lm35/` (the suite is now 141 tests; no `verifiers` or `ir` test because no compiler operation was added):

| Test | What it checks |
|---|---|
| `examples` | the two small examples (worked out above) and the loss and correct count of the 10-step training run |
| `errors` | the three mistakes give the exact messages |
| `against-reference` | `check_lm.py` in its quick mode, below (about 25 seconds). The 200-step run is not in CI because it takes about 8 minutes; `check_lm.py --full` runs it |

`check_lm.py` compares with an **independent** Python implementation (plain lists, one sequence and one position at a time; every gradient derived element by element) and checks, in order:

1. **The gradients,** for three starting-weight sets: the loss and all 16 gradient matrices equal the reference's, and for the first set **two weights of every matrix** (the first, and the one with the largest gradient: 32 weights) agree with a finite-difference estimate (step 0.001). Checking every one of the 648 would take 1,296 more forward passes in one program and has not been done.
2. **Training:** loss and correct count at the checkpoints up to step 50 (and, in the quick mode, up to step 10), the held-out loss and count, the four chunk counts and the attention pattern equal the reference's; every attention row sums to 1 and puts exactly 0 after the diagonal.
3. **The experiment (`--full`):** the 200-step run fits the training sequences (loss below 0.002), gets all 16 held-out and all 64 possible sequences right, with the later checkpoints held to their claims rather than to digits.

```text
--8<-- "docs/part35/code/check_lm_out.txt"
```

**A repaired check.** The finite-difference check first failed (largest difference 2.8·10⁻³ against a threshold of 10⁻³). The gradient was not wrong: the loss is about 1.4 and `mgc` prints six significant digits, so each printed loss carries an error of about 5·10⁻⁶, which divided by the step 0.002 becomes about 2.5·10⁻³. The program now forms the **difference** of the two losses inside Mountain Goat and prints that, so that the six digits are spent on the small difference, and the largest difference fell to 1.6·10⁻⁴.

### Are the checks good enough? Run eighteen wrong programs.

`model_mutation.py` writes eighteen versions of the program, each with one mistake, and runs the quick checker on each:

```text
--8<-- "docs/part35/code/model_mutation_out.txt"
```

Seventeen of eighteen are caught. What the pattern shows:

- **Thirteen are mistakes in the backward pass alone** (the three layer-norm errors, softmax's missing row-sum correction, the dropped `1/√8` in `dq`, `dk` without the transpose, the loss gradient not masked to the scored rows, `1/32` instead of `1/64`, the ReLU mask omitted or reversed, the residual dropped from `dx1` or from `dx0`, the value path dropped from `du1`). Each is caught by the reference gradient **and by the finite differences**, which see only the loss.
- **The forward-only changes are caught by the reference, not by finite differences.** The forward pass with no mask (every position sees all 112 rows) is also caught by the mask check and the training run; the layer-norm epsilon of 0.1 in forward **and** backward is consistent with itself, so finite differences cannot see it, and only the comparison with the reference does (as in Chapter 34). The wrong learning rate changes only training, and only the comparison of the training run notices.
- **A caveat about one line.** The mutant that drops the position vectors from the forward pass is reported as caught by finite differences too; that is partly an artifact of the mutation script, which changed the program's main forward pass but not the perturbed copies used for the embedding's finite differences. It is caught regardless, by the reference.
- **One is NOT CAUGHT: the softmax without the row-maximum subtraction.** It is algebraically the same function, and with scores of this size (and the masked entries `exp(−10⁹) = 0` exactly) it gives the same numbers. The reason for subtracting the maximum is to avoid overflow for **large** scores, and no check here has large scores. This is a gap in the checks, not in the program: a test with scores of a few hundred would catch it, and none was written.

There is no compiler-mutation run for this chapter: no compiler code changed.

The full suite:

```text
--8<-- "docs/part15/code/run_out_141.txt"
```

## Limits and what is not established

- **One toy language.** Seven tokens, four symbols, a rule that a single attention head can implement by looking two positions back. The result does not show that the model could learn anything harder, and nothing was tried on text.
- **Not Chapter 30's transformer.** This model has **one** head, **one** block and a single `D = 8` width. Chapter 30's has two heads and a different layout; **its backward pass is still not derived and its weights are still random.** Two heads and stacked blocks need a split-and-merge of heads in the backward pass and a second set of residual paths, not done here.
- **The result is one run in a chaotic regime.** The measured sensitivity (a 10⁻¹² nudge changes the step-100 loss by a factor of six) means this exact run cannot be reproduced digit for digit by a differently ordered computation after about step 70. In the sweep's 12 runs at rates 0.25 to 1.0 the training loss ends below 0.05, and the number correct of all 256 ranges from 189 to 256; **the 256 of 256 is the best case.** Whether the spread would narrow with more steps was not tested.
- **The mask-and-content question is open.** The attention pattern printed is for one all-identical sequence. That the model looks two positions back is shown there; that it copies the *content* it finds there is only indirectly supported by 256 of 256 correct predictions on all 64 sequences, and the attention for other sequences was not looked at.
- **Finite differences cover two weights per matrix,** 32 of 648, for one starting-weight set; the gradient-versus-reference comparison covers all of them for three. The agreement is limited to about 10⁻⁴ by the step and the printed digits.
- **The softmax-without-max gap** (above) means overflow robustness is untested.
- **The training program is large and slow.** 12,455 lines and about 8 minutes (one measurement, this container) because the compiler has no loops over steps for this program shape, no common-subexpression elimination, and never frees temporaries. That is a limitation of this compiler, not of the method; no attempt was made to speed it up.
- **Generation is not shown.** The model is trained to predict the next token; this chapter does not sample from it or measure tie-breaking, which Chapter 32 did for a bigram model.
- **Platform:** x86-64 Linux, LLVM 18.1.3.

## Reproducing

```sh
cd docs/part32/code && ./build.sh
cd ../../part35/code
python3 make_examples.py && ./run_examples.sh > examples_out.txt
./check_lm.py --full > check_lm_out.txt
./sensitivity.py > sensitivity_out.txt
./lr_sweep.py > lr_sweep_out.txt
./model_mutation.py > model_mutation_out.txt
cd ../../part15/code && ./run_lit.sh          # 141 tests
```

## Chapter summary

- A one-block, one-head, causal transformer language model (embeddings, layer norms, attention, feed-forward, residuals, vocabulary projection; 648 weights) is trained in Mountain Goat by hand-derived backpropagation. The task is to repeat a triple; after 200 steps the loss is 0.0009 and every scored prediction on all 64 possible sequences (256) is right, with attention that looks two positions back.
- New pieces: 16 sequences stacked into 112 rows with a block-diagonal causal mask; a cross-entropy that counts only scored rows; the attention backward pass through the mask (it needs no extra term); the three-path gradient into the layer norm; and the embedding gradient `transpose(x) @ dx0`.
- All 16 gradient matrices equal an independent per-position Python calculation at three starting points; 32 weights agree with finite differences (after a repair to the check, reported above).
- Training is **chaotic**: a 10⁻¹² change in one weight changes the loss at step 100 by a factor of six, so the run agrees with the reference digit for digit only up to about step 50 and is checked by its claims afterwards. The 256 of 256 is the best of four seeds (256, 239, 249, 239).
- Eighteen wrong programs were run through the checker: seventeen caught, one not (softmax without the row-max subtraction, which only matters for large scores).

## Self-check questions

Each answer is collapsed; try the question first.

1. Why does the attention backward pass need no extra term for the causal mask?

    ??? note "Answer"
        The mask is a constant added to the scores before the softmax, so it has no gradient of its own. The masked entries of the attention matrix `a` are exactly 0 (softmax of −10⁹), and `ds = a * (da − row_sum(a * da))` is a product with `a`, so `ds` is exactly 0 there: nothing flows back to positions that were not seen. The mask is already inside `a`.

2. The embedding is a lookup, yet its gradient is written `transpose(x) @ dx0`. Why does that work?

    ??? note "Answer"
        `x` has one 1 per row, in the column of that row's token. `transpose(x) @ dx0` gives row *t* = the sum of the rows of `dx0` over the positions whose token is *t*: a scatter-add. That is the gradient of a lookup: a token used in several places receives the sum of the gradients from all of them, and a token not used receives zero.

3. Why are the 16 sequences stacked into one 112×112 attention instead of being processed one at a time?

    ??? note "Answer"
        Mountain Goat has only rank-2 matrices, no batch dimension; stacking is the way to process several sequences in one program, and the mask (block-diagonal as well as causal) prevents any row from attending to another sequence. The price is that the score matrix is 112×112, 16 times larger than 16 separate 7×7 matrices would need, mostly entries that the mask zeroes.

4. At step 100 the program's loss is 0.0356 and the Python reference's is 0.0346. Is the program wrong?

    ??? note "Answer"
        No evidence says so. The two agree to six digits up to step 50, all 16 gradient matrices agree at three starting points, and `sensitivity.py` shows that the same Python code, with one weight changed by 10⁻¹², goes from 0.0346 to 0.2115 at step 100. The training is chaotic after about step 70, so two correct implementations whose floating-point operations are ordered differently will not agree digit for digit there. This is why the check compares claims instead of digits from step 100 on.

5. The sweep shows 256, 239, 249, 239 correct for the four seeds at learning rate 1.0. What does that say about the "256 of 256" result?

    ??? note "Answer"
        That it is the best of the four runs, not typical: the model reliably fits its 16 training sequences (loss below 0.005 in all four) but generalizes to the other 48 sequences only 93% to 100% of the time, depending on the starting weights. "The model learns the task" is true of the training; "the model has found the rule" is true of some runs and only approximately of others.

6. One mutant, softmax without the row-maximum subtraction, was not caught. Does that mean the checks are wrong?

    ??? note "Answer"
        No, it means they have a gap. Without the subtraction softmax is the same function, and for scores of this size the numbers are the same; the subtraction exists to prevent overflow of `exp` for large scores. None of the checks uses large scores, so none can tell the two apart. A test with scores in the hundreds would catch it; none was written, and the page says so rather than counting the mutant as caught.

7. Why was every intermediate result bound with its own `let`, instead of writing each gradient as a function as in Chapter 34?

    ??? note "Answer"
        Because Mountain Goat expands a function call in place wherever it is used, so a quantity used by several later gradients is recomputed for each, and the work multiplies with depth; the generated code also never frees memory. The nested version was killed, most likely for lack of memory. Binding each intermediate with `let` computes it once.
