# 32. Does It Generalize? Held-Out Data, Overfitting, Weight Decay and Greedy Generation

<p style="text-align:center"><img src="../assets/goats/ch-32.svg" alt="Mountain goats on the mountain in spring" style="max-width:100%;height:auto;border-radius:6px"></p>

**What you will understand:** the difference between a model that *fits* its data and one that *generalizes*, shown on the bigram model of Chapter 31. Chapter 31 measured the model only on the pairs it trained on. Here some pairs are **held out**, and the held-out loss shows what the training loss hid: the model gets steadily better on its training pairs while getting steadily **worse** on pairs it has not seen, until it is worse than a model that knows nothing. **Weight decay** (a penalty on large weights) fixes most of it, at a price, and a penalty that is too strong for the learning rate does not merely fail: it blows up. Finally the model **generates** text, by repeatedly choosing its most likely next token, which needs one new operation: a comparison, `ge`.

**What you need to know first:** Chapter 31 (the bigram model, cross-entropy loss and its hand-derived gradient). Nothing else is new except the comparison `ge`.

!!! tip "Compile and run"
    ```sh
    cd docs/part32/code && ./build.sh                 # once: the newest compiler (adds mg.ge)
    python3 make_examples.py                          # (re)writes the examples from generalize.mg.defs.in
    ./mgc run examples/02_train_and_validate.mg       # train with no weight decay; print train and held-out loss
    ./run_examples.sh > examples_out.txt              # every example and every error example on this page
    ./sweep.py > sweep_out.txt                        # the table: five weight-decay strengths, run through mgc
    ./check_generalize.py                             # the programs against the reference and against facts about the data
    ./model_mutation.py > model_mutation_out.txt      # runs 11 WRONG trainers through the checker
    ./mutation.sh > mutation_out.txt                  # breaks the compiler on purpose, six ways
    cd ../../part15/code && ./run_lit.sh              # the whole test suite
    ```
    Every listing and output on this page comes from these commands.

!!! note "Why this page shows divergence, FAIL lines and error messages, and why that is good"
    Example 4 is **supposed** to blow up (losses of 10<sup>58</sup>): it shows what a too-strong penalty does. The three error examples are programs the compiler must reject. The mutation outputs are negative controls, where "caught" is the wanted result and "NOT CAUGHT" would be a gap.

## The new operation: `ge`, a comparison

Choosing the most likely token means finding the largest entry of a row, and the language had no way to *compare*. `ge(a, b)` is `1` where `a >= b` and `0` where it is not, elementwise, with the same broadcasting as `+ - * /` (Chapter 22). It is a real operation: `mg.ge` in the dialect with a shape verifier, a loop nest that does a floating-point compare and selects `1.0` or `0.0`, and a built-in in the front end. (It is a function, not an operator, because the language has no comparison operators yet; and a scalar threshold must be written as a `1x1` matrix, such as `[[0.5]]`.)

```text
--8<-- "docs/part32/code/examples_out.txt:1:26"
```

The first matrix marks which entries are at least 2. The second compares a `2x1` column with each row (row 0 against 2, row 1 against 9). The third is the useful one: comparing a row with **its own maximum** (`row_max` gives the `2x1` column of maxima) gives a one-hot row marking where the maximum is: `[0, 1, 0]` and `[1, 0, 0]`. The fourth shows what a tie does: both `0.5`s reach the maximum, so there are two 1s. The last compares with a threshold written as `[[0.5]]`.

## The split

Chapter 31 used all 14 (current, next) pairs of the text `0 1 2 0 1 3 0 1 2 0 2 3 0 1 4`. Now the first 10 **train** the model and the last 4 are **held out**: used only to measure it, never to change a weight.

| | pairs (current → next) |
|---|---|
| training (10) | 0→1, 1→2, 2→0, 0→1, 1→3, 3→0, 0→1, 1→2, 2→0, 0→2 |
| held out (4) | 2→3, 3→0, 0→1, 1→4 |

Two of the held-out pairs, **2→3** and **1→4**, never occur among the training pairs: in the training data token 2 is only ever followed by token 0, and token 1 never by token 4. The other two, 3→0 and 0→1, do occur. This is the whole point of the experiment: how does a model do on cases its training data never showed?

## The definitions

```text
--8<-- "docs/part32/code/generalize.mg.defs.in"
```

(`@LAMBDA@` and `@HALF_LAMBDA@` are filled in by `make_examples.py` with the strength of the penalty, `0` for no weight decay.) Read it top to bottom: the loss on the 10 training pairs and on the 4 held-out pairs, written separately because a function's shapes are fixed; the surprise of each held-out pair on its own; the gradient with an extra `w * λ` term; the step; the penalised objective (used only to check the gradient); and `next_token`, which turns a one-hot row into the one-hot row of the likeliest next token with the comparison from above.

## Experiment 1: train, and watch two losses

`examples/02_train_and_validate.mg` is the definitions with strength 0, the data, 400 unrolled `step` lines, and then the **training loss and the held-out loss** at nine checkpoints, followed by the final weights, the surprise of each held-out pair, and the probabilities:

```text
--8<-- "docs/part32/code/examples_out.txt:30:84"
```

Read the loss pairs two at a time (training, then held-out):

| after step | 0 | 1 | 5 | 10 | 25 | 50 | 100 | 200 | 400 |
|---|---|---|---|---|---|---|---|---|---|
| training loss | 1.609 | 0.833 | 0.519 | 0.467 | 0.436 | 0.426 | 0.421 | 0.418 | **0.417** |
| held-out loss | 1.609 | 1.482 | 1.946 | 2.238 | 2.666 | 3.004 | 3.346 | 3.691 | **4.036** |

The training loss falls at every checkpoint, to 0.417, which is exactly what training is supposed to do. The held-out loss improves for one step (1.609 to 1.482) and then **rises at every checkpoint**, to 4.036. After 400 steps the model is *worse on the held-out pairs than before training began*: 4.036 against 1.609, the loss of a model that thinks every token equally likely. This is **overfitting**: the model has learned its training data too well and learned nothing that carries beyond it.

The vector of per-pair held-out surprises says why: `8.07`, `0.0025`, `0.288`, `7.78`. For the held-out pair 0→1, which the training data showed, the surprise is a modest `0.288`; for 3→0, also seen, it is `0.0025`, essentially none. But 2→3 costs `8.07` and 1→4 costs `7.78`: the pairs the training data never showed. The model believes (probability about 0.0003 to 0.0004, bottom matrix) that token 2 is never followed by 3 and token 1 is never followed by 4, because in its training data they never were. The two unseen pairs account for 15.85 of the 16.14 total surprise, 98% of the held-out loss. And the longer it trains, the more certain it becomes that those pairs are impossible: the weights for the unseen entries keep drifting down (to about −2.8) and the surprise grows with them, which is why the held-out loss climbs forever.

## Weight decay

The cure is to stop the model from becoming so sure. **Weight decay** adds a penalty to the loss: `(λ/2)` times the sum of the squares of all the weights. A weight far from 0 now costs something, so the model only keeps a large weight if the data pay for it. The penalty's gradient is `λ · w`, which is the extra term in `gradient`, and each step now also pulls every weight a little toward 0 (that is where the name comes from). `λ` is the **strength**. The same training run for several strengths, every number from an `mgc` run (`sweep.py`):

```text
--8<-- "docs/part32/code/sweep_out.txt"
```

The table is the whole story:

- **No penalty (`0`):** training loss 0.417, held-out loss 4.036, weights up to 6.5.
- **Increasing the strength lowers the held-out loss** (4.04, 2.68, 1.85, **1.475**) **and raises the training loss** (0.417, 0.435, 0.534, 0.960), while the largest weight shrinks (6.5, 4.2, 2.6, 1.1). That trade is **the price of generalizing**: the model fits the training pairs less tightly and the unseen pairs less badly.
- At `0.1` the held-out loss is **1.475, below the 1.609 of a model that knows nothing**: this model, unlike the unpenalised one, has learned something that helps on pairs it has not seen. Its probabilities show why (`03_weight_decay.mg`, final matrices):

```text
--8<-- "docs/part32/code/examples_out.txt:125:142"
```

  The weights stay between about −0.43 and 1.08. After training, token 0 is followed by token 1 with probability about 0.48 (the training data said 3 out of 4, 0.75) and unseen successors keep real probability (about 0.11 each, rather than 0.0003). The held-out surprises are now `2.04`, `1.03`, `0.73`, `2.10`: nothing is certain, and nothing costs 8.
- The held-out loss with a penalty **stops changing after enough steps** (for `0.1`, from step 50): the penalty and the data pull against each other and settle, unlike the unpenalised run which never settles.

### A penalty too strong for the learning rate

The last row of the table is `0.3`, and it is not a trade-off, it is a failure. Look at what the penalty does on its own: a step of weight decay turns `w` into `w − 8 · 0.3 · w = −1.4 · w`. The weights are multiplied by −1.4, which is *larger* than 1 in size: every step overshoots zero and lands farther away than it started, on the other side. The condition for a decay step to shrink the weights is `|1 − learning rate × strength| < 1`, that is, `learning rate × strength < 2`; here `8 × 0.3 = 2.4`.

```text
--8<-- "docs/part32/code/examples_out.txt:146:182"
```

The held-out loss goes 1.48, 5.19, 36.97, 5515, 2.6·10<sup>7</sup>, 5·10<sup>14</sup>, 2·10<sup>29</sup>, 4·10<sup>58</sup>: it is multiplied by a huge factor every few steps. This is **not** a compiler bug: the plain-Python reference run produces the *same* numbers (the checker requires it). It is what this algorithm does with these settings. The fix is a smaller strength or a smaller learning rate: with the same strength `0.3` and a learning rate of 4 the plain-Python reference trains stably (training loss 1.27 and held-out loss 1.51 after 400 steps; this one run was done in Python, not through `mgc`). The condition `learning rate × strength < 2` is necessary, not sufficient: strength `0.2` with learning rate 8 satisfies it (the decay factor is −0.6) but the reference still ends with a training loss of 3.55, because the data term adds curvature of its own, which is why it was left out of the stable list.

## Greedy generation

The trained model can now produce text. Start from a token; look up its row of probabilities; choose the likeliest next token; repeat. With `ge`, "choose the likeliest" is `next_token(x, p) = ge(x @ p, row_max(x @ p))`: `x @ p` picks the current token's row, and comparing it with its own maximum gives the one-hot row of the likeliest token. To read the token as a number, multiply by the column `[[0], [1], [2], [3], [4]]`: a one-hot row times it is the token's number. `examples/05_generate.mg` trains with strength 0.1 and generates 8 tokens from token 0:

```text
--8<-- "docs/part32/code/examples_out.txt:202:229"
```

The matrix is the model's probabilities. The nine numbers after it are the generated text: `0 1 2 0 1 2 0 1 2`. Greedy generation follows the most likely arrow each time: 0 is most likely followed by 1 (0.48), 1 by 2 (0.40), 2 by 0 (0.48), and so it goes around the cycle 0 → 1 → 2 → 0 forever. That is typical of greedy decoding from a bigram: **a model that only ever picks the most likely next token falls into a loop** (a real language model avoids it by sampling or by looking at more context). The program gives the same chain as an independent Python decoder for every starting token 0 to 3.

### A tie

Starting from token 4 shows the limit of using a comparison as an argmax. Token 4 is never a current token in the training pairs, so its row is exactly uniform: every token is equally likely, and every entry ties with the maximum.

```text
--8<-- "docs/part32/code/examples_out.txt:231:246"
```

The first step from token 4 is the number `10`: the mask is `[1, 1, 1, 1, 1]` (all five tokens tie) and `0+1+2+3+4 = 10`. It is not a token at all, it is the sum of five. The next step then multiplies that all-ones row by the probabilities (summing their rows), and its largest column is token 0. So from a tie the program does not fail, it produces a mask with several 1s and carries on with a meaningless state. A tie can only be broken by a rule the language does not have (take the first, or sample).

## Mistakes the compiler reports

```text
--8<-- "docs/part32/code/examples_out.txt:248:272"
```

`ge` of a bare number; `ge` of shapes that do not broadcast (the message says `compare`); and the held-out pairs (4 rows) passed to the training loss written for 10. The last is exactly the mistake the split invites, and the compiler catches it.

## Tests

Five new `lit` files in `test/generalize32/` (the suite is now 132 tests):

| Test | What it checks |
|---|---|
| `examples` | `ge` (worked out by hand) and the numbers this page quotes from the training runs, including the held-out pair surprises, the final weights at strength 0.1, the divergence, the generated chain and the tie |
| `errors` | the three mistakes give the exact messages |
| `verifiers` | `mg.ge` given operands of different shapes is rejected by the dialect |
| `ir` | `ge` is one `mg.ge`; a `2x1` operand is first stretched by an explicit `mg.broadcast` |
| `against-reference` | `check_generalize.py`, below |

`check_generalize.py` compares everything with an **independent** Python trainer (plain lists, `math.exp`, `math.log`, the gradient written per training pair) and checks facts that must be true whatever the code looks like:

1. **Training.** For each strength, the training and held-out loss at all nine checkpoints, and the final weights, probabilities and per-pair surprises, equal the reference's.
2. **The unstable strength.** The program and the reference blow up *identically* (same losses at every checkpoint), and the loss grows without bound.
3. **Overfitting.** Without weight decay the training loss falls at every checkpoint, the held-out loss *rises* at every checkpoint from step 5 on, and ends well above where it started.
4. **Why.** The two held-out pairs that never occur in the training pairs are found by the script (not assumed), have surprises above 4 while the others have surprises below 1.5, and carry more than 90% of the held-out loss.
5. **Weight decay.** Every positive stable strength gives a lower held-out loss than none; a stronger strength gives a higher training loss and smaller weights; the strength with the lowest held-out loss is the same for the program and the reference.
6. **The gradient** with weight decay equals a finite-difference estimate of the *penalised objective* (step 0.01) for two strengths and two random weight matrices each, to within the printing precision.
7. **Generation.** From every starting token, the 8 generated tokens equal the reference's most-likely chain, and the tie from token 4 gives the documented `10`, then the largest column sum.

```text
--8<-- "docs/part32/code/check_generalize_out.txt"
```

### Are the checks good enough? Run eleven wrong trainers.

```text
--8<-- "docs/part32/code/model_mutation_out.txt"
```

All eleven are caught. Several are caught by *different kinds* of check, which is the point of having both a reference and properties: a wrong weight-decay sign or a missing penalty is caught by the reference and by "weight decay lowers the held-out loss"; the penalty written as λ instead of λ/2 is invisible to every training comparison (the *gradient* is still right) and is caught only by the finite-difference check against the objective; the two wrong `next_token`s are caught by the generation check. The last mutation (a naive log-softmax) is the surprise: I expected it to go uncaught, because every normal run keeps its weights below 7 where `exp` cannot overflow. It is caught only by the deliberately diverging run, whose weights reach 10<sup>58</sup>. That is an accident of another check, not evidence that this chapter tests numerical stability (Chapter 31's stress case does).

### Compiler mutations

`ge` is a new compiler operation, so the compiler is also broken on purpose, six ways:

```sh
--8<-- "docs/part32/code/mutation.sh"
```

```text
--8<-- "docs/part32/code/mutation_out.txt"
```

All six are caught. As in Chapters 30 and 31 the verifier mutation is caught only by the dedicated `verifiers` test, and the last mutation (a sum that starts from 1) is not about `ge` at all: it breaks `row_sum`, which the loss and the softmax lean on. Two details specific to `ge`: the `>` mutation is the interesting one for generation, because a maximum is no longer greater than *itself*, so the mask is all zeros and the generated tokens collapse to 0; and "returns 2 where true" would pass a test that only looked at which entries are non-zero, which is why the examples check the values.

The full suite:

```text
--8<-- "docs/part15/code/run_out_132.txt"
```

## Limits and what is not established

- **Tiny data, so the numbers illustrate a mechanism and nothing more.** Ten training pairs and four held-out pairs. "The held-out loss is 1.475" is a measurement on four pairs, two of which the model had no way to predict. Nothing here says how any of this behaves on real text.
- **The strength was chosen by looking at the held-out loss.** The best strength (`0.1`, from a list of four) is the one with the lowest held-out loss, so that held-out loss is a *selected* number, optimistic by construction. An honest estimate needs a third set of data used only once, after the choice. There is none here.
- **A bigram still sees one token.** Weight decay does not give the model any context; it only stops the model being over-confident about what it has seen. The best it can do on this held-out set is still limited by the unseen pairs.
- **Unseen pairs are handled by shrinking, not by knowing.** At `0.1` the unseen successors get probabilities near 0.1 because the penalty stops the weights growing; that is a side effect of regularization, not a model of what is likely. Other ways of handling unseen events (smoothing counts, using more data) are not tried.
- **Weight decay was one remedy of several.** Early stopping (the held-out loss was lowest after one step, 1.482) was visible in the numbers but not implemented as a rule; more data, smaller models and other penalties are not compared.
- **The stability condition `learning rate × strength < 2`** is derived for the penalty on its own. The full condition also involves the data term's curvature (strength 0.2 with learning rate 8 satisfies the penalty-only condition and still trains badly: training loss 3.55 in the Python reference); it was checked here only by running a handful of settings, not proved.
- **Greedy generation loops, and ties are not handled.** `ge` marks every maximum, so a tie gives several 1s (shown, not fixed). There is no sampling (no random numbers in the language) and no stopping token.
- **The comparison `ge` is a function, not an operator,** has no less-than, equal or not-equal siblings, and takes only matrices (a threshold is a `1x1` matrix). NaN compares false.
- **Six digits.** `mgc` prints six significant digits; comparisons with Python are at a relative `10⁻⁵`, and the finite-difference check at `2·10⁻³`.
- **The transformer of Chapter 30 is still untrained,** and none of this chapter's training is applied to it.
- **Platform:** x86-64 Linux, LLVM 18.1.3.

## Reproducing

```sh
cd docs/part32/code && ./build.sh
python3 make_examples.py && ./run_examples.sh > examples_out.txt
./sweep.py > sweep_out.txt
./check_generalize.py > check_generalize_out.txt
./model_mutation.py > model_mutation_out.txt
./mutation.sh > mutation_out.txt
cd ../../part15/code && ./run_lit.sh          # 132 tests
```

## Chapter summary

- A model can fit its training data and still fail on data it has not seen. With the bigram model, the training loss fell to 0.417 while the held-out loss rose to 4.036, worse than the 1.609 of a model that knows nothing, because two of the four held-out pairs never occurred in training and the model learned to treat them as impossible.
- Weight decay (a penalty on large weights, whose gradient is `λw`) trades training loss for held-out loss: at strength 0.1 the training loss is 0.960 and the held-out loss 1.475, now better than knowing nothing.
- A penalty that is too strong for the learning rate does not just underperform: when learning rate × strength exceeds 2, every step overshoots and the weights grow without bound, in exactly the same way in an independent Python implementation.
- One new operation, `ge`, a comparison, gives the one-hot row of the likeliest token, and with it a trained model generates text. Greedy generation from a bigram loops (here 0 1 2 0 1 2 …), and a tie breaks the one-hot mask.
- Eleven wrong trainers and six broken compilers are all caught; the one wrong trainer I expected to go uncaught was caught, by the diverging run, which is reported as such.

## Self-check questions

Each answer is collapsed; try the question first.

1. Why did the held-out loss in Experiment 1 first fall (1.609 to 1.482) and then rise?

    ??? note "Answer"
        In the first steps the model learns the broad facts that help on any pair (token 0 is usually followed by 1, token 3 by 0), which lowers the loss on seen pairs in the held-out set. After that, nothing helps the held-out set further, but training keeps pushing the weights for unseen successors lower to make the training pairs fit better. That makes the model more and more certain that the unseen held-out pairs are impossible, and the surprise at them grows without limit.

2. Why is a held-out loss of 4.036 *worse than knowing nothing*, and what is "knowing nothing" here?

    ??? note "Answer"
        A model that assigns every token the probability 1/5 has loss `log 5 = 1.609` on any data. The trained model has loss 4.036 on the held-out pairs, which means that on average it gives the true next token a probability of only `e^−4.036 = 0.018`, far below 1/5. It is confidently wrong about the unseen pairs, which costs more than being unsure about everything.

3. Why does weight decay lower the held-out loss but raise the training loss?

    ??? note "Answer"
        The penalty stops weights from growing large, so the model cannot become as certain as the training data alone would make it. That keeps probabilities for unseen pairs away from 0 (good for held-out data) and also stops the model from fitting the training pairs as tightly as it could (worse training loss). Training loss is exactly the quantity that rewards memorizing, so any force against memorizing raises it.

4. Why does a strength of 0.3 diverge with learning rate 8, and what would make it stable?

    ??? note "Answer"
        A weight-decay step multiplies each weight by `1 − learning rate × strength`. With 8 and 0.3 that is `1 − 2.4 = −1.4`: the weights change sign and grow by 40% each step. Stability needs `|1 − learning rate × strength| < 1`, i.e. `learning rate × strength < 2` (for the penalty alone). The penalty alone shrinks the weights when the factor is smaller than 1 in size, e.g. a learning rate of 4 with strength 0.3 (factor −0.2; the Python reference trains stably there). But the condition is only necessary: strength 0.2 with learning rate 8 has factor −0.6 and still ends with a training loss of 3.55 in the reference, because the data term adds curvature.

5. How does `ge(row, row_max(row))` find the largest entry, and what goes wrong with ties?

    ??? note "Answer"
        `row_max(row)` is the largest number in the row, and `ge` marks every entry that is greater than or equal to it, which is exactly the entries equal to the maximum. With one maximum the result is one-hot. With ties, every tied entry is marked, so the result has several 1s and is no longer a single token; in example 6 the all-equal row marks all five tokens.

6. Why must the checker discover which held-out pairs are unseen instead of assuming 2→3 and 1→4?

    ??? note "Answer"
        If the script hard-coded those pairs, a change to the data split or the text would silently make the explanation wrong while the check still passed. Computing "which held-out pairs occur among the training pairs" from the data ties the claim to the data, so it stays true or fails loudly.

7. The best strength was chosen by held-out loss. Why is that held-out loss then too optimistic?

    ??? note "Answer"
        The held-out set was used to *make a choice* (which strength to keep), so it is no longer an independent test: among several candidates, the one that looks best on this set partly looks best by luck. An unbiased estimate needs a third set that played no part in any choice, measured once at the end. With four held-out pairs the effect could be large.

8. In the divergence run, why does the checker insist that the *reference* diverges identically?

    ??? note "Answer"
        A blow-up could be a bug in the new operation or the compiler, or it could be what the algorithm does. If an independent plain-Python implementation of the same algorithm produces the same exploding numbers at every checkpoint, the cause is the algorithm and the settings, not the compiler. The match is the evidence.

9. Why does greedy generation from a bigram loop?

    ??? note "Answer"
        The next token depends only on the current token, and greedy decoding always picks the same most likely successor for a given token. Starting at token 0 the chain 0 → 1 → 2 → 0 closes after three steps, and since the rule is deterministic and sees nothing but the current token, it repeats forever. Breaking the loop needs randomness (sampling) or more context.

10. The wrong trainer with a naive log-softmax was caught by this chapter's checker. Was that for the reason Chapter 31's naive-softmax mutants were caught?

    ??? note "Answer"
        Not by the same check. Chapter 31 added a stress case with weights of ±1000 on purpose. Here the naive version produces the same numbers as the stable one for every run with normal weights (they stay below 7). It was caught only because of the deliberately diverging run, whose weights reach 10<sup>58</sup> and overflow `exp`. That was unplanned: I expected it to go unnoticed here, and it is reported as caught by an accident of another check, not as evidence that this chapter's checks test numerical stability.
