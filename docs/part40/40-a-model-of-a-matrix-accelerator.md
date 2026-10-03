# 40. A Model of a Matrix Accelerator: Tiles, a Scratchpad, and What Loop Order Does There

![Mountain goats in space helmets on the Moon](../assets/goats/ch-40.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

**What you will understand:** what decides the speed of a matrix accelerator, measured on a machine you can read in full. This chapter builds **GA-1**, a cycle-counting **model** (not a chip, and not a design for one) with the three things that matter: a **DMA engine** that moves tiles between off-chip memory and a small on-chip **scratchpad**, a **matrix unit** that multiplies two tiles and accumulates, and a vector unit (used from Chapter 41). Then it takes the loop-order and tiling ideas of Chapters 7, 24 and 37, which on a CPU were about caches and vector registers, and asks what they do **here**: which schedule moves the fewest tiles, when the machine is limited by its memory and when by its arithmetic, and what double buffering buys. Every number comes from running the simulator, a simple analytic model is checked against it, and a deliberately broken simulator is shown to be caught.

**What you need to know first:** Chapter 24 (the `ikj` loop order and why `ijk` walks memory badly) and Chapter 37 (the idea of a core model that ignores memory). **No Mountain Goat compiler is involved in this chapter**: the schedules are written by hand. Chapter 41 compiles Mountain Goat programs onto GA-1.

!!! warning "This is a model, not a chip"
    Every parameter of GA-1 (tile size, scratchpad size, DMA cost, matrix-unit rate) is an **assumption chosen to have plausible ratios** (the matrix unit is much faster than the memory), not a measurement of any real device, and no real accelerator was consulted to calibrate it. What transfers to real chips is the *shape* of the arguments (reuse, double buffering, bound by memory or by arithmetic); the cycle counts do not.

!!! tip "Compile and run"
    ```sh
    cd docs/part40/code                               # plain Python 3, no dependencies
    ./sweep_orders.py > sweep_orders_out.txt          # 128 x 128 x 128 product, 14 schedules, two scratchpad sizes (8 seconds)
    ./timeline.py > timeline_out.txt                  # a text picture of the engines
    ./bandwidth_sweep.py > bandwidth_sweep_out.txt    # what a faster memory changes (8 seconds)
    ./check_ga.py                                     # results, traffic formulas, timing, independent hazard replay (about a second)
    ./sim_mutation.py > sim_mutation_out.txt          # 11 WRONG simulators the checker must catch (15 seconds)
    cd ../../part15/code && ./run_lit.sh              # the whole test suite
    ```
    Every listing and output on this page comes from these commands.

!!! note "Why this page shows a mutation run, and why 'caught' is the wanted result"
    `sim_mutation.py` writes broken versions of the simulator and expects the checker to fail on each. "Caught" is good; "NOT CAUGHT" would be a gap. Nothing on this page is a failing test.

## The machine

| part | what GA-1 has | assumption (a number in `ga.py`) |
|---|---|---|
| tile | `T × T` words, `T = 8` (64 words) | the unit of every transfer and of every matrix product |
| scratchpad | a few tile slots, 16 or 64 here | the only memory the units can use |
| DMA | **one** engine; one transfer at a time, DRAM ↔ one slot | `16 + 64/16 = 20` cycles per tile (setup 16, then 16 words per cycle) |
| matrix unit | `C += A @ B` on three slots; accepts a new product every 8 cycles (`8 × 8 × 8 = 512` multiply-adds, **64 per cycle**); another engine can read a product 8 cycles after it finishes (the "fill"), but accumulating into it again needs no extra wait | `mxu_cycles = 8`, `mxu_fill = 8` |
| vector unit | elementwise on a tile, 16 lanes; `exp` on a slower path of 4 lanes (Chapter 41) | |

Each engine has its **own in-order queue** and the three run independently (as in real accelerators with decoupled access and execute); an instruction starts when its engine is free, its source slots have been written, and the slots it overwrites are no longer needed by earlier instructions. The instructions are `load`, `store`, `zero`, `mxu` and, for Chapter 41, a few vector ones. The whole simulator, including the instruction set in its header comment and the one place where the timing rule lives (`_run`), is short enough to read:

```python
--8<-- "docs/part40/code/ga.py"
```

Two things to notice. The **functional** result of every instruction is computed on real numbers, in program order, so a schedule's output is what its instructions say, whatever the timing. The **timing rule** is what enforces the hazards, and the simulator records every instruction's start and finish so that a separate checker can verify it (below).

## A six-instruction program, timed by hand

Zero a slot, load two tiles, multiply them into it twice, store: `("zero", 2), ("load", 0, "A", 0, 0), ("load", 1, "B", 0, 0), ("mxu", 2, 0, 1), ("mxu", 2, 0, 1), ("store", 2, "C", 0, 0)`. By hand: the two loads share the one DMA engine, 20 cycles each, so the products can start at cycle 40; two chained products take 16 cycles (40 to 56, accumulating into the same slot needs no fill wait); the store must wait until the product can be *read*, 8 cycles after cycle 56, so it starts at 64 and takes 20: **84 cycles**. The simulator says 84, and `check_ga.py` checks that.

Here is a text picture (`timeline.py`) of a real, small product (32 × 32 × 32, 4 × 4 × 4 tiles) scheduled as one block of 2 × 2 tiles of C, single and double buffered (one character is 4 cycles; `D` is a DMA transfer, `M` a matrix-unit product):

```text
--8<-- "docs/part40/code/timeline_out.txt"
```

The DMA row is almost always busy; the matrix unit is idle most of the time, waiting for tiles (the `M`s come in bursts after each step's loads). That is the whole chapter in one picture: with these ratios the memory, not the arithmetic, is the bottleneck, and the schedule decides how bad it is.

## The schedules

Two families of hand-written programs for `C = A @ B` (`schedules.py`):

```python
--8<-- "docs/part40/code/schedules.py"
```

- **`blocked(bi, bj)`: keep a block of `bi × bj` tiles of C in the scratchpad and stream K through it.** Each step loads `bi` tiles of A and `bj` tiles of B and does `bi · bj` products, so the loads per product are `(bi + bj) / (bi · bj)`: `2` for `1 × 1` (the plain `i, j, k` order), `1.06` for a whole row of `1 × 16` (the `i, k, j` order of Chapter 24), `1` for `2 × 2`, `0.5` for `4 × 4`, `0.375` for `4 × 8`. This is *reuse*: bigger blocks do more work per loaded tile, and cost scratchpad slots.
- **double buffering:** with two sets of A/B slots, the loads for step `k + 1` are issued **before** the products of step `k` and land in the other set, so the DMA and the matrix unit overlap. It costs `bi + bj` more slots.
- **`kouter`: the `k, i, j` order.** Every tile of C is loaded (the partial sum), updated by one product and stored again, for every `k`.

## Results

`sweep_orders.py` runs all of them on a 128 × 128 × 128 product (16 × 16 × 16 tiles, 4,096 tile products), checking each result against a plain triple loop first. The matrix unit alone would need 32,768 cycles; the DMA alone, moving every tile exactly once, 15,360.

```text
--8<-- "docs/part40/code/sweep_orders_out.txt"
```

Read the 64-slot table first:

- **The plain `i, j, k` order (`1 × 1`) is the worst of the blocked ones:** 8,448 tiles moved, and even with double buffering 173,056 cycles and **19%** of the matrix unit's peak. The DMA is busy 98% of the time: the machine is **DMA-bound**.
- **Reuse is everything.** Tiles moved fall from 8,448 (`1 × 1`) to 4,608 (a row), 4,352 (`2 × 2`), 3,328 (`2 × 4`), 2,816 (`2 × 8`), 2,304 (`4 × 4`) and 1,792 (`4 × 8`). Cycles follow the tiles when the DMA is the bottleneck: `4 × 4` double buffered takes exactly **46,080 = 2,304 × 20 cycles** (the DMA 100% busy; the matrix unit at 71%, which is just 32,768 / 46,080).
- **At `4 × 8` the bottleneck flips.** A step has 12 loads (240 cycles) and 32 products (256 cycles): now the **matrix unit** is the longer, utilization reaches **88%** and the cycles (37,440) are close to the arithmetic bound of 32,768. The condition for being compute-bound is `8 · bi · bj ≥ 20 · (bi + bj)`; with these numbers it first holds at `4 × 8` among the shapes tried (it does not hold at `4 × 4`: 128 against 160).
- **Double buffering helps exactly when something is left to overlap.** It gives 1.18× at `1 × 1`, 1.09× at `2 × 2`, 1.27× at `4 × 4`, 1.41× at `4 × 8`, and almost nothing (even slightly negative) for a whole row, where the single-buffered version is already almost DMA-saturated (98%).
- **The `k` outermost order is catastrophic here:** 16,128 tiles moved (every partial sum goes out to DRAM and back for every `k`), 388,096 cycles, **10.4 times** the best, and the matrix unit at 8%. This is the accelerator version of the CPU result of Chapter 24: the loop order that keeps the accumulator close wins.
- **A simple model predicts the double-buffered rows.** `S.predicted_double_buffered_cycles` says a step takes the *longer* of its loads and its products, plus the unoverlapped first loads and last stores. It is within **4% to 6% above** the simulator for every double-buffered row in the table (the last column; it is always a little pessimistic) and within 12% in the checker's smaller runs. It is a model of a model: it explains the simulator, it does not validate it against anything real.

The **16-slot** table shows what a small scratchpad does: the large blocks and the double-buffered versions of the medium ones **do not fit**, so the best feasible schedule is `2 × 4` single buffered (76,160 cycles), and the "best" there is a worse machine than the 64-slot one's best. Capacity is a trade between blocking (reuse) and double buffering (overlap): `2 × 2` with two buffers needs 16 slots and gives 87,040 cycles, `2 × 4` with one buffer needs 16 and gives 76,160.

### What if the memory were faster?

`bandwidth_sweep.py` runs three double-buffered schedules (`1 × 1`, `2 × 4`, `4 × 8`) on machines whose DMA moves 8 to 64 words per cycle, with the setup cost of a transfer either 16 cycles or 4:

```text
--8<-- "docs/part40/code/bandwidth_sweep_out.txt"
```

Two lessons, both about the *model's* assumptions: **raising the bandwidth barely helps** while the per-transfer setup stays at 16 cycles (the gap between the worst and best schedule goes from 4.8× only down to 4.1× as bandwidth grows eightfold, because a tile takes 24 cycles at 8 words per cycle and still 17 at 64: the setup dominates), whereas **cutting the setup to 4 cycles helps a great deal** (at 16 words per cycle the gap falls to 2.2×, and `2 × 4` already reaches 96% utilization). So for this machine, **larger or fewer transfers** is a better lever than a faster bus. Whether a real device behaves this way depends on its real setup cost, which this chapter does not know.

## Tests

One new `lit` file group `test/ga40/` (the suite is now 152 tests; two files: `check` and `timeline`). `check_ga.py` checks, in order:

1. **Results:** 70 combinations (7 shapes, including sizes that are not multiples of the tile and a single row and column; 5 schedules; single and double buffering) each give exactly the plain triple loop's `C`.
2. **Traffic:** the tiles loaded and stored equal the formula in all 70 runs (`blocked`: per block, per `k`, `bi + bj` loads and one store per tile of C; `kouter`: two loads per product, a partial-sum load for every `k` after the first, a store per `k`).
3. **Timing, from first principles:** the six-instruction program takes 84 cycles; `4 × 4` double buffered on 64 × 64 × 64 takes exactly (tiles moved × 20) cycles; no schedule beats the matrix-unit bound or its own DMA bound; more reuse always moves fewer tiles; double buffering is faster for `1 × 1` and `4 × 4`; the simple model is within 12%.
4. **Hazards, independently:** the simulator records when every instruction started and finished; the checker replays that trace, written separately from the timing rule, and verifies for every slot that no instruction read a value before the write that produced it (plus fill) was done and that no write began before the earlier reads of that slot had finished.

```text
--8<-- "docs/part40/code/check_ga.py"
```

(The listing is the checker itself.) Its output:

```text
--8<-- "docs/part40/code/check_ga_out.txt"
```

### Are the checks good enough? Eleven wrong simulators.

`sim_mutation.py` breaks `ga.py` eleven ways and runs the checker on each:

```text
--8<-- "docs/part40/code/sim_mutation_out.txt"
```

All eleven are caught. Which check caught which is informative: the **independent hazard replay** catches exactly the hazard bugs (a write that does not wait for earlier reads; an instruction that waits for only one of its operands; a load that ignores the slot's earlier use), and **only** it and the double-buffering check notice them, because the *results* are computed in program order and do not depend on timing; the **hand-timed program** catches the cost bugs (no DMA setup, a wrong fill, accumulation waiting for the fill); the **traffic formula** catches a double-counted store; the **results** catch the padding and the transposed-operand bugs; and the **DMA-bound equality** catches the lock-step engines.

The full suite:

```text
--8<-- "docs/part15/code/run_out_152.txt"
```

## Limits and what is not established

- **A model of a machine that does not exist.** No real device calibrated the parameters. The matrix unit's rate, the DMA's setup and bandwidth, the scratchpad sizes and the tile size are inventions with plausible ratios; **the conclusions that depend on the ratios** (for example that `4 × 8` is the first compute-bound block, or that setup cost dominates bandwidth) hold for GA-1 and may not for any real chip.
- **What is not modelled:** instruction fetch and decode, a real memory hierarchy (DRAM is a flat store with a constant cost per transfer: no banks, no contention, no refresh, no row buffers), more than one DMA channel, tiles that are not square or not `T × T`, energy and area, numerical formats (everything is a Python number), sparsity, and any cost for the host or for launching a program.
- **Partial tiles cost a full tile.** A tile that sticks out of the matrix is padded with zeros and costs a whole transfer and a whole product, so the model charges padding waste (Chapter 41 shows what that does to small matrices).
- **The schedules are hand-written and not searched.** Only block shapes `1 × 1` to `4 × 8` and two buffer counts were tried; there is no claim that any is optimal, and the inter-block overlap is not optimized (each block's stores and the next block's loads do not overlap).
- **The analytic model is only checked against the simulator,** not against hardware.
- **Pure Python, small sizes.** The largest product is 128 × 128 × 128.

## Reproducing

```sh
cd docs/part40/code
./sweep_orders.py > sweep_orders_out.txt && ./timeline.py > timeline_out.txt && ./bandwidth_sweep.py > bandwidth_sweep_out.txt
./check_ga.py && ./sim_mutation.py > sim_mutation_out.txt
cd ../../part15/code && ./run_lit.sh          # 152 tests
```

## Chapter summary

- GA-1 is a small, readable **model** of a matrix accelerator: DMA, scratchpad, matrix unit, independent in-order queues, and a timing rule that enforces hazards. Every instruction computes real values and every run is checked against a plain triple loop.
- With ratios in which the matrix unit is much faster than the memory, the plain `i, j, k` order is **DMA-bound** (19% of peak); blocking cuts the tiles moved from 8,448 to 1,792, and a `4 × 8` block with double buffering reaches 88% (it becomes compute-bound); the `k`-outermost order is 10.4× slower than the best.
- Double buffering helps exactly when there is a compute phase to hide the loads behind; scratchpad capacity forces a choice between blocking and double buffering.
- In this model **per-transfer setup cost matters more than bandwidth**.
- A simple analytic model of a double-buffered step (the longer of loads and products) matches the simulator within 4% to 6% on the table; an independent replay of the instruction trace verifies the hazards; eleven broken simulators are caught.
- It is a model: its numbers describe GA-1, not any real chip.

## Self-check questions

Each answer is collapsed; try the question first.

1. Why is the plain `1 × 1` schedule so much worse than `4 × 4`, with the same arithmetic?

    ??? note "Answer"
        The arithmetic is identical (4,096 tile products) but `1 × 1` loads two tiles per product (8,448 tiles moved in all) while `4 × 4` loads eight tiles for sixteen products (2,304 moved). With the DMA at 20 cycles per tile, the plain schedule keeps the DMA busy for 98% of 173,056 cycles while the matrix unit idles at 19%; `4 × 4` reuses each loaded tile four times.

2. When does a blocked schedule stop being memory-bound on GA-1?

    ??? note "Answer"
        When a step's products take at least as long as its loads: `8 · bi · bj ≥ 20 · (bi + bj)`. That holds first at `4 × 8` among the shapes tried (256 against 240 cycles per step); at `4 × 4` it fails (128 against 160), which is why `4 × 4` is DMA-bound at exactly tiles × 20 cycles and `4 × 8` reaches 88% utilization. The thresholds follow from the invented parameters; other ratios would move them.

3. What does double buffering need, and what does it buy?

    ??? note "Answer"
        A second set of A and B slots (`bi + bj` more), so that the DMA can load step `k + 1` while the matrix unit works on step `k`. It buys overlap: 18% at `1 × 1`, 27% at `4 × 4`, 41% at `4 × 8`. It buys almost nothing when the DMA is already saturated by a single buffer, and it can make a schedule not fit: with 16 slots the best choice was `2 × 4` single buffered.

4. Why is the `k`-outermost order 10 times slower?

    ??? note "Answer"
        The accumulator does not stay on chip. For every `k` each tile of C is loaded from DRAM, updated by one product and stored again: 16,128 tiles moved against 1,792 for `4 × 8`, and the DMA queue, being in order, also stalls behind each store that waits for its product. It is the same lesson as Chapter 24's `ijk` against `ikj`, here with the accumulator in off-chip memory instead of a cache line.

5. The checker's hazard replay and the results check are separate. What does each catch that the other cannot?

    ??? note "Answer"
        Results are computed in program order, so they cannot reveal a timing hazard: a simulator that lets a load overwrite a slot too early still produces the right numbers. Only the replay of the recorded start and finish times (written independently of the timing rule) sees it. Conversely, the replay says nothing about whether a tile was padded or multiplied correctly; the results check does.

6. What does the chapter's bandwidth sweep say, and why must it be read with care?

    ??? note "Answer"
        That in GA-1 the fixed per-transfer setup (16 cycles) dominates a 64-word tile, so a faster bus changes little (the gap between plain and blocked stays about 4×) but a smaller setup helps a lot. It must be read with care because setup and bandwidth are invented numbers: it shows how to ask the question and what shape the answer takes, not what any real device does.

7. Name three things GA-1 does not model that would matter on a real accelerator.

    ??? note "Answer"
        Any of: a real memory hierarchy (banks, contention, row buffers, more than one DMA channel), instruction fetch and decode, energy and area, numerical formats such as 8-bit integers or 16-bit floats, sparsity, non-square or differently sized tiles, and launch overhead from a host. The chapter lists these as limits.
