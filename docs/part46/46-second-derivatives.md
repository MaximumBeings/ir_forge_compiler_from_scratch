# 46. Second Derivatives: Differentiating the Backward Pass Again

![Mountain goats in space helmets on Triton, a moon of Neptune](../assets/goats/ch-46.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

**What you will understand:** why the gradient program that Chapter 45 generates can be fed back into the same tool, what comes out (a **Hessian-vector product**: how the gradient itself changes when the parameters move in a chosen direction), how to check it against an independent reference, and one thing it is good for: measuring how sharply the loss curves, which bounds how large a learning rate can be. The compiler is unchanged. The only new code is `hvp.py` (about 20 lines, a wrapper around Chapter 45's `autograd.py`) and a measurement script.

**What you need to know first:** Chapter 45 (reverse-mode differentiation as a transformation from a Mountain Goat program to another Mountain Goat program). Chapter 26 (gradient descent and the learning rate).

!!! tip "Compile and run"
    ```sh
    cd docs/part46/code                                  # plain Python 3; needs the Chapter 44 build (../../part44/code/build.sh) for mgc
    ./hvp.py examples/s01_cubic.mg --wrt x --vec "[[1,0,0],[0,0,0]]" > hvp_example_generated.mg   # differentiate the backward pass
    ./mgc run hvp_example_generated.mg                   # run it
    ./check_hvp.py > check_hvp_out.txt                   # the checks of this page (about 20 seconds)
    ./curvature.py > curvature_out.txt                   # power iteration and the learning-rate table (about 3 minutes)
    ./mutation.py > mutation_out.txt                     # 11 WRONG versions of autograd.py the checker must catch (about 4 minutes)
    cd ../../part15/code && ./run_lit.sh                 # the whole test suite
    ```
    Every listing and output on this page comes from these commands.

!!! note "Why this page shows a mutation run, and why 'caught' is the wanted result"
    `mutation.py` writes broken versions of `autograd.py` and expects the checker to fail on each. "Caught" is good; "NOT CAUGHT" would be a gap. One mutant is not caught, and the page says why.

## The idea

Chapter 45's output is an ordinary Mountain Goat program that prints the loss `L(p)` and its gradient `g(p)` for a matrix of parameters `p`. Because it is an ordinary program made of the same operations, it can be differentiated again. A gradient is a matrix, not a number, and `autograd.py` needs a scalar loss, so fix a direction `v` (a matrix of the same shape as `p`) and ask for the derivative of the **scalar**

`sum(g(p) * v)`

with respect to `p`. By the chain rule that derivative is `H(p) v`, where `H` is the **Hessian**, the matrix of second derivatives of `L`. So the compiled program prints `H v` without ever forming `H` (for 15 parameters `H` is 15 × 15; for a real model it would not fit in memory, and `H v` is all that is needed for many purposes).

`hvp.py` does exactly this, in three steps:

```python
--8<-- "docs/part46/code/hvp.py"
```

1. `autograd.py` writes the program computing the loss and the gradient.
2. `hvp.py` replaces the program's result by `let vdir = ...` and `print col_sum(row_sum(g * vdir))`.
3. `autograd.py` differentiates *that* program.

An example (`examples/s01_cubic.mg`): `loss = sum of x*x*x + exp(x) * 0.5`, so the gradient is `3x² + eˣ/2` and the second derivative `6x + eˣ/2` at each entry.

```text
--8<-- "docs/part46/code/examples/s01_cubic.mg"
```

With `v` equal to 1 in the first entry and 0 elsewhere, `H v` is the first column of the Hessian. Running the 62-line generated program:

```text
--8<-- "docs/part46/code/hvp_example_out.txt"
```

The first matrix is `sum(g * v)`, which is the gradient's first entry `3 · 0.7² + e^0.7 / 2 = 2.47688`. The second is `H v`: its first entry is `6 · 0.7 + e^0.7 / 2 = 5.20688`, and the rest are zero because this loss treats entries independently, so its Hessian is diagonal. Both match the hand calculation.

Nothing in `autograd.py` had to change for this. The backward pass it writes uses `ones * g`, `ge(x, 0)`, `transpose`, products and quotients, and every one of those has a rule. One rule matters more here than in Chapter 45: **`ge` has gradient zero**. The relu mask `ge(x, 0)` in a backward pass is flat almost everywhere, so differentiating through it correctly contributes nothing, and the second derivative of `relu(x)²` comes out as `2` where `x > 0` and `0` where `x < 0` (the checker tests this).

## Does it give the right Hessian products?

`check_hvp.py` runs four groups of checks. The reference for the first group is not `autograd.py` at all: it is the **full Hessian from four-point central differences** of the loss, evaluated by `reference.py`'s plain-Python evaluator (step 10⁻⁴), multiplied by `v`.

1. **Eight small programs, three random directions each.** `s01` cubic and exp; `s02` a matrix product squared; `s03` softmax cross-entropy (`log`, `exp`, `row_max`); `s04` layer normalisation (`sqrt`, division, means); `s05` division, log and sqrt; `s06` relu squared; `s07` relu times exp (here the relu mask matters at both orders); `s08` a reshaped product squared. `H v` from the compiled double-differentiated program must match in every element.
2. **Symmetry.** A Hessian is symmetric: `wᵀ(H v) = vᵀ(H w)`. Two different compiled programs compute the two sides; a wrong rule typically breaks this.
3. **The first print.** The program's first print is `sum(g * v)`; it must equal the directional derivative of the loss along `v`, computed by a finite difference of the loss.
4. **Chapter 33's classifier**, with respect to its 15 output weights `wo0` (a 3 × 5 matrix), against the 15 × 15 finite-difference Hessian times a direction.

```text
--8<-- "docs/part46/code/check_hvp_out.txt"
```

The comparisons are at 10⁻⁵ relative (10⁻⁴ for Chapter 33, whose reference uses a larger step) because the compiled programs print six digits. The symmetry comparison scales its tolerance with the size of the terms for the same reason: an early version used a plain relative tolerance and failed on `s07`, where each printed entry of `H v` carries about 5 × 10⁻⁶ of rounding and the sum of six of them differed by 5 × 10⁻⁵ out of 4.3. The cause was the printing, not the tool, and the tolerance now says so.

### Are the checks good enough? Eleven wrong versions.

```text
--8<-- "docs/part46/code/mutation_out.txt"
```

Ten are caught and one is **not**:

- **The two second-order-only mutants.** A mutant that lets the gradient flow through `ge` leaves every first-order gradient of Chapter 45 unchanged (a first-order backward pass contains no `ge` to differentiate) and is caught only here, by the relu programs. The same is true of a relu mask built as `ge(x, x)` (always 1): in `relu(x)²` the relu output is already zero where the mask matters, so the first version of this test **did not catch it**; adding `s07` (relu times exp) did. A test function has to be sensitive to the thing under test.
- **Not caught: the sum rule that forgets to spread the gradient over the summed axis** (`add_adj(x, g)` instead of `ones * g`). It is caught by Chapter 45's checker (a reshape program fails to compile because the adjoint has the wrong shape), but at second order it is **equivalent** for every program here: Mountain Goat broadcasts a 1 × 1 or N × 1 adjoint when it meets a product or quotient, and every backward pass of a sum in these programs meets one. `s08` was added to try to expose it and does not. This checker therefore does not cover that rule, and the chapter does not claim it does.
- Two mutants are caught because the generated program fails to compile or fails the dependence test, rather than by a wrong number.

## What it is good for: how sharp is the loss?

The largest eigenvalue `λ` of the Hessian says how fast the gradient can change along the worst direction. For a **quadratic** loss, gradient descent with learning rate `lr` converges when `lr < 2/λ` and diverges when it exceeds it. A matrix-vector product is all that **power iteration** needs: start from any `v`, repeat `v ← H v / |H v|`, and `vᵀ H v` converges to the largest eigenvalue in magnitude.

`curvature.py` does that for Chapter 33's classifier with respect to `wo0`, each iteration being one compiled program run, then runs 30 real gradient-descent steps (`--descend 30` of Chapter 45, on `wo0` only, the other weights fixed) at several multiples of `2/λ`:

```text
--8<-- "docs/part46/code/curvature_out.txt"
```

Reading it:

- **The estimate has not converged.** After the cap of 80 iterations the value is still creeping up (0.020905 at iteration 10, 0.021089 at 20, 0.021149 at 40, 0.021162 at 60, 0.021165 at 80). It is a **lower bound** for the largest eigenvalue near 0.0212, and `2/λ` is therefore an upper bound near 94.5. I did not compute the 15 × 15 eigenvalue by another method, so this value is not independently confirmed (the Hessian-vector products it is built from are, by the checks above).
- **Well below `2/λ` the loss falls at every step** (multiples 0.25 and 0.5: no step increased the loss).
- **Near and above `2/λ` the loss rises at some step** (0.9, 1.1, 2 and 5 times): at 0.9, one step *below* the quadratic threshold, the loss already rose (1.015 after one step, 1.048 after ten) before falling to 0.751 by step 30; at 5 times it ends at 3.22, above its starting value 1.60. The classifier's loss is not quadratic, and the curvature at the starting point is only a local guide, so a prediction that is exact for quadratics held here only loosely: the rise began a little before the threshold.
- **A large learning rate is not necessarily a bad one for the final loss.** At 0.9 and 1.1 times `2/λ` the loss after 30 steps (0.751 and 0.888) was lower than at 0.25 times (0.760), though not lower than at 0.5 times (0.693), and the path to it was not monotone. This table is about what happened in this one run from this one starting point; it is not a recommendation.
- **This is `wo0` alone.** Chapter 33 trained all four weight matrices together at learning rate 3.0; the curvature of the combined problem was not measured. `hvp.py` differentiates with respect to one named matrix; a joint product would need a small extension.

## Tests

One new `lit` file `test/hvp46/check.mlir` (the suite is now 158 tests) runs `check_hvp.py`; the output shown above is what it checks.

## Limits and what is not established

- **One matrix at a time.** `hvp.py --wrt` takes one name. The Hessian blocks between different matrices are not computed.
- **Hessian-vector products, not the Hessian.** The full matrix could be built from `n` products with unit vectors; I did not do that, and `check_hvp.py` uses the finite-difference Hessian only as a reference.
- **The reference is finite differences at a moderate step** (10⁻⁴ for the small programs, 10⁻³ for Chapter 33) and the compiled programs print six digits, so agreement is to about 10⁻⁵ to 10⁻⁴, not to the last bit.
- **Kinks.** `relu` and `row_max` have no second derivative at their kinks. The test inputs are away from them; behaviour exactly at a kink is whatever the rules give (zero for relu's mask) and is not claimed to be meaningful.
- **The learning-rate experiment is one run** from one starting point, with the largest eigenvalue not converged. It is an illustration of how a Hessian-vector product is used, not a study of learning rates.
- **Cost and size.** The generated double-differentiated program for Chapter 33's classifier is much larger than the first-order one; I measured correctness, not its cost. Third derivatives were not tried.
- **The sum-spread rule is not covered by this checker** (see the mutation run); Chapter 45's checker covers it.

## Reproducing

```sh
cd docs/part46/code
./hvp.py examples/s01_cubic.mg --wrt x --vec "[[1,0,0],[0,0,0]]" > hvp_example_generated.mg && ./mgc run hvp_example_generated.mg
./check_hvp.py > check_hvp_out.txt && ./curvature.py > curvature_out.txt && ./mutation.py > mutation_out.txt
cd ../../part15/code && ./run_lit.sh          # 158 tests
```

## Chapter summary

- The program Chapter 45 generates is an ordinary Mountain Goat program, so it can be differentiated again. Differentiating the scalar `sum(g * v)` gives the **Hessian-vector product** `H v` without forming the Hessian. `hvp.py` is a three-step wrapper around the unchanged `autograd.py`.
- It matches the full finite-difference Hessian times `v` in all 156 elements of eight small programs (three directions each), is symmetric, reproduces the directional derivative of the loss, and agrees on Chapter 33's 15 output weights.
- Ten of eleven wrong versions are caught, including two that first-order checks cannot see. One is not caught, because for the programs tested it makes no difference; the page says so.
- Power iteration on Hessian-vector products estimates the sharpest curvature of Chapter 33's loss along its output weights (at least 0.0212, not converged), and real descent runs rise above the loss only near and beyond the `2/λ` guide: a quadratic rule of thumb that held loosely for this non-quadratic loss.

## Self-check questions

Each answer is collapsed; try the question first.

1. Why differentiate `sum(g * v)` and not `g` itself?

    ??? note "Answer"
        `autograd.py` differentiates a **scalar** loss. The gradient `g` is a matrix, so its derivative with respect to `p` is a whole Jacobian (the Hessian). Taking the dot product with a fixed direction `v` turns it into a scalar whose gradient is `H v`, one matrix-vector product's worth of information, which is all many algorithms need.

2. A first-order checker passes a mutant that lets gradients flow through `ge`. Why, and why does the second-order checker catch it?

    ??? note "Answer"
        A first-order backward pass only *contains* `ge` (as the relu mask); nothing differentiates through it, so the mutant's wrong rule is never used. In the second pass the mask is part of the program being differentiated, so the rule is used and the mutant produces a nonzero contribution where the correct answer is zero.

3. The first version of the test did not catch a relu mask that is always 1. What was wrong with the test, and how was it fixed?

    ??? note "Answer"
        It used `relu(x)²`, in which the relu output is already zero wherever the mask would have mattered, so the mask was invisible. Adding `relu(x) * exp(x)`, whose gradient involves the mask directly, makes the wrong mask change the answer.

4. Why is the sum-rule mutant not caught at second order?

    ??? note "Answer"
        For the programs here, the un-spread adjoint (1 × 1 or N × 1) is always combined with a product or quotient, and Mountain Goat broadcasts it there, so the result is the same as with the spread. It only fails where the adjoint is used alone (as in Chapter 45's reshape program). So the check must be done by Chapter 45's checker; this one does not cover it.

5. What does a Hessian's largest eigenvalue tell you about the learning rate, and how well did that hold here?

    ??? note "Answer"
        For a quadratic loss, gradient descent converges iff `lr < 2/λ`. For Chapter 33's non-quadratic loss with respect to `wo0`, the loss never rose at 0.25 and 0.5 times `2/λ`, but rose at some step already at 0.9 times, and ended above its start at 5 times. The rule held loosely, as a local guide; λ was also not fully converged (a lower bound), so `2/λ` is an upper bound on that estimate.

6. Name three things this chapter does not establish.

    ??? note "Answer"
        Any of: the full 15 × 15 Hessian or its eigenvalues by another method; the curvature of all of Chapter 33's weights together; third derivatives; the cost of the double-differentiated program; behaviour exactly at a kink; coverage of the sum-spread rule by this checker; learning-rate behaviour beyond one run from one starting point.
