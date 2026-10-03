# Appendix C. Introduction to LLVM IR and x86-64 Assembly

The last stage of every compiler in this book is **LLVM**: it takes the LLVM IR text that MLIR prints (Appendix B, Stage 4) and turns it into machine code. Chapter 37 reads that stage closely; this appendix is the short reading guide you would want before it. One small C function is followed through three forms (unoptimised IR, optimised IR, x86-64 assembly), and every instruction that appears is explained. Everything shown was produced by `clang-18` on the machine that built this book (x86-64 Linux).

!!! tip "Compile and run"
    ```sh
    cd docs/appendixC/code
    ./run_stages.sh                  # regenerates every file this appendix shows (about 2 seconds; needs clang-18)
    ```

## C.1 The function

```c
--8<-- "docs/appendixC/code/scale.c"
```

It multiplies each element of `x` by 2.0 and stores it in `y`. Mountain Goat's `x * 2` over a row of numbers lowers to exactly this kind of loop (Appendix B, Stage 2).

## C.2 LLVM IR, unoptimised

`clang-18 -S -emit-llvm -O0` (with `-Xclang -disable-O0-optnone`, which lets the later `opt` passes run on it) gives:

```text
--8<-- "docs/appendixC/code/5_O0_body.ll"
```

How to read it:

- **A function** is `define <return type> @name(<typed parameters>)`. `ptr` is a pointer (LLVM 18 has one pointer type, without a pointee type), `i64` a 64-bit integer, `double` a 64-bit float.
- **Values are SSA** (as in Appendix B): `%4`, `%5`, ... are defined once. Parameters are `%0`, `%1`, `%2` (unnamed values are numbered).
- **A basic block** is a straight-line run of instructions ending in a *terminator* (`br`, `ret`). A line like `8:` starts a block; `; preds = %21, %3` says which blocks can jump to it.
- **`alloca`** reserves a stack slot; `store` and `load` write and read memory. At `-O0` clang gives every local variable (here `y`, `x`, `n`, `i`) a stack slot and loads it each time it is used.
- **`getelementptr`** (GEP) computes an address: `getelementptr inbounds double, ptr %13, i64 %14` is `&x[i]`. It does not read memory.
- **`icmp slt`** compares signed integers (`i < n`); **`br i1 %c, label %a, label %b`** branches on the result; `br label %b` jumps unconditionally.
- **`fmul double`** multiplies; **`add nsw i64`** adds integers (`nsw`: "no signed wrap", a promise that lets LLVM reason about the loop counter).

## C.3 LLVM IR, optimised

The same function with `-O1` (vectorising and unrolling switched off, so the loop is still one element at a time):

```text
--8<-- "docs/appendixC/code/6_O1_body.ll"
```

The stack slots are gone: LLVM's `mem2reg` turned every `alloca` into an SSA value, and the loop counter is now a **`phi`**:

```text
  %7 = phi i64 [ %12, %6 ], [ 0, %3 ]
```

A `phi` is how SSA says "this value is 0 if we arrived from block `%3` (the entry), and `%12` (the incremented counter) if we arrived from block `%6` (the loop body itself)". It is the only instruction whose result depends on *which way control arrived*, and every loop counter in optimised IR is one. The entry now tests `n > 0` once (`icmp sgt ... br`) and the loop is a single block that tests `i + 1 == n` at its end, instead of testing before every iteration. The `!tbaa` and `!llvm.loop` marks are metadata that help later passes and can be ignored when reading.

## C.4 x86-64 assembly

`clang-18 -S -O1` turns that IR into machine instructions. In AT&T syntax (the default on Linux, source operand first):

```text
--8<-- "docs/appendixC/code/7_O1_att.s"
```

and the same instructions in Intel syntax (destination first, `-masm=intel`):

```text
--8<-- "docs/appendixC/code/8_O1_intel.s"
```

**Registers.** The System V AMD64 calling convention passes the first integer and pointer arguments in `rdi`, `rsi`, `rdx`, `rcx`, `r8`, `r9`, in that order: `y` is `rdi`, `x` is `rsi`, `n` is `rdx`. `rax` is a scratch register here, used as the loop counter `i`. `xmm0` is one of the 16 vector/floating-point registers; `movsd` and `addsd` use only the low 64 bits of it (one `double`).

| instruction (AT&T) | what it does |
|---|---|
| `testq %rdx, %rdx` / `jle .LBB0_3` | test `n` against itself; jump to the end if `n <= 0` |
| `xorl %eax, %eax` | set `rax` to 0 (xor with itself is the cheapest way to make zero) |
| `movsd (%rsi,%rax,8), %xmm0` | load the `double` at address `rsi + 8*rax`, i.e. `x[i]` |
| `addsd %xmm0, %xmm0` | `xmm0 = xmm0 + xmm0` |
| `movsd %xmm0, (%rdi,%rax,8)` | store it at `y[i]` |
| `incq %rax` | `i++` |
| `cmpq %rax, %rdx` / `jne .LBB0_2` | compare `i` with `n`; loop again if not equal |
| `retq` | return |

**One thing the compiler did that is worth noticing:** the source says `x[i] * 2.0` and the assembly says `addsd %xmm0, %xmm0`. Doubling a number by adding it to itself gives exactly the same result as multiplying by 2 in floating point, and an add is not slower than a multiply, so LLVM chose the add. No flag allowed that; it is an exact identity. (Contrast Chapter 44's flags, which allow transformations that are *not* exact.)

## C.5 The same stage, in this book's output

The LLVM IR that Appendix B's `tiny.mg` produces has the same ingredients, in a more verbose dress. Its first loop nest (`x * 2` into a fresh buffer: an outer loop over the one row and an inner loop over the three columns), from `4_scale_add.ll`:

```text
--8<-- "docs/appendixB/code/4_scale_add.ll:42:71"
```

`phi` for each counter, `icmp`/`br` for each loop test, `getelementptr`/`load`/`fmul`/`store` for the element. The index arithmetic (`mul`, `add`) comes from flattening `[row, column]` into one offset (`row * 3 + column`), because `memref` indexing has been lowered away, and the `extractvalue` reads the buffer pointer out of the five-field memref descriptor from Appendix B. At `-O0`, which is what `mgc` uses by default, none of this is cleaned up; Chapter 37 shows what LLVM does to it at higher levels.

## C.6 The tools

| command | does |
|---|---|
| `clang-18 -S -emit-llvm -O1 f.c` | C to LLVM IR text (`f.ll`) |
| `clang-18 -S -O1 f.c` (`-masm=intel`) | C to assembly (`f.s`) |
| `opt-18 -passes=... f.ll -S` | run LLVM optimisation passes on IR and print IR |
| `llc-18 f.ll` | LLVM IR to assembly |
| `llvm-mca-18` | estimate how fast an assembly loop runs on a given CPU (Chapter 37 uses it) |

To see what any option does, compile a ten-line function both ways and read the two outputs, as this appendix does.
