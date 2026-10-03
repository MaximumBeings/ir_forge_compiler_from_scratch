# 26. Learning From Data: Gradient Descent in Mountain Goat

<p style="text-align:center"><img src="../assets/goats/ch-26.svg" alt="Mountain goats on the mountain at sunset" style="max-width:100%;height:auto;border-radius:6px"></p>

**What you will understand:** how a machine-learning model is trained, from the ground up, and how to do it with a language that has matrices but no loops. You will fit a straight line (a *linear regression*) to data by **gradient descent**: the repeated, small, downhill steps that train almost every neural network. The mathematics is written in Mountain Goat and compiled; a short C++ program supplies the loop, the data and the checks. The result is checked against a closed-form answer and against an independent C++ implementation, and the tests are tested by breaking the program seven ways.

**What you need to know first:** the [language tour](../tour/language-tour.md) (matrices, `@`, `transpose`, broadcasting), Chapter 21 (the arithmetic operations), Chapter 22 (reductions such as `col_sum`) and Chapter 20 (calling compiled Mountain Goat from C++). No machine-learning background is assumed.

!!! tip "Compile and run"
    ```sh
    cd docs/part24/code && ./build.sh               # once: the newest compiler (Chapter 24's mg-opt)
    cd ../../part26/code
    cpp/run.sh                                      # compile gd.mg, build the C++ trainer against it, run it (-> cpp/run_out.txt)
    ./show.sh                                       # the MLIR the front end makes of gd.mg (-> show/)
    ./gd_mutation.sh > gd_mutation_out.txt          # breaks gd.mg on purpose, seven ways
    cd ../../part15/code && ./run_lit.sh            # the whole test suite
    ```
    Every listing and output on this page comes from these commands.

!!! note "Why this page shows FAIL lines, and why that is good"
    The mutation output near the end comes from a **negative control**: gd.mg deliberately broken and run against the test. There a "caught" line (the test failed) is the expected, wanted result. The baseline line must say the test passes, and it does. The first part of the output (the loss falling, the parameters recovered) is the real, correct program.

## Primer: learning as going downhill

**The problem.** You have data: for each of 200 samples, three measurements (the *features*) and one number to predict (the *target*). You believe the target is roughly a weighted sum of the features plus a constant: `target ≈ w1·f1 + w2·f2 + w3·f3 + b`. The weights `w1, w2, w3` and the *bias* `b` are the **parameters**. Finding the parameters that fit the data best is **linear regression**.

**A trick to keep it simple.** Add a fourth column to the data that is the number 1 for every sample. Then the bias `b` is just a fourth weight (the weight of a feature that is always 1), and the whole model is one matrix product: `predictions = x @ p`, where `x` has one row per sample and four columns, and `p` is a column of four parameters. That is why the code below has `tensor[?x4]` for the data and `tensor[4x1]` for the parameters.

**Measuring how wrong a model is.** The **residual** of a sample is its prediction minus its target. Square each residual (so errors of either sign count, and big errors count a lot), add them up and divide by the number of samples: the **mean squared error**, or **loss**. The loss is a single number, and it depends on the parameters: it is high for bad parameters and zero for perfect ones.

**Going downhill.** Picture the loss as the height of a landscape whose coordinates are the four parameters. The best parameters are at the bottom of the valley. From wherever you stand, the **gradient** is the direction in which the loss rises fastest, so stepping the opposite way goes downhill. **Gradient descent** repeats one rule: *new parameters = old parameters − (learning rate) × gradient*. The **learning rate** is the size of each step. For this loss the gradient has a clean form: `gradient = (2 / N) · xᵀ (x p − y)`, where `xᵀ` is the transpose of `x`, `x p − y` is the column of residuals and `N` is the number of samples. Read it as: for each parameter, add up (residual × that feature) over all samples.

**Too small, too large.** With a small learning rate the steps are safe but slow. With one that is too large, each step overshoots the valley, lands higher on the far side, and the loss *grows*; gradient descent diverges. Part C of the output shows exactly that.

**What the language cannot do.** Gradient descent repeats a step hundreds of times, and Mountain Goat has no loops. Rather than add one, this chapter splits the work along a clear line: the **math of one step** (gradient, update, loss) is Mountain Goat, compiled; the **loop** that repeats it, the data and the checks are a small C++ program that calls the compiled functions (as in Chapter 20).

## The Mountain Goat part

```text
--8<-- "docs/part26/code/cpp/gd.mg"
```

Three functions. `grad` is `xᵀ (x p − y)` written almost as it is on paper: `transpose(x) @ (x @ p - y)`. `step` is the update rule, `p - rate * grad(x, y, p)`; the factor `2 / N` and the learning rate are folded into one number, `rate`, which the caller passes as a 1×1 matrix (so the function works for any number of samples: `N` appears nowhere in the code). `loss_sum` squares the residuals elementwise and adds them with `col_sum`; the caller divides by `N`.

The typed parameters carry the shapes: `x: tensor[?x4]` is "any number of rows, exactly four columns", so one compiled function serves any dataset size; `p: tensor[4x1]` and `rate: tensor[1x1]` are fixed. Note that `rate * grad(...)` multiplies a 1×1 matrix by a 4×1 one: that is **broadcasting** (Chapter 22), and it requires static shapes, which is why `p` and `rate` have them. The front end turns the file into this MLIR (Chapter 20); everything from Chapters 21 to 24 now lowers it:

```mlir
--8<-- "docs/part26/code/show/gd_front_end.mlir"
```

Look at `@step`: the `mg.broadcast` is inserted automatically for `rate`, and the result of `grad` flows into the elementwise `mg.mul` and `mg.sub`. The transpose, two matrix products, a subtraction, a broadcast, a multiplication and a subtraction: that is one gradient-descent step.

## The C++ part

The driver generates data, runs the loop, and checks the answers:

```cpp
--8<-- "docs/part26/code/cpp/train.cpp"
```

The data is generated from known parameters, `2.0, −3.0, 0.5` and a bias of `1.0`, with a small deterministic random number generator so the output is the same every run. Three experiments:

- **A, noise-free data.** Gradient descent should recover the true parameters exactly.
- **B, noisy data.** Now the data is not exactly a line, so the truth is no longer the best fit: the best fit is the **least-squares** solution, which has an exact formula (the *normal equations*, `(xᵀx) p = xᵀy`, solved here by Gaussian elimination in C++). Gradient descent should land on that, not on the truth.
- **C, learning rate too large.** The loss should grow.

Everything else is **independent checking**: the driver also implements gradient descent and the loss in plain C++ loops and compares the compiled Mountain Goat results against them.

## The run

Built with `mgc lib gd.mg -O2 --matmul-order ikj` (Chapters 23 and 24's optimizations), compiled against the C++ driver, and run:

```sh
--8<-- "docs/part26/code/cpp/run.sh"
```

```text
--8<-- "docs/part26/code/cpp/run_out.txt"
```

**Reading it.**

- **A.** The loss starts at 5.43 and falls every step: 0.27 after 10 steps, 1.8×10⁻² after 20, 7×10⁻⁶ after 50, about 10⁻³⁰ after 300 (essentially the limit of the arithmetic). The learned parameters are `2.00000, −3.00000, 0.50000, 1.00000`: the truth. The compiled Mountain Goat result matches the plain C++ version to within 10⁻⁹.
- **B.** The learned parameters, `1.99714, −2.98902, 0.49820, 0.99592`, are **identical to five decimals** to the exact least-squares answer, and differ from the true parameters by the amount the noise pushed them. The final loss, 0.01343, is almost exactly what the noise alone would give: the noise is uniform up to ±0.2, whose mean square is 0.2²/3 = 0.01333. The model has learned everything there is to learn; what is left is noise. The program checks that gradient descent is closer to the exact answer than to the truth, which is the correct behavior for noisy data.
- **C.** With a learning rate of 1.2 the loss goes 5.4, 2.8, 5.2, 21, 342, 5587: each step overshoots further than the last. The limit can be computed: for a loss like this one, gradient descent is stable only when the learning rate is below 2 divided by the largest curvature of the loss, and for this data that curvature is 2.0148, so the limit is 0.9927 (`stability_limit.py` computes it, in plain Python, by reproducing the driver's data):

```text
--8<-- "docs/part26/code/stability_limit_out.txt"
```

So 0.2 is safely below the limit and 1.2 is above it. The checks print "the loss grew instead of shrinking: yes", which here is the correct behavior.

## Tests

One new `lit` test, `test/learning/gradient-descent`, builds the trainer **twice** (once optimized with the `ikj` loop order, once with the plain defaults) and runs both. Every property the driver checks must say `yes`, and the two builds' complete outputs must be identical: the compiler settings change the speed, not the answer. The suite now has 103 tests.

The driver's checks are the substance of the test, and the second half of the chapter is about whether they are good enough.

### Are the checks good enough? Break the program seven ways.

`gd_mutation.sh` edits `gd.mg` to be wrong, one way at a time, and re-runs the test:

```sh
--8<-- "docs/part26/code/gd_mutation.sh"
```

```text
--8<-- "docs/part26/code/gd_mutation_out.txt"
```

All seven are caught. One of them deserves a closer look, because the first version of the driver would **not** have caught it. The mutation "the gradient is twice too large" multiplies the gradient by 2. That is the same as doubling the learning rate, and gradient descent with a larger (but still stable) learning rate converges to the **same** answer, just faster. So a driver that only looked at the *end state* (the parameters after 300 steps) would pass: the parameters are still the truth, still match plain C++ at 300 steps (both have converged to the limit of the arithmetic), and the loss still falls at every step. I checked this by running the mutated program:

```text
  loss fell at every step: yes
  parameters recovered to within 1e-6 of the truth: yes
  matches the plain C++ gradient descent to within 1e-9: yes
  the first 5 steps match plain C++ step for step to within 1e-12: NO        <- the only check that notices
  the compiled loss equals a plain C++ loss (at the start and the end): yes
  gradient descent matches the exact least-squares answer to within 1e-6: yes
  ...
```

The only check that notices is the one added for exactly this reason: compare the **first few steps** with plain C++, one at a time. The size of every early step depends on the gradient being exactly right, while the final answer does not depend on it at all. This is a general lesson about testing iterative algorithms: **checking where a process ends up does not check how it got there**, and a bug can change the path while leaving the destination alone. The driver also checks the compiled loss against a plain C++ loss for the same reason: a loss function with a bug (the mutation that forgets to square the residuals) could otherwise go unnoticed, because gradient descent never looks at the loss, only at its gradient.

The full suite with the newest compiler:

```text
--8<-- "docs/part15/code/run_out_103.txt"
```

## Limits and what is not established

- **A toy problem.** One linear model, 200 samples, four parameters, synthetic data generated from known parameters. Nothing here says Mountain Goat can train anything realistic.
- **The loop is in C++.** The language has no loops, so every step crosses from C++ into the compiled code and back, and the wrapper copies the data in and out on each call. That is correct and simple, and it is the opposite of fast; nothing was timed.
- **No other models.** Logistic regression and neural networks need functions the language lacks (an exponential, a way to compute the derivative of `relu`, which is a comparison). `relu` itself exists (Chapter 22) but its gradient does not.
- **Fixed number of features.** The feature count (4) is part of the types; only the sample count is dynamic.
- **Full-batch gradient descent only.** Each step uses all samples. Mini-batches, momentum and adaptive learning rates were not tried.
- **The learning-rate limit is computed once, by a separate script, not tested.** Only the rates 0.2 and 1.2 were run through the real program; that rates between (say 0.9 and 1.0) behave as the computed limit predicts was not checked.
- **Exact equalities are checked to tolerances** (1e-6 to 1e-12 as printed), not bit for bit; floating-point arithmetic in a different order gives slightly different last digits.
- **Platform:** x86-64 Linux, LLVM 18.1.3.

## Reproducing

```sh
cd docs/part24/code && ./build.sh
cd ../../part26/code
cpp/run.sh > cpp/run_out.txt
./show.sh
./gd_mutation.sh > gd_mutation_out.txt
cd ../../part15/code && ./run_lit.sh          # 103 tests
```

## Chapter summary

- Linear regression is `predictions = x @ p`; the bias becomes a fourth weight with a column of ones; the loss is the mean squared residual; the gradient is `(2/N) xᵀ (x p − y)`; gradient descent repeats `p ← p − rate · gradient`.
- The gradient, the update and the loss are three one-line Mountain Goat functions; the loop, data and checks are C++ (the language has no loops).
- On noise-free data it recovers the true parameters; on noisy data it reaches the exact least-squares answer to five decimals, and the final loss is what the noise alone predicts; with a learning rate that is too large it diverges.
- The results match independent plain-C++ implementations (the descent, the loss and the closed-form answer).
- Seven deliberate bugs are all caught; one of them (a gradient twice too large) is invisible to end-state checks and needed a step-for-step trajectory check, because testing where an iteration ends does not test how it got there.

## Self-check questions

Each answer is collapsed; try the question first.

1. Why does the data get a column of ones, and what does that do to the model?

    ??? note "Answer"
        It turns the bias (the constant term) into an ordinary weight: the weight of a feature that is always 1. Then the whole model is a single matrix product, `x @ p`, with no separate "add the bias" step, and the gradient formula treats all four parameters the same way.

2. What is the gradient, and why does gradient descent step in the opposite direction?

    ??? note "Answer"
        The gradient is the direction in which the loss rises fastest, with a length that says how steeply. To make the loss smaller you go the opposite way, so each update subtracts a multiple of the gradient from the parameters: `p ← p − rate · gradient`.

3. In `gd.mg`, why is the learning rate passed in as a 1×1 matrix, and why must `p` and `rate` have fixed shapes?

    ??? note "Answer"
        The language has no scalar parameters (a scalar is a compile-time number, not a value a function can receive), so a one-number value travels as a 1×1 matrix. Multiplying it by the 4×1 gradient needs broadcasting, and broadcasting works only for static shapes (Chapter 22): the compiler must know the 1×1 is a 1 that can be repeated. So `p` and `rate` are fixed-shape, while `x` and `y` keep a dynamic row count.

4. Why do the noisy-data results match the exact least-squares answer rather than the true parameters?

    ??? note "Answer"
        With noise, the data is no longer exactly produced by the true parameters, so the true parameters are not the ones that minimize the loss on this data. Gradient descent minimizes the loss on the data it is given, so it finds the least-squares solution, which the normal equations compute exactly. The difference between that solution and the truth is the effect of the noise on this sample.

5. What happens with a learning rate that is too large, and why?

    ??? note "Answer"
        Each step overshoots the bottom of the valley and lands higher on the other side, where the gradient is bigger still, so the next step overshoots by more. The loss grows from step to step (5.4, 2.8, 5.2, 21, 342, 5587 at a rate of 1.2). Below a limit determined by the shape of the loss (0.9927 for this data, computed in `stability_limit.py`) the steps shrink toward the bottom instead.

6. The mutation "the gradient is twice too large" passed every check about the final answer. Why, and which check caught it?

    ??? note "Answer"
        A gradient twice too large is the same as a learning rate twice as large; as long as that is still stable, gradient descent converges to the same minimum, so the final parameters (and a comparison with plain C++ at 300 steps, when both have converged to the limit of the arithmetic) look right. Only the early steps differ in size. The check that compares the first five steps one at a time with plain C++ caught it.

7. What general lesson about testing iterative algorithms does that case teach?

    ??? note "Answer"
        Checking where a process ends up does not check how it got there: a bug can change the path and leave the destination unchanged. Tests for iterations should also look at intermediate states (here, the first few steps) against an independent implementation.

8. The driver checks the compiled loss against a plain C++ loss. Gradient descent never uses the loss, so why bother?

    ??? note "Answer"
        Because nothing else would notice a wrong loss: the parameters come from the gradient alone. A loss function that forgot to square the residuals, or summed along the wrong axis, would leave every check about the parameters passing while the printed losses (the thing a user watches to see whether training works) were wrong. Two of the seven mutations are exactly that.

9. Why does the test build the trainer twice and compare the complete outputs?

    ??? note "Answer"
        The two builds use different compiler settings (optimized with the `ikj` loop order, and the unoptimized defaults), which change only how fast the code runs. If the outputs differ, a compiler setting changed the answer, which would be a bug. Identical output at the printed precision is evidence that the optimizations preserve the results for this program.

10. What would you need to add to the language to train a logistic regression or a small neural network?

    ??? note "Answer"
        An exponential (for the sigmoid), a way to take the derivative of `relu` (a comparison that gives 1 where the input is positive and 0 elsewhere), probably a `log` for the usual loss, and ideally a loop so the whole training run is in the language rather than in C++. Each new operation needs a verifier, a lowering, front-end syntax and tests, as in Chapters 21 and 22.
