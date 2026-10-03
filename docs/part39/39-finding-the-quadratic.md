# 39. Finding the Quadratic: a Differential Profile of the Lowering Pass

![Mountain goats on the mountain at night](../assets/goats/ch-39.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

**What you will understand:** how to find *why* a program is slow when timing alone says only *that* it is, using a **differential profile**: run the same code at several sizes under a profiler that counts instructions and see which function's cost grows faster than the rest. Chapter 38 measured that MLIR's `SCFToControlFlow` pass is super-linear in the number of loops in one function and fixed it by outlining, but said "the mechanism inside MLIR was not identified". This chapter identifies it: one function, `ilist_traits<Operation>::transferNodesFromList`, called by `Block::splitBlock`, whose instruction count is **exactly quadratic** (×3.98, ×3.99, ×4.00 per doubling) while everything else is linear. There is **no compiler change** in this chapter.

**What you need to know first:** Chapter 38 (the problem, the synthetic experiment, the fix). The tools are `valgrind --tool=callgrind` and `callgrind_annotate`; the chapter explains what they report.

!!! tip "Compile and run"
    ```sh
    cd docs/part38/code && ./build.sh                 # once: the compiler (this chapter adds nothing to it)
    cd ../../part39/code
    ./profile_scf.py > profile_out.txt                # the differential profile (about 2.5 minutes)
    ./check_profile.py > check_profile_out.txt        # the claims, as checks on exact instruction counts (about 45 seconds)
    ./claims_mutation.py > claims_mutation_out.txt    # three WRONG inputs the checker must catch (about 3 minutes)
    cd ../../part15/code && ./run_lit.sh              # the whole test suite
    ```
    Needs `valgrind` (it provides `callgrind` and `callgrind_annotate`); CI now installs it. Every output on this page comes from these commands.

!!! note "Why this page shows a mutation run, and why 'caught' is the wanted result"
    `claims_mutation.py` feeds the checker deliberately wrong inputs; "caught" is the wanted result and "NOT CAUGHT" would be a gap.

## The method: count instructions, not seconds

A stopwatch gives one number per run and is noisy. `callgrind` runs the program on a simulated CPU and **counts the instructions executed in every function**, exactly and repeatably. If a program is linear except for one quadratic part, then running it at *n*, 2*n*, 4*n*, 8*n* and comparing each function's count between runs shows the culprit: linear functions grow ×2 per doubling, the quadratic one ×4. The program is Chapter 38's synthetic one: *n* tiny loop nests (each copies four numbers) in **one function**, lowered with `mg-opt --lower-affine --convert-scf-to-cf` (the two passes the slow stage runs for loops).

## Part 1: which function is quadratic?

```text
--8<-- "docs/part39/code/profile_out.txt:1:14"
```

- The **whole program's** instruction count grows ×1.98, ×2.06, ×2.16 per doubling: about linear.
- **`transferNodesFromList`'s** count grows ×3.98, ×3.99, ×4.00: **exactly quadratic**, from 8.1 million instructions at 1,000 loops to 512 million at 8,000.
- Compare the functions that account for the growth from *n* = 2,000 to 8,000 (the second table): `transferNodesFromList` multiplies by 15.9 (4 × 4: quadratic); the five next functions (a hash-map lookup, type uniquing, the verifier, `malloc`) multiply by 3.8 to 4.0: linear.

## Part 2: who calls it, and why it is slow

```text
--8<-- "docs/part39/code/profile_out.txt:16:20"
```

(The columns are instructions, simulated L1 data-cache read misses, and L1 write misses, each with its share of the program total, for *n* = 6,000 under `--cache-sim=yes`; the first line is the caller.) The function is called by **`mlir::Block::splitBlock`**, and:

- it executes 13.0% of all instructions,
- but causes **63.3% of the L1 read misses and 97.5% of the L1 write misses** of the whole program.

`Block::splitBlock(it)` cuts a block in two at an operation and **moves every operation from `it` to the end of the block into a new block**. `transferNodesFromList` is the linked-list move: it walks the moved operations and **rewrites each one's pointer to its parent block**. `SCFToControlFlow` lowers each `scf.for` by splitting the block at the loop (the code after the loop must become the block that follows it). In a function that is one long run of loops, the loop at position *i* has the other *n* − *i* nests behind it, so splitting at it moves all of them. The total number of operations moved is about *n*²/2 times the operations per nest, which is exactly the quadratic count above. Each move touches memory at every operation (a write per node), which is why this one function dominates the cache misses even though it is only 13% of the instructions.

This also explains Chapter 38's puzzle that the **time** grew by ×9 per doubling at first while the **instruction count** of the whole program grew by about ×2: the quadratic part is a pointer-chasing loop that misses the cache, so each of its instructions costs much more than an average one. (That the wall-clock factors were then 9.0, 9.7, 4.8 and 3.6 and not a steady ×4 is **not** explained by this profile; a change of cost per instruction as the working set outgrows the caches is a candidate that was not tested.)

## Part 3: and after outlining?

```text
--8<-- "docs/part39/code/profile_out.txt:22:24"
```

With Chapter 38's `--mg-outline-loops` run first, `transferNodesFromList` and `splitBlock` are **not in the profile at all**: the one function holds a list of calls, not loops, so there is nothing for `SCFToControlFlow` to split. The whole program is linear (484 million instructions at 2,000 loops, 1,861 million at 8,000: ×3.85 for ×4). The same loops spread over functions of 100 give ×2.0 per doubling in the check below. Chapter 38 showed that splitting the function fixes the time; this shows **why**: each function's block is small, so each split moves few operations.

## Tests

One new `lit` file, `test/profile39/claims.mlir` (the suite is now 150 tests). `check_profile.py` runs `callgrind` on `mg-opt` at *n* = 250, 500 and 1,000 and checks, from exact instruction counts (so it is **not** a timing test and not flaky):

```text
--8<-- "docs/part39/code/check_profile_out.txt"
```

1. in one function `transferNodesFromList` grows by 3.9 to 4.1 per doubling while the whole program grows by less than 2.3;
2. it is called by `Block::splitBlock`;
3. with the same loops in functions of 100, it grows by less than 2.3 per doubling (here ×2.20 and ×2.00: linear);
4. after `--mg-outline-loops` neither function is in the profile.

**CI now installs `valgrind`** (the build step of `ci.yml` and the tool list of `ci.sh`).

### Are the checks good enough? Three wrong inputs.

```text
--8<-- "docs/part39/code/claims_mutation_out.txt"
```

All three are caught, each by the claim that depends on the broken input: the "functions of 100" case secretly made one function fails the linear claim (×3.93, ×3.97); a pass that does not outline (`--canonicalize`) in place of `--mg-outline-loops` fails the "after outlining" claim; and profiling `--lower-affine` alone, without the pass under study, fails the quadratic and the caller claims (the function never runs: ×0.00). (The third case first crashed the checker with a division by zero instead of failing a claim; the checker now guards the division, and the output above is from the repaired one.)

The full suite:

```text
--8<-- "docs/part15/code/run_out_150.txt"
```

## Limits and what is not established

- **This is MLIR 18.1.3's `SCFToControlFlow`.** Another version may split blocks differently; this was not checked.
- **The profile identifies the function and its caller, not the exact line.** The link between "splitting moves the tail of the block" and the quadratic count is established by the function names, the exact ×4 growth, and the absence of the function after outlining, but the pass's source was not read and no alternative explanation was excluded by experiment (for example by patching MLIR).
- **The wall-clock explanation is partial.** The cache-miss share (63% and 97.5%) fits the observation that time grew faster than instructions; a timing experiment that isolates it (for example the same count of moved operations laid out contiguously) was not done, and the later wall-clock factors (4.8, 3.6) are unexplained.
- **A fix inside MLIR was not tried.** Lowering the loops from the last to the first would make each split move a short tail; that is an idea suggested by the mechanism, not something tested here. Chapter 38's outlining avoids the problem in the compiler this book builds.
- **The synthetic function is far simpler than the training program.** Its loops copy four numbers; the check is on instruction counts and mechanism, not on the training program's absolute time.
- **Only the lowering passes were profiled,** not `clang` or `mlir-translate`, which Chapter 38 showed to be linear.
- **Platform:** x86-64 Linux, valgrind 3.22, LLVM/MLIR 18.1.3.

## Reproducing

```sh
cd docs/part38/code && ./build.sh
cd ../../part39/code
./profile_scf.py > profile_out.txt && ./check_profile.py > check_profile_out.txt && ./claims_mutation.py > claims_mutation_out.txt
cd ../../part15/code && ./run_lit.sh          # 150 tests
```

## Chapter summary

- A differential profile (the same code at four sizes under `callgrind`) finds the function whose cost grows faster than the rest: here `transferNodesFromList`, ×3.98, ×3.99, ×4.00 per doubling of the loops, while the program as a whole grows ×2.
- It is called by `Block::splitBlock`: lowering each `scf.for` splits the function's block at the loop and moves everything after it, so *n* loops in one function cost about *n*²/2 moved operations.
- That one function is 13% of the instructions but 63% of the L1 read misses and 97.5% of the write misses, which is why wall-clock time grew faster than the instruction count.
- After Chapter 38's outlining, the function and `splitBlock` do not appear at all.
- The claims are checked from exact instruction counts, with three wrong inputs caught; CI now installs `valgrind`. No compiler change.

## Self-check questions

Each answer is collapsed; try the question first.

1. Why count instructions with `callgrind` instead of timing the pass?

    ??? note "Answer"
        Instruction counts are exact and repeatable (the same every run), per function; a stopwatch gives one noisy number per run and cannot say which function is responsible. Running at several sizes and comparing each function's count turns "the pass is slow" into "this function grows ×4 when everything else grows ×2".

2. In the table, the whole program grows ×2.06 per doubling but one function grows ×3.99. What does each number tell you?

    ??? note "Answer"
        The whole-program number says the program is *about* linear overall (most of the work scales with the size). The function's ×3.99 says it alone is quadratic; at these sizes it is still a small share of the total instructions (512 of 3,092 million at 8,000 loops), so the total's growth is only slightly above ×2 and creeps up (1.98, 2.06, 2.16) as the quadratic part takes a larger share.

3. What does `Block::splitBlock` do, and why does lowering a long run of loops make it quadratic?

    ??? note "Answer"
        It cuts a block in two at an operation and moves all later operations to a new block, updating each moved operation's parent pointer. Lowering a loop to branches needs a new block for the code after it, so each loop's lowering moves everything behind it. With *n* loops in one function, the first moves about *n* nests' worth of operations, the next *n* − 1, and so on: about *n*²/2 in total.

4. After `--mg-outline-loops`, `splitBlock` is absent from the profile. Why?

    ??? note "Answer"
        Outlining replaces each top-level loop nest with a call, so the big function contains no loops left to lower (its loops are in the small outlined functions, which are few, and each is a short block). With no loop to lower in the big block, `SCFToControlFlow` never splits it.

5. The same 32,000 loops took 88 s in one function and 0.4 s in functions of 500 (Chapter 38). How does this chapter account for the difference, and what does it leave unexplained?

    ??? note "Answer"
        In functions of 500 each split moves at most a few hundred nests' worth of operations, so the total is linear in the number of loops; in one function it is quadratic, and the quadratic part misses the cache. What it does not explain is the exact wall-clock factors (9.0, 9.7, 4.8, 3.6): the instruction count grows ×4 cleanly, but the time per moved operation changes with the working-set size, which was not measured.

6. Why can this chapter's tests run in CI when they depend on a profiler?

    ??? note "Answer"
        They check exact instruction counts, not times, so they give the same answer on any machine, and CI installs `valgrind`. A timing-based test of the same claim would depend on the machine's speed and load and would be flaky.
