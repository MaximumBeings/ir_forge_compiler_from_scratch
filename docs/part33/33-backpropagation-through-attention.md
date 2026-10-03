# 33. Backpropagation Through Attention: Training a One-Head Classifier

<p style="text-align:center"><img src="../assets/goats/ch-33.svg" alt="Mountain goats on the mountain in black and white at dusk" style="max-width:100%;height:auto;border-radius:6px"></p>

**What you will understand:** how a model with **attention** is trained, by working out its gradient by hand, step by step backwards through the computation (**backpropagation**), writing every step as a Mountain Goat function, and training the model with it. The model reads four tokens in any order and must say which one ranks highest under a hidden priority list: a job a bigram (Chapter 31) cannot do, because the answer depends on all four tokens. The backward pass, including the one tricky piece (the gradient through a softmax), is checked three ways: against an independent Python calculation done one token at a time, against a numerical estimate for every one of its 48 weights, and by whether the training run it drives lands where the reference lands. Then the trained model is tried on **all 625 possible inputs**, and the one it gets wrong is explained.

**What you need to know first:** Chapter 29 (attention), Chapter 31 (cross-entropy loss and the gradient of a softmax output) and Chapter 28's `reshape`. **No new compiler operation** is needed: the chapter's programs run on Chapter 32's compiler. It is also the first chapter whose model has more than one layer of structure to differentiate, so the section "The backward pass" is the heart of it.

!!! tip "Compile and run"
    ```sh
    cd docs/part32/code && ./build.sh                 # once: the newest compiler (this chapter adds nothing to it)
    cd ../../part33/code
    python3 make_examples.py                          # (re)writes the examples from attn_lib.py
    ../../part32/code/mgc run examples/03_train.mg    # train for 200 steps, then try every possible sequence (about 10 seconds)
    ./run_examples.sh > examples_out.txt              # every example and every error example on this page
    ./check_attention_training.py                     # the backward pass and the training run against the independent Python version
    ./model_mutation.py > model_mutation_out.txt      # runs 10 WRONG backward passes through the checker (nine are caught; see the page)
    cd ../../part15/code && ./run_lit.sh              # the whole test suite
    ```
    Every listing and output on this page comes from these commands.

!!! note "Why this page shows FAIL lines and error messages, and why that is good"
    The three error examples are programs the compiler must reject (each ends `exit status 1`). The mutation output is a negative control: deliberately wrong backward passes run against the checker, where "caught" is the wanted result and "NOT CAUGHT" would be a gap.

## The task

A sequence is four tokens, each one of 0 to 4. A hidden **priority list** ranks the tokens: `1, 3, 2, 0, 4`, first is highest. The **label** of a sequence is the token *present in it* that comes first in the list:

| sequence | label | why |
|---|---|---|
| 2 1 1 1 | 1 | token 1 is present, and it ranks first |
| 3 2 0 2 | 3 | no 1; 3 ranks next |
| 2 2 3 0 | 3 | |
| 3 4 2 2 | 3 | |
| 4 4 0 4 | 0 | no 1, 3 or 2; 0 beats 4 |
| 4 4 4 4 | 4 | only token 4 is present |

The model is shown 24 random sequences with their labels (the *training* set) and 40 more it never trains on (the *held-out* set). It is never told the rule. Order does not matter: `2 1 1 1` and `1 2 1 1` have the same label. That is the job attention is built for: it looks at all the tokens at once and combines them, with no preference for position.

(The data are deliberately lopsided, as random sequences are. Of the 24 training labels, 13 are 1, 8 are 3, 2 are 2, 1 is 0 and none is 4; of the 40 held-out labels, 22 are 1, 13 are 3, 5 are 2 and none is 0 or 4. Label 4 requires a sequence made only of 4s, which is 1 in 625. This will matter at the end.)

## The model

One attention head, with a learned **query** `q` (1×3), and tables that turn a token into a **key** and a **value** (`wk` and `wv`, each 5×3, one row per token), then an output matrix `wo` (3×5) that turns the attended value into a score for each of the five possible labels:

1. each token's **score** is its key's dot product with the query, divided by √3: `score_n = q · key(token_n) / √3`;
2. a softmax over the four scores gives the **attention weights** `a` (four positive numbers adding to 1);
3. the **context** is the attention-weighted average of the four values: `h = Σ a_n · value(token_n)` (a 1×3 row);
4. the **logits** are `h @ wo` (one score per label), and a softmax and cross-entropy loss (Chapter 31) measure how surprised the model is by the true label.

That is 3 + 15 + 15 + 15 = **48 numbers** to learn.

**Doing it for 24 sequences at once, with only matrix operations.** Mountain Goat has no batched matrix product, so the sequences are stacked: `x` has 96 rows (the four one-hot token rows of sequence 0, then of sequence 1, and so on). Keys and values for all tokens at once are `x @ wk` and `x @ wv` (96×3). The scores are `(x @ wk) @ transpose(q)`, a 96×1 column; **`reshape` turns it into 24×4**, one row per sequence, so a row-wise softmax is a softmax within each sequence. To add up each sequence's four weighted values, a constant **group matrix** `g` (24×96, with a 1 where column ÷ 4 equals the row) does it as a matrix product: `g @ (values * weights)`.

### Attention for one sequence, by hand

First the forward pass on one sequence of four tokens (1, 3, 2, 0) with numbers small enough to follow. The query is `(1, 0)`, so a token's score is the first number of its key (times 0.7071):

```text
--8<-- "docs/part33/code/examples_out.txt:1:23"
```

Token 1 scores 2, token 3 scores 1.5, token 2 scores 1 and token 0 scores 0, all times 0.7071: `1.41421, 1.06066, 0.707107, 0`. The softmax gives the attention weights `0.410, 0.288, 0.202, 0.0997`: token 1 gets the most. The context is the weighted average of the four values (`[10, 0]`, `[5, 0]`, `[0, 10]`, `[1, 1]`): `0.410·10 + 0.288·5 + 0.0997·1 = 5.64` and `0.202·10 + 0.0997·1 = 2.12`.

## The backward pass

Training needs the gradient: how the loss changes with each of the 48 numbers. It is found by the **chain rule**, working backwards from the loss one step at a time. Each step takes the gradient with respect to a step's *output* and produces the gradient with respect to its *inputs*. Write `B` for the number of sequences (24), `dX` for "the gradient of the loss with respect to X":

| forward step | backward step (what the Mountain Goat function computes) |
|---|---|
| `logits = h @ wo`, loss = cross-entropy | `dlogits = (softmax(logits) − y) / B` (Chapter 31's result, one row per sequence) |
| ↳ weights `wo` | `dwo = hᵀ @ dlogits` |
| ↳ context `h` | `dh = dlogits @ woᵀ` (one row per sequence) |
| `h = Σ a_n · v_n` | every token row of sequence *b* receives sequence *b*'s `dh`: `dh_tokens = gᵀ @ dh` (96×3) |
| ↳ values | `dv = dh_tokens * a` (each token's share of `dh` is scaled by its attention weight), and `dwv = xᵀ @ dv` |
| ↳ attention weights | `da_n = dh_n · v_n` (how much the loss would change per unit of attention on token *n*): `row_sum(dh_tokens * v)` |
| `a = softmax(s)` | `ds = a * (da − Σ a·da)` (below) |
| `s = q · k / √3` | `dq = dsᵀ @ K / √3`, `dK = ds @ q / √3`, and `dwk = xᵀ @ dK` |

**The one new piece of calculus is the softmax backward step.** If the loss depends on `a = softmax(s)` through `da`, then the derivative with respect to score `s_i` is `a_i · (da_i − Σ_j a_j da_j)`. Each score affects *its own* weight directly (the `a_i da_i` part) and every other weight indirectly, because the weights must sum to 1 (the `− a_i Σ_j a_j da_j` part). Forgetting the second part is the most natural mistake. A tiny example computes it by the formula and by brute force (nudge each score by 0.01 up and down and watch the loss change):

```text
--8<-- "docs/part33/code/examples_out.txt:25:47"
```

The formula's `[0.309696, −0.12646, −0.183235]` and the three brute-force numbers `0.309696, −0.126462, −0.183235` agree. The check on the whole model does this for all 48 weights.

Writing it down as functions (the definitions below are the program, in order: the forward pass first, then one function per gradient):

```text
--8<-- "docs/part33/code/attention.mg.defs"
```

`attn_matrix` is the 24×4 matrix of attention weights (the reshape makes the softmax work within each sequence); `context` is the group-matrix product; `d_logits`, `grad_wo`, `d_context_rows`, `grad_wv`, `d_attn_matrix`, `d_scores`, `grad_q` and `grad_wk` are the backward table, row by row. The gradients with respect to `wv` and `wk` collect contributions from every token of every sequence through `xᵀ @ …`: a token that appears in several places receives the sum of the gradients of those places, which the matrix product does automatically.

## Training

`examples/03_train.mg` is the definitions, the data (as matrices), seeded starting weights, then 200 unrolled steps (four `let` lines each: every parameter minus the learning rate 3 times its gradient), and prints. First the loss and the number of correctly classified training sequences at eight checkpoints (pairs of numbers: loss, then count):

```text
--8<-- "docs/part33/code/examples_out.txt:52:83"
```

| after step | 0 | 1 | 5 | 10 | 25 | 50 | 100 | 200 |
|---|---|---|---|---|---|---|---|---|
| loss | 1.601 | 1.514 | 0.626 | 0.274 | 0.0904 | 0.0098 | 0.00168 | **0.000522** |
| correct of 24 | 0 | 18 | 21 | 21 | 24 | 24 | 24 | **24** |

The loss starts near `log 5 = 1.609` (the model knows nothing; the seeded start gives 1.601) and falls at every checkpoint to 0.0005. After one step 18 of 24 are already right, helped by the lopsided data (13 of the 24 are labelled 1). All 24 are right from step 25 on. The final trained numbers, and then **each token's attention score** (`wk @ transpose(q) / √3`, the last matrix):

```text
--8<-- "docs/part33/code/examples_out.txt:84:107"
```

### What did the attention learn?

The five scores, by token: `0: −3.44`, `1: +3.76`, `2: −0.11`, `3: +2.36`, `4: −2.61`. Sorted from highest: **1, 3, 2, 4, 0**. The hidden rule is `1, 3, 2, 0, 4`. So the model found the first three correctly and in order, and swapped the last two: it gives token 4 more attention than token 0. (The checker confirms this rather than assuming the model learned the rule.)

Does the model attend to the answer? Here are the attention weights for all 24 training sequences:

```text
--8<-- "docs/part33/code/examples_out.txt:108:132"
```

For `3 1 2 0` (label 1) the weights are `0.195, 0.788, 0.016, 0.001`: most attention goes to the 1, as hoped. But the weights are not a clean lookup: for 13 of the 24 sequences more than 90% of the attention lands on label tokens, for only 6 more than 99%, and for the sequence `4 4 0 4` (label **0**) the weights are `0.291, 0.291, 0.127, 0.291`: **the model puts less than half as much attention on the 0 as on each of the 4s, and still gets the answer right.** The values (and `wo`) do the rest of the work: the model learned a combination of how much to attend and what each token contributes, not "attend to the winner". This is a general caution: **attention weights are part of the computation, not an explanation of it.**

### Held-out and every possible sequence

The model never trained on the 40 held-out sequences:

```text
--8<-- "docs/part33/code/examples_out.txt:133:136"
```

Held-out loss `0.000606` and **40 of 40 correct**. But look at the labels of those 40: 22 are 1, 13 are 3, 5 are 2. A model that always output 1 or 3 would score well, so this is a weak test. A stronger one: there are only 5⁴ = **625** possible sequences, and the program tries all of them, 25 at a time. The number correct in each chunk of 25:

```text
--8<-- "docs/part33/code/examples_out.txt:137:186"
```

Twenty-four chunks have 25 correct, and the last has **24**. In total **624 of 625** sequences are classified correctly: all of them but one. Which one? The last sequence in the last chunk, `4 4 4 4`, label 4. Here are the model's scores for that chunk (its last row is `4 4 4 4`):

```text
--8<-- "docs/part33/code/examples_out.txt:187:212"
```

The last row is `[7.84, −1.24, 1.40, −8.45, 0.49]`: the highest score is token **0**, so the model says 0 where the answer is 4. This failure has a clear cause. **Label 4 never occurs in any of the 64 sequences the model saw**, so nothing in training ever rewarded outputting 4: to a model trained on 24 sequences with labels 0, 1, 2 and 3, the sequence `4 4 4 4` carries no evidence at all. (Compare Chapter 32: the held-out pairs that failed were the ones the training pairs never showed.) What is notable is the other direction: the model is correct on all 15 other sequences made only of 0s and 4s, whose label is 0, though in training it saw exactly one sequence with label 0.

## Mistakes the compiler reports

```text
--8<-- "docs/part33/code/examples_out.txt:215:244"
```

A batch of 23 sequences (92 rows) where 24 (96 rows) are expected; the group matrix passed transposed (96×24 where 24×96 is wanted); and a reshape that does not keep the number of elements. As in earlier chapters the shapes are types, and a trainer cannot be connected to data of the wrong size.

## Tests

Three new `lit` files in `test/attention33/` (the suite is now 135 tests). There is no `verifiers` or `ir` test because this chapter adds no compiler operation:

| Test | What it checks |
|---|---|
| `examples` | the two small examples (worked out above) and the training run's loss and correct-count at every checkpoint |
| `errors` | the three shape mistakes give the exact messages |
| `against-reference` | `check_attention_training.py`, below |

`check_attention_training.py` compares with an **independent** Python implementation (plain lists; the gradient derived **token by token** with loops, not as matrix algebra) and checks, in order:

1. **The gradient**, for three different random starting weight sets: the loss and all four gradients equal the reference's, and **the gradient of every one of the 48 weights agrees with a finite-difference estimate** (nudge the weight by 0.01 up and down, watch the loss). The largest disagreement is about `4·10⁻⁴`; the tolerance is `2·10⁻³` because `mgc` prints the loss to six digits.
2. **Training:** the loss and the correct count at all eight checkpoints, the final weights, each token's attention score and the 24×4 attention weights equal the reference's.
3. **Learning:** the loss falls at every checkpoint to below 0.001; all 24 training and all 40 held-out sequences are right.
4. **Every sequence:** the count in each of the 25 chunks equals the reference's, the total is 624, and the single failure is `4 4 4 4`, with the label that never occurs in the data.
5. **Attention scores:** found rather than assumed: the three highest tokens are the three highest in the priority list in order, and the last two are in the opposite order (so the check would fail if a different training run learned the rule exactly, which is the point of looking).

```text
--8<-- "docs/part33/code/check_attention_training_out.txt"
```

### Are the checks good enough? Run ten wrong backward passes.

`model_mutation.py` writes ten versions of the definitions, each with one mistake mostly in the hand-derived backward pass (the softmax backward missing its second term, a forgotten `1/√d`, the wrong sign, the wrong average, keys used where values belong, and so on), and runs the checker on each:

```text
--8<-- "docs/part33/code/model_mutation_out.txt"
```

Nine of the ten are caught, and by the right checks. The two forgotten `1/√d` scales and the missing attention weighting in `grad_wv` are caught by the reference and by the finite-difference check but **not** by the learning checks that follow, because a gradient that is wrong in size or in detail but still points roughly downhill still trains (more slowly or faster, to the same kind of answer here); only comparing the gradient itself notices. The wrong-sign and wrong-average versions of `d_logits` are caught by almost everything. The forward-pass scale mutation shows why the finite-difference check is worth having: the hand-derived gradient still describes the *original* function, so it no longer matches the changed loss. The tenth (a naive softmax) is **not caught**, as I predicted before running it: nothing in this chapter drives the attention scores into the range where `exp` overflows.

There is no compiler-mutation run for this chapter: no compiler code changed.

The full suite:

```text
--8<-- "docs/part15/code/run_out_135.txt"
```

## Limits and what is not established

- **A toy task and a toy model.** Four tokens, five token types, one head, no positions, 48 parameters. The task was chosen so that the answer is the same for every ordering of the tokens, which suits attention without position information. Nothing here shows the method scales or that a full transformer trains the same way.
- **Only the backward pass of THIS model is derived.** There is no automatic differentiation: the nine backward functions are specific to this network. Chapter 30's transformer (layer normalization, two heads, a feed-forward network, residual connections, several blocks) would need a hand-derived backward pass for each of its parts; the pattern above (take the gradient with respect to a step's output, produce the gradient with respect to its inputs) carries over, but it was **not done**, and Chapter 30's weights are still random.
- **Training data are lopsided and tiny.** 13 of 24 training labels are 1; label 4 never occurs. The 40-sequence held-out score (40/40) is a weak test, for the reason shown; the exhaustive test over all 625 sequences is stronger, and it is possible only because the input space is tiny. 624/625 says nothing about larger problems.
- **The one miss is a data gap, not necessarily a method failing.** A different set of 24 sequences, or one that contained a sequence labelled 4, would change it. Nothing here tries other data sets or other starting weights beyond the three used for the gradient check.
- **Learning rate and steps were chosen by trying.** 3 and 200, after trying 1 and 3 on two starting points in plain Python. No claim of optimality, no schedule, no stopping rule.
- **The model solves the task in its own way,** not by the rule (it ranks token 4 above 0 and still classifies `0 4 0 4`-style sequences correctly, through the values). The attention weights should not be read as an explanation.
- **Finite-difference checks are limited by printing:** six digits, step 0.01, tolerance `2·10⁻³`.
- **No naive-softmax test:** the attention scores stay below about 4 in size, where `exp` does not overflow, so the checks cannot tell a naive softmax from the stable one here (the last wrong version above shows exactly that). Chapters 29 to 32 cover that regime.
- **Platform:** x86-64 Linux, LLVM 18.1.3.

## Reproducing

```sh
cd docs/part32/code && ./build.sh
cd ../../part33/code
python3 make_examples.py && ./run_examples.sh > examples_out.txt
./check_attention_training.py > check_attention_training_out.txt
./model_mutation.py > model_mutation_out.txt
cd ../../part15/code && ./run_lit.sh          # 135 tests
```

## Chapter summary

- Backpropagation is the chain rule applied backwards: from the loss, take each step's output gradient and produce its input gradients. For one-head attention that is nine short matrix expressions, and the only new calculus is the softmax backward step `a * (da − Σ a·da)`.
- Without a batched matrix product, a batch is handled by stacking sequences, a constant group matrix to sum within a sequence, and `reshape` so a row-wise softmax acts within each sequence.
- The hand-derived backward pass equals an independent token-by-token computation and a finite-difference estimate for all 48 weights, for three different starting points.
- Trained for 200 steps, the model classifies all 24 training and 40 held-out sequences correctly and 624 of all 625 possible sequences; the miss, `4 4 4 4`, is a label that never appears in the data.
- The attention is partly a lookup (it ranks tokens 1, 3, 2 correctly) and partly not (it ranks 4 above 0, and attends to the 4s in a sequence labelled 0): attention weights are not an explanation.
- Nine of ten wrong backward passes are caught, mostly by the gradient comparisons alone; the tenth, a naive softmax, is not caught, as expected, because the scores here never get large enough to overflow `exp`.

## Self-check questions

Each answer is collapsed; try the question first.

1. Why can a bigram not solve this task, and why is attention a natural fit?

    ??? note "Answer"
        The label depends on all four tokens (which of them are present), not on the most recent one, and a bigram sees only one token. Attention looks at every token in the sequence at once and combines them into one context vector, with no dependence on order, which matches a label that is the same for every ordering.

2. Why does the model stack 24 sequences into a 96-row matrix, and what do the group matrix and the `reshape` do?

    ??? note "Answer"
        Mountain Goat has no batched matrix product, so a batch is handled as one big matrix. The scores come out as a 96×1 column; `reshape` makes it 24×4 so that a row-wise softmax runs within each sequence (each row holds one sequence's four scores). The group matrix (24×96, with 1s where column ÷ 4 equals the row) turns the sum over each sequence's four weighted values into a matrix product.

3. Write the gradient of the loss with respect to the attention scores in one line, and explain each part.

    ??? note "Answer"
        `ds = a * (da − Σ a·da)`, where `a` is the attention weights, `da` the gradient with respect to them, and the sum is within each sequence. A score changes its own weight (the `a·da` part) and, because the four weights must add to 1, also every other weight (the `− a·Σ a·da` part). Leaving out the second part treats the softmax as if each output depended only on its own input.

4. Why does the checker compare the gradient both with an independent Python calculation *and* with finite differences?

    ??? note "Answer"
        They catch different things. The Python gradient is written independently from the same mathematics: it catches a mistake in the Mountain Goat translation, but if both derive the same wrong formula it would agree with itself. Finite differences use only the loss function, not any derived formula, so they catch a wrong derivation. A wrong gradient has to fool both to survive.

5. The model attends more to the 4s than to the 0 in `4 4 0 4` and still outputs the correct label 0. What does this say about reading attention weights?

    ??? note "Answer"
        The output depends on the attention weights *and* the values and the output matrix. The model learned values and an output matrix that, combined with this attention pattern, favour label 0 when the sequence contains a 0 and nothing higher. So attention weights alone do not say what the model "looked at" in a meaningful sense; they are one part of the computation.

6. Why is "40 of 40 held-out sequences correct" a weak result here, and what is the stronger test?

    ??? note "Answer"
        Random sequences are dominated by labels 1 and 3 (22 and 13 of the 40, with 5 labelled 2 and none labelled 0 or 4). A model that handles only the common labels can score well. Because there are only 625 possible sequences, the program can try every one; that test includes the rare labels, and it is where the single failure appears.

7. Why does the model fail on `4 4 4 4`, and would you call that overfitting?

    ??? note "Answer"
        The label of `4 4 4 4` is 4, and label 4 never occurs among the 64 training and held-out sequences, so nothing in training ever rewarded the output 4. It is a gap in the data, not memorizing noise: the model is right on every other sequence, including the 15 that have label 0 though only one had that label in training. It is closer to a missing-evidence failure than to Chapter 32's overfitting, though both come from the model having no way to know what training never showed.

8. Which parts of the backward pass would be needed to train Chapter 30's transformer that are not here?

    ??? note "Answer"
        The gradients through layer normalization, the residual connections (which add gradients along two paths), a second attention head and its output split, the position matrix, the relu feed-forward network and its biases, and the stacking of several blocks, each with its own weights. The principle in this chapter's table applies to each, but each needs its own derivation and its own check against finite differences; none was done.

9. The wrong backward pass with a naive softmax in the attention was not caught. Why is that expected, and what would catch it?

    ??? note "Answer"
        The attention scores in this model stay below about 4 in size, and `exp` of such numbers cannot overflow, so the naive softmax computes the same numbers as the stable one. To catch it a test needs scores in the hundreds, like the stress cases of Chapters 29 to 32.

10. What would change if the labels were 1 for sequences containing token 1 and 0 otherwise (two classes)?

    ??? note "Answer"
        Only the number of output columns: `wo` would be 3×2 instead of 3×5, and the label matrices 24×2. The forward and backward formulas are the same, because the loss and the gradient `(softmax − y)/B` do not depend on the number of classes. In Mountain Goat the shapes are types, so the function definitions would be regenerated with 2 in place of 5.
