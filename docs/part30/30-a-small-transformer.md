# 30. A Small Transformer

![Mountain goats on the mountain above a desert](../assets/goats/ch-30.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

**What you will understand:** what a transformer actually computes, by reading one written in Mountain Goat: token embeddings, positions, **layer normalization**, **multi-head causal self-attention**, a **feed-forward network**, **residual connections**, and a final softmax that gives next-token probabilities. The model is two blocks deep and small enough that every number can be inspected. Mountain Goat gets one new operation, `sqrt`; everything else is Chapters 21 to 29. The program is checked against an independent Python implementation at every stage, and against properties any correct transformer must have: **causality** (the future cannot influence the past), **permutation equivariance** (without positions, reordering the tokens reorders the outputs), normalized layer-norm rows, and no overflow when scores are huge.

**What you need to know first:** Chapter 29 (softmax and attention, which this chapter builds on without re-deriving), Chapter 22 (reductions and broadcasting) and the language tour. If the word "transformer" is new, read the section "What a transformer is" below first; it assumes only the matrix operations you have already seen.

!!! tip "Compile and run"
    ```sh
    cd docs/part30/code && ./build.sh                 # once: the newest compiler (adds mg.sqrt)
    python3 make_examples.py                          # (re)writes the examples from transformer.mg.defs
    ./mgc run examples/03_tiny_transformer.mg         # compile and run the whole model
    ./run_examples.sh > examples_out.txt              # every example and every error example on this page
    ./check_transformer.py                            # the model against the reference, and the properties
    ./model_mutation.py > model_mutation_out.txt      # runs 15 WRONG models through the checker
    ./mutation.sh > mutation_out.txt                  # breaks the compiler on purpose, six ways
    cd ../../part15/code && ./run_lit.sh              # the whole test suite
    ```
    Every listing and output on this page comes from these commands.

!!! important "This model is not trained"
    The weights are **seeded pseudo-random numbers**, not learned. The model is a faithful, checked implementation of the transformer's *computation*, so its next-token probabilities are meaningless as language (they scatter around the uniform 0.2 over the five-token vocabulary). Training would need gradients through every operation here, which Mountain Goat does not have (Chapter 26 trained a much simpler model by hand-derived gradients). Nothing on this page claims the model has learned anything.

!!! note "Why this page shows FAIL lines, and why that is good"
    The four error examples are programs the compiler must reject (each ends `exit status 1`). The two mutation outputs are negative controls: a deliberately wrong compiler, and deliberately wrong *models*, run against the checks, where "caught" is the wanted result and "NOT CAUGHT" would be a gap.

## What a transformer is

A transformer reads a sequence of tokens (words or pieces of words, here just the numbers 0 to 4) and, for each position, produces a probability for every token that might come next. It does so with a stack of identical-shaped **blocks**, each of which does two things to a matrix with one row per token:

1. **Attention** lets every token gather information from the other tokens (Chapter 29). Rows are mixed.
2. A **feed-forward network** transforms each token on its own, the same way for every token. Rows are not mixed.

Each of the two steps is wrapped the same way: a **layer normalization** first (rescale each token's numbers to a standard size), then the step, then a **residual connection** (add the step's output back to its input, so each step only has to *adjust* the token, not rebuild it). Before the first block, token numbers become vectors by looking up a row of an **embedding** matrix, and a **position** vector is added, because attention on its own cannot tell which token came first. After the last block, one more layer norm and a matrix multiplication give a score per vocabulary entry, and a softmax turns the scores into probabilities.

This chapter writes exactly that, in Mountain Goat, with these sizes: **4 tokens** (so a `4x4` score matrix), **model width 4**, **2 heads** of width 2, **feed-forward width 8**, **vocabulary 5**, **2 blocks**.

## The one new operation: `sqrt`

Layer normalization divides by a standard deviation, which needs a square root. `sqrt(m)` takes the square root of every element, added the same way as `exp` in Chapter 29: `mg.sqrt` in the dialect with a shape verifier, a loop-nest lowering that uses `math.sqrt` (which becomes an LLVM intrinsic), and a built-in in the front end. The square root of a negative number is `nan`, as IEEE arithmetic says:

```text
print sqrt([[4, 2], [0, 9]])      ->  [[2, 1.41421], [0, 3]]
print sqrt([[-1]])                ->  [[-nan]]
```

(The minus sign in front of `nan` is the hardware's, and meaningless.)

## The definitions

The whole model, as functions. Every `def` is one line (a language rule), so the long ones are long; the comments say what each part does.

```text
--8<-- "docs/part30/code/transformer.mg.defs"
```

Read them from the bottom up, and compare with the description above:

- `ffn_sublayer` and `attention_sublayer` are the two wrapped steps: `x + step(layer_norm(x, ...))`. The `x +` is the residual connection. Because `layer_norm` is applied to `x` *before* the step and the residual adds to the *unnormalized* `x`, this arrangement is called **pre-norm** (the original 2017 transformer normalized after, "post-norm"; pre-norm is what most current models use, and either can be written).
- `ffn` is `relu(x @ w1 + b1) @ w2 + b2`: widen from 4 to 8 features, zero the negative ones, narrow back to 4. The biases `b1` (`1x8`) and `b2` (`1x4`) are one row stretched down all four tokens, the broadcasting of Chapter 22.
- `attention` is two `head`s, each producing a `4x2` result. A real implementation concatenates the heads side by side (`4x4`) and multiplies by one `4x4` output matrix. Mountain Goat has no concatenation, but the two are the same arithmetic: `concat(h1, h2) @ wo = h1 @ wo_top + h2 @ wo_bottom`, so `wo1` is the top half of that matrix and `wo2` the bottom half. (Only because the matrix product distributes over the split; no approximation.)
- `head` is Chapter 29's attention with projections: queries `x @ wq`, keys `x @ wk`, values `x @ wv`, the scores scaled by `1/sqrt(2) = 0.7071067811865476` and added to a **mask** (0 where a token may look, `-1e9` where it may not) before the softmax.
- `layer_norm` subtracts each row's mean, divides by the row's standard deviation (`sqrt` of the mean of squares of the centered row, plus `0.00001` so a constant row does not divide by zero), then multiplies by a learned scale `g` and adds a learned shift `b` (one number per feature, `1x4`, stretched down the rows).
- `softmax` and `softmax_vocab` are Chapter 29's stable softmax, once for the `4x4` attention scores and once for the `4x5` vocabulary scores.

## Layer normalization

```text
--8<-- "docs/part30/code/examples_out.txt:1:20"
```

Row 0, `1 2 3 4`, has mean 2.5 and standard deviation 1.118, so it becomes `-1.34164 -0.447212 0.447212 1.34164`. Row 1, `10 10 10 10`, is constant: the numerator is 0 and the division is `0 / sqrt(0.00001)`, which is exactly 0 (this is what the epsilon is for). Row 2, `-1 0 1 0`, has mean 0 and standard deviation 0.7071, so it becomes `-1.4142 0 1.4142 0`. Row 3, `0 0 0 8`, has mean 2 and standard deviation 3.4641. After normalization every row has mean 0 and variance 1 (the checker tests this on random matrices). The second matrix applies a scale of 2 and a shift of 5 to the same normalized rows: `-1.34164 · 2 + 5 = 2.31672`.

## The feed-forward network

```text
--8<-- "docs/part30/code/examples_out.txt:22:46"
```

The example chooses `w1 = [I | −I]` and `w2 = [I ; −I]` (an identity beside a negated identity, and the reverse). The hidden layer then holds `relu(x)` beside `relu(-x)`, and the output is `relu(x) − relu(−x)`, which is `x` itself: the first matrix prints the input unchanged. Two relus can build a straight line. The second matrix gives the first four hidden features a bias of `-1`, which hides every value below 1: the output is `relu(x − 1) − relu(−x)`, so row 0 (`1 −2 0 3`) becomes `0 −2 0 2`. This is all a feed-forward layer is: a weighted sum, a bend, and another weighted sum.

## The whole model

The generated program `examples/03_tiny_transformer.mg` is the definitions above, followed by the seeded weights (`let` statements), the token ids as one-hot rows, a causal mask, the sinusoidal position matrix, and the forward pass:

```text
let x0 = onehot @ emb + positions
let a1 = attention_sublayer(x0, mask, g1_1, bt1_1, wq1_1, wk1_1, wv1_1, wo1_1, wq2_1, wk2_1, wv2_1, wo2_1)
let y1 = ffn_sublayer(a1, g2_1, bt2_1, w1_1, b1_1, w2_1, b2_1)
let a2 = attention_sublayer(y1, mask, g1_2, ...)
let y2 = ffn_sublayer(a2, g2_2, bt2_2, w1_2, b1_2, w2_2, b2_2)
let probs = softmax_vocab(layer_norm(y2, gf, bf) @ wout)
```

`onehot @ emb` is the embedding lookup (a one-hot row times the embedding matrix picks one row of it; matrix multiplication is the lookup). The positions are `sin` and `cos` of the position at two frequencies, as in the original paper, computed by the generator and written as numbers (the language has no `sin`). The token ids are `[1, 3, 0, 2]`. It prints four matrices: the embedded input, the output of block 1, the output of block 2, and the probabilities:

```text
--8<-- "docs/part30/code/examples_out.txt:48:71"
```

The last matrix is the answer: row *i* is the model's probability for each of the five tokens coming after token *i*. Every row is positive and sums to 1. They range from about 0.08 to 0.36, scattered around the uniform 0.2 that an untrained model's would be; the checker confirms that they equal the Python reference's to six digits.

### The future cannot influence the past

The causal mask is meant to guarantee that row *i* depends only on tokens `0..i`. Example 4 changes **only the last token**, from `2` to `4`:

```text
--8<-- "docs/part30/code/examples_out.txt:73:96"
```

Compare it with the previous output: rows 0, 1 and 2 of all four matrices are **identical**, digit for digit, in the embedded input, in both blocks and in the probabilities, and only row 3 changed. That is causality, shown in the output, and it is a checked property, not a coincidence of the example (see Tests). Without the mask, changing the last token would change every row.

## Mistakes the compiler reports

```text
--8<-- "docs/part30/code/examples_out.txt:98:135"
```

In order: three tokens passed to a layer norm written for four; eleven arguments to a function that takes twelve (the shapes of all twelve are checked at the call); `sqrt` of a bare number; and a residual connection whose two sides have different shapes (a `4x2` head output added to a `4x4` input). Every one is caught when compiling, with the file and line. The model's shapes are *types*: a wrong-shaped weight cannot be connected.

## Tests

Five new `lit` files in `test/transformer30/` (the suite is now 122 tests):

| Test | What it checks |
|---|---|
| `examples` | layer norm and feed-forward (worked out by hand) and the model's outputs, including that example 4's rows 0 to 2 equal example 3's |
| `errors` | the four mistakes give the exact messages, with file and line |
| `verifiers` | `mg.sqrt` given a result of a different shape is rejected by the dialect |
| `ir` | layer normalization is a reduce, subtract, multiply, reduce, `mg.sqrt`, divide, multiply, add, in that order |
| `against-reference` | `check_transformer.py`, below |

`check_transformer.py` is the real test. Its reference (`transformer_lib.py`) is an **independent** implementation: plain Python lists, `math.exp` and `math.sqrt`, written from the definition of each step rather than translated from the Mountain Goat. It checks:

1. **Every stage against the reference** for four weight sets and four token sequences (including all tokens equal): the embedded input, block 1, block 2 and the probabilities, to a relative 10<sup>-5</sup> (`mgc` prints six digits), and that each probability row is positive and sums to 1.
2. **Stress:** weights scaled up until the attention scores reach the hundreds and the vocabulary scores the thousands. The output must contain no `nan` or `inf` and must still equal the reference. A naive softmax overflows here.
3. **Causality:** for each of the last three positions, change that token and require rows before it to be *identical* (the printed numbers equal, with no tolerance) in block 1, block 2 and the probabilities, and row *j* itself to change (otherwise a model that ignores its input would pass). Without the mask, changing the last token must change row 0, so the mask is shown to be what causes the first property.
4. **Permutation equivariance:** with no positions and no mask, the output for a reordered input must be the original output reordered the same way, for three orders. With positions added, the same reordering must **not** be a reordering of the output (positions break the symmetry; a test that always passed would prove nothing).
5. **Layer norm:** on random matrices with scale 1 and shift 0, rows have mean 0 and variance 1, and a constant row becomes exactly 0.

```text
--8<-- "docs/part30/code/check_transformer_out.txt"
```

### Are the checks good enough? Run fifteen wrong models.

A test of a model should notice a wrong model. `model_mutation.py` writes fifteen versions of `transformer.mg.defs`, each with one deliberate mistake (the mask not applied, the scale missing, a wrong epsilon, a missing residual, no relu, values taken from the keys, and so on), and runs the checker on each:

```text
--8<-- "docs/part30/code/model_mutation_out.txt"
```

All fifteen are caught. The last two (a naive softmax in the attention, and in the vocabulary) are the interesting ones: **the first version of this checker did not catch them.** With the seeded weights, the scores are small, and `exp` of a small number does not overflow, so a naive softmax gives the right answer and no comparison with the reference can tell the two apart. They are caught only by the *stress* check, which was added after the first run of this script showed the gap. A correct-looking test with friendly numbers cannot see a numerical-stability bug; this is Chapter 29's lesson again, now at the level of a whole model.

### Compiler mutations

`sqrt` is a new compiler operation, so the compiler itself is also broken on purpose, six ways:

```sh
--8<-- "docs/part30/code/mutation.sh"
```

```text
--8<-- "docs/part30/code/mutation_out.txt"
```

All six are caught. The verifier mutation is caught only by the dedicated `verifiers` test (no program the front end writes can reach it, because the front end builds `mg.sqrt` with matching shapes), which is why that test exists. The last mutation, a sum that starts from 1 instead of 0, is not about `sqrt` at all: it breaks `row_sum` and `row_mean`, which layer norm and the softmax both lean on, and it shows that the transformer tests would also notice a regression in an operation from an earlier chapter.

The full suite:

```text
--8<-- "docs/part15/code/run_out_122.txt"
```

## Limits and what is not established

- **Not trained.** The weights are seeded pseudo-random numbers. The probabilities are not language. Nothing here shows the model can learn, and no claim is made that it would learn well if trained.
- **Tiny and fixed.** 4 tokens, width 4, 2 heads, 2 blocks, vocabulary 5. All sizes are static (a `?` size cannot be stretched, Chapter 22), so a different sequence length means different definitions. Nothing was run at a realistic size, and nothing was timed.
- **No batching, and heads are hand-split.** There is no batched matrix product, so the two heads are written out separately and their outputs combined with the split output matrix described above. A model with many heads would need either many such lines or batched matrix multiplication, which the language does not have.
- **Positions are given as numbers.** The sinusoidal position matrix is computed by the Python generator and written into the program, because the language has no `sin` or `cos`. Learned position vectors would work unchanged.
- **No argmax or sampling.** The program ends at probabilities. Choosing the most likely token or sampling one happens outside the language (the checker reads the printed matrix).
- **Pre-norm only, no dropout, no weight tying.** Other variants (post-norm, a final-layer bias, tying the output matrix to the embedding) are small changes, not written.
- **The mask uses `-1000000000`, not minus infinity** (Chapter 29), and the layer-norm epsilon is a literal `0.00001`.
- **Six digits.** Everything is compared at a relative 10<sup>-5</sup>, since `mgc` prints six significant digits. Exact equality was not possible or claimed (except for the causality property, where the printed digits are identical).
- **Equivalence of the head split** to concatenating heads is argued (the matrix product distributes), and the model agrees with a reference that *also* uses the split. A reference using real concatenation was not written.
- **`exp` comes from the platform's C library and `sqrt` is an LLVM intrinsic** (normally one hardware instruction); their last-digit accuracy was not measured here. GPU lowering of either is not covered.
- **Platform:** x86-64 Linux, LLVM 18.1.3.

## Reproducing

```sh
cd docs/part30/code && ./build.sh
python3 make_examples.py && ./run_examples.sh > examples_out.txt
./check_transformer.py > check_transformer_out.txt
./model_mutation.py > model_mutation_out.txt
./mutation.sh > mutation_out.txt
cd ../../part15/code && ./run_lit.sh          # 122 tests
```

## Chapter summary

- A transformer block is attention (mixes tokens) plus a feed-forward network (transforms each token), each wrapped in a layer norm and a residual connection. A model is an embedding, positions, a stack of blocks, a final layer norm and a softmax.
- With `sqrt` added, all of that is a few lines of Mountain Goat, and the shapes of every weight are types the compiler checks.
- The program agrees with an independent Python version at every stage, for several weights and token sequences, and has the properties it must: probabilities sum to 1, the future cannot influence the past, reordering tokens reorders outputs when positions are absent, layer-norm rows are normalized, and huge scores do not overflow.
- Fifteen wrong models and six broken compilers are all caught; two of the wrong models were caught only after a stress case was added, which is a finding about the checker, reported as such.
- The model is untrained, tiny and fixed in size. Training, batching and variable lengths are what would come next.

## Self-check questions

Each answer is collapsed; try the question first.

1. In one sentence each: what does attention do, what does the feed-forward network do, and which of them mixes information between tokens?

    ??? note "Answer"
        Attention lets each token gather a weighted average of information from tokens it may look at, so it mixes rows. The feed-forward network applies the same two-layer transformation to every token separately, so it does not mix rows. Only attention moves information between positions.

2. What does a residual connection do, and what would happen to the "no residual" mutations' outputs?

    ??? note "Answer"
        It adds a sublayer's output to its own input (`x + step(x)`), so the sublayer only has to learn an adjustment and the original information is kept. Without it the output is only what the sublayer computed, which is a different matrix, so the comparison with the reference fails at the first block. (In a *trained* deep model a missing residual also makes training hard; that is not tested here since nothing is trained.)

3. Why is the layer norm's epsilon needed? What does `layer_norm` produce for the constant row `10 10 10 10`?

    ??? note "Answer"
        The row's variance is 0, so without an epsilon the division would be `0/0`, which is `nan`. With the `0.00001`, the numerator `x − mean` is exactly 0 and the denominator is `sqrt(0.00001)`, so the result is exactly 0 (then the learned scale and shift apply). Example 1's second row shows `0 0 0 0`.

4. Why does the checker require rows before the changed token to be **identical**, not merely close?

    ??? note "Answer"
        With the causal mask the masked scores are `-1e9`, whose exponentials are exactly 0, so earlier rows are computed from exactly the same numbers through exactly the same operations and must be bit-for-bit equal. A tolerance would let a small leak of future information through (for instance a mask that was `-5` instead of `-1e9`). Equality is a sharper test than closeness here.

5. Why does the checker also require that changing token *j* changes row *j*, and that removing the mask changes row 0?

    ??? note "Answer"
        A model that ignored its input entirely would pass "earlier rows do not change" trivially, and so would a mask that has no effect. Requiring row *j* to change shows the model reads its input; requiring row 0 to change without the mask shows the mask, not something else, is what makes the earlier rows independent of later tokens.

6. Why is permutation equivariance tested **without** positions and expected to **fail** with them?

    ??? note "Answer"
        Attention treats its input as a set: reordering the rows reorders the outputs the same way, because nothing in the computation depends on row order (the feed-forward and layer norm work row by row). Positions are added precisely to break that symmetry, so with positions the same reordering must *not* just reorder the output. Checking both directions shows the property is real and that the position matrix does its job.

7. Why does the hand-split of the heads (`h1 @ wo1 + h2 @ wo2`) equal concatenating the heads and multiplying by one output matrix?

    ??? note "Answer"
        Concatenating two `4x2` matrices side by side gives a `4x4` matrix `[h1 | h2]`. Multiplying by a `4x4` matrix `W` whose top two rows are `wo1` and bottom two rows are `wo2` gives, for each output element, a sum over four terms: the first two come from `h1` and `wo1`, the last two from `h2` and `wo2`. That is exactly `h1 @ wo1 + h2 @ wo2`. The matrix product distributes over the split, so no approximation is involved.

8. Two of the fifteen wrong models passed the first version of the checker. Which, why, and what fixed it?

    ??? note "Answer"
        The two with a naive softmax (no row-maximum subtraction), in the attention and in the vocabulary. With the seeded weights all scores are small, so `exp` does not overflow and the naive formula gives the same numbers as the stable one; no reference comparison could tell them apart. The *stress* check scales the weights until the scores reach the hundreds and thousands, where the naive softmax gives `nan` and the stable one does not.

9. What would be needed to train this model, and which parts of it does the language lack?

    ??? note "Answer"
        Gradients of the loss with respect to every weight, computed by differentiating through each operation (matrix product, softmax, layer norm, relu, residuals), plus an update rule such as gradient descent. Chapter 26 did this by hand for a linear model. Mountain Goat has no automatic differentiation, no loss function (cross-entropy needs a logarithm, which the language lacks), and no way to select one probability from a row (an index or argmax operation).

10. What is the difference between this model's embedding lookup and a lookup table in a conventional language?

    ??? note "Answer"
        Here the lookup is a matrix product: a one-hot row (a single 1 among zeros) times the embedding matrix returns exactly one row of it. It does the work of an index, with `V` times the arithmetic, but it needs no indexing operation (the language has none) and it is differentiable, which is why real frameworks use the same idea for the gradient of an embedding.
