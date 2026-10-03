# 23. Measuring Performance: Does Any of It Make the Code Fast?

![Mountain goats on the mountain drawn as a blueprint](../assets/goats/ch-23.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

**What you will understand:** how to measure a compiler's output honestly, and what the measurements say about Mountain Goat's matrix product. Every chapter so far said "no performance claim is made". This chapter makes some, carefully: it times one operation under different compiler settings and loop transforms, compares it with hand-written C++, shows the noise in its own numbers, and looks at the machine code to explain one result. It also finds, on the way, a bug in the driver that had been there since Chapter 20.

**What you need to know first:** Chapter 7 (loop tiling and the other loop transforms), Chapter 17 (those transforms on dynamic bounds), Chapters 20 and 21 (the `mgc` driver and `@`, the matrix product). No performance background is assumed; the terms are explained below.

!!! tip "Compile and run"
    ```sh
    cd docs/part23/code
    ../part22/code/build.sh                       # once: Chapter 22's mg-opt (this chapter changes only the driver)
    ./machine_info.sh > machine_info_out.txt      # what machine the numbers come from
    ./run_bench.sh > bench_out_1.txt              # build and time every variant (takes about a minute)
    ./run_bench.sh > bench_out_2.txt              # a second, independent pass
    python3 summarize.py bench_out_1.txt bench_out_2.txt > summary.txt
    ./inspect_asm.sh > inspect_asm_out.txt        # look at the machine code behind one result
    ./mgc run examples/matmul_odd.mg -O2 --passes "--affine-loop-tile=tile-size=2"   # the new options on one program
    ./mgc_mutation.py > mgc_mutation_out.txt      # breaks mgc on purpose to test the tests
    cd ../part15/code && ./run_lit.sh             # the whole test suite
    ```
    Every listing and output on this page comes from these commands. Timings will differ on your machine; that is expected.

!!! note "Why this page shows FAIL lines, and why that is good"
    The mutation output near the end comes from a **negative control**: deliberately broken code run against the tests. There a "caught by" line (a test failed) is the expected, wanted result. The baseline lines must say "all tests pass", and they do.

## Primer: what is being measured

**Throughput and GFLOP/s.** Multiplying two N by N matrices takes N³ multiplications and N³ additions, so **2·N³ floating-point operations** (FLOPs). Dividing that by the time gives a speed in **GFLOP/s** (billions of floating-point operations per second). It is a fair way to compare implementations of the same operation at the same size, and a bad way to compare different sizes or machines, because caches and clock speeds matter.

**Why speeds differ so much between correct programs.** All the programs below compute exactly the same numbers. They differ in *how the computer is asked to do it*:

- **Optimization level.** `-O0` tells the C compiler (clang) to do almost no optimization; `-O2` and `-O3` ask for increasingly aggressive rewriting. Until this chapter every Mountain Goat program was built at `-O0` (clang's default for a `.ll` file), which is fine for demonstrating correctness and wrong for anything about speed.
- **Memory and caches.** A processor reads memory through small, fast **caches**. Reading consecutive addresses is fast; jumping around memory is slow, because each jump may miss the cache. In the textbook matrix-product loop the innermost loop walks down a *column* of the right-hand matrix, which in row-major storage means jumping a whole row's length each step.
- **Loop tiling** (also called blocking, Chapter 7) restructures the loops to work on small square **tiles** at a time, so the data a tile needs stays in cache while it is reused. Here the tile is 32 by 32 numbers; three of them (one from each matrix) are 24 KiB, which fits in this machine's 48 KiB of L1 data cache per core.
- **Vectorization** (SIMD) uses instructions that operate on several numbers at once. `-march=native` tells clang it may use every instruction this particular CPU supports, which includes wide vector instructions on this machine.
- **Loop order.** The same triple loop can be written with its three loops in different orders (`i,j,k` or `i,k,j`), which changes which memory is read in what pattern. Order matters enormously and the compiler will not reliably change it for you.

**What makes a measurement trustworthy.** Computers are noisy. A fair measurement runs the code once to warm up (page faults, cold caches), repeats it several times, reports the **median** (robust to a slow outlier) and the **minimum** (the least disturbed run), checks that the answer is still right, says what machine it ran on, and repeats the whole experiment to show how much results move between runs.

## Two new options for `mgc`

`mgc` gains two options (and two environment variables) so that these experiments are one-line changes:

- `-O0`, `-O1`, `-O2`, `-O3`: the optimization level for the final clang step (default `-O0`, so nothing earlier changes).
- `--passes "…"`: extra `mg-opt` passes run on the affine loops **before** they are lowered further. For example `--passes "--affine-loop-tile=tile-size=32"` runs Chapter 7's tiling pass on every loop nest in the program.
- `MGC_CFLAGS`: extra flags for clang, such as `-march=native`. `MGC_CLANG`: which clang to call (a test seam, explained below).

The change against Chapter 22's driver:

```diff
--8<-- "docs/part23/code/chapter23.diff"
```

**A bug found while writing the tests.** Testing `mgc build` showed that it exited with **status 1 even on success**. The last line of the script was `[ "$cmd" = run ] && exec "$exe"`, and when the command is `build` that comparison is false, so the script's final status is 1. Chapters 20 to 22 only ever used `mgc run` (which replaces the shell with the program) and `mgc lib` (which exits explicitly), so nothing noticed. It is fixed in all four copies of `mgc` (Chapters 20 to 23), and the new test `tiling-structure` builds with `mgc build` and would fail on the old behavior.

## The experiment

The function being measured is a matrix product, once with dynamic sizes and once with a fixed 256 by 256 shape:

```text
--8<-- "docs/part23/code/bench/matmul.mg"
```

The harness times it from C++ (the compiled code is linked in through the generated object file, as in Chapter 20) at N = 64, 128, 256 and 512. It computes a reference answer with an ordinary triple loop and **checks every variant's result against it** (the inputs are small whole numbers, so every product and sum is exact and the comparison is exact equality, not a tolerance). Each variant is built from the same harness source; only the object being timed changes:

```cpp
--8<-- "docs/part23/code/bench/bench.cpp"
```

The script that builds and runs all the variants:

```sh
--8<-- "docs/part23/code/run_bench.sh"
```

The variants:

| Name | What it is |
|---|---|
| `mg_O0` | Mountain Goat's matmul, built the way every earlier chapter built things |
| `mg_O2` | the same, with clang `-O2` |
| `mg_O2_tile32` | `-O2`, and the loops tiled 32 by 32 by Chapter 7's pass |
| `mg_O3_native` | `-O3 -march=native` (all of this CPU's instructions) |
| `mg_O3_native_tile32` | `-O3 -march=native` and tiled |
| `C++ ijk loop, clang -O2` | the textbook triple loop, in the same loop order Mountain Goat generates, written in C++ |
| `C++ ikj loop, -O3 native` | what a person who knows about caches would write: the middle two loops swapped, built with every optimization |

## The machine

```text
--8<-- "docs/part23/code/machine_info_out.txt"
```

This is a **shared cloud virtual machine**, not a quiet benchmarking host. Other tenants may be using the same physical hardware, the clock speed is not fixed by me, and the cache sizes shown are what the virtual machine reports. The harness pins itself to one core (`taskset -c 3`) to reduce scheduler noise, which helps but does not remove it. Treat every number below as "what happened on this machine in this session", not as a property of Mountain Goat.

## Results

The raw output of both passes (click to expand):

??? note "Pass 1: `bench_out_1.txt`"
    ```text
    --8<-- "docs/part23/code/bench_out_1.txt"
    ```

??? note "Pass 2: `bench_out_2.txt`"
    ```text
    --8<-- "docs/part23/code/bench_out_2.txt"
    ```

And the two passes combined by `summarize.py`. The columns are the median time per call in each pass, how much the two passes differ (a rough measure of noise), the average GFLOP/s, and the speedup compared with the plain `mgc -O2` build at the same size (above 1.00 is faster). Every result was checked against the reference:

```text
--8<-- "docs/part23/code/summary.txt"
```

## Reading the numbers

Each statement below is about this table, and is followed by what the evidence does and does not show.

**1. Turning on the C compiler's optimizer matters a lot.** `-O2` is between about 2× (at N = 512) and 6× (at N = 64) faster than the `-O0` that every earlier chapter used. Nothing in Mountain Goat changed; only the flag. (At N = 64 each call takes about a tenth of a millisecond, so that figure is the least reliable.)

**2. Mountain Goat's generated matmul is as fast as the same loop written in C++.** At `-O2`, `mg_O2` and `C++ ijk loop, clang -O2` are within the noise of each other at every size (the ratio column is 0.97 to 1.21; at N = 128 and above the two passes of each disagree by at most 10%, at N = 64 by up to 30%). That is what you would expect: the compiler lowers `a @ b` to exactly the textbook `i, j, k` loop. It is *not* a claim that Mountain Goat is fast; it is a claim that it is no slower than the algorithm it implements.

**3. Tiling helps, and helps more as the matrices get bigger.** Tiling by 32 at `-O2` is 1.1× at N = 64 (within noise), 2.3× at N = 128, 2.6× at N = 256 and **5.2×** at N = 512, relative to untiled `-O2`. The trend is consistent with the cache explanation in the primer: the untiled loop's column walk costs more as the matrices outgrow the cache. This chapter did not measure cache misses (no hardware counters were used), so the explanation is a consistent story, not a proven mechanism.

**4. `-O3 -march=native` alone did nothing.** Without tiling, `mg_O3_native` is 0.87× to 1.07× of `mg_O2`: no gain. The machine code shows why (next section): the compiled loop is scalar, with no vector instructions at all, despite the CPU having wide ones.

**5. One combination is very fast: tiled, fixed shape, all instructions.** `mg_O3_native_tile32 (static 256)` reaches 9.65 GFLOP/s, **5.2×** the plain `-O2` build and equal to the hand-written `ikj` loop at the same size (9.60 GFLOP/s). The same transform on the *dynamic-size* function reaches only 3.95 GFLOP/s (2.1×). So there is a gap between "the compiler knew the sizes" and "it did not".

**6. At N = 512 nothing from Mountain Goat gets close to the hand-written loop.** The best Mountain Goat variant (tiled, `-O3 -march=native`, dynamic sizes) reaches 3.46 GFLOP/s; the hand-written `ikj` loop reaches 7.44, about **2.1× faster**. There is no fixed-size 512 function in the experiment, so this does not say what a fixed-size 512 build would do. A better Mountain Goat matmul (the loop order, a tuned tile size, a micro-kernel) is not built here.

**7. The numbers are noisy.** The two passes of the same experiment differ by up to 44% (`mg_O2_tile32` at N = 128), 36% (`mg_O0` at N = 256) and 30% (`mg_O2` at N = 64). Differences smaller than about this are not meaningful, which is why the statements above compare large effects (2× and up) and call 1.0× to 1.2× "within the noise".

## Looking at the machine code

Result 4 says the code is scalar and result 5 says one build is different. `inspect_asm.sh` checks directly, by counting vector and fused multiply-add instructions in the assembly of each function:

```sh
--8<-- "docs/part23/code/inspect_asm.sh"
```

```text
--8<-- "docs/part23/code/inspect_asm_out.txt"
```

Only the **tiled, fixed-shape** function (`mm_256` in the tiled build) contains vector instructions (64 of them). The dynamic-size function has none in either build, and the untiled fixed-shape function has none. That matches the speed ranking in result 5. What it does *not* tell us is **which** of the two ingredients (the tiling, or the fixed shape) is the one that unlocks vectorization on its own: only the combination was tried. For comparison, the plain `-O2` build's inner loop is a chain of scalar `mulsd`/`addsd` instructions, unrolled four times, with the running sum kept in a register (so the compiler *did* avoid reloading and storing the result on every step).

## Tests

Three new test files in `test/perf/` (the suite now has 93 tests). Note what is **not** tested: no test asserts that anything is *faster*. Timings depend on the machine and its load, and a test that fails when a shared machine is busy is worse than no test. Instead the tests check the things that must hold regardless of speed:

| Test | What it checks |
|---|---|
| `options-same-results` | the same 3×5 by 5×2 product (no dimension a multiple of the tile size) gives identical output at `-O0`, `-O2`, tiled by 2 and by 3 with dynamic shapes, and tiled by 2 with static shapes, and equals the hand-computed `12 15 / 32 35 / 52 55` |
| `tiling-structure` | `--passes` really reaches `mg-opt`: the plain build has 5 loops, the tiled one 10, with `min` bounds at the edges; and `mgc build` exits with status 0 |
| `flags-reach-clang` | `-O2`, `-O3` and `MGC_CFLAGS` reach the final clang command, for both `build` and `lib`, and no `-O` appears when none was given |

The third test needs an explanation, because it came from a failure of the first two. Optimization flags never change a program's *results*, so no test of the output can tell whether `-O2` was applied. I broke `mgc` so that `-O` was ignored, and **both** result-checking tests still passed. The fix is a small seam: `MGC_CLANG` names the clang to call, and the test sets it to `echo`, so `mgc` prints the command line it would have run and the test checks that line. Without that seam, "-O is ignored" would be an equivalent mutant (Chapter 22): a bug no test of results can see.

`mgc_mutation.py` breaks the driver five ways, one at a time, and runs the tests each time:

```python
--8<-- "docs/part23/code/mgc_mutation.py"
```

```text
--8<-- "docs/part23/code/mgc_mutation_out.txt"
```

## Limits and what is not established

- **One machine, one session.** A shared cloud VM with four vCPUs, pinned to one core. Nothing here says how Mountain Goat behaves on other hardware, other compilers, or a quiet machine.
- **One operation.** Square `f64` matrix products from 64 to 512. Nothing about elementwise operations, reductions, other shapes or sizes.
- **One tile size (32), not tuned.** A better tile size would likely do better; none was searched for.
- **No hardware counters.** Explanations involving caches are consistent with the data but not demonstrated by measuring cache misses.
- **No multithreading.** Everything ran on one core. The machine has four.
- **Which ingredient matters is not isolated** for result 5 (tiling versus fixed shape); only the combination was measured.
- **The GPU path is not measured at all.** There is no GPU here.
- **No test asserts speed**, by design.
- **Not a competitive matrix product.** The best Mountain Goat variant is more than twice as slow as a simple hand-written loop at N = 512, and far below what a tuned library would achieve on this CPU.

## Reproducing

```sh
cd docs/part23/code
../part22/code/build.sh               # once
./machine_info.sh > machine_info_out.txt
./run_bench.sh > bench_out_1.txt && ./run_bench.sh > bench_out_2.txt
python3 summarize.py bench_out_1.txt bench_out_2.txt > summary.txt
./inspect_asm.sh > inspect_asm_out.txt
./mgc_mutation.py > mgc_mutation_out.txt
cd ../../part15/code && ./run_lit.sh  # 93 tests
```

## Chapter summary

- `mgc` gained `-O0` to `-O3`, `--passes`, `MGC_CFLAGS` and `MGC_CLANG`; the old default (`-O0`) is unchanged.
- Measured on one shared VM: clang's `-O2` makes the generated matmul 2× to 6× faster than `-O0`; at `-O2` it matches the same loop written in C++, so Mountain Goat adds no overhead but also no cleverness.
- Chapter 7's tiling pass gives 2.6× at N = 256 and 5.2× at N = 512 over untiled `-O2`; with a fixed shape and all CPU instructions, it matches a hand-written `ikj` loop at N = 256 and is the only build whose machine code uses vector instructions.
- At N = 512 the best Mountain Goat variant is still about 2.1× slower than that hand-written loop.
- Repeated runs differ by up to 44%, so only large differences are claims.
- Testing the new options found a bug in `mgc build` (exit status 1 on success) and an equivalent-mutant problem for `-O`, solved with a test seam.

## Self-check questions

Each answer is collapsed; try the question first.

1. Why does this chapter report both the median and the minimum, and why does it run the whole experiment twice?

    ??? note "Answer"
        Timings on a real computer include interference (other processes, frequency changes, a cold cache), so one number is unreliable. The median ignores a few slow outliers and the minimum shows the least disturbed run. Running the whole experiment a second time shows how much the numbers move from run to run: here by up to 44%, which tells the reader which differences (large ones) can be trusted and which (1.0× to 1.2×) cannot.

2. What is a GFLOP/s, and why can it compare two implementations of the same product at the same size but not different sizes?

    ??? note "Answer"
        It is billions of floating-point operations per second; a product of N by N matrices costs 2·N³ operations, so dividing by the time gives the speed. At a fixed size the work is the same, so a higher number is simply faster. Across sizes the memory behavior changes (the matrices stop fitting in cache), so the same code runs at different speeds at different sizes, and the numbers do not measure the same thing.

3. The Mountain Goat matmul at `-O2` matches the C++ `ijk` loop. Does that mean Mountain Goat is fast?

    ??? note "Answer"
        No. It means the compiler turned `a @ b` into exactly the textbook loop, so it is no slower than that algorithm. The same table shows a hand-written loop with the middle loops swapped running about 5× faster at N = 256 and 12× faster at N = 512. "Matches the naive version" is a statement about overhead, not about speed.

4. What does loop tiling do, and what would you expect to happen to its benefit as N grows?

    ??? note "Answer"
        It restructures the loops to work on small square blocks at a time so that the data a block needs stays in cache while it is reused. Its benefit should grow with N because the untiled loop's memory traffic gets worse as the matrices become larger than the cache. The measurements are consistent with that: 1.1× at N = 64, 2.3× at 128, 2.6× at 256, 5.2× at 512. Cache misses were not measured, so this is consistent with the data, not proven by it.

5. `-O3 -march=native` made the untiled matmul no faster. What did the machine code show, and what can you conclude?

    ??? note "Answer"
        The assembly of the untiled functions contains zero vector or fused-multiply-add instructions: the loop is scalar, even though the CPU supports wide vectors. So "allow every instruction" cannot help if the compiler does not use them. What can be concluded is only that these builds are scalar; why the compiler declined to vectorize them was not investigated.

6. Result 5 says the tiled, fixed-shape build is fast and contains vector instructions. What does the chapter say it has *not* established?

    ??? note "Answer"
        Which ingredient matters. Only the combination (tiled and fixed shape) was built and measured. The dynamic-size tiled build is not vectorized, and the untiled fixed-shape build is not either, but a fixed-shape build tiled differently, or a dynamic build with a different tile size, was not tried. Claiming that "knowing the sizes" alone, or "tiling" alone, is the cause would go beyond the evidence.

7. Why is there no test saying "the tiled build is faster than the untiled one"?

    ??? note "Answer"
        Speed depends on the machine and how busy it is. A test like that would fail randomly on a loaded shared machine and pass on a quiet one, which makes it noise that teaches people to ignore failures. The tests instead check what must always hold: the results are identical across variants, the tiling pass really runs (loop counts), and the flags reach the compiler.

8. Ignoring the `-O` flag did not make any result-checking test fail. Why not, and how was it caught?

    ??? note "Answer"
        An optimization level changes how fast the program runs, not what it computes, so no test of the output can see whether it was applied. The bug is an equivalent mutant with respect to results. It was caught by adding a seam (`MGC_CLANG`) that lets a test substitute `echo` for clang, so `mgc` prints the command line it would have run, and the test checks that `-O2` is on it.

9. How did testing `mgc build` find a bug that had existed since Chapter 20, and what was it?

    ??? note "Answer"
        Earlier tests used `mgc run` and `mgc lib`, which never reach the script's last line in the failing way. A new test used `mgc build` and checked it succeeded. The last line, `[ "$cmd" = run ] && exec "$exe"`, evaluates to false when the command is `build`, and in a shell script the last command's status becomes the script's status, so `build` exited 1 on success. The fix is an explicit `if`. The lesson is that a new test exercised a path no earlier test used.

10. What would you need to do to turn this chapter's results into a claim about Mountain Goat's performance in general?

    ??? note "Answer"
        Run on more machines (ideally quiet, fixed-frequency ones), more operations and shapes, tune the tile size, use hardware counters to check the cache explanation, isolate the tiling and fixed-shape effects, and compare against a tuned library. This chapter did none of that, so its results are statements about one operation on one shared virtual machine in one session.
