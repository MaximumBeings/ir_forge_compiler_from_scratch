# 31. Training a Language Model: Gradient Descent on a Bigram

<p style="text-align:center"><img src="../assets/goats/ch-31.svg" alt="Mountain goats on the mountain at midday" style="max-width:100%;height:auto;border-radius:6px"></p>

**What you will understand:** how a model *learns*, shown on the smallest language model there is, and how a Mountain Goat program trains it. The model reads one token and predicts the next. Training is gradient descent on the **cross-entropy loss**, with a gradient derived by hand, run for 400 steps, and every claim checked: the loss falls and cannot go below a bound that follows from the data, the model ends up predicting exactly the frequencies it saw, a token it never saw as input keeps exactly the weights it started with, and the hand-derived gradient agrees with a numerical estimate. Mountain Goat gets one new operation, `log`.

**What you need to know first:** Chapter 26 (gradient descent on a linear model; this chapter does the same with a softmax output), Chapter 29 (softmax) and Chapter 30 (what a transformer predicts). The model here is the simplest relative of Chapter 30's: it looks at one token instead of a whole sequence. Training the transformer itself is **not** done (see Limits).

!!! tip "Compile and run"
    ```sh
    cd docs/part31/code && ./build.sh                 # once: the newest compiler (adds mg.log)
    python3 make_examples.py                          # (re)writes the examples from bigram.mg.defs
    ./mgc run examples/04_training.mg                 # train: 400 gradient-descent steps
    ./run_examples.sh > examples_out.txt              # every example and every error example on this page
    ./check_bigram.py                                 # the trainer against the reference and against facts about the data
    ./model_mutation.py > model_mutation_out.txt      # runs 12 WRONG trainers through the checker
    ./mutation.sh > mutation_out.txt                  # breaks the compiler on purpose, six ways
    cd ../../part15/code && ./run_lit.sh              # the whole test suite
    ```
    Every listing and output on this page comes from these commands.

!!! note "Why this page shows nan, -inf, FAIL lines and error messages, and why that is good"
    Example 1 prints `-inf` and `nan` on purpose: they are what `log` of 0 and of a negative number are. The three error examples are programs the compiler must reject. The two mutation outputs are negative controls: wrong trainers and a deliberately broken compiler run against the checks, where "caught" is the wanted result and "NOT CAUGHT" would be a gap.

## The task

A **language model** assigns a probability to every possible next token given what came before. The *bigram* model looks at only the most recent token. It has a table `w` with one row per token and one column per possible next token; row *i* holds **scores** (logits) for what follows token *i*, and a softmax turns the row into probabilities.

The data is a 15-token text over five tokens, numbered 0 to 4:

```text
0 1 2 0 1 3 0 1 2 0 2 3 0 1 4
```

It contains 14 (current, next) pairs. Counting them gives the table the model should end up reproducing (rows are the current token, columns the next):

| current | next 0 | next 1 | next 2 | next 3 | next 4 | observed probabilities of the next token |
|---|---|---|---|---|---|---|
| 0 | 0 | 4 | 1 | 0 | 0 | 0.8 for token 1, 0.2 for token 2 |
| 1 | 0 | 0 | 2 | 1 | 1 | 0.5 for token 2, 0.25 for token 3, 0.25 for token 4 |
| 2 | 2 | 0 | 0 | 1 | 0 | 2/3 for token 0, 1/3 for token 3 |
| 3 | 2 | 0 | 0 | 0 | 0 | 1.0 for token 0 |
| 4 | 0 | 0 | 0 | 0 | 0 | (never a current token: no data) |

Token 4 appears only as the last token, so it never has a successor in the data. That is deliberate and will matter.

## The new operation: `log`

The loss needs a logarithm, which Mountain Goat did not have. `log(m)` takes the natural logarithm of every element, added the way `exp` and `sqrt` were: `mg.log` in the dialect with a shape verifier, a loop-nest lowering that uses `math.log`, and a built-in in the front end.

```text
--8<-- "docs/part31/code/examples_out.txt:1:25"
```

`log(1) = 0`, `log(e) = 1`, `log(10) = 2.30259`, and numbers below 1 have negative logs. `exp` undoes `log`. `log(0)` is minus infinity (no power of *e* is 0) and the log of a negative number is not a number. The last two lines show the property that makes logs useful for probabilities: `log(a·b) = log(a) + log(b)`; the product of probabilities becomes a sum, and the sum does not underflow.

## The loss: cross-entropy

How good is a model's prediction? For each pair, look at the probability the model gave to the token that *really* came next, call it *p*, and take **−log p**: the model's *surprise*. A probability of 1 costs 0; a probability near 0 costs a lot. The **loss** is the average surprise over the data.

```text
--8<-- "docs/part31/code/examples_out.txt:27:43"
```

Four cases over three tokens (the true token is always token 0): a model with no idea (uniform, 1/3 each) costs `log 3 = 1.0986`; a confident correct model (0.98) costs `0.0202`; a confident *wrong* model (0.01 on the right token) costs `4.605`, which is the steepest penalty; a coin flip between two costs `0.6931`. The loss is their average, `1.60428`. In the program, `y` is a one-hot row marking the true token, so `y * log(p)` keeps one number per case and `row_sum` picks it.

## The model and its gradient

The data go in as two `14x5` matrices of one-hot rows: `x` holds the current tokens and `y` the next tokens. Then `x @ w` is a `14x5` matrix of scores: since each row of `x` has a single 1, multiplying by it *selects* the matching row of `w`. The probabilities are the softmax of each row, and the loss is the average of `−log` of the right entry.

To learn, we need the **gradient**: how the loss changes when each of the 25 weights changes, since gradient descent moves every weight a little downhill. For one pair with scores `z`, probabilities `p = softmax(z)` and one-hot target `y`, the loss is `−log p_k` where *k* is the true token, and a short calculation gives

∂(−log p_k)/∂z_j = p_j − y_j

(the probability of each token, minus 1 for the true one). The scores come from `w` by `z = x_t · w`, so the pair's gradient on row *a* of `w` (where *a* is the current token) is that vector `p − y`. Summing the pairs and dividing by the 14 that were averaged gives, for the whole data set,

**gradient = xᵀ · (softmax(x · w) − y) / 14**

a `5x5` matrix. Nothing about that was found by a program: it is derived by hand, and only trusted because it is *checked* (below, against a numerical estimate). The step is `w ← w − (learning rate) · gradient`.

## One step, by hand

Before the full run, a case small enough to do on paper. Two tokens, four pairs (`0→1, 0→1, 0→0, 1→0`), weights zero (so every probability is 1/2), learning rate 1:

```text
--8<-- "docs/part31/code/examples_out.txt:45:71"
```

Row 0 of `w` sees three pairs: two push toward token 1 and one toward token 0, so its gradient is `[0.5, −0.5]/4 = [0.125, −0.125]`; row 1 sees one pair (`1→0`) and gets `[−0.125, 0.125]`. The step subtracts the gradient: each row moves toward the token that followed it more often, and the loss falls from `0.693147` (= log 2, a coin flip) to `0.638439`. You can reproduce that last number by hand: the new probabilities are `0.5622` and `0.4378`, and `−(2·ln 0.5622 + ln 0.4378 + ln 0.5622)/4 = 0.6384`.

## The definitions

The whole trainer, as functions:

```text
--8<-- "docs/part31/code/bigram.mg.defs"
```

`log_softmax` is the log of the softmax, computed as `s − max − log(sum(exp(s − max)))`. It is written this way rather than as `log(softmax(s))` for a reason that is easy to miss: a softmax probability can **underflow to exactly 0** when a score is far below the maximum, and the log of 0 is minus infinity, which times a 0 in `y` gives `nan`. The `log-sum-exp` form never builds the probability, so it cannot do that. The stress check below pushes it to scores of ±1000. `gradient` is the formula above, `step` subtracts it with learning rate 8, and `probabilities` is the softmax of the weight rows.

## Training

`examples/04_training.mg` is the definitions followed by the data and 400 `let w1 = step(w0, x, y)` lines (a generated file; it has no loop because the language has none, and each step is one call), then it prints the loss at ten checkpoints, the final weights, the final probabilities and the final gradient:

```text
--8<-- "docs/part31/code/examples_out.txt:73:114"
```

Read it in order:

- **The loss** starts at `1.60944`, which is exactly `log 5`: the model begins knowing nothing, so every token is equally likely (1/5), and the surprise is `−log(1/5)`. It falls at every checkpoint, quickly at first (`0.99` after one step) and then more slowly, to `0.613551` after 400.
- **It cannot fall below 0.612174.** That number is the **conditional entropy of the data**: the best average surprise any bigram model could possibly have, reached when each row of probabilities equals the *observed* frequencies in the table above. (A model cannot be less surprised than the data itself is random.) After 400 steps the loss is within `0.0014` of that floor.
- **The weights and probabilities.** The probabilities row by row: token 0 is followed by token 1 with probability `0.799476` (observed 0.8) and token 2 with `0.199474` (observed 0.2); token 1 by tokens 2, 3, 4 with `0.4996`, `0.2496`, `0.2496` (observed 0.5, 0.25, 0.25); token 2 by token 0 with `0.665791` (observed 2/3) and token 3 with `0.332455` (observed 1/3); token 3 by token 0 with `0.998244` (observed 1). The model has learned the table.
- **Zero counts are approached, never reached.** The probabilities for pairs never seen (such as token 0 followed by token 3) are about `0.00035`, not 0. The weights for those entries are `−2.8` and still drifting down: a softmax probability is exactly 0 only when its score is minus infinity. With more steps the numbers shrink without ever vanishing.
- **Row 4 never moved.** Token 4 is never a current token, so no pair pushes on its row: its gradient is exactly zero, its weights are exactly `0` after 400 steps, and its probabilities are exactly `0.2`, uniform. The model has no information about what follows token 4 and says so.
- **The final gradient** is small (about 10<sup>−4</sup>) everywhere and exactly 0 in row 4: nearly at the bottom, but still pulling very slightly.

## Mistakes the compiler reports

```text
--8<-- "docs/part31/code/examples_out.txt:116:147"
```

Thirteen rows passed where the data are 14; `log` of a bare number; and a 4-row weight matrix where `5x5` is required. As in earlier chapters the shapes are types: a trainer cannot be connected to the wrong-sized data or weights.

## Tests

Five new `lit` files in `test/bigram31/` (the suite is now 127 tests):

| Test | What it checks |
|---|---|
| `examples` | the `log`, cross-entropy and one-step examples (worked out by hand above) and the training run's outputs |
| `errors` | the three mistakes give the exact messages, with file and line |
| `verifiers` | `mg.log` given a result of a different shape is rejected by the dialect |
| `ir` | log-softmax is a max-reduce, exp, sum-reduce, `mg.log` of the row sums, in that order |
| `against-reference` | `check_bigram.py`, below |

`check_bigram.py` compares the Mountain Goat trainer with an **independent** Python trainer (plain lists, `math.exp`, `math.log`, with the gradient written from the definition of each pair's contribution rather than as a matrix formula), and checks facts that must be true whatever the code looks like:

1. **Training.** The loss at all ten checkpoints and the final weights, probabilities and gradient equal the reference's (to `mgc`'s six printed digits).
2. **The loss.** Strictly decreasing at the checkpoints; never below the conditional entropy; within 0.002 of it at the end; exactly `log 5` before training.
3. **What it learned.** Every trained probability is within 0.01 of the observed frequency, for every token that has a successor in the data.
4. **The unseen row.** Token 4's weights and gradient are exactly 0 and its probabilities exactly uniform.
5. **The gradient.** The hand-derived gradient agrees with a **finite-difference** estimate for three random weight matrices: for each of the 25 weights, the loss is computed with that weight raised and lowered by 0.01, and `(L₊ − L₋)/0.02` must match the gradient entry. The agreement is within about `4·10⁻⁴`, and the tolerance is `2·10⁻³`. It is not tighter because `mgc` prints the loss to only six digits, which limits a finite-difference estimate with step 0.01 to errors around a few times `10⁻⁵`, plus the estimate's own truncation error.
6. **Stress.** Weights of ±1000 (where `exp` overflows): no `nan` or `inf`, and the loss, gradient and probabilities equal the reference.

```text
--8<-- "docs/part31/code/check_bigram_out.txt"
```

### Are the checks good enough? Run twelve wrong trainers.

`model_mutation.py` writes twelve versions of `bigram.mg.defs`, each with one deliberate mistake (the gradient with the wrong sign, forgotten averaging, forgotten targets, the loss with the wrong sign, the naive log-sum-exp, the step uphill, and so on), and runs the checker on each:

```text
--8<-- "docs/part31/code/model_mutation_out.txt"
```

All twelve are caught. As in Chapter 30, **two were not caught at first**: the naive log-sum-exp (no maximum subtracted) and the naive softmax in `probabilities`. The first version of the stress check used weights of ±400, and `exp(400)` is large but still representable (overflow starts near 709), so a naive formula gave the right answer. Raising the stress weights to ±1000 made the naive versions produce `inf` and `nan`, and the script was re-run. A numerical-stability test must actually reach the instability.

### Compiler mutations

`log` is a new compiler operation, so the compiler is also broken on purpose, six ways:

```sh
--8<-- "docs/part31/code/mutation.sh"
```

```text
--8<-- "docs/part31/code/mutation_out.txt"
```

All six are caught. As in Chapter 30, the verifier mutation is caught only by the dedicated `verifiers` test (no program the front end writes can reach it), and the last mutation, a sum that starts from 1 instead of 0, is not about `log`: it breaks `row_sum` and `col_sum`, which the loss and the log-softmax lean on, so the training tests would also notice a regression in an operation from an earlier chapter.

The full suite:

```text
--8<-- "docs/part15/code/run_out_127.txt"
```

## Limits and what is not established

- **A bigram looks at one token.** It cannot represent "after `0 1` comes 2 but after `3 1` comes 4"; any context beyond the last token is invisible to it. It is the *simplest* language model, not a good one.
- **Training loss only.** All 14 pairs are used for training and the same 14 for the loss. The model has been shown to *fit* them (it reaches the entropy bound); nothing here measures how it would do on text it has not seen. With data this small, "learned the frequencies" is also "memorized the data".
- **Pairs never seen get tiny probabilities, not zero,** and token 4's successor is left uniform. A real model smooths or regularizes; this one does neither.
- **The gradient is derived by hand, for this model.** Mountain Goat has no automatic differentiation. Chapter 26 derived a linear model's gradient; here a softmax model's. **Training Chapter 30's transformer is not done:** that needs the gradient of every operation in it (attention, layer normalization, the residual connections, the feed-forward network) derived by hand, or an automatic differentiation system, and neither exists here. Chapter 30's weights remain random.
- **Full-batch gradient descent with a fixed learning rate of 8,** chosen by trying 4 and 8 on this data in plain Python (both converge; 8 is faster). No learning-rate schedule, no momentum, no minibatches, no stopping rule: it just runs 400 steps. The step size is stable here because rows of `w` are independent and the largest curvature is bounded; nothing says 8 is safe for other data.
- **No sampling or argmax.** The program prints probabilities. Choosing the likeliest next token, or generating text, would need an `argmax` or random choice the language lacks.
- **Six digits.** `mgc` prints six significant digits, so the comparisons with Python are at a relative `10⁻⁵`, and the finite-difference check can only be as sharp as printing allows (stated above).
- **`exp` and `log` come from the platform's C library;** their last-digit accuracy was not measured. GPU lowering is not covered.
- **Platform:** x86-64 Linux, LLVM 18.1.3.

## Reproducing

```sh
cd docs/part31/code && ./build.sh
python3 make_examples.py && ./run_examples.sh > examples_out.txt
./check_bigram.py > check_bigram_out.txt
./model_mutation.py > model_mutation_out.txt
./mutation.sh > mutation_out.txt
cd ../../part15/code && ./run_lit.sh          # 127 tests
```

## Chapter summary

- A language model predicts the next token; the bigram model looks at one token and keeps a table of scores per token. The loss is the average surprise, `−log` of the probability given to what really came next.
- With `log` added, training is a few lines of Mountain Goat: the gradient is `xᵀ(softmax(xw) − y)/14`, derived by hand, and a step subtracts it.
- The loss falls from `log 5` toward the entropy of the data and cannot go below it; after 400 steps the model's probabilities equal the observed frequencies to about 0.001, and a token with no successors in the data keeps exactly the weights it started with.
- Everything is checked against an independent Python trainer, against theory (the entropy bound), against finite differences, and under overflow-sized weights; twelve wrong trainers and six broken compilers are all caught, and two of the wrong trainers were caught only after the stress test was made big enough.
- It is a toy: one token of context, training loss only, hand-derived gradient. Training a transformer needs gradients Mountain Goat cannot yet produce for itself.

## Self-check questions

Each answer is collapsed; try the question first.

1. Why is the loss exactly `log 5 = 1.609438` before training?

    ??? note "Answer"
        All weights are 0, so every score is 0 and every softmax row is uniform: probability 1/5 for each of the five tokens. The surprise of any pair is `−log(1/5) = log 5`, and the average of equal numbers is the number itself.

2. What does it mean that the loss cannot go below 0.612174, and why is that the floor?

    ??? note "Answer"
        0.612174 is the conditional entropy of the data: the average of `−log(observed probability of the next token)` when each row of probabilities equals the observed frequencies. Among all ways to assign probabilities to the next token given the current one, matching the observed frequencies gives the smallest average surprise on this data (Gibbs' inequality); any other assignment is worse. A bigram model's rows are free, so it can reach but not beat that value.

3. Why are probabilities of unseen pairs (like 0 then 3) small but not exactly 0 after 400 steps?

    ??? note "Answer"
        A softmax output is `e^s / Σ e^s`, which is exactly 0 only if a score is minus infinity. Gradient descent keeps lowering the score (here to about −2.8) but each step makes a smaller change, so it only approaches zero. The loss never rewards going all the way: it is already almost at its floor.

4. Why does row 4 of the weights stay exactly 0, and what does the model say about the token after 4?

    ??? note "Answer"
        Token 4 is never a *current* token, so no row of `x` has its 1 in column 4, and the gradient `xᵀ(…)` has a zero row 4 (it is a sum over pairs, and no pair contributes). The step subtracts 0, so those weights stay at their starting value 0, and the softmax of a zero row is uniform: 0.2 each. The model has no information, and reports that rather than inventing something.

5. Why is `log_softmax` written as `s − max − log(sum(exp(s − max)))` instead of `log(softmax(s))`?

    ??? note "Answer"
        `softmax` produces probabilities, and a probability far below the maximum underflows to exactly 0; the log of 0 is minus infinity, and `y * (−inf)` with a 0 in `y` is `nan`. The log-sum-exp form never builds a probability, so it stays finite. It also subtracts the maximum before `exp`, so `exp` cannot overflow. The ±1000 stress check exercises both.

6. How does the finite-difference check work, and why is its tolerance only `2·10⁻³`?

    ??? note "Answer"
        For each weight, compute the loss with that weight raised by 0.01 and lowered by 0.01; the slope `(L₊ − L₋)/0.02` estimates the derivative, and it should match the gradient entry. The tolerance is loose because `mgc` prints the loss to six significant digits, so each loss value has an error around `10⁻⁶`, which divided by 0.02 is a few times `10⁻⁵`, and because the estimate itself has an error from the finite step. Observed differences are about `4·10⁻⁴`.

7. The gradient formula `xᵀ(p − y)/14` came from a hand derivation. What makes it trustworthy rather than a guess?

    ??? note "Answer"
        Two independent checks: it matches a numerical estimate that uses only the loss function (finite differences, which does not use the formula), and training with it reproduces an independent Python trainer step for step and ends at the known optimum (the observed frequencies, the entropy floor). A wrong formula (the wrong sign, a missing 1/14, forgotten targets) fails these, as the wrong-trainer runs show.

8. Why were two of the twelve wrong trainers missed at first, and what does that teach about testing numerical code?

    ??? note "Answer"
        The naive log-sum-exp and the naive softmax compute the same numbers as the stable versions whenever `exp` does not overflow. The first stress check used scores of ±400, and `exp(400)` is representable (overflow begins near 709), so both naive formulas were correct on every test. Scores of ±1000 overflow, giving `inf` and `nan`, and caught both. A test for a numerical-stability bug must reach the regime where the bug bites.

9. Why can a bigram model not represent "what comes after the pair `0 1`"?

    ??? note "Answer"
        Its prediction depends only on the current token: the row of `w` for token 1. In the data, token 1 is followed by 2, 3 and 4, and the model can only give the average over every occurrence of token 1, whatever came before it. Capturing the effect of the earlier token needs a model that sees more than one token at a time, which is what attention in Chapters 29 and 30 provides.

10. What would be needed to train the Chapter 30 transformer the way this chapter trained the bigram?

    ??? note "Answer"
        The gradient of the loss with respect to every weight in it: the embeddings, each head's query, key and value matrices, the output matrices, the layer-norm scales and shifts, the feed-forward weights and biases, and the final projection. That is the chain rule through softmax attention, layer normalization, relu and the residual connections, derived by hand for each, or an automatic differentiation system that does it from the program. Mountain Goat has neither, so Chapter 30's weights remain random numbers; the loss and the training loop of this chapter would carry over unchanged.
