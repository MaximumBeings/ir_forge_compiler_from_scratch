# 24. Closing the Gap: A Matrix Product That Walks Memory in a Better Order

<p style="text-align:center"><img src="../assets/goats/ch-24.svg" alt="Mountain goats on the mountain in a storm" style="max-width:100%;height:auto;border-radius:6px"></p>

**What you will understand:** how a change to the *order* of three loops, with no change to the arithmetic, can make a program several times faster, and how to add that change to a compiler without breaking anything that depends on the old behavior. Chapter 23 measured Mountain Goat's matrix product, found it more than twice as slow as a simple hand-written C++ loop at N = 512, and listed "isolating why" as unfinished. This chapter finishes the job: it adds a second loop order to the lowering, measures it, looks at the machine code, and shows that the two orders give identical answers to the last bit.

**What you need to know first:** Chapter 23 (the benchmark, the noise, `-O` and `--passes`), Chapter 21 (how `mg.matmul` is lowered), and Chapter 7 (loop tiling). The new idea (loop order and memory access) is explained from scratch.

!!! tip "Compile and run"
    ```sh
    cd docs/part24/code
    ./build.sh                                 # builds ./build/mg-opt (Chapter 24's: adds the matmul-order option)
    ./mgc run examples/matmul_odd.mg --matmul-order ikj       # one program with the new loop order
    ./run_bench.sh > bench_out_1.txt           # the benchmark, pass 1 (about a minute)
    ./run_bench.sh > bench_out_2.txt           # pass 2
    python3 summarize.py bench_out_1.txt bench_out_2.txt > summary.txt
    ./inspect_asm.sh > inspect_asm_out.txt     # vector instructions in the machine code
    ./bits_check.sh > bits_check_out.txt       # are the two orders identical to the last bit?
    ./machine_info.sh > machine_info_out.txt
    ./mgc_mutation.py > mgc_mutation_out.txt   # breaks mgc on purpose
    ./lowering_mutation.sh > lowering_mutation_out.txt   # breaks the lowering on purpose (a rebuild each; several minutes)
    cd ../../part15/code && ./run_lit.sh       # the whole test suite
    ```
    Timings will differ on your machine.

!!! note "Why this page shows FAIL lines, and why that is good"
    The two mutation outputs near the end come from **negative controls**: deliberately broken code run against the tests. There a "caught by" line or a FAIL is the expected, wanted result. The baseline lines must say "all tests pass", and they do.

## Primer: why loop order matters

The matrix product of **A** (m by k) and **B** (k by n) is `C[i][j] = sum over k of A[i][k] * B[k][j]`. The textbook way to compute it is three nested loops. Which loop is outermost, which is in the middle and which is innermost can be chosen freely, because the arithmetic is the same. The two orders in this chapter are named by the loop variables from outermost to innermost:

- **`ijk`** (what Chapters 21 to 23 generate): for each result element `C[i][j]`, run a loop over `k` that adds up the products. The innermost loop reads `A[i][k]` (walking *along a row* of A: consecutive addresses) and `B[k][j]` (walking *down a column* of B).
- **`ikj`**: for each row `i` of A and each `k`, take the single number `A[i][k]` and add `A[i][k] * B[k][j]` into `C[i][j]` for every `j`. The innermost loop now reads `B[k][j]` and writes `C[i][j]` while `j` increases, and both of those walk *along a row*: consecutive addresses.

**Why that matters.** Memory is stored one row after another ("row-major"), so walking along a row visits neighboring addresses, and walking down a column jumps by a whole row's length each step (for a 512-wide matrix, 4096 bytes). A processor reads memory in chunks called **cache lines** (typically 64 bytes, eight numbers); a walk along a row uses all eight numbers of each chunk it fetches, while a walk down a column uses one number per chunk and wastes the rest. There is a second benefit: a loop that touches consecutive addresses is the kind of loop a compiler can turn into **vector instructions** (SIMD: one instruction operating on several numbers), which a loop jumping through memory is not.

**What does not change.** For every result element `C[i][j]`, both orders add the products in the same order (`k` = 0, 1, 2, …). Floating-point addition is not associative (adding the same numbers in a different order can change the last bits), but because the order *per element* is unchanged, the two loop orders give **bit-for-bit identical** results. That is an argument; this chapter also tests it (below).

## The change

`mg.matmul` already lowers to a zero-fill loop nest plus a three-deep accumulate nest (Chapter 21). The new code builds the accumulate nest with its bounds and induction variables in either order, selected by a **pass option**, `--convert-mg-to-affine=matmul-order=ikj` (the default stays `ijk`, so every earlier chapter's output is unchanged). The lowering pattern now remembers which order it was asked for:

```cpp
--8<-- "docs/part24/code/LowerToAffine.cpp:283:292"
```

The accumulate nest, with the order choice in the loop bounds and in which induction variable plays which role:

```cpp
--8<-- "docs/part24/code/LowerToAffine.cpp:319:333"
```

An option on a pass is declared as a member of the pass class. Because a pass with options must be copyable (MLIR clones passes), the class also gets an explicit copy constructor, and the pass rejects any value other than `ijk` or `ikj` with an error instead of silently falling back:

```cpp
--8<-- "docs/part24/code/LowerToAffine.cpp:448:474"
```

`mgc` gets a flag that passes it through: `--matmul-order ikj`. The complete change (this chapter's lowering and driver, against Chapter 22's and 23's):

??? note "The full diff for this chapter (click to expand)"
    ```diff
    --8<-- "docs/part24/code/chapter24.diff"
    ```

To rebuild `mg-opt`:

```sh
--8<-- "docs/part24/code/build.sh"
```

You can see the order in the lowered code. This is a 2 by 3 times 3 by 4 product in each order; the accumulate nest has bounds 2, 4, 3 for `ijk` (the reduction `k` innermost) and 2, 3, 4 for `ikj` (the output column `j` innermost):

```text
--8<-- "docs/part24/code/show/loop_orders.txt"
```

## Results

The experiment is Chapter 23's, on the same kind of machine, with the new order added:

```text
--8<-- "docs/part24/code/machine_info_out.txt"
```

As before: a shared cloud virtual machine, pinned to one core, two complete passes, every result compared with a reference by exact equality. The variants this time:

| Name | What it is |
|---|---|
| `mg_O2` | Chapter 23's baseline: loop order `ijk`, clang `-O2` |
| `mg_O2_ikj` | the new order, `-O2` |
| `mg_O2_ikj_tile32` | the new order, tiled 32 by 32, `-O2` |
| `mg_O3_native_tile32` | Chapter 23's best dynamic-size variant: `ijk`, tiled, `-O3 -march=native` |
| `mg_O3_native_ikj` | the new order, `-O3 -march=native` |
| `mg_O3_native_ikj_tile32` | the new order, tiled, `-O3 -march=native` |
| `C++ ijk loop, clang -O2`, `C++ ikj loop, -O3 native` | the hand-written loops from Chapter 23, for comparison |

The raw output of both passes (click to expand):

??? note "Pass 1: `bench_out_1.txt`"
    ```text
    --8<-- "docs/part24/code/bench_out_1.txt"
    ```

??? note "Pass 2: `bench_out_2.txt`"
    ```text
    --8<-- "docs/part24/code/bench_out_2.txt"
    ```

And the combined table (median time per call in each pass, how much the passes differ, average GFLOP/s, and speedup versus `mg_O2` at the same size; every result matched the reference):

```text
--8<-- "docs/part24/code/summary.txt"
```

## Reading the numbers

**1. The new loop order alone is a large win.** At `-O2`, `ikj` is 3.6× faster than `ijk` at N = 128, 3.1× at N = 256 and **7.5×** at N = 512 (4.22 against 0.56 GFLOP/s). Nothing about the arithmetic changed.

**2. With the CPU's full instruction set, the gap from Chapter 23 closes.** Chapter 23's result 6 said the best Mountain Goat variant at N = 512 was about 2.1× slower than a hand-written `ikj` loop. Now `mg_O3_native_ikj` reaches 7.14 GFLOP/s against the hand-written loop's 7.37, within the noise (the two differ by 6% and 3% between passes). At N = 256 with dynamic sizes it reaches 9.12 against the hand-written loop's 8.71, but that hand-written figure moved by 30% between passes, so the right reading is "comparable", not "faster".

**3. Tiling no longer clearly helps.** On top of `ikj` with all instructions, tiling gives 6.96 against 7.14 GFLOP/s at N = 512 and 7.67 against 9.12 at N = 256 with dynamic sizes: no gain, and the passes differ by up to 20%. At N = 128 the tiled version is faster (10.83 against 8.78), but the passes differ by 12% and 15%, so it is not a firm result. The loop order had already fixed most of what tiling was fixing in Chapter 23. There are two exceptions, and both are specific: at plain `-O2`, tiling still helps `ikj` (6.66 against 4.22 GFLOP/s at N = 512, 1.6×), and with a *fixed* shape at N = 256 the tiled `ikj` native build reaches 12.10 GFLOP/s against 9.72 untiled, the best number in the table and the only one clearly above the hand-written loop (and that comparison is at one size, against a hand-written figure that was itself noisy).

**4. It is the loop order that unlocks vectorization.** Chapter 23 left this open (it had only seen vector instructions in one build and could not say which ingredient mattered). `inspect_asm.sh` counts them again:

```text
--8<-- "docs/part24/code/inspect_asm_out.txt"
```

With `ijk`, the only function with vector instructions is the tiled fixed-shape one (64). With `ikj`, **even the untiled dynamic-size function has them** (8), and the fixed-shape ones have more (16 untiled, 32 tiled). So for dynamic sizes the loop order alone is enough; the fixed shape and the tiling are not what was needed. The consistent explanation is that the `ikj` inner loop reads and writes consecutive addresses, which is what a vectorizer wants. I did not test other loop orders (for example `jki`) or look at the vectorizer's own reports, so "consistent" is as far as this goes.

**5. The numbers are noisy, and some spreads are large.** Between the two passes the same experiment differs by up to 54% (`mg_O3_native_tile32` at N = 64), 41% and 39% at N = 256. As in Chapter 23, differences of 2× and more are claims; differences of 1.0× to 1.3× are not.

## Same answers, to the last bit

The argument above says the two loop orders add each element's products in the same order. `bits_check.sh` tests it with numbers where it would show: a 5 by 7 times 7 by 4 product of values that are not exactly representable, printed as hexadecimal floating point (every bit of every result), built once with each loop order:

```cpp
--8<-- "docs/part24/code/cpp/bits.cpp"
```

```text
--8<-- "docs/part24/code/bits_check_out.txt"
```

The two outputs are identical in all 20 elements. The script also checks that the check is *able* to fail: summing the same products in decreasing `k` order, instead of increasing, changes 19 of the 20 results, so a loop order that changed the order of additions would have been caught. (The benchmark itself uses small whole numbers, where every sum is exact in any order, so on its own it could not have shown this.)

## Tests

Six new test files in `test/loop-order/` (the suite now has 99 tests). As in Chapter 23, none asserts speed.

| Test | What it checks |
|---|---|
| `structure` | the default and `matmul-order=ijk` give loop bounds 2, 4, 3 for a 2×3 @ 3×4 product, and `ikj` gives 2, 3, 4 (with the zero-fill nest before it) |
| `bad-option` | `matmul-order=jki` is an error with a clear message, not a silent fallback |
| `results-identical` | the same 3×5 @ 5×2 product (no dimension a multiple of the tile size) prints the same at `ijk`, `ikj`, and `ikj` tiled by 2 and by 3, static and dynamic, equal to the hand-computed `12 15 / 32 35 / 52 55` |
| `cpp-ikj` | Chapter 21's whole C++ program (every elementwise result, matmul against a plain C++ loop, the dirty-heap check, the abort message) against a library built with `ikj` |
| `flag-reaches-pass` | `mgc --matmul-order` really reaches the pass: the kept affine IR differs in loop order |
| `bitwise-identical` | the hexadecimal-float comparison above, as a test |

Two bugs were injected into `mgc` and four into the lowering, one at a time:

```python
--8<-- "docs/part24/code/mgc_mutation.py"
```

```text
--8<-- "docs/part24/code/mgc_mutation_out.txt"
```

```sh
--8<-- "docs/part24/code/lowering_mutation.sh"
```

```text
--8<-- "docs/part24/code/lowering_mutation_out.txt"
```

Reading the mutation results:

- **"The ikj order is ignored"** produces correct answers (the two orders are identical by design), so only tests that look at the *structure* of the generated loops can catch it: `structure` and `flag-reaches-pass` do, and nothing else fails.
- **"Bounds not reordered"** (loops run in `i, k, j` order but with the `i, j, k` sizes) is caught by five of the six tests: it produces wrong answers or reads outside the matrices.
- **"The right-hand matrix is read transposed"** is caught by only two tests, `results-identical` (it checks a hand-computed answer) and `cpp-ikj`. It is **not** caught by `bitwise-identical`, and that is worth understanding: that test compares the `ijk` result with the `ikj` result, and this bug is in the code both orders share, so both are equally wrong and still agree with each other. A differential test (compare two implementations) cannot catch a bug that both implementations have; a test against a known right answer can.
- **"The option is not validated"** is caught by exactly one test, `bad-option`, the only test that passes a bad value.

The full suite with the Chapter 24 build:

```text
--8<-- "docs/part15/code/run_out_99.txt"
```

## Limits and what is not established

- **Same machine, same caveats as Chapter 23:** a shared cloud VM, one core, one session, noisy (up to 54% between passes here).
- **Still one operation.** Square `f64` products from 64 to 512; nothing about other shapes (a tall-thin product has different memory behavior), and not about the other operations.
- **Two loop orders only.** `ijk` and `ikj`. The other four orders were not tried, so "the loop order matters" is shown for this pair, not as a ranking of all six.
- **One tile size (32), still untuned,** and tiling was measured on top of `ikj` only at that size.
- **No hardware counters and no vectorizer reports.** The explanations (contiguous inner loop, cache lines) are consistent with the data and with the instruction counts, not demonstrated by measuring cache misses.
- **The default is still `ijk`.** The faster order is opt-in (`--matmul-order ikj`), because changing the default would change every earlier chapter's generated code and recorded output. A real compiler would make the better order the default.
- **No multithreading,** no GPU measurement, and nothing like a tuned library's blocking, packing or register micro-kernel; the best result here is still modest next to what a tuned library reaches on this CPU.
- **The benchmark's exact-equality check uses small whole numbers;** the bit-for-bit claim rests on the separate hexadecimal-float check (one 5×7×4 product), on the argument about the order of additions, and on that check being shown able to fail.

## Reproducing

```sh
cd docs/part24/code
./build.sh
./run_bench.sh > bench_out_1.txt && ./run_bench.sh > bench_out_2.txt
python3 summarize.py bench_out_1.txt bench_out_2.txt > summary.txt
./inspect_asm.sh > inspect_asm_out.txt && ./bits_check.sh > bits_check_out.txt && ./machine_info.sh > machine_info_out.txt
./mgc_mutation.py > mgc_mutation_out.txt
./lowering_mutation.sh > lowering_mutation_out.txt     # four rebuilds
cd ../../part15/code && ./run_lit.sh                    # 99 tests
```

## Chapter summary

- A second loop order for `mg.matmul`, `ikj`, is selected with `--convert-mg-to-affine=matmul-order=ikj` or `mgc --matmul-order ikj`; the default (`ijk`) is unchanged.
- It is 3× to 7.5× faster than `ijk` at `-O2` on this machine, and with all CPU instructions it matches a hand-written `ikj` loop at N = 512 (7.14 against 7.37 GFLOP/s), closing the gap Chapter 23 left.
- Tiling on top of `ikj` helps little or not at all, except at `-O2` and for one fixed shape; the loop order did most of the work.
- Loop order alone is enough for the compiler to produce vector instructions for dynamic sizes; Chapter 23's open question is answered for this pair of orders.
- The two orders give bit-identical results, shown by a hexadecimal-float test that can fail; the benchmark's own check could not have shown it.
- Six tests (suite: 99) and six injected bugs, all caught.

## Self-check questions

Each answer is collapsed; try the question first.

1. In `ijk` and `ikj`, which loop is innermost, and which memory does that innermost loop walk?

    ??? note "Answer"
        In `ijk` the innermost loop is `k`: it reads `A[i][k]` along a row of A (consecutive addresses) and `B[k][j]` down a column of B (jumping a whole row each step). In `ikj` the innermost loop is `j`: it reads `B[k][j]` and updates `C[i][j]`, and both walk along a row, so consecutive addresses.

2. Why does walking down a column of a row-major matrix cost more than walking along a row?

    ??? note "Answer"
        Memory is fetched in cache lines of about 64 bytes (eight doubles). Along a row, every number of a fetched line is used. Down a column, each step lands in a different line, so one number of each fetched line is used and the rest is wasted, and for large matrices those lines are evicted before they are needed again. A walk along a row also lets the compiler use vector instructions; a walk with a large stride does not.

3. Why are the `ijk` and `ikj` results identical to the last bit, rather than merely close?

    ??? note "Answer"
        Floating-point addition is not associative, so the order of additions matters. But in both loop orders, each result element `C[i][j]` accumulates its products in the same order (`k` increasing from 0), so each element goes through exactly the same sequence of additions and the same roundings. What differs between the orders is only the order in which different elements are worked on, which does not affect any element's value.

4. Why does the benchmark's exact-equality check not prove that, and what does?

    ??? note "Answer"
        The benchmark uses small whole numbers, for which every product and sum is exact in any order, so any order would pass. The proof needs numbers that round: `bits_check.sh` multiplies values that are not exactly representable, prints every bit, and compares the two orders. It also shows the comparison could fail: adding in decreasing `k` order changes 19 of the 20 results.

5. Chapter 23 could not say whether tiling or fixed sizes unlocked vectorization. What did this chapter find, and what did it not test?

    ??? note "Answer"
        With the `ikj` order, even the untiled dynamic-size function contains vector instructions (8, against 0 with `ijk`), so for dynamic sizes the loop order alone is sufficient; neither tiling nor fixed shape was needed. It did not test other loop orders, did not read the compiler's vectorization reports, and did not measure why the fixed-shape builds have more vector instructions. The explanation (consecutive addresses in the inner loop) is consistent with the evidence, not proven.

6. Tiling gave 2.6× to 5.2× in Chapter 23 but little here. Why, and where does it still help?

    ??? note "Answer"
        Part of what tiling does is reduce cache misses caused by the column walk. The `ikj` order removed the column walk, so there is less left for tiling to fix. It still helps at plain `-O2` (1.6× at N = 512) and with a fixed 256 shape and all instructions (12.10 against 9.72 GFLOP/s), where other effects are in play that this chapter did not isolate.

7. Why is the default still `ijk` if `ikj` is better?

    ??? note "Answer"
        Changing the default would change the generated code for every earlier chapter's matmul, and with it recorded outputs, structure tests and page text. Making the better order opt-in kept everything earlier valid. A production compiler would make the better order the default and keep the old one selectable, or choose per shape.

8. The test `bad-option` checks that `matmul-order=jki` is an error. What would the mutation "option not validated" do without it?

    ??? note "Answer"
        The pass would accept any string and treat everything other than `ikj` as `ijk`, so `jki` (or a typo like `ijk ` or `IKJ`) would silently produce the default order. The user would think they had changed the order and would see no change. The test makes a wrong value fail loudly.

9. The mutation "the ikj order is ignored (always lowers as ijk)" produces correct results. How can any test catch it?

    ??? note "Answer"
        Only by looking at the structure of the lowered code, because the results are identical by design. `structure` and `flag-reaches-pass` check the loop bounds in the generated IR (2, 3, 4 for `ikj`). This is the same situation as Chapter 22's equivalent mutant: a bug with no effect on results can only be caught by checking implementation, not behavior.

10. What would you have to do to claim that `ikj` is "the" right loop order for Mountain Goat?

    ??? note "Answer"
        Try all six orders, many shapes (including tall, thin and small ones), more machines and compilers, and look at hardware counters and vectorizer reports to confirm the mechanism. Then compare against a tuned library. This chapter measured two orders on square products on one shared virtual machine.
