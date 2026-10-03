# 41. Compiling Mountain Goat to GA-1: Fusion, Tiling and Why Decoding Is Memory-Bound

**What you will understand:** what it takes to send real Mountain Goat programs, including a transformer block, to Chapter 40's model accelerator, and what the compiler's decisions are worth there. The back end reads the same `mg` dialect text that `mgc mlir` writes for the CPU path, and produces a GA-1 program: a matmul becomes Chapter 40's blocked schedule (block shape chosen by comparing the analytic model), a run of elementwise operations becomes one **fused** kernel that keeps its intermediates in the scratchpad, and reductions and transposes become tile loops. Every program it accepts is run on the simulator and its printed matrices are compared with `mgc run`'s. Then the chapter measures three things on GA-1: what common-subexpression elimination, fusion and double buffering are each worth; where a transformer block spends its time; and why running one token at a time (decode) leaves the matrix unit nearly idle while many tokens at once (prefill) do not.

**What you need to know first:** Chapter 40 (GA-1, tiles, double buffering, the analytic model) and Chapters 29 and 30 (softmax, attention, the transformer block). The Mountain Goat compiler is used only for its front end (`mgc mlir`); nothing in the compiler changes.

!!! warning "This is a model, not a chip"
    GA-1's parameters are invented (Chapter 40 says so), so every cycle count here describes GA-1 only. What transfers to real hardware is the shape of the argument: fusion removes round trips to memory, a one-token matmul is limited by streaming the weights, and the same weights serve many tokens for free. The ratios are not calibrated against any device.

!!! tip "Compile and run"
    ```sh
    cd docs/part41/code                                   # plain Python 3; needs the Chapter 38 build for `mgc mlir` (../../part38/code/build.sh)
    ./show_program.py > show_program_out.txt             # kernels of the stable softmax, with and without fusion
    ./compare_with_cpu.py > compare_out.txt              # all book examples: GA-1 result against `mgc run` (about 2 minutes)
    ./studies.py > studies_out.txt                       # options, decode versus prefill, a transformer block (about 50 seconds)
    ./check_backend.py                                   # the checks of this page (about 45 seconds)
    ./backend_mutation.py > backend_mutation_out.txt     # 14 WRONG back ends the checker must catch (about 12 minutes)
    cd ../../part15/code && ./run_lit.sh                 # the whole test suite
    ```
    Every listing and output on this page comes from these commands.

!!! note "Why this page shows a mutation run, and why 'caught' is the wanted result"
    `backend_mutation.py` writes broken versions of the back end and the simulator and expects the checker to fail on each. "Caught" is good; "NOT CAUGHT" would be a gap. Nothing on this page is a failing test.

## What the back end does

It is a Python program over the *text* of the IR, not an MLIR pass (a limit, below). The steps:

1. **Parse and flatten.** Read the `func.func` bodies of `mgc mlir`, and inline every call, so the program is one list of operations with unique names.
2. **CSE and dead code.** Merge identical pure operations (the softmax definition mentions `exp(x - row_max(x))` twice, so every call of it carries two identical copies) and drop what no `print` needs.
3. **Group.** With fusion on, consecutive elementwise operations of the same shape become one group; a broadcast of a value made inside the group starts a new one.
4. **Emit, kernel by kernel.** Each tensor lives in DRAM. A kernel loads the tiles it needs, computes, and stores what later kernels need.

| `mg` operation | GA-1 code |
|---|---|
| `matmul` | Chapter 40's output-stationary blocked schedule; the block shape and double buffering are the ones the analytic model of Chapter 40 predicts fastest among all that fit the scratchpad |
| `add sub mul div ge neg relu exp sqrt log`, scalar operations, `broadcast` | one vector-unit instruction per tile (`exp`, `sqrt`, `log` go to the special-function unit); a size-1 axis is broadcast by loading its only tile and expanding it |
| `reduce` (sum or max, either axis) | accumulate tile by tile; the padding of a partial tile is hidden behind a mask (fill 0 for sum, minus infinity for max) |
| `transpose` | load the tile at swapped coordinates, transpose it on the vector unit, store |
| `constant`, `print` | a DRAM array; the printed value is read back after the run |

Everything else (dynamic shapes, rank other than 2, `reshape`, `permute`, `contract`) is refused with a message rather than guessed at.

The whole back end:

```python
--8<-- "docs/part41/code/ga_backend.py"
```

The simulator needed more operations than Chapter 40 gave it (`ge`, `sqrt`, `log`, broadcasts along either axis, column reductions, a transposer, and `exp` that overflows to infinity the way IEEE does instead of raising); they live in a subclass:

```python
--8<-- "docs/part41/code/ga_ext.py"
```

### One small program, kernel by kernel

Chapter 29's stable softmax (`exp(x - row_max(x)) / row_sum(exp(x - row_max(x)))`, applied three times), with nothing turned on and then with CSE and fusion:

```text
--8<-- "docs/part41/code/show_program_out.txt"
```

Without options the operations come out as 34 kernels and 1,854 cycles; with CSE and fusion, 13 kernels and 804. Each softmax is now reduce, a fused `broadcast sub exp`, reduce, a fused `broadcast div`. The fused kernel stores `c1_t4` (the exponentials) because later kernels need them, and nothing else: its subtraction result lives and dies in a scratchpad slot.

## Does it give the right answers?

`compare_with_cpu.py` runs every Mountain Goat example of Chapters 20 to 32 and the tour (excluding the large training programs, which are too slow for a Python simulator) on GA-1 and compares each printed matrix with `mgc run`'s, to a tolerance of 1e-5 (relative, or absolute below 1; `mgc run` prints only six digits):

```text
--8<-- "docs/part41/code/compare_out.txt"
```

(The listing is long; the last line is the total.) **61 programs print the same matrices; 4 print nothing** (they are the four GPU-path examples, which are compile-only on this machine and have nothing to run); **27 are refused**, each for dynamic shapes or a rank other than 2. No program differs. "Same" means numerically close, not bit-identical: GA-1 sums reductions in tile order, and the CPU path sums in row order.

## What the options are worth

`studies.py` compiles the same programs with each combination of options and runs them on GA-1 with 32 scratchpad slots. Every cell is a run whose result was compared with the CPU's:

```text
--8<-- "docs/part41/code/studies_out.txt"
```

Study 1, the options (the first table):

- **CSE alone** is worth 1.2× to 1.55×: the front end evaluates repeated subexpressions repeatedly, and on GA-1 every repetition is a set of loads, vector instructions and stores.
- **Fusion on top** takes the stable softmax from 1,194 to 804 cycles and the 8-token block from 5,809 to 3,794: intermediates no longer make a round trip through DRAM.
- **Double buffering** alone, after CSE, gives nothing for the softmax (every kernel is a single tile, so there is nothing to overlap) and 5,809 to 5,419 for the block. With all three options the block reaches 2.10×, and the 32-token, width-32 block 2.31×.

## Decode and prefill

Study 2 is the point of the chapter for anyone interested in inference hardware. A feed-forward network (64 to 256 to 64) is compiled for 1, 2, 4, ... 64 tokens at once:

- 1, 2, 4 and 8 tokens all take **14,400 cycles**. The weights are 720 tiles that must stream through the DMA whatever the number of tokens, and the DMA is 100% busy; the extra tokens ride along in tile rows that were being padded anyway. So the cycles *per token* fall 8× and the **useful** matrix-unit utilization (padding excluded) is exactly proportional to the tokens: 3.6%, 7.1%, 14.2%, 28.4%.
- Past 8 tokens the extra tokens need extra tile rows, so the cycles start to grow (18,880 for 16 tokens; 28,904 for 32) and the utilization rises more slowly (43%, then 57%; 64 tokens gives 57% again). I did not break down what limits the schedule at 32 and 64 tokens; the DMA is still 97% busy there.

This is the decode-versus-prefill picture in miniature: producing one token at a time is limited by moving the weights, and the cure (batching, or processing a long prompt at once) works because the weights are reused. It is a statement about GA-1's ratios; a real device's balance point would be elsewhere.

## Where a block spends its time

Study 3 compiles one 64-token transformer block (width 64, feed-forward 128) and splits the busy cycles by kernel type:

- Total 127,006 cycles; useful MXU utilization 32%; the DMA is busy 100% of the time, the MXU 32%, the vector unit 14%.
- The 8 matmuls take 62,720 DMA cycles and 40,960 matrix-unit cycles; the 14 elementwise kernels take 52,480 DMA cycles (and only 12,480 of vector work). **About 41% of the DMA time is elementwise kernels that do almost no arithmetic.** That is what the fusion of this chapter shrinks and what a back end with cross-kernel on-chip fusion (flash-attention-style) would shrink further; this back end does not do that, so the number is an upper bound on what remains to be gained, not a prediction.

## Tests

One new `lit` group `test/ga41/` (the suite is now 153 tests). `check_backend.py` checks, in order:

1. **Agreement with the CPU:** the 61 programs print the same matrices; the 27 refusals are for the two stated reasons only.
2. **All option combinations:** each of the 8 combinations of CSE / fusion / double buffering gives the right answer on three programs.
3. **Other machines:** tiles of 4, 8 and 16 words and scratchpads of 24 and 64 slots give the right answer, so nothing depends on the tile being 8.
4. **What the options do:** pinned cycle counts (1,854 → 1,194 → 804; 7,484 → 3,564); fusion turns 22 kernels into 13 (the 9-to-4 figure one might first guess is wrong: the stored values the later code needs stay as kernels); double buffering changes nothing for one-tile kernels and helps the block.
5. **Decode and prefill:** 14,400 cycles for 1, 2, 4 and 8 tokens; utilization proportional to the tokens.
6. **Unsupported:** dynamic shapes and rank 3 are refused with a message.

```text
--8<-- "docs/part41/code/check_backend_out.txt"
```

### Are the checks good enough? Fourteen wrong back ends.

```text
--8<-- "docs/part41/code/backend_mutation_out.txt"
```

All 14 are caught. Two are caught by a crash rather than by a failing comparison (a fused kernel that stores only its last value loses a tile a later kernel loads; an `exp` that raises on overflow stops the run). A crash is a valid detection but a weaker one, and the page says so rather than counting it as a clean mismatch. The mutants that need a particular program to show up (the max-reduction padded with 0 instead of minus infinity; CSE ignoring attributes) are caught only because the book's own examples happen to contain them; a program whose partial tile holds all negative values for a max is the kind the examples might not have included.

## Limits and what is not established

- **A model, not a chip.** Cycle counts are GA-1's; no real device was consulted.
- **Not an MLIR pass.** The back end parses printed IR with regular expressions. It would not survive a change in the printing format (the check would notice), and it shares nothing with the passes of Chapters 14 to 38.
- **No dynamic shapes, no rank other than 2** (27 of the book's examples are refused for this).
- **No cross-kernel on-chip fusion.** Attention's scores are written to DRAM and read back; a back end that kept them in the scratchpad (as flash attention does) would remove the traffic, and this one cannot.
- **Tiny sizes.** The blocks are 8 to 64 tokens wide; the simulator is in Python and large programs take minutes. Trends at real model sizes (thousands of wide matrices, scratchpads of megabytes) are not established.
- **Partial tiles cost full tiles.** A 2 × 3 matrix takes a whole 8 × 8 tile of work; that is why the "useful utilization" excludes padding and why decode looks so poor.
- **The block choice rests on Chapter 40's analytic model,** which was within 4% to 6% of the simulator on the sweep there, but was not re-validated on every matmul here.
- **Numerics:** results agree to 1e-5 (the CPU path prints six digits), not bit for bit; GA-1 sums reductions in tile order.
- **The large training programs were not compiled:** the comparison skips every example of 400 lines or more, because simulating them in Python takes too long.

## Reproducing

```sh
cd docs/part41/code
./show_program.py > show_program_out.txt && ./compare_with_cpu.py > compare_out.txt && ./studies.py > studies_out.txt
./check_backend.py && ./backend_mutation.py > backend_mutation_out.txt
cd ../../part15/code && ./run_lit.sh          # 153 tests
```

## Chapter summary

- A Python back end over the `mg` dialect text compiles Mountain Goat to GA-1: matmul to Chapter 40's blocked schedule with a model-chosen block, runs of elementwise operations to fused kernels, reductions with masks, transposes on the vector unit.
- 61 of the book's examples give the CPU's matrices; 27 are refused for dynamic shapes or rank; 4 print nothing; none differ.
- CSE, fusion and double buffering together are worth 2.1× on an 8-token block; fusion alone cuts the stable softmax from 1,194 to 804 cycles.
- The feed-forward network takes the same 14,400 cycles for 1 to 8 tokens: decode is limited by streaming the weights, and batching is nearly free until the matrix unit fills.
- About 41% of a block's DMA time goes to elementwise kernels; what remains to fuse would need on-chip fusion across kernels, which this back end does not have.
- Fourteen broken back ends are caught (two only by a crash).

## Self-check questions

Each answer is collapsed; try the question first.

1. Why does the front end's output contain the same `exp(x - row_max(x))` several times, and what does CSE do on GA-1?

    ??? note "Answer"
        The front end expands a call to the softmax definition each time it is used, and the definition mentions `exp(x - row_max(x))` twice. The IR therefore holds identical operations. On GA-1 each repetition is loads, vector instructions and stores; merging them takes the stable softmax from 1,854 to 1,194 cycles.

2. What does fusion save, and what does it not?

    ??? note "Answer"
        It saves the stores and loads of intermediates that nothing else needs: the result of the subtraction stays in a scratchpad slot. It does not save stores of values that later kernels read (the exponentials, needed by the sum and the division), which is why 22 kernels become 13 rather than fewer.

3. Why do 1, 2, 4 and 8 tokens take the same number of cycles through the feed-forward network?

    ??? note "Answer"
        The weight tiles (720 of them) dominate and are streamed once for any number of tokens up to a tile's 8 rows; the matrix unit's rows for the extra tokens were being padded anyway. The DMA is 100% busy, so more rows cost nothing until they exceed 8.

4. The tool reports "useful" utilization separately from utilization. Why?

    ??? note "Answer"
        A padded tile multiplies zeros at full speed, so counting padded multiply-adds makes a one-token matmul look as busy as an eight-token one. Useful utilization counts only the multiply-adds the program asked for, so it rises in proportion to the tokens: 3.6%, 7.1%, 14.2%, 28.4%. The mutant that counts padding is caught.

5. Two of the fourteen mutants are "caught" by a crash. Why does the page call that weaker?

    ??? note "Answer"
        A crash proves the checker noticed something was badly wrong, but not that it would notice a subtle wrong answer of the same kind. A mismatch against the CPU result is evidence the checker compares numbers.

6. What would a back end need in order to remove the 41% of DMA time spent on elementwise kernels?

    ??? note "Answer"
        Fusion across kernels with matmuls and reductions: keeping an attention score tile in the scratchpad from the matmul through the softmax into the next matmul. This back end ends every group at a matmul or a reduction and stores the result to DRAM, so it cannot.

7. Name three limits of the claims on this page.

    ??? note "Answer"
        Any of: the machine is invented, so cycle counts are not a prediction for a real device; the sizes are tiny; the back end is not an MLIR pass and parses printed text; nothing with dynamic shapes or rank other than 2 is accepted; the tile-block choice trusts Chapter 40's analytic model; results are close to, not identical to, the CPU's.
