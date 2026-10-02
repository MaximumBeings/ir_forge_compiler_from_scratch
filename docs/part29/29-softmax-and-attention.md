# 29. Softmax and Attention

**What you will understand:** how a Mountain Goat program computes **softmax** (turning scores into probabilities) and **scaled dot-product attention**, the operation at the heart of a transformer. The one thing the language lacked was an exponential, so this chapter adds a single new operation, `exp`, and then writes everything else with what already existed: the matrix product, reductions, broadcasting, `transpose`. Along the way it shows a real numerical trap (the textbook softmax produces `nan` on large scores), the one-line fix, causal masking, and a complete self-attention block, each checked against an independent Python implementation.

**What you need to know first:** Chapter 22 (reductions such as `row_max` and `row_sum`, and broadcasting a size-1 axis), Chapter 21 (`@`, `transpose`) and the language tour. Chapter 28 is not needed (everything here is rank 2).

!!! tip "Compile and run"
    ```sh
    cd docs/part29/code && ./build.sh                 # once: the newest compiler (adds mg.exp)
    ./mgc run examples/06_attention.mg                # compile and run one example
    ./mgc mlir examples/04_softmax_stable.mg          # show the MLIR the front end produces
    ./run_examples.sh > examples_out.txt              # every example and every error example on this page
    ./check_attention.py                              # softmax and attention against an independent Python version
    ./mutation.sh > mutation_out.txt                  # breaks the compiler on purpose, eight ways
    cd ../../part15/code && ./run_lit.sh              # the whole test suite
    ```
    Every listing and output on this page comes from these commands.

!!! note "Why this page shows nan, FAIL lines and error messages, and why that is good"
    Example 3 is **supposed** to print `inf` and `nan`: it demonstrates why the textbook softmax formula is wrong on a computer. The four error examples are programs the compiler must reject (each ends `exit status 1`). The mutation output is a negative control: the compiler deliberately broken and run against the tests, where "caught" is the wanted result and "NOT CAUGHT" would be a test gap.

## What is new: `exp`

`exp(m)` applies e<sup>x</sup> to every element of a matrix, and nothing else is new in the language. Adding it touched the same three layers as every earlier operation (Chapter 22):

- **the dialect:** `mg.exp` in `MgOps.td` (one input, one result of the same shape) with the same verifier as `mg.neg` and `mg.relu`;
- **the lowering:** a loop nest that loads each element, calls MLIR's own `math.exp`, and stores the result. The `math` dialect is then converted to LLVM (`--convert-math-to-llvm`, a new step in `mgc`), which turns it into a call to the C library's `exp`, so `mgc` also links the math library (`-lm`);
- **the front end:** `exp` joins `relu`, `row_sum` and the others as a built-in function that needs a matrix.

Because it is an ordinary elementwise operation, `exp` works on the dynamic shapes of Chapter 14 too, though softmax itself does not (see the limits).

```text
--8<-- "docs/part29/code/examples_out.txt:1:18"
```

The first matrix is `e^0 = 1`, `e^1 = 2.71828`, `e^2 = 7.38906`, `e^-1 = 0.367879`. The last two lines show the rule that makes softmax work: `exp(x + y)` and `exp(x) * exp(y)` are the same numbers (here `[4.48169, 0.606531]` for both), because e<sup>x+y</sup> = e<sup>x</sup>·e<sup>y</sup>. A sum of scores becomes a product of positive numbers.

## Softmax

Given a row of scores, softmax produces a row of positive numbers that add up to 1, bigger scores getting bigger shares:

softmax(row)<sub>j</sub> = e<sup>row<sub>j</sub></sup> / (e<sup>row<sub>0</sub></sup> + e<sup>row<sub>1</sub></sup> + …)

In Mountain Goat that is one line. `exp(x)` has shape `2x3` and `row_sum(exp(x))` has shape `2x1` (one total per row); dividing the first by the second uses Chapter 22's broadcasting to stretch the total across the three columns:

```text
--8<-- "docs/part29/code/examples_out.txt:20:35"
```

Row 0, scores `1 2 3`, becomes `0.0900306, 0.244728, 0.665241`: the score 3 takes about two thirds. Row 1, three equal scores, gives a third each. The second matrix is `row_sum` of the first and is exactly `1` in every row, as it must be.

### The textbook formula breaks: overflow

The function above is called `softmax_naive` for a reason. A double-precision number cannot be larger than about 1.8 × 10<sup>308</sup>, and e<sup>710</sup> already exceeds it. Scores in the hundreds or thousands are normal in real models.

```text
--8<-- "docs/part29/code/examples_out.txt:37:48"
```

**Read this output as the expected one.** `exp` of 1000 is `inf` (infinity), so the formula computes `inf / inf`, which is "not a number": `nan` (the minus sign printed in front of `nan` is an accident of the hardware; a `nan` has no meaningful sign). The formula is right on paper and wrong in a computer. Notice that the compiler did nothing wrong, nothing aborted, and the program printed a result. Silent `nan` is the failure mode.

### The fix: subtract the row maximum

Divide the top and bottom of the fraction by e<sup>max</sup> (which changes nothing, because it cancels), and the formula becomes

softmax(row)<sub>j</sub> = e<sup>row<sub>j</sub> − max</sup> / Σ e<sup>row<sub>k</sub> − max</sup>

Now every exponent is at most 0, so every `exp` is at most 1: nothing can overflow. The largest score contributes exactly `e^0 = 1`, so the denominator is at least 1: nothing divides by zero. A function is a single expression (no `let` inside), so the subexpression is written twice:

```text
--8<-- "docs/part29/code/examples_out.txt:50:67"
```

Three observations, each visible in the output:

1. Scores `1000 1001 1002` and scores `1 2 3` give **the same probabilities**, `0.0900306, 0.244728, 0.665241`, because only the *gaps* between scores matter.
2. Adding 100 to every score changes nothing (the second matrix): softmax is **shift invariant**, which is exactly why subtracting the maximum is allowed.
3. Very negative scores (the third matrix) are fine: the exponentials underflow to `0` harmlessly, and the largest score still gets the largest share. A row of zeros gives a third each.

What the compiler built for the stable version is exactly the recipe, and a test checks it (this is `mgc mlir`, abridged):

```text
mg.reduce ... kind = "max" : tensor<2x3xf64> -> tensor<2x1xf64>      # the row maximum
mg.broadcast ...           : tensor<2x1xf64> -> tensor<2x3xf64>      # stretched across the columns
mg.sub ...                 : tensor<2x3xf64>, tensor<2x3xf64> -> tensor<2x3xf64>
mg.exp ...                 : tensor<2x3xf64> -> tensor<2x3xf64>
mg.reduce ... kind = "sum" : tensor<2x3xf64> -> tensor<2x1xf64>      # the row total
mg.div ...                 : tensor<2x3xf64>, tensor<2x3xf64> -> tensor<2x3xf64>
```

### Temperature

Dividing the scores by a number *T* (a compile-time scalar) before the softmax sharpens it when T < 1 and flattens it when T > 1:

```text
--8<-- "docs/part29/code/examples_out.txt:69:83"
```

With `T = 0.5` the top score takes 86.7% (the gaps double, from 1 and 2 to 2 and 4). With `T = 4` the three shares are `0.254, 0.326, 0.419`: nearly equal.

## Attention

Attention lets each position in a sequence take a weighted average of every position's content. There are three matrices with one row per position: **queries** `q` (what each position is looking for), **keys** `k` (what each position offers) and **values** `v` (what each position hands over). The score of position *i* looking at position *j* is the dot product of `q[i]` and `k[j]`, so all the scores at once are `q @ transpose(k)`, an `n x n` matrix. Softmax turns each row of scores into weights, and the output is the weights times `v`. Dividing the scores by √d (where *d* is the width of a query) keeps their size from growing with *d*:

attention(q, k, v) = softmax(q · kᵀ / √d) · v

```text
--8<-- "docs/part29/code/examples_out.txt:85:106"
```

Here `q`, `k` and `v` have three positions of width `d = 2`, and the scale is `1/√2 = 0.7071067811865476`, a compile-time number. The first matrix is the **attention weights**: row 0 (`0.401, 0.198, 0.401`) says position 0 listens mostly to positions 0 and 2 (their keys, `[1,0]` and `[1,1]`, point the same way as its query `[1,0]`) and least to position 1. The second matrix is the output: row 0 is `0.401·[10,0] + 0.198·[0,10] + 0.401·[5,5] = [6.017, 3.983]`, which you can check by hand. The functions call each other (`attention` calls `weights`, which calls `softmax`), and every call is shape-checked: the compiler knows `softmax`'s argument must be `3x3`.

### Causal attention: not looking ahead

A model that generates text must not let position *i* see positions after it. The standard trick is to **add a mask** to the scores before the softmax: 0 where looking is allowed (`j ≤ i`) and a huge negative number where it is not. `e^(-1000000000)` is exactly `0`, so masked positions get weight exactly 0 and the row still sums to 1:

```text
--8<-- "docs/part29/code/examples_out.txt:108:128"
```

The weights are lower triangular. Row 0 is `[1, 0, 0]`: position 0 can only see itself, so the first output row is exactly row 0 of `v` (`[10, 0]`). Row 1 mixes only positions 0 and 1. Row 2 is the same as the unmasked one, because the last position was allowed to see everything.

### A self-attention block

In a transformer the queries, keys and values are not given; they are made from the same input by three learned matrices. One more matrix maps the attention output back to the input's width, and the block's result is added to its input (a *residual connection*), so each token keeps what it had and gains what it attended to:

```text
--8<-- "docs/part29/code/examples_out.txt:130:147"
```

Three tokens of four numbers become queries, keys and values of width two (`x @ wq`, `x @ wk`, `x @ wv`), are attended over, and projected back to width four by `wo`, then added to `x`. The definition is one long line because a `def` is one line. The result was checked against an independent Python calculation (the attention weights are different for each token here: `0.187, 0.045, 0.768` for token 0, a third each for token 1 whose query matches every key equally, and `0.284, 0.140, 0.576` for token 2).

## Mistakes the compiler reports

```text
--8<-- "docs/part29/code/examples_out.txt:149:182"
```

In order: passing four tokens to a function defined for three; `exp` of a bare number (a compile-time scalar has no shape); a query width that does not match the key width in `q @ transpose(k)`; and softmax over a sequence of any length. The last one is a real limit, not a bug: `x - row_max(x)` with a `?` row count needs a `?` size to be stretched, and the language never stretches a `?` size (Chapter 22). Attention in this chapter is for a fixed sequence length.

## Tests

Five new `lit` files in `test/attention29/` (the suite is now 117 tests, counting the tour's new test):

| Test | What it checks |
|---|---|
| `examples` | the eight examples print the values on this page (including `inf` and `nan` for example 3) |
| `errors` | the four mistakes give the exact messages, with file and line |
| `verifiers` | `mg.exp` given a result of a different shape is rejected by the dialect, whatever front end built it |
| `ir` | the stable softmax is a max-reduce, broadcast, subtract, exp, sum-reduce, divide, in that order |
| `against-reference` | `check_attention.py`: softmax of eight score matrices, including scores of ±500 and of −1500 to −1000 (where the naive formula gives `nan`), attention and causal attention for five sizes, against an independent Python implementation, plus the properties below |

The properties that must hold whatever the numbers are, checked on every case: each softmax row is positive and sums to 1; adding a constant to every score changes nothing; causal weights above the diagonal are **exactly** 0. Values are compared with a relative tolerance of 10<sup>-5</sup>, because `mgc` prints six significant digits (Chapter 28's contractions could be compared exactly because integers and quarters are exact in binary; an exponential is not).

```text
--8<-- "docs/part29/code/check_attention_out.txt"
```

### Are the tests good enough? Break the compiler eight ways.

```sh
--8<-- "docs/part29/code/mutation.sh"
```

```text
--8<-- "docs/part29/code/mutation_out.txt"
```

All eight are caught. Two details are worth noticing.

- **"A maximum starts from 0, not -infinity"** is caught only because a test uses scores below −745. Scores such as −490 survive the mistake: `e^−490` is tiny but not zero, so the answer stays right. Only when the scores are so negative that the exponentials underflow (the `[-1500, -1000]` case here, and example 4's `-1000` row) does the wrong starting value produce `0/0`. An earlier version of `check_attention.py` used only `[-500, -480]` and this mutation was caught by the examples alone; the extra case was added after the first run of this script showed that, and the script was re-run in full.
- **Dropping `-lm` is caught.** Without the math library the link step fails, so `mgc` produces nothing and every example fails. It would have been an equivalent mutant had the C library's `exp` lived in the main C library on this platform; it does not.

The full suite:

```text
--8<-- "docs/part15/code/run_out_117.txt"
```

## Limits and what is not established

- **Fixed sequence length.** Softmax and attention are written for static shapes. A function over `tensor[?x3]` is rejected (example error 4) because a `?` size is never stretched. Attention over a sequence of any length is not available.
- **One head, no batch.** Multi-head attention and a batch of sequences need a batched matrix product (an axis shared by both inputs and the output). Chapter 28's `contract` does not support batch axes, and nothing here adds them. A multi-head block can be written as separate heads added together (each head's output through its own slice of the output projection), which is mathematically the same; that is not demonstrated here.
- **No normalization layers, no feed-forward network, no training.** A transformer has more than attention. This chapter stops at the attention block with a residual connection.
- **Numbers printed to six significant digits.** All comparisons with Python are to a relative 10<sup>-5</sup>. The compiled `exp` calls the platform C library's `exp`; its accuracy (typically within one unit in the last place) was **not measured** here, and a different C library could print different last digits.
- **A large negative number is not minus infinity.** The mask uses `-1000000000`. A score of that size in real data would be masked incorrectly; `exp` of it is exactly 0 only because it underflows. (The language has no literal for infinity.)
- **The stable softmax computes the exponentials twice** (a `def` cannot name a subexpression), so it does about twice the `exp` work it needs to. Speed was **not measured**, and the compiler does not eliminate the duplicate.
- **`exp` on the GPU path is not covered.** `mgc ptx` was not run with `exp`; the math dialect's route to PTX was not tried.
- **Overflow is demonstrated, not defended.** Nothing in the language prevents a user writing the naive softmax; example 3 shows what happens. A mistake that produces `nan` produces no error.
- **Platform:** x86-64 Linux, LLVM 18.1.3.

## Reproducing

```sh
cd docs/part29/code && ./build.sh
./run_examples.sh > examples_out.txt
./check_attention.py > check_attention_out.txt
./mutation.sh > mutation_out.txt
cd ../../part15/code && ./run_lit.sh          # 117 tests
```

## Chapter summary

- One new operation, `exp`, was enough to write softmax and scaled dot-product attention in Mountain Goat: everything else was already there.
- The textbook softmax overflows to `nan` for scores in the hundreds; subtracting the row maximum fixes it without changing the answer (shift invariance), and the examples show both.
- Attention is `softmax(q @ transpose(k) * scale) @ v`; a causal mask is an added matrix of 0 and a huge negative number; a self-attention block adds three projections and a residual connection.
- Everything agrees with an independent Python version to the six printed digits, including scores of plus and minus 500, and the structural properties (rows sum to 1, masked weights exactly 0) hold on every case.
- Static shapes only, one head, no batching: the transformer chapter that follows has to deal with the limits listed above.

## Self-check questions

Each answer is collapsed; try the question first.

1. Why is `softmax_naive([[1000, 1001, 1002]])` all `nan` rather than a plausible wrong answer?

    ??? note "Answer"
        `exp(1000)` exceeds the largest double and becomes infinity, and so do `exp(1001)` and `exp(1002)`. The row total is infinity, and each element is infinity divided by infinity, which is undefined, so the result is not-a-number. The stable version never makes a number bigger than 1, so it cannot overflow.

2. Why does subtracting the row maximum not change the result?

    ??? note "Answer"
        e<sup>x − m</sup> = e<sup>x</sup>·e<sup>−m</sup>, so every term of the numerator and of the denominator is multiplied by the same factor e<sup>−m</sup>, which cancels in the fraction. This is the "shift invariance" that example 4's second matrix shows directly.

3. In `exp(x) / row_sum(exp(x))` the shapes are `2x3` and `2x1`. What makes that legal, and what would stop it if the row count were `?`?

    ??? note "Answer"
        Chapter 22's broadcasting: a *static* dimension of size 1 is stretched to match the other operand (a `2x1` becomes `2x3`). A `?` size is not known when compiling, so it cannot be stretched, and the compiler rejects the program (example error 4). The same rule is why attention here needs a fixed length.

4. What do the three matrices `q`, `k`, `v` each contribute, and what shape is `q @ transpose(k)` for `n` positions of width `d`?

    ??? note "Answer"
        Queries say what each position is looking for, keys say what each position offers, values say what each position hands over. For `q` and `k` of shape `n x d`, `transpose(k)` is `d x n`, so `q @ transpose(k)` is `n x n`: entry `[i][j]` is the dot product of query *i* and key *j*, the score of position *i* looking at position *j*.

5. Why divide the scores by the square root of `d`?

    ??? note "Answer"
        A dot product of two vectors of width `d` with entries of ordinary size grows in size with `d` (the typical size of a sum of `d` products grows like √d). Large scores push the softmax toward giving almost all the weight to one position. Dividing by √d keeps the scores about the same size whatever `d` is. In the examples `d = 2` and the scale is `1/√2 = 0.7071067811865476`, written as a compile-time number.

6. The causal mask uses `-1000000000`. Why does a masked position get weight exactly 0, not a tiny positive number, and when would this go wrong?

    ??? note "Answer"
        After the maximum is subtracted, a masked score is about −10<sup>9</sup> below the largest, and `exp` of that is far smaller than the smallest positive double, so it underflows to exactly 0. It would go wrong if real scores were as large as the mask (or if a whole row were masked, which makes a row of equal very negative numbers and a meaningless result); the language has no literal for −infinity, which is the usual choice.

7. Why can row 0 of the causal output in example 7 be read off without computing anything?

    ??? note "Answer"
        The only position row 0 may attend to is position 0, so its weights are `[1, 0, 0]` and its output is `1·v[0] + 0·v[1] + 0·v[2] = v[0]`: `[10, 0]`.

8. Why does `check_attention.py` compare with a tolerance when Chapter 28's check compared exactly?

    ??? note "Answer"
        Chapter 28 used whole numbers and multiples of a quarter, whose sums and products are exact in binary, so any difference at all meant a bug. An exponential's result is almost never exactly representable, and `mgc` prints only six significant digits, so exact comparison is impossible; a relative tolerance of 10<sup>-5</sup> is a little looser than the printing precision.

9. Which mutation in `mutation.sh` is caught only because a test uses very negative scores?

    ??? note "Answer"
        "A maximum starts from 0, not −infinity" gives the right answer for any row with a non-negative score, so only an all-negative row can expose it, and even scores around −490 survive it (`e^−490` is tiny but not zero). It takes scores below about −745, where `exp` underflows to exactly 0, to turn the wrong maximum into `0/0`: the `[−1500, −1000]` case and example 4's third matrix. The lesson is the same as Chapter 22's `13_negative_max` example: a test with only friendly numbers cannot see a wrong starting value, and a *somewhat* unfriendly one may not either.

10. What would multi-head attention need that this chapter's language does not have?

    ??? note "Answer"
        A batched matrix product: the head index appears in both inputs and in the output, which is a batch axis, and Chapter 28's `contract` rejects that (an axis must be paired and summed away). Without it, heads can be written as separate functions and their outputs combined by adding each head's product with its own slice of the output matrix, which is the same arithmetic but not a single batched operation.
