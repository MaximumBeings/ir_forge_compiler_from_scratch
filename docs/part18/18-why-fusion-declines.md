# 18. Why Fusion Declines: Reading the Pass, and a Second Bug Found Along the Way

**What you will understand:** why `--affine-loop-fusion` does nothing on loops with dynamic bounds, which Chapter 17 measured but could not explain. The method is the one that works for any opaque compiler behavior: read the source, form a hypothesis, then design experiments that *discriminate* between hypotheses rather than merely agree with one. The result is a precise rule, established from the pass's own code and confirmed on six hand-written programs. Testing the obvious workaround then exposed a second, unrelated problem: the same pass produces **invalid IR** on tiled dynamic loops. Every source excerpt on this page is embedded from unmodified copies of the LLVM 18.1.3 files kept in the repository.

**What you need to know first:** Chapter 17's results, in particular the fusion rows. New ground: how a loop-fusion pass decides whether to fuse (a cost model), and reading MLIR's affine transform source.

## Background: what a fusion pass decides

Two adjacent loop nests, where the first writes a buffer and the second reads it, can often be merged into one nest, so each element is consumed right after it is produced and the intermediate buffer can shrink. Chapter 7 showed this on static loops: an add nest and a transpose nest became one nest and a 4x6 buffer became a single scalar slot. But fusion is not always a win (it can duplicate work), so the pass does not fuse blindly. It runs a **profitability analysis**: a cost model that counts operation instances (roughly, ops in the body times trip counts) for the nests before and after fusion and compares them. A cost model made of products of trip counts needs the trip counts as *numbers*. That is the thread this chapter pulls.

## What Chapter 17 observed

Fusion left the dynamic chain at four loops. A dynamic add-then-add chain was also left alone, while the same add-then-transpose chain with static bounds fused from four loops to two. That ruled out the transpose, and Chapter 17 stopped there: "dynamic bounds block fusion; the cause was not established". The pass reports nothing when it declines, so the observable behavior is only "the IR did not change".

## Step 1: read the source

`isFusionProfitable` is the function that decides. Its opening lines (`LoopFusion.cpp`):

```cpp
--8<-- "docs/part18/code/llvm-18.1.3/LoopFusion.cpp:445:475"
```

Two early exits matter. Lines 468 and 473 call `getLoopNestStats` on the producer nest and on the consumer nest and **return false** (decline) if either call fails. `getLoopNestStats` (in `LoopFusionUtils.cpp`) is where the trip counts are collected:

```cpp
--8<-- "docs/part18/code/llvm-18.1.3/LoopFusionUtils.cpp:472:510"
```

The relevant lines are the walk over **every** `affine.for` in the nest, and inside it: if `getConstantTripCount(forOp)` yields no value, the code logs `"Non-constant trip count unsupported"` and interrupts the walk, so the function returns false. The comment is explicit: `// Currently only constant trip count loop nests are supported.` One loop with a non-constant trip count anywhere in either nest is enough.

A second exit exists a little further down. After the cost stats, the pass computes the size of the region the producer writes (`LoopFusion.cpp`):

```cpp
--8<-- "docs/part18/code/llvm-18.1.3/LoopFusion.cpp:493:503"
```

and `MemRefRegion::getRegionSize` (in `Analysis/Utils.cpp`) returns no value, with the message `"Dynamic shapes not yet supported"`, when the region does not have a constant bounding size:

```cpp
--8<-- "docs/part18/code/llvm-18.1.3/AffineAnalysisUtils.cpp:1215:1238"
```

So the source offers **two** candidate reasons, and they predict different things. The trip-count check depends on the *loops'* bounds; the region-size check depends on the *shape of what is accessed*. Finally, how the pass reacts to a "no". At the producer-consumer call site:

```cpp
--8<-- "docs/part18/code/llvm-18.1.3/LoopFusion.cpp:968:974"
```

When `isFusionProfitable` returns false the code does `continue`: skip this candidate pair, say nothing. That is exactly the silent no-op Chapter 17 saw.

## Step 2: the source's own explanation is not available

Reading code tells you what the pass *would* say, but the message strings live inside `LLVM_DEBUG(...)`, which is compiled out of release builds. Whether this toolchain can print them was checked rather than assumed (`debug_unavailable.sh`):

```sh
--8<-- "docs/part18/code/debug_unavailable.sh"
```

```text
--8<-- "docs/part18/code/debug_unavailable_out.txt"
```

`--debug-only` does not exist in this `mlir-opt-18`, and neither message string is present in the binary. So the source cannot be confirmed by asking the pass. It has to be confirmed by experiment.

## Step 3: experiments that discriminate

The two hypotheses make opposite predictions about two kinds of program:

- **H1, trip counts:** dynamic *loop bounds* over *static buffers* should decline; *constant* loop bounds over *dynamic buffers* should fuse (nothing non-constant for `getLoopNestStats` to trip on, and the region touched is still constant-sized).
- **H2, region size / dynamic memref shapes:** the opposite: dynamic buffers should decline.

Chapter 17's chain varied both at once (dynamic bounds *and* dynamic buffers), so it could not tell them apart. The experiments below are hand-written affine programs, each an add nest feeding a transpose nest through an intermediate buffer, varying one property. The control, `exp_C`, is fully static:

```mlir
--8<-- "docs/part18/code/exp_C.mlir"
```

`exp_A`: both nests' loop bounds are function-argument symbols (`%n`, `%m`), buffers static:

```mlir
--8<-- "docs/part18/code/exp_A.mlir"
```

`exp_B`: loop bounds constant, buffers **dynamic** (`memref<?x?xf64>`, allocated from runtime sizes):

```mlir
--8<-- "docs/part18/code/exp_B.mlir"
```

Three more variants (`exp_E`, `exp_F`, `exp_G`) are generated from the control by changing **exactly one loop's bound** to the symbol `%n`: the producer's outer loop, the producer's inner loop, and the consumer's outer loop. Their exact differences from the control (`exp_variants_diff.txt`; note each also gains the `%n` parameter):

```diff
--8<-- "docs/part18/code/exp_variants_diff.txt"
```

The script that runs everything:

```sh
--8<-- "docs/part18/code/fusion_experiments.sh"
```

### Results

The first part of the real output (`fusion_experiments_out.txt`): loops before and after `--affine-loop-fusion`, where a successful fusion of these programs takes 4 loops to 2.

```text
--8<-- "docs/part18/code/fusion_experiments_out.txt:1:7"
```

- **C (control):** fuses, 4 to 2. The programs are fusable in principle.
- **A (dynamic bounds, static buffers):** declines. H1 predicted this; H2 did not.
- **B (constant bounds, dynamic buffers):** **fuses**. This is the discriminating result. If dynamic buffer shapes were the blocker (H2), B would decline. It does not, because the *region accessed* is still constant-sized (the loops touch a fixed 4x6 block), so the `getRegionSize` check passes even though the memref type is dynamic.
- **E, F, G:** declining with only **one** dynamic loop anywhere (producer outer, producer inner, consumer outer). That matches `getLoopNestStats` walking *every* loop of *both* nests and giving up at the first non-constant one.

## What this establishes, and what it does not

**Established** (source reading plus six experiments that agree with it and exclude the alternative): this toolchain's `--affine-loop-fusion` needs every `affine.for` in both the producer and the consumer nest to have a constant trip count. Dynamic buffer shapes alone do not prevent fusion. When the rule fails the pass declines silently, via `continue`.

**Not established**, stated plainly:

- **The second exit was never isolated.** `getRegionSize`'s "Dynamic shapes not yet supported" check exists, but every program that could reach it with a non-constant region already failed the trip-count check first (a region cannot be unbounded unless a loop bound is dynamic). Whether that message can fire by itself was not demonstrated.
- **`getConstantTripCount`'s definition was not read.** Its behavior is inferred from the experiments (constant bounds yield a count; function-argument symbols do not), not from its code. Whether a bound like `min(...)` ever counts as constant was not tested here.
- **The sibling-fusion path** (the other call to `isFusionProfitable`, near line 1187) calls the same function and presumably obeys the same rule, but no sibling-fusion program was tried.

This explains a fact Chapter 17 recorded but could not explain, and it makes a prediction that is easy to falsify (a toolchain that relaxes the rule would fuse the dynamic programs). The test below pins it.

## A workaround attempt that found a bug

An obvious idea: if the problem is non-constant trip counts, give the pass constant ones by **tiling first** with a constant tile size, then fuse. The tile loops step by a constant, so perhaps the pass will see something it likes. It does not work, and failing in an unexpected way. The second half of the output records it, with static controls:

```text
--8<-- "docs/part18/code/fusion_experiments_out.txt:9:12"
```

- On the **static** chain, tiling by 1 and then fusing works (8 loops down to 4) and tiling by 2 then fusing leaves the loops alone (8), both with valid IR.
- On the **dynamic** chain, tiling by 4 and then fusing does not decline. The pass **changes the IR and the result fails verification**: `operand #0 does not dominate this use`.

That last case is a different kind of failure from everything above: not "does nothing" but "produces invalid IR". To see what the pass did, verification was turned off (`--verify-each=0`) and both versions were printed in MLIR's generic form so only real changes show. The loop-header lines that differ (`<` before fusion, `>` after, again from `fusion_experiments_out.txt`):

```text
--8<-- "docs/part18/code/fusion_experiments_out.txt:14:30"
```

Read the `step` fields. Before, the nest is tile loops (`step = 4`) outermost, then point loops (`step = 1`, whose bounds mention the tile loops' induction variables, e.g. `(%arg4, %11, %arg4)`). After, the nest order is **reversed**: the `step = 1` loops are outermost and the `step = 4` loops innermost, in *both* nests. The point loops' bounds still reference the tile loops' induction variables (`%arg4`, `%arg5`), which are now defined *inside* them, so they no longer dominate their use. That is the verifier's complaint.

### Where it happens in the source

The pass interchanges loops before it even considers profitability. At the start of its per-destination-nest work (`LoopFusion.cpp`):

```cpp
--8<-- "docs/part18/code/llvm-18.1.3/LoopFusion.cpp:827:836"
```

`sinkSequentialLoops(dstNode)` runs for every destination loop nest, **whether or not any fusion will follow**. Its definition (`LoopUtils.cpp`):

```cpp
--8<-- "docs/part18/code/llvm-18.1.3/LoopUtils.cpp:1490:1537"
```

The steps: collect the perfectly nested loops; compute dependence components between the ops; mark a loop *sequential* if any dependence component has a nonzero bound; compute a permutation that moves sequential loops inward and parallel loops outward; check **only data dependences** (`checkLoopInterchangeDependences`); then call `permuteLoops`. The head of `permuteLoops`:

```cpp
--8<-- "docs/part18/code/llvm-18.1.3/LoopUtils.cpp:1421:1447"
```

validates that the permutation is a permutation and that the loops are perfectly nested. **In the lines read, nothing checks whether a loop's *bounds* use an enclosing loop's induction variable.** That is exactly the structure of a tiled nest, so a permutation that moves the tile loops inward yields invalid IR.

What this explains, and what it does not:

- **Consistent with the evidence:** the observed permutation (tile loops moved inward) is the output of this function; it runs before profitability; and the only legality check visible before the permutation concerns data dependences.
- **Inferred, not demonstrated:** *why* the tile loops are judged sequential on the dynamic nest but not on the static one. The natural reading is that dependence analysis with symbolic bounds cannot prove independence and reports nonzero components, while with constant bounds it can. The pass's dependence results were not printed (debug output is compiled out), so this is a hypothesis.
- **Not read in full:** `checkLoopInterchangeDependences` and the body of `permuteLoops` beyond its head. The claim is only that no bound check appears in the lines shown here, not that none exists anywhere.

## What this means for Mountain Goat's pipeline

- **Fusion cannot help dynamic shapes in this toolchain.** Every nest in a dynamic `mg` program has non-constant trip counts, so fusion declines. Chapter 7's fusion benefit exists only for static shapes.
- **Order matters: never tile and then fuse dynamic loops.** Chapter 7's own order (fusion, then tiling, then unrolling) is safe because fusion runs first. The reversed order breaks on dynamic bounds with this LLVM version.
- **Not tried:** specializing a dynamic program into static copies for common sizes (which would let fusion apply), or checking whether a newer LLVM relaxes either behavior.

## The tests, and whether they can fail

Two tests pin this chapter's findings. The first pins the rule (the constant-trip-count requirement) with the six programs above, three that must fuse and declining ones where each single dynamic loop blocks it:

```mlir
--8<-- "docs/part15/code/test/dynamic-loops/fusion-needs-constant-trip-counts.mlir"
```

The second pins the bug, with the static controls that show the failure needs dynamic bounds. Its header says it is **designed to start failing**: if a newer LLVM fixes the interchange, the dynamic run will stop producing an error, and that is the signal to revisit this chapter:

```mlir
--8<-- "docs/part15/code/test/dynamic-loops/fusion-after-tiling.mlir"
```

The suite is now 44 tests (`run_out_44.txt`):

```text
--8<-- "docs/part15/code/run_out_44.txt"
```

Five new mutations were added to the Chapter 17 failure-injection script, three for the rule test and two for the bug-pin test, and all were caught (the complete output):

```text
--8<-- "docs/part15/code/dynloops_mutation_out.txt"
```

Mutations 7 to 9 feed a "must decline" run a program that fuses (or a "must fuse" run a program that declines), so the rule test fails exactly when the rule stops holding; 10 feeds the "must error" run a static program that verifies; 11 changes the static control's tile size so its loop count is wrong.

## What this does and does not establish

- **One LLVM version.** All of it describes `llvmorg-18.1.3`; the source read and the binary run are the same release. Newer versions may differ.
- **Fusion was examined only for this producer-consumer shape.** Sibling fusion, other op mixes and other loop counts were not.
- **The invalid-IR finding is a symptom and a located cause, not a root-cause analysis.** The inferred link (dependence analysis marks tile loops sequential on dynamic bounds) is a hypothesis, and the bug was not reported upstream or tested against other versions.
- **No performance claims.** Nothing here was timed.
- **No CI.** The suite runs when someone runs it.

## Reproducing this chapter

```bash
../part14/code/build.sh          # the mg-opt under test (and: pip install lit)
cd docs/part18/code
./debug_unavailable.sh > debug_unavailable_out.txt
./fusion_experiments.sh > fusion_experiments_out.txt
cd ../part15/code
./run_lit.sh > run_out_44.txt
./dynloops_mutation.sh > dynloops_mutation_out.txt
```

The LLVM source in `code/llvm-18.1.3/` was read from `llvm/llvm-project` at tag `llvmorg-18.1.3` (provenance and license in its `NOTICE.md`); every quoted line is embedded from those unmodified copies. As in Chapters 10 through 17, no documentation was consulted: each claim comes from running the commands or reading the source.

## Chapter summary

This chapter explained Chapter 17's unexplained limitation. Reading the LLVM 18.1.3 source showed that `--affine-loop-fusion`'s profitability analysis collects trip counts for both loop nests and declines the moment any loop has a non-constant one (`getLoopNestStats`: "Currently only constant trip count loop nests are supported"), and that a decline is a silent `continue`. The source also contains a second candidate reason (dynamic region sizes). Experiments designed to tell them apart showed that constant-bound loops over *dynamic* buffers fuse while a dynamic bound on any single loop, anywhere, declines. So trip counts, not buffer shapes, are the blocker. Testing the obvious workaround (tile by a constant, then fuse) exposed a second problem: on tiled dynamic loops the pass interchanges loops through `sinkSequentialLoops` without checking that loop bounds survive the move, producing invalid IR, while static tiled loops are fine. Two `lit` tests pin the rule and the bug (suite: 44), and eleven mutations were all caught.

Deliberately out of scope, stated explicitly: only one LLVM version and one producer-consumer shape; the `getRegionSize` exit was never isolated; `getConstantTripCount` and most of `permuteLoops` were not read; the reason tile loops are judged sequential on dynamic nests is an inference; the bug was not reported upstream; and specializing to static sizes was not tried.

## Self-check questions

**1. Chapter 17's chain had both dynamic loop bounds and dynamic buffers. Why could it not distinguish the two candidate reasons for fusion declining, and what experiment did?**

Worked answer: because both properties were present at once, either explanation predicted a decline. The source offered two reasons: a non-constant trip count (`getLoopNestStats`) and a non-constant region size (`getRegionSize`). Experiment B separated them: constant loop bounds over dynamic buffers. If dynamic buffer shapes were the blocker it would decline; it fused (4 loops to 2), because the region those loops access is a fixed 4x6 block. Experiment A, dynamic bounds over static buffers, declined, so the trip counts are what matter.

**2. Why did the chapter try to read the pass's own debug explanation, and why could it not?**

Worked answer: the pass logs its reason for declining, so asking it would be the most direct confirmation. But the messages are inside `LLVM_DEBUG(...)`, which is compiled out of release builds: `mlir-opt-18` has no `--debug-only` option, and neither message string appears in the binary (`strings` finds zero occurrences of each). So the source was read for the hypothesis and the experiments were used to confirm it.

**3. Experiments E, F and G each make a single loop dynamic. What does it show that all three decline?**

Worked answer: it shows the rule is not "the outer loops" or "the producer" but *any* loop in *either* nest. That matches `getLoopNestStats`, which walks every `affine.for` in a nest and interrupts at the first non-constant trip count, and which `isFusionProfitable` calls for both the producer and the consumer. A dynamic bound on the producer's outer loop, the producer's inner loop or the consumer's outer loop each triggers it.

**4. Tiling by a constant and then fusing did not simply fail to help. What actually happened, and what do the static controls show?**

Worked answer: on the dynamic chain the pass changed the IR and the result failed verification (`operand #0 does not dominate this use`). Printed in generic form, the nest order was reversed: the `step = 1` point loops moved outermost and the `step = 4` tile loops innermost, in both nests, so the point loops' bounds referred to tile induction variables now defined inside them. The static controls (tile by 1 then fuse gives 4 loops, tile by 2 then fuse leaves 8) verify, so the failure needs dynamic bounds.

**5. The invalid IR is attributed to `sinkSequentialLoops`. What in the source supports that, and what is only inferred?**

Worked answer: the pass calls `sinkSequentialLoops(dstNode)` on every destination loop nest before any profitability decision; the function labels loops sequential from dependence components, computes a permutation moving sequential loops inward, checks only data dependences, and calls `permuteLoops`, whose visible head checks only that the map is a valid permutation and the loops are perfectly nested. The observed output is exactly that permutation. What is only inferred is why the tile loops are judged sequential on the dynamic nest but not the static one (the dependence results could not be printed), and the claim that no bound check exists is limited to the lines read.
