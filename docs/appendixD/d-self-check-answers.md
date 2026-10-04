# Appendix D. Self-Check Answers

![Mountain goats on the mountain in autumn](../assets/goats/appx-d.svg){ style="display:block;margin:0 auto;max-width:100%;height:auto;border-radius:6px" }

Every chapter ends with a short *Self-check questions* section. On the chapter pages the newer ones keep each answer collapsed so you can try the question first; this appendix opens every answer in one place, in chapter order, for review or for looking one up. It is generated from the chapter pages by `appendixD/make_appendix_d.py` and is therefore always the same text as the chapters (nothing here is separately written). Questions that refer to a listing, a table or an output refer to the one on the chapter page.

## Chapter 1

*(from [1. Why a Multi-Level IR at All](../part1/01-why-a-multi-level-ir-at-all.md))*

**1. Why does `--finalize-memref-to-llvm` turn one `memref<5xi32>` argument into five separate LLVM-level arguments, rather than one pointer?**

Worked answer: a real `memref` carries more information than a bare pointer -- not just where the data starts, but its own allocated-versus-aligned base address (these can differ in real, more general cases this chapter's own simple example doesn't exercise), and its own shape and stride in each dimension. LLVM IR has no type that bundles all of that together, so lowering to it has to make each real piece an explicit, separate value; `sum_llvm.mlir`'s own real output shows exactly that unpacking, five arguments where the source had one.

**2. The chapter claims `scf.for`'s own structure is "gone" after lowering. In what real, precise sense is that true, given that the lowered code still only sums five elements, correctly?**

Worked answer: the lowered code's own *behavior* is unchanged -- it still computes the same real sum, which the real captured program output confirms. What is gone is the explicit, nameable *fact* that this behavior came from a loop at all: `^bb1`/`^bb2`/`^bb3` with `llvm.br`/`llvm.cond_br` is a real, ordinary control-flow graph that could equally have come from a hand-written `goto` chain, a `while` loop, or several other real source constructs. A pass operating at this level has no direct way to ask "is this a loop," only "is this graph shape consistent with one" -- real, extra analysis `scf.for`'s own explicit representation never required.

**3. Why does this chapter cite `mlir/docs/Rationale/Rationale.md` read directly from a cloned `llvm/llvm-project` repository, rather than from `mlir.llvm.org`'s own rendered documentation site?**

Worked answer: `mlir.llvm.org` is unreachable from this book's own sandbox (confirmed directly, not assumed). The rendered website is itself generated from the exact same real Markdown files living in the `mlir/docs/` directory of the `llvm/llvm-project` repository -- cloning that repository and reading the file directly reaches the identical real, official text, from the actual primary source, rather than a secondary rendering of it; nothing about the citation's own strength is lost by reading the source file instead of its rendered form.

**4. Why does `harness.c`'s own `sum_array` declaration need to match the real lowered function's own five-argument shape exactly, rather than just declaring `int32_t sum_array(int32_t *arr, int len)` and hoping it links?**

Worked answer: once `sum.ll` is compiled, the real, binary calling convention is fixed by what `--finalize-memref-to-llvm` actually generated -- five real arguments in a specific real order (allocated pointer, aligned pointer, offset, size, stride) -- and the C compiler has no way to know this function started life as a one-argument MLIR function; it only sees the real LLVM IR signature `sum.ll` actually declares. A mismatched C declaration would either fail to link against the real symbol's own type, or -- worse, if argument counts and types happened to coincidentally fit into the same real registers -- silently read wrong values with no compiler error at all.

**5. The three real `arith`/`scf`/`memref` dialects used in `sum.mlir` are each separate, rather than one combined "basic operations" dialect. What real benefit does that separation buy, based on what this chapter actually demonstrated?**

Worked answer: separating dialects by concern is exactly what let this chapter's own four real lowering passes each do one focused, independently-understandable job: `--convert-scf-to-cf` only ever had to know about *control flow*, `--convert-arith-to-llvm` only ever had to know about *arithmetic*, and `--finalize-memref-to-llvm` only ever had to know about *memory layout* -- each pass genuinely ignorant of the other two dialects' own real concerns. Had `sum.mlir` instead used one combined dialect mixing loops, arithmetic, and memory access into single, do-everything operations, no such focused, single-purpose pass could exist at all; lowering would have to be one large, tangled transformation handling every concern at once.

---

## Chapter 2

*(from [2. A Minimal Dialect From Scratch: Mountain Goat's Own `mg` Dialect](../part2/02-a-minimal-dialect-from-scratch.md))*

**1. Why does `ConstantOp` use `DeclareOpInterfaceMethods<InferTypeOpInterface>` instead of just writing `type($result)` in its `assemblyFormat`, the way `AddOp` does?**

Worked answer: `ConstantOp`'s one operand is a `dense<...> : tensor<2x2xf64>` attribute, which already carries a full, real type as part of its own attribute syntax. Writing `type($result)` as well would ask the person reading or writing Mountain Goat IR to state that same tensor type a second time, with no way for the parser to catch it if the two ever disagreed. `AddOp` has no such attribute to read a type from -- both its operands are plain `Value`s, so without `InferTypeOpInterface`, its own result type genuinely cannot be reconstructed from anything else already in the text.

**2. `TransposeOp` declares `let hasVerifier = 1;` in `MgOps.td`. What, concretely, does `mlir-tblgen-18` generate in response to that one line, and what does this chapter's own code supply that ODS could not generate on its own?**

Worked answer: `mlir-tblgen-18` generates a real call to `TransposeOp::verify()` inside the operation's generated `verifyInvariantsImpl()`, but generates no body for `verify()` itself -- `hasVerifier = 1` is a real request for hand-written C++, not an instruction ODS can fulfill declaratively. This chapter's own `MgDialect.cpp` supplies that body: reading both tensor types' real ranks and shapes and confirming the result is the input reversed, a relationship about two different operands' shapes that ODS's own declarative constraint language has no way to express directly.

**3. This chapter showed `mg-opt` silently accepting `mg.add %0, %1 : tensor<2x2xf64>, tensor<3xf64> -> tensor<2x2xf64>` without error. Precisely why does the dialect, as built in this chapter, allow that, and what real, minimal change would close the gap?**

Worked answer: `AddOp`'s two operands are each independently constrained to `F64Tensor` (any rank, any shape, so long as the element type is `f64`), and nothing in `MgOps.td` relates the two operands' own shapes to each other or to the result's shape -- ODS enforces exactly the constraints it is told to enforce, no more. Closing the gap needs exactly the pattern `TransposeOp` already demonstrates: adding `let hasVerifier = 1;` to `AddOp` and writing a real `AddOp::verify()` that checks `getLhs().getType()`, `getRhs().getType()`, and `getResult().getType()` are all the same shape.

**4. Why does this chapter's own `CMakeLists.txt` need both `-DMLIR_DIR=` and `-DLLVM_DIR=` passed explicitly on the `cmake` command line, rather than CMake finding them on its own the way it finds, say, `ZLIB`?**

Worked answer: CMake's `find_package(... CONFIG)` mode searches a fixed, conventional set of installation prefixes (and `CMAKE_PREFIX_PATH`, when set) for a package's own `*Config.cmake` file. Ubuntu's `libmlir-18-dev`/`llvm-18-dev` packages genuinely install `MLIRConfig.cmake`/`LLVMConfig.cmake` at `/usr/lib/llvm-18/lib/cmake/{mlir,llvm}/` -- a real, valid location, but one versioned by LLVM major version specifically so that LLVM 17, 18, and 19 can coexist on one real system without colliding, and precisely because of that versioning, it is not a path CMake's own default search covers. Passing both variables explicitly is this chapter's own real, confirmed fix, not a guess.

**5. The chapter's opening Mountain Goat example uses `func.func`/`func.return` rather than a hypothetical `mg.func`/`mg.return`. What real design decision does that reflect, and what would be lost by instead reinventing function definition inside the `mg` dialect?**

Worked answer: MLIR's own built-in `func` dialect already provides a real, complete, well-tested representation of function definition, arguments, and return -- genuinely independent of anything tensor- or array-specific. Reinventing an `mg.func`/`mg.return` pair would duplicate that real functionality for no real gain, and would also mean every later real MLIR pass, tool, or interface that already understands `func.func` (inlining, symbol resolution, calling-convention lowering) would need Mountain Goat-specific support added before it could be reused. Keeping `mg`'s own dialect minimal -- covering only what `func` does not already cover -- is this chapter's own real, deliberate scope decision, not an oversight.

---

## Chapter 3

*(from [3. The Real Pass Infrastructure: Canonicalizing Mountain Goat](../part3/03-the-pass-infrastructure.md))*

**1. `ConstantOp::fold` and `AddOp::fold` are both real, legitimate uses of MLIR's folding hook, but they differ in an important way. What is it, and why does only one of them need to inspect its own operands' actual values?**

Worked answer: `ConstantOp::fold` always succeeds, unconditionally returning `getValueAttr()` -- a constant is already its own answer, nothing to inspect. `AddOp::fold` is conditional: it has to check, via `dyn_cast_if_present<DenseElementsAttr>`, whether its own two real operands are themselves constants before it can do anything; if either is some other, non-constant value (the general, common case), it genuinely returns `nullptr`, declining to fold rather than failing or guessing.

**2. The chapter states that leaving out `MgDialect::materializeConstant` caused `--canonicalize` to silently leave `mg.add` of two constants unfolded, with no error. Why no error specifically, rather than a crash or a compile failure?**

Worked answer: `AddOp::fold` itself ran successfully and genuinely computed the correct summed `DenseElementsAttr` -- the folding *logic* was never broken. What was missing was purely the real, separate step of turning that resulting attribute back into an operation the IR could actually hold; without `materializeConstant`, the canonicalizer's own driver has a valid folded attribute in hand but no real way to re-insert it, and its own documented behavior for that situation is to leave the original operation alone rather than crash -- "best-effort," exactly as `mlir/docs/Canonicalization.md` states directly.

**3. Why does `SimplifyRedundantTranspose` need the heavier `RewritePattern` framework, when `AddOp`'s constant folding only needed the lighter `fold()` hook?**

Worked answer: `AddOp::fold` only ever needs to look at its own two direct operands -- exactly what the `FoldAdaptor` it receives already hands it. `SimplifyRedundantTranspose` needs to look *past* its own one operand, at the operation that produced it (`op.getInput().getDefiningOp<TransposeOp>()`) -- a second, separate operation entirely, possibly with its own separate uses elsewhere in the IR that `rewriter.replaceOp` has to correctly redirect. `fold()`'s own narrower contract has no access to a `PatternRewriter` capable of safely making that kind of broader IR surgery; `RewritePattern` is the real framework built for exactly that larger class of rewrite.

**4. The real captured `--canonicalize` output collapses the chapter's own seven-operation example down to two in one single pass invocation, despite `SimplifyRedundantTranspose` and `AddOp`'s folder being two entirely independent, separately-written real rewrites. What makes that single-pass result genuinely correct rather than lucky?**

Worked answer: MLIR's own real canonicalizer is explicitly documented as a greedy, iterate-to-fixpoint driver -- it keeps re-applying every registered pattern and folder across the whole IR until no further change occurs (or an iteration limit is hit), not a single linear sweep that visits each operation exactly once. That is precisely why this chapter's own two independent rewrites, touching entirely different operations (`mg.add` versus `mg.transpose`), did not need to be manually sequenced or run as two separate passes -- the same one greedy loop kept applying both until nothing more could fire.

**5. Why does this chapter explicitly defer real dialect conversion (`ConversionTarget`, `TypeConverter`, `ConversionPattern`) to Part 3 instead of demonstrating it here, given `mlir/docs/DialectConversion.md` is already cited in this very chapter?**

Worked answer: both of this chapter's own real rewrites are deliberately same-dialect: `SimplifyRedundantTranspose` only ever deletes `mg.transpose` operations and redirects existing SSA values, and `AddOp`'s folder only ever replaces `mg.add`/`mg.constant` operations with another `mg.constant` -- no operation from any other dialect is ever introduced. Dialect conversion's own real machinery (a `ConversionTarget` declaring what is "illegal," a `TypeConverter` mapping types across dialects) exists specifically for the harder case this chapter never actually needed: turning an illegal operation in one dialect into a legal one in a genuinely different dialect, which is exactly Part 3's own real subject once Mountain Goat is lowered to `affine`.

---

## Chapter 4

*(from [4. Progressive Lowering: Mountain Goat to `affine`, Two Real Ways](../part4/04-progressive-lowering-to-affine.md))*

**1. Why did the chapter's own first version of `ConvertMgToAffinePass` fail with an `unrealized_conversion_cast` error on `add_tensors.mlir`, specifically, rather than on `mountain_goat.mlir`?**

Worked answer: `mountain_goat.mlir`'s own tensors all genuinely originate from `mg.constant`, an operation this chapter's own `ConstantOpLowering` pattern directly converts -- no block argument is ever involved. `add_tensors.mlir`'s own two tensors are real `func.func` arguments, whose type the conversion framework has no pattern to change unless `func.func` itself is addressed -- exposing the real gap (function signatures) that `mountain_goat.mlir`'s own all-internal structure happened not to exercise.

**2. The chapter's own `ConstantOpLowering` fully unrolls its stores rather than emitting a real `affine.for` loop, while `AddOpLowering` and `TransposeOpLowering` both use `buildAffineLoopNest`. What real, principled reason justifies that difference, rather than it being arbitrary?**

Worked answer: `ConstantOp`'s own real values come from a compile-time-known `DenseElementsAttr` -- there is no real per-iteration *computation*, only a fixed sequence of literal values to place into memory, genuinely indexable without a loop induction variable at all. `AddOp` and `TransposeOp` both perform a real, uniform operation (a load-load-add-store, or a load-store with swapped indices) that is identical at every index -- exactly the situation a real loop exists to express once instead of unrolling, which is what `buildAffineLoopNest` is for.

**3. Running `--convert-mg-to-affine` alone on `mountain_goat.mlir` produced no `arith.addf` at all, yet the real captured output is still correct. Why does calling this a bug in `ConvertMgToAffinePass` be the wrong conclusion?**

Worked answer: the real, correct sum (`[[6, 8], [10, 12]]`) genuinely appears in the output -- nothing about the program's own meaning changed, only *how* it was computed changed, from a real runtime `affine.for` loop to a real compile-time fold. This is the dialect-conversion driver's own documented behavior (trying an operation's own `fold()` hook before a `ConversionPattern`), not a defect in `AddOpLowering`'s own code, which is exactly why the chapter re-ran the same program with `--canonicalize` first: to make that same real folding happen visibly and deliberately, rather than as a side effect discovered only by reading the output closely.

**4. `mlir/docs/Bufferization.md` is cited in this chapter as stating `BufferizableOpInterface` requires implementing `bufferizesToMemoryRead`/`bufferizesToMemoryWrite`. Why does the chapter claim this is genuinely *more* work than `ConvertMgToAffinePass` needed, rather than a shortcut this chapter avoided for no real reason?**

Worked answer: `ConvertMgToAffinePass`'s own patterns only ever have to reason about one operation at a time, locally -- "allocate a buffer for my own result, compute into it." `BufferizableOpInterface`, by the documentation's own real description, supports a genuine whole-function analysis that decides whether a tensor value can be bufferized *in place* (reusing an existing buffer) or needs a fresh allocation, which requires each op to correctly answer real questions about whether it reads or writes through each operand *in the context of the rest of the function*, not in isolation -- a real, harder problem this chapter's own narrower, always-allocate-fresh patterns never had to solve.

**5. The chapter erases `mg.print` rather than lowering it to anything. What real, concrete problem would lowering it to an actual print call have to solve that this chapter's own other three patterns do not?**

Worked answer: `ConstantOpLowering`, `AddOpLowering`, and `TransposeOpLowering` all stay entirely within MLIR's own IR -- every operation they emit (`memref.alloc`, `affine.for`, `arith.addf`) is itself genuinely runnable by the same JIT/native-compilation pipeline Chapter 1 already proved works. A real print call needs to reach outside that pipeline entirely, into an actual C runtime function (something like a real `printf`-based helper) that has to be linked in or declared as an external symbol -- real native-execution machinery (`mlir-cpu-runner-18`/`ExecutionEngine`, or a real compiled host harness) this book has not yet built, which is exactly why the chapter defers it to Part 5 rather than inventing a placeholder call to nothing.

---

## Chapter 5

*(from [5. Finishing Progressive Lowering: `affine` to `scf` to `llvm`, and Mountain Goat Finally Runs](../part5/05-affine-to-scf-to-llvm.md))*

**1. `--lower-affine` needed no hand-written pattern at all, unlike every one of Chapter 4's own `mg`-to-`affine` patterns. What real, structural difference between `mg` and `affine` explains that?**

Worked answer: `affine` is itself one of MLIR's own real, built-in dialects -- MLIR ships `--lower-affine` as a generic pass precisely because every `affine.for`/`affine.load`/`affine.store` operation, in any dialect's own IR, has the same real, fixed structure the pass already knows how to interpret. `mg.add`/`mg.transpose` are this book's own invented operations; nothing in MLIR could possibly ship a pre-built lowering for them, which is exactly why Chapter 4 had to write `AddOpLowering`/`TransposeOpLowering` by hand -- the real, general principle being that a dialect conversion needs hand-written patterns precisely for the parts of the IR that are not already standard.

**2. The chapter needed to declare `@printMemrefF64` with `llvm.emit_c_interface` rather than just calling it as an ordinary function. What real, concrete problem would omitting that attribute have caused?**

Worked answer: `printMemrefF64`'s own real, C++-level signature (from `RunnerUtils.h`) is `void printMemrefF64(int64_t rank, void *ptr)` -- two plain scalar arguments. The function MLIR's own lowering actually needs to call, `_mlir_ciface_printMemrefF64`, takes a single pointer to an `UnrankedMemRefType<double>` descriptor struct instead -- a real, different, C-interface-specific ABI. Without `llvm.emit_c_interface`, `--convert-func-to-llvm` would emit a direct call matching the first, plain signature, which does not match what `_mlir_ciface_printMemrefF64` (the symbol actually present in `libmlir_runner_utils.so`) expects -- a genuine link or runtime-crash risk, not merely a cosmetic one.

**3. Why did this chapter's own worked example need a *separate* `@add_tensors` function, called from `@main`, rather than just building the two tensors and adding them directly inside `@main`?**

Worked answer: Chapter 4's own real, honest discovery was that `AddOp::fold` fires automatically during dialect conversion's own legalization, *whenever* both of `mg.add`'s own operands are defined, within the same function, by `mg.constant`. Passing the two tensors across a real function boundary (`func.call`) is what breaks that chain: inside `@add_tensors`, `%a`/`%b` are genuine block arguments, with no real defining operation at all for the folder to inspect -- guaranteeing the real `affine.for`/`scf.for` loop genuinely survives all the way to execution, rather than silently folding away before this chapter's own pipeline had anything to run.

**4. The real captured LLVM-dialect output shows `@add_tensors` taking fourteen separate arguments for what were originally two `memref<2x2xf64>` parameters. Is this the same real phenomenon Chapter 1 first identified, or something new?**

Worked answer: the same real phenomenon, just doubled: Chapter 1 established that `--finalize-memref-to-llvm` unpacks one `memref` into five separate LLVM-level arguments (allocated pointer, aligned pointer, offset, size, stride per dimension) because LLVM IR has no single type that bundles all of that together. `@add_tensors` takes two real `memref<2x2xf64>` arguments, each independently unpacked the same real way -- five arguments each, for ten total, plus `printMemrefF64`'s own two-argument C-interface call elsewhere in the module accounting for the rest of what the excerpt shows; no new mechanism, the same real one applied twice.

**5. Why does the chapter call running this program through `mlir-cpu-runner-18` genuinely different from, and not a replacement for, the real native-executable approach Chapter 1 used (`mlir-translate-18` + `clang-18` + a C harness)?**

Worked answer: `mlir-cpu-runner-18` is itself a real, genuine JIT -- it compiles and runs the given LLVM-dialect IR in-process, through MLIR's own `ExecutionEngine`, without ever producing a standalone, independently distributable binary. Chapter 1's own approach (`mlir-translate-18` to real LLVM IR text, then `clang-18` compiling that text, linked against a real hand-written C harness) produces a genuine, ordinary native executable that could be copied to another machine and run without MLIR present at all. Both are real and both genuinely execute the same real logic, but they are not the same real thing, which is exactly why this chapter states plainly that the native-executable path, for a Mountain Goat program specifically, remains Part 5's own subject rather than claiming this chapter's own JIT run already covers it.

---

## Chapter 6

*(from [6. Real Bufferization: Closing Chapter 4's Own Honest Gap](../part6/06-real-bufferization.md))*

**1. `mg.add`'s own `getAliasingValues` returns an empty `AliasingValueList`, yet `bufferizesToAllocation` returns `true` for its result. Why are both of these the correct, specific answers, rather than one implying the other?**

Worked answer: `getAliasingValues` answers "does this result alias one of my own *operands*' buffers" -- for `mg.add`, genuinely no, since a fresh buffer is always allocated for the sum. `bufferizesToAllocation` answers a different real question entirely: "may this value bufferize to a new allocation at all," independent of what it does or doesn't alias. Both being set the way this chapter set them is exactly what tells One-Shot Bufferize's own analysis that `mg.add`'s result is a genuinely new, non-aliasing buffer -- getting either one wrong independently would misinform a different part of the same real analysis.

**2. The chapter needed `getBuffer(rewriter, addOp.getLhs(), options)` inside `AddOpInterface::bufferize`, while Chapter 4's own `AddOpLowering::matchAndRewrite` just used `adaptor.getLhs()` directly. Why the difference?**

Worked answer: Chapter 4's own pattern ran inside MLIR's dialect-conversion framework, where `OpAdaptor` is built specifically to hand back each operand already in its *converted* (memref) form -- the framework had already done that substitution before the pattern's own body ever ran. One-Shot Bufferize's own `bufferize()` hook receives the *original* operation, still referring to its own original tensor-typed operands; `getBuffer` is the real, explicit call needed to ask, "what buffer does this specific tensor value's own bufferization produce" -- a real difference in how the two frameworks hand operands to a pattern, not an arbitrary API inconsistency.

**3. Running `--one-shot-bufferize` alone (no `--canonicalize` first) on a program adding two `mg.constant`s produced a genuine `affine.for` loop, while Chapter 4's own `--convert-mg-to-affine` alone folded the same real operation away. What, precisely, differs between the two drivers that explains this?**

Worked answer: dialect conversion's own `applyPartialConversion` driver is built to *legalize* operations, and trying a cheaper, already-registered `fold()` hook before reaching for a full `ConversionPattern` is a natural, real optimization within that specific job. One-Shot Bufferize's own driver exists to answer a different real question (how should each tensor value be bufferized), and has no comparable reason to also run unrelated constant-folding logic along the way -- the two frameworks' own real responsibilities simply do not overlap in that specific way, even though both, in this book's own experience, end up processing the exact same operations.

**4. Why did `mlir::bufferization::func_ext::registerBufferizableOpInterfaceExternalModels(registry)` need to be called explicitly, rather than being automatically included whenever `mg`'s own four external models are registered?**

Worked answer: `mg`'s own `registerBufferizableOpInterfaceExternalModels` only ever attaches interfaces to `mg`'s own four operations (`ConstantOp`, `AddOp`, `TransposeOp`, `PrintOp`) -- it has no reason to know or care about `func.func`, an operation from an entirely separate, built-in dialect. MLIR ships a real, separate external model specifically for `func.func`'s own bufferization behavior precisely because dialects are meant to be independently extensible; registering `mg`'s own models was never going to implicitly pull in `func`'s own, any more than linking `MgDialect` implicitly linked `MLIRFuncDialect`'s own unrelated features.

**5. The chapter's own real captured output shows `func.func @add_tensors` taking `memref<2x2xf64, strided<[?, ?], offset: ?>>` arguments under One-Shot Bufferize, versus plain `memref<2x2xf64>` under Chapter 4's own hand-written pass. Does this real difference mean one of the two approaches is wrong?**

Worked answer: no -- both are genuinely correct for what each approach actually knows. Chapter 4's own `MgToAffineTypeConverter` was written assuming every real argument this book's own examples pass is a plain, contiguous buffer, which happens to be true for every example in this book. One-Shot Bufferize's own function-boundary conversion is real, general-purpose infrastructure that cannot make that same real assumption about every possible real caller of a public function, so it conservatively produces a strided, dynamic-offset memref type instead -- a real, more general answer to a real, more general problem than this book's own narrow `TypeConverter` ever had to solve.

---

## Chapter 7

*(from [7. Real Loop Transforms: Fusion, Tiling, and Unrolling at the `affine` Level](../part7/07-real-loop-transforms.md))*

**1. The real fused loop nest's own intermediate buffer shrank from `memref<2x2xf64>` to `memref<1x1xf64>`. What real, specific property of the fused loop did `--affine-loop-fusion` have to confirm before it could safely make that change?**

Worked answer: the real pass had to confirm that, once the add and transpose loop bodies share one real iteration space, each individual element the add computes is consumed (read by the transpose's own load) in the very same iteration it is produced, and never needed again afterward. If any later iteration needed an *earlier* iteration's own intermediate value, shrinking the buffer to a single element would silently overwrite data still required -- a real correctness bug the pass's own real dependence analysis exists specifically to rule out before making this optimization.

**2. Why did `--affine-loop-fusion` swap the add's own loop induction variables (from `[%arg2, %arg3]` to `[%arg3, %arg2]`) rather than leaving the add's own iteration order untouched and only merging the loop bodies?**

Worked answer: the transpose's own real access pattern reads `input[j, i]` to produce `output[i, j]` -- a real, fixed relationship between the two loops' own index variables. For one shared loop nest to drive both the add's own writes and the transpose's own reads correctly, the add's own iteration order had to be adjusted to match the order the fused loop nest actually walks the buffer in, which is dictated by the transpose's own real index relationship, not the add's own original, arbitrary order.

**3. The chapter needed to invoke `--affine-loop-unroll="unroll-full"` twice to fully unroll both loop levels, rather than once. What does that real, observed behavior reveal about the pass's own real, default scope?**

Worked answer: the real pass's own documented default behavior targets *innermost* loops specifically, not every loop in a nest indiscriminately. After the first invocation unrolled the original inner loop away, the loop that used to be the *outer* loop became the new innermost loop (since nothing was nested inside it anymore) -- genuinely requiring a second, separate invocation to reach it, rather than the pass recursing through every nesting level in one real pass.

**4. Why does the chapter call it a real, structural mistake to treat `--affine-loop-fusion`, `--affine-loop-tile`, and `--affine-loop-unroll` as if any one of them were also responsible for cleaning up the redundant arithmetic the others introduce?**

Worked answer: each real pass has one real, specific job -- fusion merges loop nests, tiling restructures iteration order, unrolling replicates loop bodies -- and MLIR's own real design, visible directly in this chapter's own captured output, is that none of them also runs a general cleanup sweep over the arithmetic its own transform happens to leave behind (the `affine.apply` calls unrolling introduced, for instance). Expecting one of them to clean up after itself would mean duplicating canonicalization's own real, general-purpose logic inside every single transform pass, for no real benefit over simply running canonicalization again afterward, as this chapter actually did.

**5. The final real worked example chains `--affine-loop-fusion`, tiling, unrolling, canonicalization, and then Chapter 5's own unmodified `affine`-to-`llvm` pipeline, and it genuinely still produces the correct answer. What real property of all the passes involved does that successful final run actually confirm?**

Worked answer: it confirms that every one of these real, independently-developed MLIR passes -- fusion, tiling, unrolling, canonicalization, and the five-pass `affine`-to-`llvm` lowering pipeline, developed across entirely separate chapters of this book and, in MLIR's own real codebase, by entirely separate engineering efforts -- preserves the real, observable *meaning* of the program even while aggressively restructuring its own real IR. A transform pipeline this deep producing a wrong answer would have been a real, visible failure at the very last step; genuinely getting `[[6, 10], [8, 12]]` is real, direct evidence that semantics survived every real rewrite along the way, not merely that each pass ran without crashing.

---

## Chapter 8

*(from [8. A Standalone Native Executable: Mountain Goat Without MLIR At Runtime](../part8/08-a-standalone-native-executable.md))*

**1. Chapter 1's own `harness.c` declared five separate `int32_t`/pointer parameters for one memref *argument*. This chapter's own harness instead declares one C `struct` for a memref *result*. Why does an argument and a result need different real C-side shapes for what is, in both cases, "a memref descriptor"?**

Worked answer: LLVM IR's own calling convention allows a function to take any number of separate scalar parameters, which is exactly how `--finalize-memref-to-llvm` unpacks a memref argument -- five separate values, passed the ordinary way. A function's own *return value*, by contrast, is a single value in LLVM IR's own real model; there is no mechanism for "returning five separate things." Packing the same five real fields into one struct, returned by value, is the only real way to get all five fields back out of a single return -- which is exactly why the C side needs a matching `struct` for a result, but plain separate parameters for an argument.

**2. Why did this chapter need no new code at all in `ConvertMgToAffinePass` (Chapter 4's own pass) to support a function that returns a tensor, when earlier gaps (function signatures, `func.call`) each needed real, new conversion-pattern work?**

Worked answer: `mg.add`'s own lowering pattern already produces a real `memref` value as its result, regardless of what the surrounding function does with it afterward -- whether that value is consumed by `mg.print`, passed to another function, or returned directly was never something `AddOpLowering` itself needed to know or care about. The real, already-registered `func.func`/`func.return` signature-conversion machinery (from Chapter 4's own `populateFunctionOpInterfaceTypeConversionPattern` and the dynamically-legal `func::ReturnOp` check) already covers a function returning a converted type, since a return value is conceptually no different, to that real machinery, from a return type needing conversion as part of the function's own signature.

**3. The chapter confirms the resulting binary is standalone by running `ldd` and finding only `libc`. Why would that same real check, run against one of Chapter 5's own `mlir-cpu-runner-18` invocations, not make sense as a comparison?**

Worked answer: `mlir-cpu-runner-18` is not itself a program this book compiled from Mountain Goat source -- it is a real, pre-built MLIR tool that reads LLVM-dialect IR as its own input at runtime and JIT-compiles it in-process. Running `ldd` on `mlir-cpu-runner-18` would show its own real, fixed set of MLIR/LLVM library dependencies, true regardless of which Mountain Goat program it happens to be given -- it says nothing about whether *that particular program* depends on MLIR, since the program itself was never turned into an independent binary at all; it only ever exists as IR text handed to the JIT.

**4. Why does this chapter's own harness compute `result.aligned[i * result.strides[0] + j * result.strides[1]]` rather than something simpler, like `result.aligned[i][j]` or `result.aligned[i * 2 + j]`?**

Worked answer: `result.aligned[i][j]` is not real, valid C for a flat `double *` -- `aligned` is a pointer to the buffer's own first element, not a pointer to an array of rows. `result.aligned[i * 2 + j]` would happen to produce the correct real answer for this one `2x2` example, but only by coincidence: it hard-codes the real stride (`2`) as a literal, rather than reading the real stride this specific memref descriptor actually reports. The general formula the harness actually uses is the real, same one every genuine memref consumer (including `affine.load` itself) relies on -- multiply each index by its own dimension's real stride and sum -- correct for any real shape, not just this chapter's own `2x2` example.

**5. This chapter's own real program never calls `mg.print`, unlike every previous chapter's own worked example. What real, concrete problem would calling `mg.print` here have reintroduced, that returning the tensor directly avoided?**

Worked answer: Chapter 5's own real `mg.print` lowering calls `printMemrefF64`, declared with `llvm.emit_c_interface` so `--convert-func-to-llvm` routes the call through `_mlir_ciface_printMemrefF64` -- a real, specific symbol that only exists inside `libmlir_runner_utils.so`. Linking a standalone binary against that call would have reintroduced exactly the real MLIR-runtime dependency this chapter's own `ldd` check was built to rule out; returning the tensor directly, and reading it with plain, dependency-free C instead, is what let this chapter's own binary end up depending on nothing but `libc`.

---

## Chapter 9

*(from [9. MLIR's Own Real C++ `ExecutionEngine` API, Called In-Process](../part9/09-the-execution-engine-api.md))*

**1. The chapter's own first, working test (`scale`, a plain `f64` argument and result) needed none of the three real fixes this chapter ultimately found. What real, specific property of a plain scalar type explains why?**

Worked answer: `_mlir_ciface_scale`'s own real parameter and return types are both plain `f64` -- not pointers to anything. `Argument<T>::pack`'s own real default (`args.push_back(&val)`) already produces exactly what a plain scalar ciface parameter needs: a pointer *to* the value. The real complication this chapter's own later fixes address only arises when the ciface parameter or return type is *itself* already a pointer (as every memref descriptor's own real ciface representation is) -- a case the scalar example never exercises at all.

**2. Why did the chapter's own second real fix (wrapping the result in an extra pointer, `StridedMemRefType<double,1> *resultPtr = &result;`) have to come before the *third* fix (reordering `result()` to be first), rather than either one alone being sufficient for `add_tensors`?**

Worked answer: these two real fixes address two genuinely separate real problems. The indirection fix (fix 2) addresses *what value* each packed argument slot must actually hold -- a pointer-to-pointer for a struct-typed result, confirmed in isolation on `make_ones` (no arguments at all, so argument *order* was never in question there). The ordering fix (fix 3) addresses *which position in the call* that correctly-built value has to occupy, a question that genuinely could not arise until a real test combined a struct result with real arguments, which `make_ones`'s own isolated test never did. Both real, independent facts had to be true simultaneously for `add_tensors` to work; fixing only one left the other real bug fully intact.

**3. The chapter states the third real fix was found because `add_tensors` "produced silently wrong output -- no crash." Why is a silent wrong answer a more concerning kind of real bug than the earlier crashes, from a debugging-discipline standpoint?**

Worked answer: a real crash is self-announcing -- `gdb`'s own backtrace pointed directly at the faulting instruction and the garbage register values, making the first two real bugs comparatively fast to diagnose. A silently wrong answer produces no error at all; the program runs to completion and prints a plausible-looking (if incorrect) result. Catching it at all depended entirely on this book's own stated discipline of comparing every real captured output against the independently-known correct answer (`[[6, 8], [10, 12]]`, confirmed in Chapters 5, 6, and 8 through three unrelated execution paths) rather than trusting that "it ran without crashing" means "it ran correctly."

**4. Why does the chapter claim `mlir::ExecutionEngine` is "genuinely embedded" in a way Chapter 8's own standalone executable is not, given both ultimately run the exact same real computation on the exact same real hardware?**

Worked answer: Chapter 8's own executable has its one specific function's own native machine code fixed permanently at the moment `clang-18` links it -- running it again, or on another machine, executes that exact same pre-compiled code, with no opportunity for the program itself to decide, while running, to compile some *different* MLIR module it has not seen before. This chapter's own host program, by contrast, parses and JIT-compiles whatever module its one command-line argument names, *while it is already running* -- the real, defining property of genuine embedding: the decision of what to compile is made at the embedding application's own runtime, not fixed in advance at the embedding application's own build time.

**5. This chapter's own host program calls both `mlir::registerLLVMDialectTranslation` and `mlir::registerBuiltinDialectTranslation` before parsing its input module. What real, concrete failure did omitting the second of these two calls produce, and why specifically that error?**

Worked answer: omitting `registerBuiltinDialectTranslation` produced a real, genuine failure directly from `mlir::ExecutionEngine::create` itself: `"cannot be converted to LLVM IR: missing LLVMTranslationDialectInterface registration for dialect for op: builtin.module"`. Every real MLIR module, including one already fully lowered to the `llvm` dialect, is still wrapped in a real `builtin.module` operation at its own top level -- and translating that wrapper to real LLVM IR needs its own real, separate translation interface registered, exactly as the `llvm` dialect's own operations (`llvm.func`, `llvm.call`, and so on) needed `registerLLVMDialectTranslation` registered for them specifically.

---

## Chapter 10

*(from [10. GPU Lowering: Mountain Goat to the `gpu` Dialect, NVVM, and Real PTX](../part10/10-gpu-lowering-to-ptx.md))*

**1. The MLIR kernel declares 23 parameters and the CUDA kernel 3, yet both do the same two loads, one add and one store. Where do the 20 extra parameters come from?**

Worked answer: a `memref<2x2xf64>` does not cross a call boundary as a pointer. By Chapter 1's descriptor rule it becomes seven scalars: an allocated pointer, an aligned pointer, an offset, two sizes and two strides. The kernel takes three memrefs, so 3 x 7 = 21, plus two `index` arguments (the loop's step and lower bound), for 23. The CUDA kernel takes three raw pointers and writes the loop bounds and row stride into its source (`row * 2 + col`), so it has nothing else to pass.

**2. Of the 23 declared parameters, the PTX body loads only five. Which five, and why those?**

Worked answer: `param_0` and `param_1` (the loop step and lower bound, used in `block * step + lb`), and `param_3`, `param_10`, `param_17`, the *aligned pointer* slot, the second field, of each of the three descriptor groups (fields 2 to 8, 9 to 15 and 16 to 22 after the two index arguments). Sizes, strides and offsets are never read, because the shape is static and baked into the index arithmetic (`shl 1` for the row stride, `shl 3` for eight bytes per element). The backend deleted every unused read without being asked.

**3. `--convert-affine-for-to-gpu` failed twice. How did the two failures differ, and what did the working route do differently?**

Worked answer: the first failure was a scheduling error: the pass operates on a `func.func`, not on a `builtin.module`, so it must be nested in the pass pipeline. Nested, it produced `affine.load` operations indexed by GPU block and thread ids, which are not valid affine dimensions or symbols, so the result failed verification. The working route went through parallelism instead: `affine-parallelize` proved the loops independent, `lower-affine` turned them into `scf.parallel`, and the GPU mapping passes built the launch, with the kernel body using plain `memref.load`/`memref.store`. The chapter did not establish *why* the first route fails beyond that observation, and says so.

**4. Why does this chapter have no equivalent of the `[[6, 8], [10, 12]]` check that Chapters 5 through 9 ended with, and why is that its most important caveat?**

Worked answer: that check ran a program and compared its output with the independently known answer. Here nothing could be run: there is no GPU, no CUDA driver and no `ptxas`. The chapter therefore establishes only that real MLIR and real LLVM accept every stage and emit the PTX shown, which is a statement about the compiler, not about the kernel's correctness. Reading the PTX, the load, add and store look right, but reading is not executing, and the book's own discipline is that a plausible-looking result is not evidence.

**5. Switching `index-bitwidth` from 64 to 32 changed the instruction count from 25 to 22. What changed in the PTX, and what did not?**

Worked answer: the index arithmetic became 32-bit (`mad.lo.s32`, `shl.b32`, `add.s32` in place of `mul.lo.s64`, `add.s64`, `shl.b64`), and the two index parameters are now declared `.u32`. What did not change is the parameter count (still 23, because that comes from the memref descriptor ABI, not from the index width) and the memory traffic (still two loads and one store). Chapter 12 later showed that a different option, `kernel-bare-ptr-calling-convention`, is what changes the count.

---

## Chapter 11

*(from [11. The GPU Host Side: Device Memory, Real Runtime Calls, and a Stub "Device"](../part11/11-the-gpu-host-side.md))*

**1. `gpu-to-llvm` ran without error on the original host function and left `gpu.alloc` and `gpu.memcpy` in place. What fixed it, and why was the failure silent?**

Worked answer: `gpu-async-region` fixed it, by rewriting the ops into their async form with `!gpu.async.token`s. The failure was silent because the lowering patterns only match async operations and a pattern that does not match simply leaves the op alone; the first visible error came later, when a conversion pass hit an `unrealized_conversion_cast` it could not legalize. The evidence in this chapter is the before/after listing: nine `gpu.alloc`/`gpu.memcpy`/`gpu.dealloc` ops survive without the pass and none with it. Chapter 12 later read the pattern's source and found the explicit "Can convert only async version" test.

**2. The final `mgpuLaunchKernel` call ends in `i64 23`. What is that number, and what are the arguments before it?**

Worked answer: it is the number of kernel parameters, 23, the same expanded count as the kernel's own signature (2 index arguments plus 3 memrefs of seven scalars each). The arguments in order are the kernel function handle; the grid x, y, z (2, 1, 1); the block x, y, z (2, 1, 1); the shared-memory size (0); the stream; a pointer to an array of 23 pointers, one per kernel parameter; and a null `extra`. The grid and block match Chapter 10's kernel exactly.

**3. Where is `gpu.launch_func` actually turned into runtime calls in this toolchain, and how did the chapter find out?**

Worked answer: at LLVM IR translation time, in `mlir-translate-18`, not in `gpu-to-llvm`. The evidence is a before/after observation: after the packaged pipeline, the MLIR still contains a `gpu.launch_func` (now with a stream operand and the 23 expanded operands) and no launch runtime call, while the translated `host.ll` contains `mgpuModuleLoadJIT`, `mgpuLaunchKernel` and `mgpuModuleUnload`. The chapter reached this from the outputs, not from documentation.

**4. What does linking against the stub runtime establish, and what does it leave open?**

Worked answer: it establishes that the host glue is right: three device allocations of 32 bytes, two copies in, a launch with grid `(2,1,1)` and block `(2,1,1)`, the parameter array packed in the layout the stub reads, one copy out, and the memref descriptor returned correctly through Chapter 8's calling convention. It leaves open everything about the PTX: the stub's kernel is hand-written C mirroring the PTX's five loaded parameters and arithmetic, so a defect in the PTX, or a difference between how a real driver packs the parameter array and how the stub reads it, would be invisible.

**5. Why was the negative control worth running, and what exactly did it show?**

Worked answer: a check that cannot fail proves nothing. The same program was rebuilt with the stub's one arithmetic line removed. It printed zeros (the contents of a fresh `malloc`, which happened to be zero and are not guaranteed to be), not `6 8 / 10 12`. So the correct answer in the real run does depend on the launch being packed and executed correctly, rather than being produced by some other path.

---

## Chapter 12

*(from [12. Reading MLIR's Own Production Pipelines: What This Book's Compiler Is Missing](../part12/12-reading-the-production-pipelines.md))*

**1. Why does the real packaged pipeline run `gpu-to-llvm` before `gpu-module-to-binary`, and what happens in this toolchain if the order is reversed?**

Worked answer: `gpu-module-to-binary` replaces each `gpu.module` with a `gpu.binary`, and the launch lowering looks the kernel module up with a lookup typed to `gpu::GPUModuleOp`. After the replacement that lookup returns null; the `assert` guarding it is compiled out of a release build, and the next line calls `getTargetsAttr()` on the null result. The observed symptom is a segmentation fault whose top frame is exactly `GPUModuleOp::getTargetsAttr()`. Running `gpu-to-llvm` first, as the real pipeline does, avoids it.

**2. Which option reduces the kernel from 23 parameters to 5, and what does it cost?**

Worked answer: `kernel-bare-ptr-calling-convention=1` on the packaged pipeline, which passes each memref as one raw pointer instead of the seven-scalar descriptor. The five parameters are the loop step, the lower bound and three pointers. It costs the size and stride information, so it only works because every shape in the book is static (the option's help text says all memrefs must have static shape on the host side). The PTX instruction count did not change, since the backend had already deleted the unused descriptor reads: the ABI cost 18 parameters and zero instructions.

**3. The GPU pipeline's own header comment calls it a pass "for testing". Why does that wording limit what this chapter can claim?**

Worked answer: it says the file is MLIR's reference pipeline for testing the lowering to NVVM, not a production compiler's pipeline. The chapter can therefore say how this book's pass order compares to MLIR's own reference order, but not what any production compiler ships. Compilers built on MLIR outside the `llvm-project` repository were not read, and the chapter makes no claim about them.

**4. The chapter says the book "never used" `expand-strided-metadata`, `cse` and several other passes. How was that established, and why does the method matter?**

Worked answer: `checks.sh` counts, for each pass name, how many files in the whole book (Chapters 1 through 11, pages and code directories) mention it; the recorded result is zero for every one. The method matters because "never used" is a claim about 11 chapters of material, which is easy to assert from memory and wrong; counting turns it into an observation anyone can rerun, and the same script printed the type and shape evidence used for the gap list.

**5. Chapter 12 wrote that dynamic-shape support was "unknown, not no". Why that phrasing, and what did Chapter 13 find?**

Worked answer: at the time, every `.mlir` file in the book used static shapes (the check found no `?` dimension in any of them), so there was no evidence either way, and "no" would have been an unsupported claim. Chapter 13 tested it and found the answer was no in three ways (a verifier that wrongly rejected compatible shapes, and both lowerings failing on a dynamic `memref.alloc`), then fixed them and found two further bugs while doing so.

---

## Chapter 13

*(from [13. Dynamic Shapes: Closing Chapter 12's Biggest Unknown](../part13/13-dynamic-shapes.md))*

**1. Why can the lowering not simply use `tensorType.getShape()[0]` as a loop bound when the dimension is `?`?**

Worked answer: for a dynamic dimension `getShape()` returns MLIR's sentinel for "dynamic", `-1`, not a size, so the number would become a bogus loop bound. A dynamic extent has to be read at runtime, with a `memref.dim` operation on the buffer, and passed to the loop and to `memref.alloc` as an operand. The unmodified compiler never got as far as running such a loop: the verifier on `memref.alloc` rejected an allocation of a `memref<?x?xf64>` with no size operands.

**2. `tensor<?x2xf64>` plus `tensor<3x2xf64>` was rejected by the original verifier. Why is rejecting it wrong, and what rule replaced it?**

Worked answer: the `?` may be 3 at runtime, so the two shapes can agree, and a compile-time error would reject a valid program. The original check compared shapes with `!=`, which treats `?` and `3` as different. `compatibleDim(a, b)` now accepts two extents if they are equal or if either is dynamic; the verifier applies it to every dimension of both operands and the result.

**3. The canonicalizer bug did not appear when the program was run on the unmodified compiler. Why not, and how was it reproduced?**

Worked answer: on the unmodified build the mixed-type transpose program was rejected earlier, by the old verifier (`?` against `2` counted as unequal), so the canonicalizer never saw it. The bug only appears once the verifier has been relaxed but the pattern has not been guarded, a state reproduced exactly by the build with the relaxed verifiers and the exact-type guard removed, which printed that the function returns `tensor<?x2xf64>` but is declared to return `tensor<?x?xf64>`.

**4. What does the column-major strided-view test show about the two lowering paths?**

Worked answer: the bufferization path's function arguments are strided memref types (`strided<[?, ?], offset: ?>`), so it honors a caller's strides, and it produced the correct transpose of the logical matrix `[[1,3,5],[2,4,6]]`. The hand-written path's arguments are plain row-major memrefs, so passing different strides would violate its type's contract; the test is not run against it and the chapter says that is not a defect of that path. The finding is a capability difference that static 2x2 examples could not show.

**5. Why did the mismatched-size call (2x3 plus 1x2) return numbers instead of failing?**

Worked answer: the loop bounds come from the first operand and nothing compares the operands' runtime sizes, so the loads from the second operand run off the end of its two-element buffer and read whatever memory is there. The first two sums are right because those elements exist in both; the rest are meaningless and not guaranteed to be reproducible. That silent out-of-bounds read is what Chapter 14 closes with a runtime check.

---

## Chapter 14

*(from [14. A Runtime Shape Check: Closing Chapter 13's Memory-Safety Hole](../part14/14-runtime-shape-checks.md))*

**1. Why can no compile-time check catch the 2x3-plus-1x2 call?**

Worked answer: the verifier only sees types, and `tensor<?x?xf64>` plus `tensor<?x?xf64>` is compatible as types. Whether the two sizes agree is a property of the values that arrive at runtime, so the only place left to enforce it is the compiled code, which is why the lowering emits a comparison and an assertion.

**2. Why does the helper skip a dimension that is static on both sides?**

Worked answer: the verifier already rejected any static mismatch, so a check there could never fire and would be dead code. Skipping it is also what keeps static programs untouched: the static add's lowering has no `cf.assert` and no `memref.dim`, and the `--convert-mg-to-affine` output for it is byte-identical to the file stored in Chapter 10.

**3. The bufferization path crashed on first use while the hand-written path worked. What was the cause, and what is the rule?**

Worked answer: One-Shot Bufferize's model created a `cf.assert`, but the `cf` dialect, though registered with `mg-opt`, had not been loaded into the context, and MLIR loads dialects on demand; the build aborted with "Building op `cf.assert` but it isn't known in this MLIRContext". The fix is one `ctx->loadDialect<cf::ControlFlowDialect>()` in the external-model registration. The rule: any op a bufferization model creates should have its dialect loaded by that model's registration instead of relying on something else having loaded it. Why `affine`, `arith` and `memref` never hit this was not investigated.

**4. Run through a pipe, the aborting program printed no message. Why, and does that weaken the safety property?**

Worked answer: the lowered code calls `puts` (stdout) then `abort()`. When stdout is not a terminal it is fully buffered, and `abort()` does not flush stdio buffers, so the message is discarded. The safety property is untouched, since the program still dies with exit status 134 (`SIGABRT`) before any out-of-bounds access; what is lost is the explanation, in exactly the cases (CI logs, captured output) where it is most needed. Under a terminal or line-buffered output the message appears.

**5. What does the check still not guarantee?**

Worked answer: it compares the sizes the caller declared in the descriptors. A caller whose descriptor claims 2x3 over a buffer of two doubles is lying about memory, and no compiled comparison can detect that. The guarantee is that the operand sizes agree, not that each buffer is as large as its descriptor claims; the response to a mismatch is process death, with no recoverable error.

---

## Chapter 15

*(from [15. A Real Test Suite: `lit`, `FileCheck`, and Proof That the Tests Can Fail](../part15/15-a-real-test-suite.md))*

**1. What does `CHECK-NOT` assert, and which tests lean on it to show that the dynamic-shape work costs static programs nothing?**

Worked answer: `CHECK-NOT: text` requires that `text` does not appear between the surrounding matches. The static lowering tests (`static-add-affine` and `bufferize-static-add`) use `CHECK-NOT: cf.assert` and `CHECK-NOT: memref.dim` after the loop checks, so if the dynamic machinery leaked into a static program the test would fail.

**2. Why is the `mg-opt` under test chosen by an environment variable rather than hard-coded in `lit.cfg.py`?**

Worked answer: so the identical suite can be pointed at other builds. That is how the chapter shows the tests can fail: `older_builds.sh` runs the unchanged tests with `MG_OPT` set to Chapter 7's and Chapter 13's builds, and `mutation.sh` sets it to builds with deliberate bugs. A suite tied to one binary could only ever report on that binary.

**3. The two `not --crash` tests failed on the first run, while the verifier tests written with plain `not` passed. Why was that not good enough, and what was the fix?**

Worked answer: `lit`'s builtin `not` did not support `--crash` ("`not`: command not found" for that form), so those tests could not run. The plain-`not` tests passing was not reassuring either, because at that point a passing `not` test could not be told apart from a broken one. The fix was to define `%not` as LLVM's `not-18`, which supports `--crash`, and use it everywhere; the older-build runs then showed the verifier tests really do fail when the behavior is absent.

**4. What did mutating the code to check only dimension 0 reveal about the suite as first written?**

Worked answer: with 21 tests, that mutation was caught only by tests of the IR's structure (the lowering tests expecting an assert for dimension 1). No native test mismatched the columns while the rows agreed, because the only mismatch case differs in rows first, so a runtime bug in dimension 1 could have passed every executable test. The 22nd test, `mismatch-columns-aborts` (2x3 plus 2x2), was added and the mutation re-run: it now fails there too.

**5. Why is pinning an exact diagnostic message a double-edged choice? Give the example from this chapter.**

Worked answer: it makes the test strict about wording, so it also fails when only the text changes. On Chapter 7's build, `verifier/add-static-mismatch` fails not because the program is accepted but because the message then read "operands must have the same shape" and Chapter 13 changed it to "operands must have compatible shapes". The test was kept pinned deliberately, on the view that a changed message should make a human look, but it is a brittleness a reader should know about.

---

## Chapter 16

*(from [16. Testing the GPU Path and the Loop Transforms](../part16/16-testing-the-gpu-path-and-loop-transforms.md))*

**1. `gpu/pass-order-crash.mlir` is designed to start failing. Why write such a test, and what should someone do when it fails?**

Worked answer: it pins a property of the toolchain, the LLVM 18.1.3 segmentation fault when `gpu-to-llvm` runs after `gpu-module-to-binary`, that Chapters 11 and 12 depend on. If a newer LLVM fixes the bug, the test goes red. That is the signal to revisit those two chapters and the recipe, not a regression in this book, and the test's header says so for whoever sees it fail.

**2. Eight recipe mutations were all caught, but the chapter calls two of the failures weaker evidence. Which two, and why?**

Worked answer: mutation 2 (a different chip) and mutation 5 (a recipe missing `gpu-map-parallel-loops`). In both the broken recipe produced no output at all, so `FileCheck` reported its first pattern missing from an empty input. Those tests failed because the pipeline errored, which shows only that the recipe still works. For the other six (index width, parameter count in two tests, tile structure, unrolled loops, printed numbers) the pipeline ran and a specific value changed, which is the stronger evidence.

**3. What went wrong the first time mutation 1 ran, and what guard was added?**

Worked answer: the `sed` expression `'index-bitwidth=64/s/64/32/'` had no slashes around its address, so `sed` read it as an insert command and added a junk line after every line of the test file instead of substituting. The recipe was never changed, so the unchanged test passed, and the script had treated "the file differs" as "the mutation applied". The expression was corrected and the script now rejects any mutation that changes the file's line count, since a substitution never should.

**4. All 12 new tests pass on the Chapter 7 and Chapter 13 builds. What does that tell you about what they test?**

Worked answer: they pin the GPU and loop pipelines and the toolchain's behavior, which those builds share, not the dynamic-shape features added in Chapters 13 and 14. That is why they cannot tell those builds apart, and it is expected: the earlier 22 tests are the ones that distinguish them.

**5. What does the stub-runtime execution test tell you, and what does it not?**

Worked answer: it checks the host glue: the program prints `6 8 / 10 12` with both the 23-parameter and the 5-parameter launch, and the stub's trace confirms the grid, block and parameter count. It does not execute the PTX, because the stub's kernel is C code written to mirror it. Mutation 8, changing the stub's `a + b` to `a - b`, shows the test catches a wrong stub, which is a statement about the test, not about the real kernel.

---

## Chapter 17

*(from [17. Loop Transforms on Dynamic Bounds](../part17/17-loop-transforms-on-dynamic-bounds.md))*

**1. Why must tiling clip its point loops with `min(arg + tile, n)`, and what would go wrong without the `min`?**

Worked answer: the tile loop steps through the data in strides of the tile size, but when `n` is not a multiple of the tile size the last tile is partial. A point loop running a fixed tile-size number of iterations would walk past the end of the data in that last tile, reading and writing out of bounds. The `min` bound makes the last tile stop at `n`. The chapter's evidence is the tiled IR (`min #map1(%dim_6, %arg2)`) and the passing results on `5x9`, `7x4`, `13x3` and other shapes that are not multiples of 4.

**2. What does the epilogue loop do after partial unrolling, and when does it run zero times?**

Worked answer: the main loop runs up to `(n floordiv k) * k`, `n` rounded down to a multiple of the unroll factor `k`, stepping by `k` with `k` copies of the body. The epilogue loop runs the remaining `n mod k` iterations one at a time. When `n` is already a multiple of `k` the main loop covers everything and the epilogue loop's range is empty, so it runs zero times. For `unroll-factor=2` that is every even `n`.

**3. Full unrolling produced no error and no change on the dynamic chain. Why is "no error" a trap, and how was the no-op demonstrated?**

Worked answer: a pass that declines to apply reports nothing, so a script or reader could assume the loops were unrolled when they were not. The chapter shows the output IR is byte-identical to the input (`cmp`), and the loop count stays at 4. The reason is that full unrolling must emit a fixed number of copies of the body, which needs a constant trip count; with a bound read from `memref.dim` there is none. With `tensor<?x2xf64>` the inner loop's count is the constant 2, and the same pass does unroll it (4 loops down to 3).

**4. A natural guess is that the transpose's access pattern stops `--affine-loop-fusion` on the dynamic chain. How did the chapter test that guess, and what was the answer?**

Worked answer: it ran fusion on three programs: the dynamic add-then-transpose chain, a dynamic add-then-add chain (identical index patterns, no transpose), and the same add-then-transpose chain with static 4x6 bounds. The dynamic add-then-add chain was also left at 4 loops, while the static add-then-transpose chain fused to 2. So the transpose is not the blocker; dynamic bounds are. The chapter then stops: it did not establish *why* dynamic bounds block fusion, and says no test distinguishes the candidate explanations. *(Update, added after Chapter 18: the pass requires constant trip counts for every loop in both nests, found by reading the source and confirmed with six experiments.)*

**5. Why does `fusion-declines.mlir` come with a companion test, `fusion-fires-when-static.mlir`, and what is the first test designed to do if the toolchain changes?**

Worked answer: the first test passes when fusion leaves the dynamic nests alone, which would also be true if fusion were simply broken everywhere. The companion shows the same chain with static bounds *does* fuse (4 loops to 2), so the first test is passing for the specific reason the chapter claims. The first test is also designed to start failing if a newer toolchain begins fusing dynamic nests: that is the signal to revisit this chapter's finding, not a regression in the book.

---

## Chapter 18

*(from [18. Why Fusion Declines: Reading the Pass, and a Second Bug Found Along the Way](../part18/18-why-fusion-declines.md))*

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

---

## Chapter 19

*(from [19. A Better Abort: Reporting Assertion Failures on stderr](../part19/19-a-better-abort.md))*

**1. Why does `puts` followed by `abort()` lose the message when stdout is a pipe, while `write(2, ...)` followed by `abort()` does not?**

Worked answer: `puts` writes into the C library's buffered stdout stream. When stdout is a terminal the library flushes at each newline, but when it is a pipe or a file the text stays in memory until the buffer fills or the program exits normally. `abort()` ends the process immediately without flushing stdio buffers, so the text is discarded. `write` is a thin wrapper over the operating system's write call with no library buffer: when it returns the bytes are already in the kernel, so a later `abort()` cannot lose them. Writing to descriptor 2 also puts the message on the stream conventionally used for errors.

**2. The pass only rewrites an assert whose parent operation is a `func.func`. What goes wrong without that guard, and how can the pass still cover a nested assert?**

Worked answer: rewriting splits the assert's block in two and adds a failing block, which needs a region that may hold several blocks. An `affine.for` body is a single-block region, so splitting it produced invalid IR (`'affine.for' op expects region #0 to have 0 or 1 blocks`). The guard leaves such asserts to MLIR's default lowering. Running the pass after `--lower-affine --convert-scf-to-cf`, when no structured loops remain and every assert sits in a function body of blocks, makes the nested assert eligible; the nested program was then run for real and a NaN aborted with its message on stderr.

**3. Why must the pass run before `--convert-func-to-llvm`, and how would you notice if it did not?**

Worked answer: `--convert-func-to-llvm` already lowers `cf.assert` (to `puts` plus `abort`), so by the time a later pass runs, no `cf.assert` is left to rewrite and the pass silently does nothing. You would notice by looking at the IR or the behavior: with the standard lowering first, the output contains two `puts` calls and zero `write` calls, and the message is lost again when stdout is a pipe. Nothing warns about this, which is why the chapter shows it and why every test uses the one correct ordering.

**4. Running the pass twice on one module used to fail with a redefinition error. What caused it, and what was the fix?**

Worked answer: the message globals were named from a counter that restarted at zero on each run. A first run rewrote a top-level assert (global `_0`) and left a nested one; after flattening, a second run rewrote the nested one and reused `_0`, so the module had two globals with the same symbol name. The fix searches the module's symbols for the first unused `mg_assert_stderr_msg_<k>` instead of counting, so each message gets a distinct name regardless of how many times the pass runs.

**5. Two of the new tests did not fail under the first four mutations. Why did the chapter add more mutations, and which ones?**

Worked answer: a test that has never failed has not been shown to test anything. `valid-shapes-still-pass` guards against the pass breaking programs whose assertions hold, and `static-unchanged` guards against the pass altering programs it should leave alone; the first four mutations (wrong descriptor, no abort, no guard, truncated length) broke neither property. Mutation 5 swaps the branch targets so a true condition goes to the failing side, which makes valid programs abort and fails `valid-shapes-still-pass`; mutation 6 declares `abort` even when nothing needs rewriting, which changes a program with no asserts and fails `static-unchanged`. Mutation 7, removing the unique-name search, was added once the collision bug was found.

---

## Chapter 20

*(from [20. The Mountain Goat Demo: A Surface Syntax, a Driver, and C++ Calling Compiled Code](../part20/20-the-mountain-goat-demo.md))*

1. What is the difference between a front end and a driver? Which parts of this chapter are each?

    **Answer.** A **front end** reads the source text, checks it, and produces the compiler's internal form: here `mgfront.py`, which parses `.mg` text and writes `mg`-dialect MLIR. A **driver** runs the stages in order and connects them: here `mgc`, which calls the front end, then `mg-opt`, `mlir-translate` and `clang`. The front end knows the *language*; the driver knows the *pipeline*.

2. Why does the front end accept `add([[1,2,3],[4,5,6]], [[1,2],[3,4],[5,6]])` when `add` is declared `tensor[?x?]`, and what stops it at run time?

    **Answer.** The front end can only compare dimensions it knows. Both parameters are `tensor[?x?]`, so it accepts any arguments that fit `?x?`; the sizes 2x3 and 3x2 are not compared against each other. At run time the lowering of `mg.add` compares the actual extents with `cf.assert`, and Chapter 19's pass makes that assert write its message to stderr and abort.

3. Why did the first GPU example produce no kernel, and what changed to fix it?

    **Answer.** With `let` constants as inputs, `mg.add` of two `mg.constant` operands was folded by the compiler into a single precomputed constant, so the program became stores of the final numbers: no loop, hence no loop to turn into a kernel. The fix was to make the inputs function parameters, whose values the compiler cannot know, so the addition survives as a loop.

4. Why can the C++ wrapper throw an exception for `rot` but not for a failed dynamic check in `add`?

    **Answer.** The `rot` parameter has a static shape (2x3), which the generated C++ code can compare against the matrix's `rows` and `cols` before calling anything, so it throws `std::invalid_argument`. A failed dynamic check happens *inside* the compiled code, which has no way to throw a C++ exception: it writes its message and calls `abort()`, which ends the process.

5. What does `tensor.cast` from `tensor<2x3xf64>` to `tensor<?x?xf64>` change, and what would a cast in the other direction need that this one does not?

    **Answer.** It changes only the static type: the data is the same, the compiler just stops promising the sizes. Static to dynamic is always safe. The reverse direction (`?x?` to `2x3`) would claim sizes the compiler cannot know, so a correct lowering would need a run-time check that the actual sizes are 2 and 3.

6. Which of the five breakages in `prove_tests_can_fail_out.txt` is caught by the `cpp-interop` test, and why?

    **Answer.** The `cpp-interop` test is caught by 'driver forgets Chapter 19's stderr pass': that test checks the abort message on stderr for the C++ program's mismatch run, and without the pass the message goes to stdout (and is lost when stdout is not a terminal).

7. Why is the CUDA host program not in this chapter, and what exactly would it need that this environment lacks?

    **Answer.** There is no GPU and no CUDA driver in this environment, and no `cuda.h` to compile against. Such a program would load the PTX with `cuModuleLoadData` and launch with `cuLaunchKernel`, passing the 23 kernel parameters in Chapter 10's order; none of that can be built or run here, and the book does not print code it never executed.

---

## Chapter 21

*(from [21. More Operations: Subtract, Hadamard, Divide, Matrix Product, and Scalars](../part21/21-more-operations.md))*

1. What are the three meanings of "multiply" for matrices, and which operator in Mountain Goat is each?

    **Answer.** **Elementwise (Hadamard):** each element times the matching element, written `*`, needs equal shapes. **Matrix product:** row-by-column dot products, written `@`, needs only the inner dimensions to match and gives (rows of the left) by (columns of the right). **By a scalar:** every element times one number, written `*` with a number on one side. The language disambiguates by operator and by operand type (matrix or number), never by guessing from shapes.

2. Why does `a - 1` give a different answer from `10 - a`, and how does the compiler represent the difference?

    **Answer.** Subtraction is not commutative: `a - 1` subtracts 1 from each element, while `10 - a` subtracts each element from 10. Both are `mg.scalar` with `op = "sub"`; the `reversed` attribute is `false` for the first and `true` for the second. The lowering uses it to decide which side of `arith.subf` the constant goes on (`subf %0, %cst` versus `subf %cst, %0`). The same applies to division (`16 / a` versus `a / 16`).

3. What is a reduction, and which loop in the lowered matmul is one?

    **Answer.** A reduction combines many values into one, here by summing. In the lowered matrix product it is the innermost loop over `k`: for each output position `(i, j)`, it sums `lhs[i][k] * rhs[k][j]` over all `k` into the same memory location. The `i` and `j` loops are independent of each other (each result element is its own computation), which is why the GPU recipe makes them parallel and leaves the `k` loop sequential inside each thread.

4. Why must the result of a matmul be zero-filled first?

    **Answer.** The main loop *accumulates*: it reads the current value at `result[i][j]`, adds a product, and writes it back. `memref.alloc` gives memory with unspecified contents, so without the fill every sum would start from garbage. The lowering therefore runs a separate loop nest that stores 0.0 everywhere before the accumulate nest. One of this chapter's mutations removes exactly this step. Only the lowering-structure test and one deliberately dirtied-heap test in the C++ program reliably notice (see "After an independent review" below); no program written in the language itself can, because the generated code never reuses memory.

5. `mg.matmul`'s verifier does not require the two operand shapes to be equal. What does it require, and what happens when a dimension is `?`?

    **Answer.** It requires the inner dimensions to be compatible (the left operand's columns against the right operand's rows) and the result to be (left rows) by (right columns). "Compatible" is Chapter 13's rule: equal, or `?` on either side. When the inner dimension is `?` on either side, the verifier accepts it, and the lowering emits one `cf.assert` that compares the two extents at run time. A failed check aborts with `mg.matmul: inner dimensions differ at runtime` on stderr.

6. Dividing a matrix by zero does not stop the program, but dividing a *scalar* by a scalar zero in source is an error. Why the difference?

    **Answer.** Matrix division is carried out at run time by the hardware's floating-point divide, which follows IEEE 754: `x/0` gives `inf` or `-inf` and `0/0` gives `nan`; there is no exception to raise. Scalar-by-scalar arithmetic is folded by the *front end* while compiling, where a literal division by zero is certainly a mistake it can see and report with a line number. The front end cannot tell what a matrix will contain, so it does not guess.

7. Why did the first attempt to compile `matmul` to PTX fail, and why had Chapter 10 not hit that?

    **Answer.** The `k` loop stays sequential, so it ends up as an `scf.for` *inside* the GPU kernel. The device pipeline from Chapter 10 converted the GPU dialect to NVVM but never converted structured loops (`scf`) to branches (`cf`), so a leftover cast could not be legalized. Chapter 10's kernels had no loops inside them (every loop became a thread index), so the missing pass was never needed. Adding `convert-scf-to-cf` inside `gpu.module(...)` fixed it.

8. Why does `(a - b) * a / 2 + 1` produce four kernels, and what does that say about the generated code?

    **Answer.** Each operation lowers to its own loop nest over its own result buffer, and each nest becomes one kernel. So four operations give four kernels, each reading the previous one's output from memory and writing a new buffer. Nothing fused them into one pass over the data. That is correct but does more memory traffic than a fused version would; the book does not measure it and makes no speed claim.

9. The test `matmul-mismatch-aborts` checks stdout as well as stderr. What does the stdout check establish?

    **Answer.** That the abort happens *before* anything is printed: the program printed nothing to stdout, and the message went only to stderr. Without that check, a bug that printed a partial or wrong result and *then* aborted would pass.

10. The C++ test compares Mountain Goat's matmul against a hand-written C++ triple loop. Why is that a stronger check than the values in example 4?

    **Answer.** Example 4's expected values were computed by hand for one small pair of matrices; the C++ comparison checks 7x5 by 5x9 matrices with 63 outputs, against an implementation that Mountain Goat did not produce. A bug that coincidentally gives the right numbers on a tiny input (say, a transposed index that happens to be symmetric) is unlikely to survive a non-square, non-symmetric comparison.

---

## Chapter 22

*(from [22. Broadcasting, Reductions and relu: Enough Operations for a Neural-Network Layer](../part22/22-broadcasting-reductions-and-relu.md))*

1. What does broadcasting do, and what is the rule for when two shapes can be broadcast together?

    **Answer.** A dimension of size 1 is conceptually repeated to match the other operand, so `[[10, 20, 30]]` (1x3) can be added to a 2x3 matrix as if it were two stacked copies. Per dimension, the sizes must be equal or one of them must be 1; otherwise the shapes cannot be broadcast. It changes only shapes, not the arithmetic. In Mountain Goat the rule applies only to static dimensions.

2. Why is `?` never broadcast?

    **Answer.** A `?` dimension's size is unknown when the program is compiled, so the compiler cannot know whether it is 1 (and so repeatable) or not. Guessing would silently change the meaning of a program depending on its inputs. Instead the dimension must equal the other operand's at run time, and a mismatch aborts with a message (example 10). To get broadcasting, write a static size in the type.

3. What is the difference between `row_sum(a)` and `col_sum(a)`, and what shapes do they return for a 2x3 matrix?

    **Answer.** `row_sum` gives one total per row, a 2x1 result (the three columns collapse). `col_sum` gives one total per column, a 1x3 result (the two rows collapse). The name says what you get one of; the reduced dimension becomes size 1.

4. Why does `mg.reduce` lower to two loop nests instead of one?

    **Answer.** Each output element combines several input elements, so it must start from a known value and then accumulate. The first nest stores the starting value (0 for a sum, negative infinity for a max) into every output cell; the second walks the input and folds each element into its output cell. A single nest that stored each output once would not have anywhere to accumulate.

5. Why does a max reduction start at negative infinity rather than at 0?

    **Answer.** `max(x, -infinity) = x` for every `x`, so the starting value never affects the answer. Starting at 0 would be wrong whenever every element is negative: the result would be 0, a number that is not in the data at all. (This is one of the lowering mutations; see the results above for whether the tests catch it.)

6. What is `a - col_mean(a)` for a 3x2 matrix `a`, shape by shape?

    **Answer.** `col_mean(a)` is 1x2 (one mean per column). Subtracting a 1x2 from a 3x2 broadcasts the 1x2 across the three rows, so every element has its own column's mean subtracted. The result is 3x2, and each column of it sums to zero.

7. Why is `row_mean` an error on a `tensor[?x?]` but `row_sum` is not?

    **Answer.** A mean is a sum divided by a count, and the front end bakes the count into the program as a constant. With a `?` size the count does not exist until run time, so there is no constant to divide by. A sum needs no count, so it works for any size.

8. The first mutation run left "a size-1 left operand is not broadcast" uncaught. What does that tell you about the tests, and what was done?

    **Answer.** It showed that no test exercised the branch of the broadcast rule where the *left* operand is the one that grows: every example wrote the small operand on the right, so the branch could be deleted with no test noticing. An example with the small operand on the left (including a non-commutative operator, so order matters) and a matching check were added, and the same mutation now fails a test.

9. In the PTX, the reduction's accumulate kernel has three `add.rn.f64` instructions in a row for a 2x3 input. What are they?

    **Answer.** They are the three iterations of the inner loop over the columns, unrolled because the column count (3) is a constant. Each GPU thread handles one row and adds that row's three elements into the output cell in order. The row loop was made parallel (one thread per row); the reduction loop was left sequential, because parallelizing a loop that accumulates into one cell would be a race.

10. `relu` is lowered with a NaN-propagating maximum. What is the observable difference from a maximum that ignores NaN?

    **Answer.** With a NaN input, a propagating maximum returns NaN, so the problem stays visible in the output, while a NaN-ignoring maximum would return 0 and hide it. This chapter chose propagation (and the GPU's `max.NaN`). No test feeds a NaN to relu, so that behavior is by design and by the instruction's definition, not something the tests demonstrate.

---

## Chapter 23

*(from [23. Measuring Performance: Does Any of It Make the Code Fast?](../part23/23-measuring-performance.md))*

1. Why does this chapter report both the median and the minimum, and why does it run the whole experiment twice?

    **Answer.** Timings on a real computer include interference (other processes, frequency changes, a cold cache), so one number is unreliable. The median ignores a few slow outliers and the minimum shows the least disturbed run. Running the whole experiment a second time shows how much the numbers move from run to run: here by up to 44%, which tells the reader which differences (large ones) can be trusted and which (1.0× to 1.2×) cannot.

2. What is a GFLOP/s, and why can it compare two implementations of the same product at the same size but not different sizes?

    **Answer.** It is billions of floating-point operations per second; a product of N by N matrices costs 2·N³ operations, so dividing by the time gives the speed. At a fixed size the work is the same, so a higher number is simply faster. Across sizes the memory behavior changes (the matrices stop fitting in cache), so the same code runs at different speeds at different sizes, and the numbers do not measure the same thing.

3. The Mountain Goat matmul at `-O2` matches the C++ `ijk` loop. Does that mean Mountain Goat is fast?

    **Answer.** No. It means the compiler turned `a @ b` into exactly the textbook loop, so it is no slower than that algorithm. The same table shows a hand-written loop with the middle loops swapped running about 5× faster at N = 256 and 12× faster at N = 512. "Matches the naive version" is a statement about overhead, not about speed.

4. What does loop tiling do, and what would you expect to happen to its benefit as N grows?

    **Answer.** It restructures the loops to work on small square blocks at a time so that the data a block needs stays in cache while it is reused. Its benefit should grow with N because the untiled loop's memory traffic gets worse as the matrices become larger than the cache. The measurements are consistent with that: 1.1× at N = 64, 2.3× at 128, 2.6× at 256, 5.2× at 512. Cache misses were not measured, so this is consistent with the data, not proven by it.

5. `-O3 -march=native` made the untiled matmul no faster. What did the machine code show, and what can you conclude?

    **Answer.** The assembly of the untiled functions contains zero vector or fused-multiply-add instructions: the loop is scalar, even though the CPU supports wide vectors. So "allow every instruction" cannot help if the compiler does not use them. What can be concluded is only that these builds are scalar; why the compiler declined to vectorize them was not investigated.

6. Result 5 says the tiled, fixed-shape build is fast and contains vector instructions. What does the chapter say it has *not* established?

    **Answer.** Which ingredient matters. Only the combination (tiled and fixed shape) was built and measured. The dynamic-size tiled build is not vectorized, and the untiled fixed-shape build is not either, but a fixed-shape build tiled differently, or a dynamic build with a different tile size, was not tried. Claiming that "knowing the sizes" alone, or "tiling" alone, is the cause would go beyond the evidence.

7. Why is there no test saying "the tiled build is faster than the untiled one"?

    **Answer.** Speed depends on the machine and how busy it is. A test like that would fail randomly on a loaded shared machine and pass on a quiet one, which makes it noise that teaches people to ignore failures. The tests instead check what must always hold: the results are identical across variants, the tiling pass really runs (loop counts), and the flags reach the compiler.

8. Ignoring the `-O` flag did not make any result-checking test fail. Why not, and how was it caught?

    **Answer.** An optimization level changes how fast the program runs, not what it computes, so no test of the output can see whether it was applied. The bug is an equivalent mutant with respect to results. It was caught by adding a seam (`MGC_CLANG`) that lets a test substitute `echo` for clang, so `mgc` prints the command line it would have run, and the test checks that `-O2` is on it.

9. How did testing `mgc build` find a bug that had existed since Chapter 20, and what was it?

    **Answer.** Earlier tests used `mgc run` and `mgc lib`, which never reach the script's last line in the failing way. A new test used `mgc build` and checked it succeeded. The last line, `[ "$cmd" = run ] && exec "$exe"`, evaluates to false when the command is `build`, and in a shell script the last command's status becomes the script's status, so `build` exited 1 on success. The fix is an explicit `if`. The lesson is that a new test exercised a path no earlier test used.

10. What would you need to do to turn this chapter's results into a claim about Mountain Goat's performance in general?

    **Answer.** Run on more machines (ideally quiet, fixed-frequency ones), more operations and shapes, tune the tile size, use hardware counters to check the cache explanation, isolate the tiling and fixed-shape effects, and compare against a tuned library. This chapter did none of that, so its results are statements about one operation on one shared virtual machine in one session.

---

## Chapter 24

*(from [24. Closing the Gap: A Matrix Product That Walks Memory in a Better Order](../part24/24-closing-the-matmul-gap.md))*

1. In `ijk` and `ikj`, which loop is innermost, and which memory does that innermost loop walk?

    **Answer.** In `ijk` the innermost loop is `k`: it reads `A[i][k]` along a row of A (consecutive addresses) and `B[k][j]` down a column of B (jumping a whole row each step). In `ikj` the innermost loop is `j`: it reads `B[k][j]` and updates `C[i][j]`, and both walk along a row, so consecutive addresses.

2. Why does walking down a column of a row-major matrix cost more than walking along a row?

    **Answer.** Memory is fetched in cache lines of about 64 bytes (eight doubles). Along a row, every number of a fetched line is used. Down a column, each step lands in a different line, so one number of each fetched line is used and the rest is wasted, and for large matrices those lines are evicted before they are needed again. A walk along a row also lets the compiler use vector instructions; a walk with a large stride does not.

3. Why are the `ijk` and `ikj` results identical to the last bit, rather than merely close?

    **Answer.** Floating-point addition is not associative, so the order of additions matters. But in both loop orders, each result element `C[i][j]` accumulates its products in the same order (`k` increasing from 0), so each element goes through exactly the same sequence of additions and the same roundings. What differs between the orders is only the order in which different elements are worked on, which does not affect any element's value.

4. Why does the benchmark's exact-equality check not prove that, and what does?

    **Answer.** The benchmark uses small whole numbers, for which every product and sum is exact in any order, so any order would pass. The proof needs numbers that round: `bits_check.sh` multiplies values that are not exactly representable, prints every bit, and compares the two orders. It also shows the comparison could fail: adding in decreasing `k` order changes 19 of the 20 results.

5. Chapter 23 could not say whether tiling or fixed sizes unlocked vectorization. What did this chapter find, and what did it not test?

    **Answer.** With the `ikj` order, even the untiled dynamic-size function contains vector instructions (8, against 0 with `ijk`), so for dynamic sizes the loop order alone is sufficient; neither tiling nor fixed shape was needed. It did not test other loop orders, did not read the compiler's vectorization reports, and did not measure why the fixed-shape builds have more vector instructions. The explanation (consecutive addresses in the inner loop) is consistent with the evidence, not proven.

6. Tiling gave 2.6× to 5.2× in Chapter 23 but little here. Why, and where does it still help?

    **Answer.** Part of what tiling does is reduce cache misses caused by the column walk. The `ikj` order removed the column walk, so there is less left for tiling to fix. It still helps at plain `-O2` (1.6× at N = 512) and with a fixed 256 shape and all instructions (12.10 against 9.72 GFLOP/s), where other effects are in play that this chapter did not isolate.

7. Why is the default still `ijk` if `ikj` is better?

    **Answer.** Changing the default would change the generated code for every earlier chapter's matmul, and with it recorded outputs, structure tests and page text. Making the better order opt-in kept everything earlier valid. A production compiler would make the better order the default and keep the old one selectable, or choose per shape.

8. The test `bad-option` checks that `matmul-order=jki` is an error. What would the mutation "option not validated" do without it?

    **Answer.** The pass would accept any string and treat everything other than `ikj` as `ijk`, so `jki` (or a typo like `ijk ` or `IKJ`) would silently produce the default order. The user would think they had changed the order and would see no change. The test makes a wrong value fail loudly.

9. The mutation "the ikj order is ignored (always lowers as ijk)" produces correct results. How can any test catch it?

    **Answer.** Only by looking at the structure of the lowered code, because the results are identical by design. `structure` and `flag-reaches-pass` check the loop bounds in the generated IR (2, 3, 4 for `ikj`). This is the same situation as Chapter 22's equivalent mutant: a bug with no effect on results can only be caught by checking implementation, not behavior.

10. What would you have to do to claim that `ikj` is "the" right loop order for Mountain Goat?

    **Answer.** Try all six orders, many shapes (including tall, thin and small ones), more machines and compilers, and look at hardware counters and vectorizer reports to confirm the mechanism. Then compare against a tuned library. This chapter measured two orders on square products on one shared virtual machine.

---

## Chapter 25

*(from [25. Keeping It Working: Continuous Integration and the Tests the Early Chapters Never Had](../part25/25-keeping-it-working.md))*

1. Why is the CI work in a script rather than written directly in the workflow file?

    **Answer.** A script can be run on your own machine, so a failure in CI can be reproduced and fixed without pushing and waiting. The workflow file is then only about *when* and *where* (triggers, a fresh machine, installing packages), and it does not tie the project to one CI service: another service could call the same script.

2. What does "exit status" have to do with CI, and why does it matter that `ci.sh` exits 1 on failure?

    **Answer.** A CI service does not read your test output; it looks at the exit status of the step it ran. Zero means success and anything else means failure. If `ci.sh` printed failures but still exited 0, CI would show green over failing tests. The failure demonstration exists to show it exits 1 when tests fail.

3. Why does CI run on a fresh machine, and what kind of problem does that expose?

    **Answer.** A fresh machine has none of your leftover files, none of the packages installed long ago, and none of the environment variables you set, so it shows whether the project builds from nothing. It exposes dependencies you forgot you had: a package only installed on your machine, a file only present in your working directory, an older tool version.

4. Before the workflow's first real run, what had been established about it, and what changed afterwards?

    **Answer.** Before: the script it calls passed locally, a parse of the workflow found no inconsistency (triggers, packages, paths), and the script failed when tests failed. Not established: that GitHub accepted the file, that the packages installed on a fresh runner, that the cache restored, and that the run finished in time. The environment could not run GitHub Actions. The first real run then passed (102 tests, compiler built from nothing in 46 s), settling acceptance, packages and time; only the cache restore and long-run stability remained open.

5. Why is the compiler build cached, and what decides when the cache is used?

    **Answer.** Building the compiler takes several minutes on a fresh machine, so rebuilding it on every push wastes time. The cache stores the build directory under a key that is a hash of every source file that goes into the compiler; if none changed, the key matches and the build is restored, and if any changed the key differs, so a fresh build runs and a new cache is saved. A hit alone does not skip the build, though: in this repository `build.sh` recopies the sources, which makes `make` rebuild everything, so the workflow also tells `ci.sh` to skip building on an exact hit. The first version of the workflow had the cache and still took 35 seconds to build; only reading the timing in the log showed it.

6. Why does `ci.sh` skip the test step when the build step fails?

    **Answer.** Running the tests against a compiler that was not built would produce dozens of unrelated-looking failures that hide the real cause. Skipping the dependent step keeps the failure report short and points at the first thing that broke.

7. Chapter 2's compiler accepted the mismatched add, but the new Chapter 2 test expects it to be *rejected*. Is the test wrong?

    **Answer.** No. The test runs Chapter 2's example files with the *current* compiler, not with Chapter 2's. Chapter 3 added the shape check, so rejecting that program is the later, correct behavior, and a test expecting acceptance would assert a bug. The test says so in its comment.

8. Why are the mutation scripts and benchmarks not run by CI?

    **Answer.** The mutation scripts take minutes and several rebuild the compiler for each injected bug; they are evidence about the quality of the tests, not checks that must pass on every push. The benchmarks measure speed, which on shared runners is too noisy to gate on: a test that fails when a neighbor is busy teaches people to ignore red. They are run by hand and their results recorded.

9. What kind of mistake would the `check_ci.py` script catch, and what kind would it miss?

    **Answer.** It catches mistakes you can see without GitHub: invalid YAML, a missing trigger, a deleted script, a path in the cache key that does not exist, a forgotten package. It misses anything only GitHub knows: whether an action version exists, whether a package name resolves on the runner image, whether the syntax is valid by GitHub's own rules. A successful parse is not validation.

10. The chapter was written and committed before the workflow's first run, and said so. Why not wait and write it afterwards, and what would have been the right response had the run failed?

    **Answer.** Waiting would have hidden the real order of events and tempted the text to claim more than had been known at the time; stating what was unknown, then recording what the run showed, keeps the two apart and makes the unknowns checkable. Had the run failed, the failure would have been a finding: read the log, fix the workflow or the script, note which of the "not established" items it turned out to be, and rerun. A run that passes does not close every question (cache restore and stability remain), which is why the section still lists what is open.

---

## Chapter 26

*(from [26. Learning From Data: Gradient Descent in Mountain Goat](../part26/26-learning-from-data.md))*

1. Why does the data get a column of ones, and what does that do to the model?

    **Answer.** It turns the bias (the constant term) into an ordinary weight: the weight of a feature that is always 1. Then the whole model is a single matrix product, `x @ p`, with no separate "add the bias" step, and the gradient formula treats all four parameters the same way.

2. What is the gradient, and why does gradient descent step in the opposite direction?

    **Answer.** The gradient is the direction in which the loss rises fastest, with a length that says how steeply. To make the loss smaller you go the opposite way, so each update subtracts a multiple of the gradient from the parameters: `p ← p − rate · gradient`.

3. In `gd.mg`, why is the learning rate passed in as a 1×1 matrix, and why must `p` and `rate` have fixed shapes?

    **Answer.** The language has no scalar parameters (a scalar is a compile-time number, not a value a function can receive), so a one-number value travels as a 1×1 matrix. Multiplying it by the 4×1 gradient needs broadcasting, and broadcasting works only for static shapes (Chapter 22): the compiler must know the 1×1 is a 1 that can be repeated. So `p` and `rate` are fixed-shape, while `x` and `y` keep a dynamic row count.

4. Why do the noisy-data results match the exact least-squares answer rather than the true parameters?

    **Answer.** With noise, the data is no longer exactly produced by the true parameters, so the true parameters are not the ones that minimize the loss on this data. Gradient descent minimizes the loss on the data it is given, so it finds the least-squares solution, which the normal equations compute exactly. The difference between that solution and the truth is the effect of the noise on this sample.

5. What happens with a learning rate that is too large, and why?

    **Answer.** Each step overshoots the bottom of the valley and lands higher on the other side, where the gradient is bigger still, so the next step overshoots by more. The loss grows from step to step (5.4, 2.8, 5.2, 21, 342, 5587 at a rate of 1.2). Below a limit determined by the shape of the loss (0.9927 for this data, computed in `stability_limit.py`) the steps shrink toward the bottom instead.

6. The mutation "the gradient is twice too large" passed every check about the final answer. Why, and which check caught it?

    **Answer.** A gradient twice too large is the same as a learning rate twice as large; as long as that is still stable, gradient descent converges to the same minimum, so the final parameters (and a comparison with plain C++ at 300 steps, when both have converged to the limit of the arithmetic) look right. Only the early steps differ in size. The check that compares the first five steps one at a time with plain C++ caught it.

7. What general lesson about testing iterative algorithms does that case teach?

    **Answer.** Checking where a process ends up does not check how it got there: a bug can change the path and leave the destination unchanged. Tests for iterations should also look at intermediate states (here, the first few steps) against an independent implementation.

8. The driver checks the compiled loss against a plain C++ loss. Gradient descent never uses the loss, so why bother?

    **Answer.** Because nothing else would notice a wrong loss: the parameters come from the gradient alone. A loss function that forgot to square the residuals, or summed along the wrong axis, would leave every check about the parameters passing while the printed losses (the thing a user watches to see whether training works) were wrong. Two of the seven mutations are exactly that.

9. Why does the test build the trainer twice and compare the complete outputs?

    **Answer.** The two builds use different compiler settings (optimized with the `ikj` loop order, and the unoptimized defaults), which change only how fast the code runs. If the outputs differ, a compiler setting changed the answer, which would be a bug. Identical output at the printed precision is evidence that the optimizations preserve the results for this program.

10. What would you need to add to the language to train a logistic regression or a small neural network?

    **Answer.** An exponential (for the sigmoid), a way to take the derivative of `relu` (a comparison that gives 1 where the input is positive and 0 elsewhere), probably a `log` for the usual loss, and ideally a loop so the whole training run is in the language rather than in C++. Each new operation needs a verifier, a lowering, front-end syntax and tests, as in Chapters 21 and 22.

---

## Chapter 27

*(from [27. Tensor Contractions as Matrix Products](../part27/27-tensor-contractions.md))*

1. In one sentence each, what are free axes and contracted axes, and what does the output shape consist of?

    **Answer.** Contracted axes are the paired axes that are summed over and disappear; free axes are all the others and survive. The output shape is A's free axes followed by B's free axes, each at its original size.

2. A has shape `[2,3,4]` and B has shape `[3,4,5]`; the pairs are A's axes `{1,2}` with B's `{0,1}`. What matrices does the matrix-product version multiply, and how many multiply-adds does that take?

    **Answer.** A is read as `[2, 12]` (the free axis, then the two contracted axes bundled: 3·4 = 12) and B as `[12, 5]` (the contracted axes bundled, then the free axis). The product is `[2, 5]` and takes 2·5·12 = 120 multiply-adds, equal to the appendix's formula: output elements (10) times the product of the contracted sizes (12).

3. Why does the "reshape" step cost nothing in this case, and when does the "transpose" step have to copy data?

    **Answer.** A row-major tensor is already a flat buffer, so viewing it as a matrix just changes how the same numbers are read. Here A's free axis is first and its contracted axes are last, and B's contracted axes are first and its free axis last, so no reordering is needed. If an axis is somewhere else (say, a contracted axis at the front of A), the axes must be reordered, which means copying the data into the new order.

4. What are the matrix shapes for an outer product (no contracted axes) and for a dot product (all axes contracted), and why?

    **Answer.** An outer product has K = 1, because the product of no sizes is 1: a `[M, 1]` times a `[1, N]` gives `[M, N]`. A dot product has no free axes, so M = N = 1 (again the empty product): a `[1, K]` times a `[K, 1]` gives `[1, 1]`, the scalar, which the tensor code represents with the empty shape.

5. Why does case 3 include a contraction with the contracted axes listed in reverse order, and what mutation does it catch?

    **Answer.** The pairing order of the contracted axes matters: the axis listed first for A must meet the axis listed first for B. If B's contracted axes were instead taken in sorted order, simple cases where the axes are already increasing would still be right, and only a case with a reversed order would produce wrong numbers. The mutation "B's contracted axes taken in increasing order, not paired" is caught by exactly that case.

6. Why are the results bit-for-bit identical to the definition rather than merely close?

    **Answer.** For each output element both versions add the products in the same order: the flattened contracted index runs over the contracted axes in row-major order, the same order the direct definition's inner loop uses. Floating-point addition is not associative, but the same sequence of additions gives the same bits. The test uses numbers that are not exactly representable so that a different order would show.

7. What happens if the axis validation is skipped and the contracted sizes differ, in the appendix's unchecked version and here?

    **Answer.** In the appendix's unchecked version the loop is sized from one tensor's axis and quietly reads only part of the other tensor, giving a plausible but wrong result with no error. Here the two tensors are flattened to matrices with different inner sizes and handed to the compiled matrix product, whose own run-time check (Chapter 14) aborts with `mg.matmul: inner dimensions differ at runtime`. The failure is loud even without the C++ validation.

8. Why does the mutation script check the exact error message rather than only that an exception was thrown?

    **Answer.** Several mistakes are caught by more than one check. If the repeated-axis check were deleted, a later check (the size comparison) might still throw for the same input, with a different message; a test that only asked "was an exception thrown?" would pass, and the deleted check would go unnoticed. Checking the exact message distinguishes which check fired.

9. Why can't this chapter claim anything about the speed of contractions?

    **Answer.** Nothing was timed: the shapes are tiny and meant for checking correctness, and the permutation's copy cost was not measured. Chapters 23 and 24 measured square matrix products on one shared machine, and those numbers cannot be transferred to other shapes or to the permute-and-reshape overhead.

10. What would be needed for Mountain Goat itself, not C++, to express a general contraction?

    **Answer.** Tensors of rank greater than two, a reshape operation (a no-copy reinterpretation of a contiguous tensor as another shape) and a general permute (a transpose over any axes), each with a verifier, a lowering and front-end syntax and tests, as in Chapters 21 and 22. Alternatively a single contraction operation with axis-list attributes, lowered to the same permute, reshape and matrix product. The C++ code in this chapter is a specification of what those operations would have to do.

---

## Chapter 28

*(from [28. Tensor Contractions in Mountain Goat Itself](../part28/28-contraction-in-mountain-goat.md))*

1. What is the shape of `contract(a, (0, 2), b, (1, 0))` for `a` of shape `[3, 5, 4]` and `b` of shape `[4, 3, 6]`, and which matrices are multiplied?

    **Answer.** A's axis 0 (size 3) pairs with B's axis 1 (size 3), and A's axis 2 (size 4) with B's axis 0 (size 4). A's free axis is axis 1 (size 5); B's is axis 2 (size 6). The output is `[5, 6]`. A is permuted to `[5, 3, 4]` (free axis first, then the contracted axes in the order listed: 0 then 2, i.e. sizes 3 and 4) and read as `5x12`; B is permuted to `[3, 4, 6]` (axis 1, then axis 0, then the free axis 2) and read as `12x6`. The product is `5x6`.

2. Why does example 2's contraction compile to a single `mg.matmul`, while example 4's needs an `mg.permute`?

    **Answer.** In example 2, A's free axis is already first and its contracted axis last, and B's contracted axis is already first, so the row-major data of each is already a matrix and nothing needs to move. In example 4, A's contracted axis is first, so its numbers are not in the order a matrix product needs (free axes bundled as rows, contracted as columns), and the data must be copied into that order.

3. Which of `reshape` and `permute` copies data, and why can the other not?

    **Answer.** `permute` copies. After permuting, the same logical tensor must be laid out in memory with a different axis order, and this chapter's matrix product reads its operands row-major, so the numbers have to be moved. `reshape` only changes how a flat, row-major buffer is cut into axes, which does not change where any number is stored, so it is a new view of the same memory.

4. Why must a 3-cycle (not a swap) be among the permutation tests?

    **Answer.** A swap is its own inverse: applying it forwards or backwards gives the same tensor. A lowering that reads the permutation the wrong way round would therefore pass every swap-only test. A 3-cycle is not its own inverse, so only it exposes that mistake. The mutation "permute reads through the inverse permutation" is caught only because of this.

5. Why is the mismatch of the appendix's trap a compile error here but a run-time abort in Chapter 27?

    **Answer.** Chapter 27's C++ built the matrices from sizes known only when the C++ ran, so the sizes reached the compiled matrix product as run-time numbers and only its run-time check could stop them. Here the sizes are literal numbers in the source, so `contract` can compare them while compiling. A `?` size could not be checked at compile time; that is why `reshape` and `contract` refuse values with a `?` dimension.

6. Why does the dot product return `[[14]]` (a `1x1` matrix) rather than `14`?

    **Answer.** The language has no rank-0 tensors: a number such as `14` in the source is a compile-time scalar, folded away before code is generated, while a computed value must be a tensor with a shape. The dot product is computed at run time, so it is a `1x1` matrix.

7. What does `reshape(x, 2, 3, 4)` do when `x` is `4x6`, and what is printed?

    **Answer.** It views the 24 numbers of `x` in row-major order as two blocks of three rows of four. Nothing is copied. For `x` holding 1 to 24 row by row, the first block is rows `1 2 3 4`, `5 6 7 8`, `9 10 11 12`. (`4x6` and `2x3x4` both have 24 elements; `reshape(x, 4, 2)` would be an error: 6 and 8 elements differ.)

8. The mutation "an unneeded permute is emitted (identity permutation not skipped)" does not change any program's output. Why is it still worth catching?

    **Answer.** An identity permute is a full copy of a tensor for nothing: it would slow every contraction down without changing its answer, and no test of *values* could ever notice. The `ir` test asserts that example 3 has no `mg.permute` at all, which is how a performance property (no data moves when none needs to) is turned into something a test can fail on.

9. Why can tensors of rank other than 2 not be function parameters yet, and what is the workaround?

    **Answer.** The type syntax `tensor[RxC]`, the C++ header generator (`mgc lib`, which wraps a function's arguments as `mg::Matrix`) and the dynamic-shape machinery were all built for rank 2, and extending them was not part of this chapter's scope. The workaround is the one example 8 uses: pass a matrix (a `2x12` for a `2x3x4` tensor) and `reshape` it inside the function. The reshape is free, and the compiled function works for any values of that shape.

10. What would be needed to add a rank-N `+`?

    **Answer.** An elementwise operation already exists in the dialect for any equal ranks (`mg.add`'s verifier compares rank and each dimension), but its lowering is a two-loop nest and the front end rejects non-matrices. Needed: a lowering that builds a loop nest of the operand's rank (as `mg.permute`'s already does), front-end shape rules for ranks above 2 (equal shapes; whether size-1 axes stretch), and tests with a definition-style reference as for `contract`.

---

## Chapter 29

*(from [29. Softmax and Attention](../part29/29-softmax-and-attention.md))*

1. Why is `softmax_naive([[1000, 1001, 1002]])` all `nan` rather than a plausible wrong answer?

    **Answer.** `exp(1000)` exceeds the largest double and becomes infinity, and so do `exp(1001)` and `exp(1002)`. The row total is infinity, and each element is infinity divided by infinity, which is undefined, so the result is not-a-number. The stable version never makes a number bigger than 1, so it cannot overflow.

2. Why does subtracting the row maximum not change the result?

    **Answer.** e<sup>x − m</sup> = e<sup>x</sup>·e<sup>−m</sup>, so every term of the numerator and of the denominator is multiplied by the same factor e<sup>−m</sup>, which cancels in the fraction. This is the "shift invariance" that example 4's second matrix shows directly.

3. In `exp(x) / row_sum(exp(x))` the shapes are `2x3` and `2x1`. What makes that legal, and what would stop it if the row count were `?`?

    **Answer.** Chapter 22's broadcasting: a *static* dimension of size 1 is stretched to match the other operand (a `2x1` becomes `2x3`). A `?` size is not known when compiling, so it cannot be stretched, and the compiler rejects the program (example error 4). The same rule is why attention here needs a fixed length.

4. What do the three matrices `q`, `k`, `v` each contribute, and what shape is `q @ transpose(k)` for `n` positions of width `d`?

    **Answer.** Queries say what each position is looking for, keys say what each position offers, values say what each position hands over. For `q` and `k` of shape `n x d`, `transpose(k)` is `d x n`, so `q @ transpose(k)` is `n x n`: entry `[i][j]` is the dot product of query *i* and key *j*, the score of position *i* looking at position *j*.

5. Why divide the scores by the square root of `d`?

    **Answer.** A dot product of two vectors of width `d` with entries of ordinary size grows in size with `d` (the typical size of a sum of `d` products grows like √d). Large scores push the softmax toward giving almost all the weight to one position. Dividing by √d keeps the scores about the same size whatever `d` is. In the examples `d = 2` and the scale is `1/√2 = 0.7071067811865476`, written as a compile-time number.

6. The causal mask uses `-1000000000`. Why does a masked position get weight exactly 0, not a tiny positive number, and when would this go wrong?

    **Answer.** After the maximum is subtracted, a masked score is about −10<sup>9</sup> below the largest, and `exp` of that is far smaller than the smallest positive double, so it underflows to exactly 0. It would go wrong if real scores were as large as the mask (or if a whole row were masked, which makes a row of equal very negative numbers and a meaningless result); the language has no literal for −infinity, which is the usual choice.

7. Why can row 0 of the causal output in example 7 be read off without computing anything?

    **Answer.** The only position row 0 may attend to is position 0, so its weights are `[1, 0, 0]` and its output is `1·v[0] + 0·v[1] + 0·v[2] = v[0]`: `[10, 0]`.

8. Why does `check_attention.py` compare with a tolerance when Chapter 28's check compared exactly?

    **Answer.** Chapter 28 used whole numbers and multiples of a quarter, whose sums and products are exact in binary, so any difference at all meant a bug. An exponential's result is almost never exactly representable, and `mgc` prints only six significant digits, so exact comparison is impossible; a relative tolerance of 10<sup>-5</sup> is a little looser than the printing precision.

9. Which mutation in `mutation.sh` is caught only because a test uses very negative scores?

    **Answer.** "A maximum starts from 0, not −infinity" gives the right answer for any row with a non-negative score, so only an all-negative row can expose it, and even scores around −490 survive it (`e^−490` is tiny but not zero). It takes scores below about −745, where `exp` underflows to exactly 0, to turn the wrong maximum into `0/0`: the `[−1500, −1000]` case and example 4's third matrix. The lesson is the same as Chapter 22's `13_negative_max` example: a test with only friendly numbers cannot see a wrong starting value, and a *somewhat* unfriendly one may not either.

10. What would multi-head attention need that this chapter's language does not have?

    **Answer.** A batched matrix product: the head index appears in both inputs and in the output, which is a batch axis, and Chapter 28's `contract` rejects that (an axis must be paired and summed away). Without it, heads can be written as separate functions and their outputs combined by adding each head's product with its own slice of the output matrix, which is the same arithmetic but not a single batched operation.

---

## Chapter 30

*(from [30. A Small Transformer](../part30/30-a-small-transformer.md))*

1. In one sentence each: what does attention do, what does the feed-forward network do, and which of them mixes information between tokens?

    **Answer.** Attention lets each token gather a weighted average of information from tokens it may look at, so it mixes rows. The feed-forward network applies the same two-layer transformation to every token separately, so it does not mix rows. Only attention moves information between positions.

2. What does a residual connection do, and what would happen to the "no residual" mutations' outputs?

    **Answer.** It adds a sublayer's output to its own input (`x + step(x)`), so the sublayer only has to learn an adjustment and the original information is kept. Without it the output is only what the sublayer computed, which is a different matrix, so the comparison with the reference fails at the first block. (In a *trained* deep model a missing residual also makes training hard; that is not tested here since nothing is trained.)

3. Why is the layer norm's epsilon needed? What does `layer_norm` produce for the constant row `10 10 10 10`?

    **Answer.** The row's variance is 0, so without an epsilon the division would be `0/0`, which is `nan`. With the `0.00001`, the numerator `x − mean` is exactly 0 and the denominator is `sqrt(0.00001)`, so the result is exactly 0 (then the learned scale and shift apply). Example 1's second row shows `0 0 0 0`.

4. Why does the checker require rows before the changed token to be **identical**, not merely close?

    **Answer.** With the causal mask the masked scores are `-1e9`, whose exponentials are exactly 0, so earlier rows are computed from exactly the same numbers through exactly the same operations and must be bit-for-bit equal. A tolerance would let a small leak of future information through (for instance a mask that was `-5` instead of `-1e9`). Equality is a sharper test than closeness here.

5. Why does the checker also require that changing token *j* changes row *j*, and that removing the mask changes row 0?

    **Answer.** A model that ignored its input entirely would pass "earlier rows do not change" trivially, and so would a mask that has no effect. Requiring row *j* to change shows the model reads its input; requiring row 0 to change without the mask shows the mask, not something else, is what makes the earlier rows independent of later tokens.

6. Why is permutation equivariance tested **without** positions and expected to **fail** with them?

    **Answer.** Attention treats its input as a set: reordering the rows reorders the outputs the same way, because nothing in the computation depends on row order (the feed-forward and layer norm work row by row). Positions are added precisely to break that symmetry, so with positions the same reordering must *not* just reorder the output. Checking both directions shows the property is real and that the position matrix does its job.

7. Why does the hand-split of the heads (`h1 @ wo1 + h2 @ wo2`) equal concatenating the heads and multiplying by one output matrix?

    **Answer.** Concatenating two `4x2` matrices side by side gives a `4x4` matrix `[h1 | h2]`. Multiplying by a `4x4` matrix `W` whose top two rows are `wo1` and bottom two rows are `wo2` gives, for each output element, a sum over four terms: the first two come from `h1` and `wo1`, the last two from `h2` and `wo2`. That is exactly `h1 @ wo1 + h2 @ wo2`. The matrix product distributes over the split, so no approximation is involved.

8. Two of the fifteen wrong models passed the first version of the checker. Which, why, and what fixed it?

    **Answer.** The two with a naive softmax (no row-maximum subtraction), in the attention and in the vocabulary. With the seeded weights all scores are small, so `exp` does not overflow and the naive formula gives the same numbers as the stable one; no reference comparison could tell them apart. The *stress* check scales the weights until the scores reach the hundreds and thousands, where the naive softmax gives `nan` and the stable one does not.

9. What would be needed to train this model, and which parts of it does the language lack?

    **Answer.** Gradients of the loss with respect to every weight, computed by differentiating through each operation (matrix product, softmax, layer norm, relu, residuals), plus an update rule such as gradient descent. Chapter 26 did this by hand for a linear model. Mountain Goat has no automatic differentiation, no loss function (cross-entropy needs a logarithm, which the language lacks), and no way to select one probability from a row (an index or argmax operation).

10. What is the difference between this model's embedding lookup and a lookup table in a conventional language?

    **Answer.** Here the lookup is a matrix product: a one-hot row (a single 1 among zeros) times the embedding matrix returns exactly one row of it. It does the work of an index, with `V` times the arithmetic, but it needs no indexing operation (the language has none) and it is differentiable, which is why real frameworks use the same idea for the gradient of an embedding.

---

## Chapter 31

*(from [31. Training a Language Model: Gradient Descent on a Bigram](../part31/31-training-a-bigram-model.md))*

1. Why is the loss exactly `log 5 = 1.609438` before training?

    **Answer.** All weights are 0, so every score is 0 and every softmax row is uniform: probability 1/5 for each of the five tokens. The surprise of any pair is `−log(1/5) = log 5`, and the average of equal numbers is the number itself.

2. What does it mean that the loss cannot go below 0.612174, and why is that the floor?

    **Answer.** 0.612174 is the conditional entropy of the data: the average of `−log(observed probability of the next token)` when each row of probabilities equals the observed frequencies. Among all ways to assign probabilities to the next token given the current one, matching the observed frequencies gives the smallest average surprise on this data (Gibbs' inequality); any other assignment is worse. A bigram model's rows are free, so it can reach but not beat that value.

3. Why are probabilities of unseen pairs (like 0 then 3) small but not exactly 0 after 400 steps?

    **Answer.** A softmax output is `e^s / Σ e^s`, which is exactly 0 only if a score is minus infinity. Gradient descent keeps lowering the score (here to about −2.8) but each step makes a smaller change, so it only approaches zero. The loss never rewards going all the way: it is already almost at its floor.

4. Why does row 4 of the weights stay exactly 0, and what does the model say about the token after 4?

    **Answer.** Token 4 is never a *current* token, so no row of `x` has its 1 in column 4, and the gradient `xᵀ(…)` has a zero row 4 (it is a sum over pairs, and no pair contributes). The step subtracts 0, so those weights stay at their starting value 0, and the softmax of a zero row is uniform: 0.2 each. The model has no information, and reports that rather than inventing something.

5. Why is `log_softmax` written as `s − max − log(sum(exp(s − max)))` instead of `log(softmax(s))`?

    **Answer.** `softmax` produces probabilities, and a probability far below the maximum underflows to exactly 0; the log of 0 is minus infinity, and `y * (−inf)` with a 0 in `y` is `nan`. The log-sum-exp form never builds a probability, so it stays finite. It also subtracts the maximum before `exp`, so `exp` cannot overflow. The ±1000 stress check exercises both.

6. How does the finite-difference check work, and why is its tolerance only `2·10⁻³`?

    **Answer.** For each weight, compute the loss with that weight raised by 0.01 and lowered by 0.01; the slope `(L₊ − L₋)/0.02` estimates the derivative, and it should match the gradient entry. The tolerance is loose because `mgc` prints the loss to six significant digits, so each loss value has an error around `10⁻⁶`, which divided by 0.02 is a few times `10⁻⁵`, and because the estimate itself has an error from the finite step. Observed differences are about `4·10⁻⁴`.

7. The gradient formula `xᵀ(p − y)/14` came from a hand derivation. What makes it trustworthy rather than a guess?

    **Answer.** Two independent checks: it matches a numerical estimate that uses only the loss function (finite differences, which does not use the formula), and training with it reproduces an independent Python trainer step for step and ends at the known optimum (the observed frequencies, the entropy floor). A wrong formula (the wrong sign, a missing 1/14, forgotten targets) fails these, as the wrong-trainer runs show.

8. Why were two of the twelve wrong trainers missed at first, and what does that teach about testing numerical code?

    **Answer.** The naive log-sum-exp and the naive softmax compute the same numbers as the stable versions whenever `exp` does not overflow. The first stress check used scores of ±400, and `exp(400)` is representable (overflow begins near 709), so both naive formulas were correct on every test. Scores of ±1000 overflow, giving `inf` and `nan`, and caught both. A test for a numerical-stability bug must reach the regime where the bug bites.

9. Why can a bigram model not represent "what comes after the pair `0 1`"?

    **Answer.** Its prediction depends only on the current token: the row of `w` for token 1. In the data, token 1 is followed by 2, 3 and 4, and the model can only give the average over every occurrence of token 1, whatever came before it. Capturing the effect of the earlier token needs a model that sees more than one token at a time, which is what attention in Chapters 29 and 30 provides.

10. What would be needed to train the Chapter 30 transformer the way this chapter trained the bigram?

    **Answer.** The gradient of the loss with respect to every weight in it: the embeddings, each head's query, key and value matrices, the output matrices, the layer-norm scales and shifts, the feed-forward weights and biases, and the final projection. That is the chain rule through softmax attention, layer normalization, relu and the residual connections, derived by hand for each, or an automatic differentiation system that does it from the program. Mountain Goat has neither, so Chapter 30's weights remain random numbers; the loss and the training loop of this chapter would carry over unchanged.

---

## Chapter 32

*(from [32. Does It Generalize? Held-Out Data, Overfitting, Weight Decay and Greedy Generation](../part32/32-does-it-generalize.md))*

1. Why did the held-out loss in Experiment 1 first fall (1.609 to 1.482) and then rise?

    **Answer.** In the first steps the model learns the broad facts that help on any pair (token 0 is usually followed by 1, token 3 by 0), which lowers the loss on seen pairs in the held-out set. After that, nothing helps the held-out set further, but training keeps pushing the weights for unseen successors lower to make the training pairs fit better. That makes the model more and more certain that the unseen held-out pairs are impossible, and the surprise at them grows without limit.

2. Why is a held-out loss of 4.036 *worse than knowing nothing*, and what is "knowing nothing" here?

    **Answer.** A model that assigns every token the probability 1/5 has loss `log 5 = 1.609` on any data. The trained model has loss 4.036 on the held-out pairs, which means that on average it gives the true next token a probability of only `e^−4.036 = 0.018`, far below 1/5. It is confidently wrong about the unseen pairs, which costs more than being unsure about everything.

3. Why does weight decay lower the held-out loss but raise the training loss?

    **Answer.** The penalty stops weights from growing large, so the model cannot become as certain as the training data alone would make it. That keeps probabilities for unseen pairs away from 0 (good for held-out data) and also stops the model from fitting the training pairs as tightly as it could (worse training loss). Training loss is exactly the quantity that rewards memorizing, so any force against memorizing raises it.

4. Why does a strength of 0.3 diverge with learning rate 8, and what would make it stable?

    **Answer.** A weight-decay step multiplies each weight by `1 − learning rate × strength`. With 8 and 0.3 that is `1 − 2.4 = −1.4`: the weights change sign and grow by 40% each step. Stability needs `|1 − learning rate × strength| < 1`, i.e. `learning rate × strength < 2` (for the penalty alone). The penalty alone shrinks the weights when the factor is smaller than 1 in size, e.g. a learning rate of 4 with strength 0.3 (factor −0.2; the Python reference trains stably there). But the condition is only necessary: strength 0.2 with learning rate 8 has factor −0.6 and still ends with a training loss of 3.55 in the reference, because the data term adds curvature.

5. How does `ge(row, row_max(row))` find the largest entry, and what goes wrong with ties?

    **Answer.** `row_max(row)` is the largest number in the row, and `ge` marks every entry that is greater than or equal to it, which is exactly the entries equal to the maximum. With one maximum the result is one-hot. With ties, every tied entry is marked, so the result has several 1s and is no longer a single token; in example 6 the all-equal row marks all five tokens.

6. Why must the checker discover which held-out pairs are unseen instead of assuming 2→3 and 1→4?

    **Answer.** If the script hard-coded those pairs, a change to the data split or the text would silently make the explanation wrong while the check still passed. Computing "which held-out pairs occur among the training pairs" from the data ties the claim to the data, so it stays true or fails loudly.

7. The best strength was chosen by held-out loss. Why is that held-out loss then too optimistic?

    **Answer.** The held-out set was used to *make a choice* (which strength to keep), so it is no longer an independent test: among several candidates, the one that looks best on this set partly looks best by luck. An unbiased estimate needs a third set that played no part in any choice, measured once at the end. With four held-out pairs the effect could be large.

8. In the divergence run, why does the checker insist that the *reference* diverges identically?

    **Answer.** A blow-up could be a bug in the new operation or the compiler, or it could be what the algorithm does. If an independent plain-Python implementation of the same algorithm produces the same exploding numbers at every checkpoint, the cause is the algorithm and the settings, not the compiler. The match is the evidence.

9. Why does greedy generation from a bigram loop?

    **Answer.** The next token depends only on the current token, and greedy decoding always picks the same most likely successor for a given token. Starting at token 0 the chain 0 → 1 → 2 → 0 closes after three steps, and since the rule is deterministic and sees nothing but the current token, it repeats forever. Breaking the loop needs randomness (sampling) or more context.

10. The wrong trainer with a naive log-softmax was caught by this chapter's checker. Was that for the reason Chapter 31's naive-softmax mutants were caught?

    **Answer.** Not by the same check. Chapter 31 added a stress case with weights of ±1000 on purpose. Here the naive version produces the same numbers as the stable one for every run with normal weights (they stay below 7). It was caught only because of the deliberately diverging run, whose weights reach 10<sup>58</sup> and overflow `exp`. That was unplanned: I expected it to go unnoticed here, and it is reported as caught by an accident of another check, not as evidence that this chapter's checks test numerical stability.

---

## Chapter 33

*(from [33. Backpropagation Through Attention: Training a One-Head Classifier](../part33/33-backpropagation-through-attention.md))*

1. Why can a bigram not solve this task, and why is attention a natural fit?

    **Answer.** The label depends on all four tokens (which of them are present), not on the most recent one, and a bigram sees only one token. Attention looks at every token in the sequence at once and combines them into one context vector, with no dependence on order, which matches a label that is the same for every ordering.

2. Why does the model stack 24 sequences into a 96-row matrix, and what do the group matrix and the `reshape` do?

    **Answer.** Mountain Goat has no batched matrix product, so a batch is handled as one big matrix. The scores come out as a 96×1 column; `reshape` makes it 24×4 so that a row-wise softmax runs within each sequence (each row holds one sequence's four scores). The group matrix (24×96, with 1s where column ÷ 4 equals the row) turns the sum over each sequence's four weighted values into a matrix product.

3. Write the gradient of the loss with respect to the attention scores in one line, and explain each part.

    **Answer.** `ds = a * (da − Σ a·da)`, where `a` is the attention weights, `da` the gradient with respect to them, and the sum is within each sequence. A score changes its own weight (the `a·da` part) and, because the four weights must add to 1, also every other weight (the `− a·Σ a·da` part). Leaving out the second part treats the softmax as if each output depended only on its own input.

4. Why does the checker compare the gradient both with an independent Python calculation *and* with finite differences?

    **Answer.** They catch different things. The Python gradient is written independently from the same mathematics: it catches a mistake in the Mountain Goat translation, but if both derive the same wrong formula it would agree with itself. Finite differences use only the loss function, not any derived formula, so they catch a wrong derivation. A wrong gradient has to fool both to survive.

5. The model attends more to the 4s than to the 0 in `4 4 0 4` and still outputs the correct label 0. What does this say about reading attention weights?

    **Answer.** The output depends on the attention weights *and* the values and the output matrix. The model learned values and an output matrix that, combined with this attention pattern, favour label 0 when the sequence contains a 0 and nothing higher. So attention weights alone do not say what the model "looked at" in a meaningful sense; they are one part of the computation.

6. Why is "40 of 40 held-out sequences correct" a weak result here, and what is the stronger test?

    **Answer.** Random sequences are dominated by labels 1 and 3 (22 and 13 of the 40, with 5 labelled 2 and none labelled 0 or 4). A model that handles only the common labels can score well. Because there are only 625 possible sequences, the program can try every one; that test includes the rare labels, and it is where the single failure appears.

7. Why does the model fail on `4 4 4 4`, and would you call that overfitting?

    **Answer.** The label of `4 4 4 4` is 4, and label 4 never occurs among the 64 training and held-out sequences, so nothing in training ever rewarded the output 4. It is a gap in the data, not memorizing noise: the model is right on every other sequence, including the 15 that have label 0 though only one had that label in training. It is closer to a missing-evidence failure than to Chapter 32's overfitting, though both come from the model having no way to know what training never showed.

8. Which parts of the backward pass would be needed to train Chapter 30's transformer that are not here?

    **Answer.** The gradients through layer normalization, the residual connections (which add gradients along two paths), a second attention head and its output split, the position matrix, the relu feed-forward network and its biases, and the stacking of several blocks, each with its own weights. The principle in this chapter's table applies to each, but each needs its own derivation and its own check against finite differences; none was done.

9. The wrong backward pass with a naive softmax in the attention was not caught. Why is that expected, and what would catch it?

    **Answer.** The attention scores in this model stay below about 4 in size, and `exp` of such numbers cannot overflow, so the naive softmax computes the same numbers as the stable one. To catch it a test needs scores in the hundreds, like the stress cases of Chapters 29 to 32.

10. What would change if the labels were 1 for sequences containing token 1 and 0 otherwise (two classes)?

    **Answer.** Only the number of output columns: `wo` would be 3×2 instead of 3×5, and the label matrices 24×2. The forward and backward formulas are the same, because the loss and the gradient `(softmax − y)/B` do not depend on the number of classes. In Mountain Goat the shapes are types, so the function definitions would be regenerated with 2 in place of 5.

---

## Chapter 34

*(from [34. Why a Block Has a Feed-Forward Network: Backpropagation Through Layer Normalization, ReLU and Residuals](../part34/34-why-a-block-has-a-feed-forward-network.md))*

1. Why can model A not solve "exactly one of the tokens 1 and 2 is present", according to the argument on this page?

    **Answer.** Attention pooling gives a weighted average of token value vectors, a point in a triangle. Under the picture where attention favours tokens 1 and 2 over 0, "1 only" and "2 only" land at the two ends of the line between `v1` and `v2` and "both" lands between them, so the labels along that line run 1, 0, 1. A linear read-out separates space with a straight line, which cannot make a label that is 1 at both ends and 0 in the middle. The page is clear that this is an argument consistent with the experiment, not a proof.

2. What does the residual connection do to the backward pass?

    **Answer.** `z = h + f` makes `h` influence the loss along two routes, directly and through `f`. By the chain rule the gradient with respect to `h` is the **sum** of the gradients along the two routes: `dh = dz + dh_ln`. Dropping the direct route (a mutation tested above) leaves the gradient with only the layer-norm path.

3. Why does layer normalization's backward pass have three terms?

    **Answer.** Each entry of `h` affects the mean, the spread `sigma` and, through them, every normalized entry. The terms account for each: `dŷ / sigma` for the direct effect on its own normalized value, `−mean(dŷ) / sigma` for the effect through the mean, and `−ŷ · mean(dŷ · ŷ) / sigma` for the effect through the spread. Together they make the gradient entries sum to zero, as they must since shifting every `h` by a constant changes nothing.

4. What is the derivative of ReLU at exactly 0, and what does this chapter do?

    **Answer.** It does not exist: the slope is 0 to the left and 1 to the right. A brute-force estimate averages them, giving half of the upstream gradient (example 2 shows `1` for an upstream `2`). Training code must choose; this chapter passes the gradient at exactly 0 (the mask is `ge(pre, 0)`), as most frameworks do.

5. The first finite-difference check failed for model B. Was the gradient wrong?

    **Answer.** No. The gradient equalled the independent Python gradient. A plain-Python finite difference with exact losses and step 0.01 showed the same `5.6·10⁻³` disagreement, and with step 0.001 only `10⁻⁶`, so the error was in the estimate (a step that straddles a ReLU corner or misjudges curvature). The check's step was changed to 0.001, which `mgc`'s six printed digits still allow.

6. Why is "model B gets 80 of 81" more convincing than "model B gets 26 of 27 held-out sequences right"?

    **Answer.** There are only 81 possible inputs, so the program can try every one: it is exhaustive, with no sampling luck and no held-out set that might happen to be easy. The 27 held-out sequences are one particular random subset; 26 of 27 says less than a full census of the input space. It also identifies exactly which sequence fails.

7. Why does the page report a Python-only sweep, and what does it show that the single run does not?

    **Answer.** Running every seed and learning rate through `mgc` would take hours (model B's program is 6,000 lines and about 100 seconds to build). The Python implementation agrees with the Mountain Goat one step for step, so it is a fair stand-in for a sweep. It shows that model B's success depends on the start and the learning rate (five of six seeds at 0.5, six of six at 0.25, one of six at 1.0), which one run cannot show, and that model A fails for every seed.

8. Why did the experiment not isolate which of layer normalization, the feed-forward network and the residual connection matters?

    **Answer.** Model B adds all three at once and is compared with a model with none of them. Isolating one would need further models (for example, the feed-forward network without layer normalization, or layer normalization without the feed-forward network), each with its own backward pass checked and its own training runs. That was not done, and the page says so; the argument about the ReLU's bend points at the feed-forward network, but the experiment does not test that.

9. How is `0 0 0 0` the model's only error, and what does it have in common with the failures in Chapters 32 and 33?

    **Answer.** It is the only one of the 81 sequences that model B classifies wrongly, and the training set (a random 54 of the 81) happened not to contain it, so the model never saw the case "neither token present" and extrapolates confidently wrong. In Chapter 32 the held-out pairs that failed were the ones the training pairs never showed; in Chapter 33 `4 4 4 4` failed because label 4 never occurred in the data. In each, the failure is an input outside what training covered.

10. What would be needed to train Chapter 30's full transformer with these methods?

    **Answer.** The backward passes of the parts still missing: the position matrix (a fixed input, so no gradient), two attention heads with their output split, causal masking over positions (the gradient through the masked softmax is the same formula, with masked entries contributing zero), per-position outputs and a loss over all positions, and several stacked blocks (the residual structure makes the gradient flow through each block's two paths, as here). Layer normalization, ReLU, residuals and single-head attention are now derived and checked; the remaining work is assembling them, with a finite-difference check of every new weight.

---

## Chapter 35

*(from [35. Training a Transformer Language Model: Backpropagation Through Causal Attention, Layer Norms, a Feed-Forward Network and Embeddings](../part35/35-training-a-transformer-language-model.md))*

1. Why does the attention backward pass need no extra term for the causal mask?

    **Answer.** The mask is a constant added to the scores before the softmax, so it has no gradient of its own. The masked entries of the attention matrix `a` are exactly 0 (softmax of −10⁹), and `ds = a * (da − row_sum(a * da))` is a product with `a`, so `ds` is exactly 0 there: nothing flows back to positions that were not seen. The mask is already inside `a`.

2. The embedding is a lookup, yet its gradient is written `transpose(x) @ dx0`. Why does that work?

    **Answer.** `x` has one 1 per row, in the column of that row's token. `transpose(x) @ dx0` gives row *t* = the sum of the rows of `dx0` over the positions whose token is *t*: a scatter-add. That is the gradient of a lookup: a token used in several places receives the sum of the gradients from all of them, and a token not used receives zero.

3. Why are the 16 sequences stacked into one 112×112 attention instead of being processed one at a time?

    **Answer.** Mountain Goat has only rank-2 matrices, no batch dimension; stacking is the way to process several sequences in one program, and the mask (block-diagonal as well as causal) prevents any row from attending to another sequence. The price is that the score matrix is 112×112, 16 times larger than 16 separate 7×7 matrices would need, mostly entries that the mask zeroes.

4. At step 100 the program's loss is 0.0356 and the Python reference's is 0.0346. Is the program wrong?

    **Answer.** No evidence says so. The two agree to six digits up to step 50, all 16 gradient matrices agree at three starting points, and `sensitivity.py` shows that the same Python code, with one weight changed by 10⁻¹², goes from 0.0346 to 0.2115 at step 100. The training is chaotic after about step 70, so two correct implementations whose floating-point operations are ordered differently will not agree digit for digit there. This is why the check compares claims instead of digits from step 100 on.

5. The sweep shows 256, 239, 249, 239 correct for the four seeds at learning rate 1.0. What does that say about the "256 of 256" result?

    **Answer.** That it is the best of the four runs, not typical: the model reliably fits its 16 training sequences (loss below 0.005 in all four) but generalizes to the other 48 sequences only 93% to 100% of the time, depending on the starting weights. "The model learns the task" is true of the training; "the model has found the rule" is true of some runs and only approximately of others.

6. One mutant, softmax without the row-maximum subtraction, was not caught. Does that mean the checks are wrong?

    **Answer.** No, it means they have a gap. Without the subtraction softmax is the same function, and for scores of this size the numbers are the same; the subtraction exists to prevent overflow of `exp` for large scores. None of the checks uses large scores, so none can tell the two apart. A test with scores in the hundreds would catch it; none was written, and the page says so rather than counting the mutant as caught.

7. Why was every intermediate result bound with its own `let`, instead of writing each gradient as a function as in Chapter 34?

    **Answer.** Because Mountain Goat expands a function call in place wherever it is used, so a quantity used by several later gradients is recomputed for each, and the work multiplies with depth; the generated code also never frees memory. The nested version was killed, most likely for lack of memory. Binding each intermediate with `let` computes it once.

---

## Chapter 36

*(from [36. Training Chapter 30's Transformer: Two Heads, Two Blocks, and a Result That Is Not Better](../part36/36-training-chapter-30s-transformer.md))*

1. Why does the gradient with respect to `u1` have six terms in this model and three in Chapter 35's?

    **Answer.** `u1` feeds the query, key and value maps of every head. With one head that is three routes; with two heads it is six. A quantity that influences the loss along several routes receives the **sum** of the gradients along them (the chain rule for fan-out), so each head contributes its own `dq @ wqᵀ + dk @ wkᵀ + dv @ wvᵀ` and the two are added.

2. What does block 2's backward pass hand to block 1's?

    **Answer.** The gradient with respect to its **input**, which is block 1's **output** (`dX1`). Block 2's backward pass starts from the gradient arriving at its output (from the final layer norm), runs the feed-forward residual, then attention, and returns `dx1 + ln_back(du1, …)`: the direct residual route plus the route through the layer norm and the heads. Block 1 treats it as the gradient at its own output. The last thing returned is the gradient with respect to the embedded input.

3. The two-block model reaches a training loss of 0.0031 and 64 of 64 correct. Does that show it has learned the task?

    **Answer.** No. On the 16 held-out sequences it gets 40 of 64 and a loss of 2.33 (guessing uniformly gives 1.39), and over all 64 sequences it gets 184 of 256. Fitting the training data shows the optimization works; it does not show the rule was found. Compare Chapter 35's model, which on the same data got 256 of 256.

4. The sweep shows the gap closing when the training set doubles. Does that prove the gap is a data-size effect?

    **Answer.** It supports it but does not prove it: with 32 sequences the two-block model reaches 128 of 128 for two seeds, 125 for a third and still only 108 for a fourth. Also, the one-block and two-block models differ in blocks, heads, head width and learning rate at once, and none of these was varied alone. The result says more data helps this model; it does not say the extra capacity is the cause of the gap.

5. One mutant (no row-sum correction in one head's softmax backward) passed the finite-difference check even over 36 weights. How can a wrong gradient pass?

    **Answer.** The finite-difference estimate has a resolution: a step of 0.001 and six printed digits limit how small a disagreement it can see, about 10⁻³ here, and the gradient entries are of order 10⁻². A mistake confined to one head of one block changes the gradient by 4.7·10⁻⁴, below the threshold. The reference comparison works at a relative 10⁻⁵ and sees it. It is the reason this book keeps an independent reference implementation and does not rely on finite differences alone.

6. Chapter 35's run was chaotic and this one is not. What should you conclude about the next model?

    **Answer.** Nothing without measuring: it is a property of each model and each starting point, found by `sensitivity.py`, and cheap to measure (a minute or two in plain Python). It decides whether a check may compare digit for digit at every checkpoint or must compare claims after the transition.

7. Why does this program take about 40 minutes, when Chapter 35's took about eight?

    **Answer.** It is a larger program (29,552 lines against 12,455), and the compile stage (`mg-opt`) ran at 100% of a core for over thirty minutes in an observed run, so the cost grows faster than the size. Why was **not** investigated. The measurement is from one machine and one run, with other jobs sharing the machine for part of it.

---

## Chapter 37

*(from [37. Inside the LLVM Stage: Reading the IR, and Why a Loop Does or Does Not Vectorize](../part37/37-inside-the-llvm-stage.md))*

1. Why does LLVM refuse to vectorize `sum = sum + a * b` but vectorize `c[j] = c[j] + x * b[j]`?

    **Answer.** The first is a reduction: vectorizing it computes several partial sums and adds them at the end, in a different order than the program wrote, and floating-point addition is not associative, so the result could differ in the last digits. LLVM keeps exactly the program's order unless a `reassoc` flag allows otherwise. The second updates a different element each iteration, so the iterations are independent and doing four at once changes no individual result.

2. The `fadd` in the IR has no flags. Where would a C programmer have gotten them, and why did `-ffast-math` do nothing here?

    **Answer.** When clang compiles C or C++ source, `-ffast-math` makes the *front end* put fast-math flags (`reassoc`, `nnan`, …) on the instructions it generates. `mgc` generates its instructions through MLIR, with no flags, and then clang is handed a finished `.ll` file; clang's optimizer reads the flags that are there and does not add any. The assembly with and without the option was byte for byte identical. The flag has to be on the instruction in the IR (`fadd reassoc double`, or `fastmath<reassoc>` in MLIR).

3. With `reassoc` the ijk loop was vectorized. Why was it not faster?

    **Answer.** The loop reads `b` down a column, one element per row, so a vector of four consecutive `k` values has to be gathered from four different rows (the assembly has 16 `vgather` instructions where ikj has none). The vectorized loop moves the same scattered data a scalar loop would. The timings (0.64 against 0.67 GFLOP/s at N = 512) say the arithmetic was not the bottleneck. This is an inference from the instruction counts and the timings; cache misses were not measured.

4. What does `llvm-mca` model, and what did the experiment show about its limits?

    **Answer.** It models the CPU core: instruction latencies, issue ports and dispatch width, with every load assumed to hit the L1 cache. It ranked ikj above ijk correctly (0.29 against 3.02 cycles per multiply-add) but predicted that vectorizing ijk would be 15 times better (0.20), which the measurement contradicted, because the strided column walk (the real limit) is a memory-system effect it does not simulate.

5. What does the `contract` flag allow, and why does LLVM need to be told?

    **Answer.** It allows a `fmul` followed by a `fadd` to be fused into one fused multiply-add (`vfmadd`), which rounds once instead of twice and so can give a slightly different result. Without the flag LLVM must keep two roundings. C compilers grant it by default for C source (`-ffp-contract=on`), which is why it is rarely noticed; a `.ll` file generated from MLIR has no flags. With the flag the ikj loop became `vfmadd` instructions and ran about 24% faster at N = 512 (and showed no clear gain at N = 256).

6. In `ops_table_out.txt`, `exp` has no packed arithmetic. What does the assembly do instead, and why does that matter for the transformer chapters?

    **Answer.** It calls the C library's `exp` once per element: LLVM has no vector version of it to use. Softmax in every attention head (Chapters 29 to 36) computes `exp` over the whole score matrix (112 × 112 per head in Chapters 35 and 36), so those calls are a large part of the work that the matrix products' loop-order tuning does not touch. This chapter did not measure how large.

7. The chapter's first `opt` experiment showed 0 vector lines for every pass. What was wrong?

    **Answer.** `opt` was run without a target (`-mtriple`, `-mcpu`), so it had no description of the machine's vector instructions and the vectorizer had nothing to vectorize with. With `-mtriple=x86_64-unknown-linux-gnu -mcpu=native` the same passes vectorize. One of the six wrong inputs in `claims_mutation.py` reproduces this on purpose, and the checker catches it.

---

## Chapter 38

*(from [38. Why Compile Time Was Quadratic, and a Pass That Outlines Loop Nests](../part38/38-outlining-loop-nests.md))*

1. How did the chapter find which stage and which pass made the compile slow?

    **Answer.** It timed each `mgc` stage separately at several program sizes (the `lower` stage grew faster than the rest), then used `mg-opt --mlir-timing`, which reports time per pass (one pass, `SCFToControlFlow`, took 64% of the lowering), then timed that pass alone against the number of loops.

2. What does the synthetic experiment show, and what does it not show?

    **Answer.** It shows the cost depends on how many loops one function holds: the same 32,000 loop nests take 88 s in one function and 0.4 s in functions of 500. It does not show why: the cause inside MLIR (for instance repeated block splitting) was not identified, and the growth was not a clean power law.

3. Why does the pass clone `arith.constant` operations into the outlined function instead of passing them as arguments?

    **Answer.** So that two nests that differ only in where their constants were defined still print the same and are deduplicated into one function. A constant passed as an argument would also work, but every nest would then have its own argument list and the calls would carry values that never change. Cloning also keeps constants such as `2.0` visible inside the loop body, where later passes can fold them.

4. `a + a` and `a + b` on the same shapes become two different outlined functions. Why, and is that a bug?

    **Answer.** The key is the printed function. `a + a` uses one input twice, so its function has one input plus the output; `a + b` has two inputs. They print differently, so they are different functions. It is not incorrect (each computes the right thing); it only means two functions where one might do. Matching by structure rather than by text would merge them, at the cost of a more complicated pass.

5. One mutation, "the original loop nest is not erased", passed the output comparison. Why, and what caught it?

    **Answer.** Leaving the original nest in `main` runs each computation twice, writing the same values to the same memref, so the printed result is unchanged for these elementwise programs. The structural test counts the `affine.for` left after outlining (8 for Example 1, not 78), and the pass test checks the IR, so both see the leftover loops. An output comparison alone could not.

6. Why is the pass off by default?

    **Answer.** Turning it on would change the IR of every program with at least 32 top-level loop nests, and the earlier chapters' tests and recorded outputs were written against the old IR. Its benefit appears only for very large programs such as the unrolled training steps, so `--outline` is an opt-in; a default would be a separate, deliberate change.

7. The timings here come from single runs. How does that limit what the chapter can say?

    **Answer.** Differences of a few percent (such as the 0.4 s against 0.5 s run time at 32 steps) are not evidence of anything. The large effects (88 s against 0.4 s; 60 s against 14 s; about 40 minutes against 94 s) are far outside run-to-run noise, so the conclusions drawn from them stand; the claim that outlining costs "nothing visible" at run time rests on a single small measurement and is only suggestive.

---

## Chapter 39

*(from [39. Finding the Quadratic: a Differential Profile of the Lowering Pass](../part39/39-finding-the-quadratic.md))*

1. Why count instructions with `callgrind` instead of timing the pass?

    **Answer.** Instruction counts are exact and repeatable (the same every run), per function; a stopwatch gives one noisy number per run and cannot say which function is responsible. Running at several sizes and comparing each function's count turns "the pass is slow" into "this function grows ×4 when everything else grows ×2".

2. In the table, the whole program grows ×2.06 per doubling but one function grows ×3.99. What does each number tell you?

    **Answer.** The whole-program number says the program is *about* linear overall (most of the work scales with the size). The function's ×3.99 says it alone is quadratic; at these sizes it is still a small share of the total instructions (512 of 3,092 million at 8,000 loops), so the total's growth is only slightly above ×2 and creeps up (1.98, 2.06, 2.16) as the quadratic part takes a larger share.

3. What does `Block::splitBlock` do, and why does lowering a long run of loops make it quadratic?

    **Answer.** It cuts a block in two at an operation and moves all later operations to a new block, updating each moved operation's parent pointer. Lowering a loop to branches needs a new block for the code after it, so each loop's lowering moves everything behind it. With *n* loops in one function, the first moves about *n* nests' worth of operations, the next *n* − 1, and so on: about *n*²/2 in total.

4. After `--mg-outline-loops`, `splitBlock` is absent from the profile. Why?

    **Answer.** Outlining replaces each top-level loop nest with a call, so the big function contains no loops left to lower (its loops are in the small outlined functions, which are few, and each is a short block). With no loop to lower in the big block, `SCFToControlFlow` never splits it.

5. The same 32,000 loops took 88 s in one function and 0.4 s in functions of 500 (Chapter 38). How does this chapter account for the difference, and what does it leave unexplained?

    **Answer.** In functions of 500 each split moves at most a few hundred nests' worth of operations, so the total is linear in the number of loops; in one function it is quadratic, and the quadratic part misses the cache. What it does not explain is the exact wall-clock factors (9.0, 9.7, 4.8, 3.6): the instruction count grows ×4 cleanly, but the time per moved operation changes with the working-set size, which was not measured.

6. Why can this chapter's tests run in CI when they depend on a profiler?

    **Answer.** They check exact instruction counts, not times, so they give the same answer on any machine, and CI installs `valgrind`. A timing-based test of the same claim would depend on the machine's speed and load and would be flaky.

---

## Chapter 40

*(from [40. A Model of a Matrix Accelerator: Tiles, a Scratchpad, and What Loop Order Does There](../part40/40-a-model-of-a-matrix-accelerator.md))*

1. Why is the plain `1 × 1` schedule so much worse than `4 × 4`, with the same arithmetic?

    **Answer.** The arithmetic is identical (4,096 tile products) but `1 × 1` loads two tiles per product (8,448 tiles moved in all) while `4 × 4` loads eight tiles for sixteen products (2,304 moved). With the DMA at 20 cycles per tile, the plain schedule keeps the DMA busy for 98% of 173,056 cycles while the matrix unit idles at 19%; `4 × 4` reuses each loaded tile four times.

2. When does a blocked schedule stop being memory-bound on GA-1?

    **Answer.** When a step's products take at least as long as its loads: `8 · bi · bj ≥ 20 · (bi + bj)`. That holds first at `4 × 8` among the shapes tried (256 against 240 cycles per step); at `4 × 4` it fails (128 against 160), which is why `4 × 4` is DMA-bound at exactly tiles × 20 cycles and `4 × 8` reaches 88% utilization. The thresholds follow from the invented parameters; other ratios would move them.

3. What does double buffering need, and what does it buy?

    **Answer.** A second set of A and B slots (`bi + bj` more), so that the DMA can load step `k + 1` while the matrix unit works on step `k`. It buys overlap: 18% at `1 × 1`, 27% at `4 × 4`, 41% at `4 × 8`. It buys almost nothing when the DMA is already saturated by a single buffer, and it can make a schedule not fit: with 16 slots the best choice was `2 × 4` single buffered.

4. Why is the `k`-outermost order 10 times slower?

    **Answer.** The accumulator does not stay on chip. For every `k` each tile of C is loaded from DRAM, updated by one product and stored again: 16,128 tiles moved against 1,792 for `4 × 8`, and the DMA queue, being in order, also stalls behind each store that waits for its product. It is the same lesson as Chapter 24's `ijk` against `ikj`, here with the accumulator in off-chip memory instead of a cache line.

5. The checker's hazard replay and the results check are separate. What does each catch that the other cannot?

    **Answer.** Results are computed in program order, so they cannot reveal a timing hazard: a simulator that lets a load overwrite a slot too early still produces the right numbers. Only the replay of the recorded start and finish times (written independently of the timing rule) sees it. Conversely, the replay says nothing about whether a tile was padded or multiplied correctly; the results check does.

6. What does the chapter's bandwidth sweep say, and why must it be read with care?

    **Answer.** That in GA-1 the fixed per-transfer setup (16 cycles) dominates a 64-word tile, so a faster bus changes little (the gap between plain and blocked stays about 4×) but a smaller setup helps a lot. It must be read with care because setup and bandwidth are invented numbers: it shows how to ask the question and what shape the answer takes, not what any real device does.

7. Name three things GA-1 does not model that would matter on a real accelerator.

    **Answer.** Any of: a real memory hierarchy (banks, contention, row buffers, more than one DMA channel), instruction fetch and decode, energy and area, numerical formats such as 8-bit integers or 16-bit floats, sparsity, non-square or differently sized tiles, and launch overhead from a host. The chapter lists these as limits.

---

## Chapter 41

*(from [41. Compiling Mountain Goat to GA-1: Fusion, Tiling and Why Decoding Is Memory-Bound](../part41/41-compiling-mountain-goat-to-ga-1.md))*

1. Why does the front end's output contain the same `exp(x - row_max(x))` several times, and what does CSE do on GA-1?

    **Answer.** The front end expands a call to the softmax definition each time it is used, and the definition mentions `exp(x - row_max(x))` twice. The IR therefore holds identical operations. On GA-1 each repetition is loads, vector instructions and stores; merging them takes the stable softmax from 1,854 to 1,194 cycles.

2. What does fusion save, and what does it not?

    **Answer.** It saves the stores and loads of intermediates that nothing else needs: the result of the subtraction stays in a scratchpad slot. It does not save stores of values that later kernels read (the exponentials, needed by the sum and the division), which is why 22 kernels become 13 rather than fewer.

3. Why do 1, 2, 4 and 8 tokens take the same number of cycles through the feed-forward network?

    **Answer.** The weight tiles (720 of them) dominate and are streamed once for any number of tokens up to a tile's 8 rows; the matrix unit's rows for the extra tokens were being padded anyway. The DMA is 100% busy, so more rows cost nothing until they exceed 8.

4. The tool reports "useful" utilization separately from utilization. Why?

    **Answer.** A padded tile multiplies zeros at full speed, so counting padded multiply-adds makes a one-token matmul look as busy as an eight-token one. Useful utilization counts only the multiply-adds the program asked for, so it rises in proportion to the tokens: 3.6%, 7.1%, 14.2%, 28.4%. The mutant that counts padding is caught.

5. Two of the fourteen mutants are "caught" by a crash. Why does the page call that weaker?

    **Answer.** A crash proves the checker noticed something was badly wrong, but not that it would notice a subtle wrong answer of the same kind. A mismatch against the CPU result is evidence the checker compares numbers.

6. What would a back end need in order to remove the 41% of DMA time spent on elementwise kernels?

    **Answer.** Fusion across kernels with matmuls and reductions: keeping an attention score tile in the scratchpad from the matmul through the softmax into the next matmul. This back end ends every group at a matmul or a reduction and stores the result to DRAM, so it cannot.

7. Name three limits of the claims on this page.

    **Answer.** Any of: the machine is invented, so cycle counts are not a prediction for a real device; the sizes are tiny; the back end is not an MLIR pass and parses printed text; nothing with dynamic shapes or rank other than 2 is accepted; the tile-block choice trusts Chapter 40's analytic model; results are close to, not identical to, the CPU's.

---

## Chapter 42

*(from [42. Lowering the Loops Last to First: Testing the Idea Chapter 39 Left Open](../part42/42-lowering-loops-last-to-first.md))*

1. Why does lowering the loops from last to first avoid the quadratic?

    **Answer.** Lowering a loop splits its block there and moves everything behind it. First to last, loop *i* has all the later unlowered nests behind it, so about *n*²/2 are moved in all. Last to first, what is behind a loop is already lowered (it left a branch and its blocks live elsewhere), so each split moves only the few operations between two loops.

2. The two wrong orders are caught only by the instruction count, not by any output check. Why?

    **Answer.** MLIR's patterns give the same lowering of each loop whatever the order; only how long it takes differs. The output of a pass with the wrong order is still byte-identical. Only a measurement of cost can see that the speed-up has gone.

3. Why does the hand-written `edge_cases.mlir` matter when 107 book programs already agree?

    **Answer.** The front end only produces plain loops, so none of the book's programs has a top-level `scf.if` or `scf.while`, or loops with results used later. The mutants that skip those statements are caught only by the hand-written file.

4. The new pass is about 1% more expensive at 2,000 loops. Why, and what does that say about when to use it?

    **Answer.** It runs one conversion per top-level statement, and each conversion has a fixed price, while the quadratic part it removes is only 5% of the instructions at that size. It pays off for functions with many top-level loops (the gap opens from 4,000 loops) and costs a little for small ones, so it should be chosen by size or accepted as a small tax.

5. What does the nested-loops experiment show, and what would be needed to fix it?

    **Answer.** One outer loop with *n* inner loops takes the same time under both passes (about 24 seconds at 16,000), because the pass reorders only top-level statements. Fixing it means lowering inner loops last to first as well, but a lowered inner loop leaves the outer loop's body with several blocks, which an `scf.for` cannot have, so the order of conversion has to change more than this pass does.

6. The 2,106-second figure should be read with care. Why?

    **Answer.** It is one run, made while other work was running on the same four cores. It supports "about 35 minutes", consistent with the roughly 40 minutes Chapter 36 measured for compile and run together, not a figure to the second.

7. Name two things this chapter does not establish.

    **Answer.** Any of: why the new pass and the control both grow by about 2.5× per doubling at the top of the table; why `clang -O0` is slower on outlined input; that the outputs match for every possible `scf` program; whether the same change would be accepted into MLIR; any benefit for loops nested in one body.

---

## Chapter 43

*(from [43. Outlining by Default: What the Calls Cost, and Which Defaults Changed](../part43/43-outlining-by-default.md))*

1. Why does the chapter rely on instruction counts and not on wall-clock time for the cost of the calls?

    **Answer.** Instruction counts under callgrind are exact and repeatable; wall-clock time here varied by 40% between runs of the same executable (3.1 to 4.3 seconds), more than any effect being measured, and two measurements of the same comparison disagreed in sign (1.10 and 0.91).

2. What does 34 extra instructions per call mean for a loop nest that does hundreds of thousands of instructions of work?

    **Answer.** Nothing measurable: 34 instructions are the call itself, passing the memref descriptors as arguments, and the return, against a body that runs hundreds of thousands. Over 1,928 calls it is 66,050 extra instructions in a program of 489 million (0.0135%).

3. The `-O2` build executes 8.2% more instructions when outlined. What was ruled out and what was not tested?

    **Answer.** Ruled out as the explanation: a loss of vectorization (1,390 against 1,396 vectorized loops) and the library calls (identical counts). Not tested: that clang optimizes across neighbouring loop nests in one big function (forwarding stores, merging allocations) and cannot across a call. The cause is not established.

4. Why did the new defaults not require changing any earlier chapter's tests?

    **Answer.** Each chapter's tests run that chapter's own copy of the `mgc` driver, and Chapter 43's new defaults are only in `part43/code/mgc`. The older drivers still behave as they did, so everything recorded earlier reproduces.

5. Why is "the default lowering order is flipped back" caught only by the check of which passes are asked for?

    **Answer.** Because the lowering order does not change the printed output (Chapter 42 showed byte-identical IR), so no output comparison can see it. Only a check on the arguments passed to `mg-opt`, or a measurement of cost, can notice the speed-up has gone.

6. Name three limits of the claims of this chapter.

    **Answer.** Any of: the 8% at `-O2` is unexplained and measured on one program; `-O3` and the 200-step program at `-O2` were not measured; wall-clock time was not resolved; compile times are single runs on one machine; the default check covers every third example, not all; debuggability of the generated function names was not studied.

---

## Chapter 44

*(from [44. Fast-Math Flags from the Compiler: What Reordering Is Allowed to Buy, and What It Did](../part44/44-fast-math-flags.md))*

1. Why did Chapter 37's `-ffast-math` experiment on a `.ll` file do nothing, and what does this chapter do instead?

    **Answer.** Fast-math flags are properties of individual LLVM instructions. `-ffast-math` is an option of the C front end of clang that sets them on the instructions it generates from C; a `.ll` file already contains the instructions and clang does not rewrite them. The compiler that writes the IR has to put the flags on the operations, which is what `--mg-set-fastmath` does.

2. What do `reassoc` and `contract` allow, and why those two and not `-ffast-math`'s whole set?

    **Answer.** `reassoc` allows regrouping sums and products, which is what lets the dot-product loop be vectorized; `contract` allows a multiply and an add to become one fused multiply-add. Both change rounding. `nnan` and `ninf` change the meaning of NaN and infinity, which Mountain Goat's softmax examples rely on; the negative control shows `nnan` turning `ge(p, p)` for a NaN `p` from 0 to 1.

3. The 109 book programs print the same with `nnan,ninf`. Why is that not evidence the flags are safe?

    **Answer.** It only shows that none of those programs has a computation on which LLVM exploited the assumption. The negative control, written specifically to depend on NaN behaviour, changes its answer at `-O2`. A test that passes on programs that never exercise the risk says nothing about the risk.

4. Why did the vectorized ijk loop not run faster, and what is the evidence?

    **Answer.** With sizes known at run time, LLVM guards the vectorized loop with a check that the stride is 1; ijk reads the second matrix down a column, so the check fails and the scalar loop runs. At `-O2` every result element is bit-identical with and without the flags (a vectorized sum in another order would differ), although the object file contains packed adds. This does not explain the remaining timing differences, and static sizes were not benchmarked.

5. What reproduced as a speed-up, and why?

    **Answer.** ikj at `-O3 -march=native`: 17% to 24% faster in both passes (ratios 0.76 to 0.91, with N = 64 at 0.84 and 0.97). The cause is `contract`: the machine has a fused multiply-add, and the inner loop does one instruction where it did two. The loop was already vectorized, so it is not about vectorization.

6. With `-march=native`, 88% to 89% of the matrix-product results differ in their bits with the flags. Is the answer worse?

    **Answer.** Not by the measure used: the largest error against an 80-bit reference stays at the same size (8.1 × 10⁻¹⁷ against 9.3 × 10⁻¹⁷ at N = 512), and a fused multiply-add rounds once instead of twice. The bits are different, which matters for a program that compares outputs exactly or amplifies tiny differences, as Chapter 35's chaotic run does.

7. Name three things this chapter does not establish.

    **Answer.** Any of: whether the flag changes a 200-step training run (neither the `-O2` compile in 29 minutes nor the `-O1` compile in 40 minutes finished); the speed for statically known sizes; how often `nnan` changes an answer (one program only); the effect of the other flags (`ninf`, `nsz`, `arcp`, `afn`); why the timings of the ijk builds differ at all when their results are bit-identical; per-operation instead of module-wide flags.

---

## Chapter 45

*(from [45. Automatic Differentiation: Letting the Compiler Write the Backward Pass](../part45/45-automatic-differentiation.md))*

1. Why does reverse mode walk the operations backwards, and what happens to a value that is used twice?

    **Answer.** The derivative of the loss with respect to an operation's result must be complete before it can be turned into contributions to that operation's inputs; walking the operations in reverse order guarantees that every operation after it has already contributed. A value used by several operations receives the **sum** of their contributions (the chain rule over all the paths from it to the loss): `x * x * x` gives `x` three contributions.

2. Derive by hand what `autograd.py` wrote for `col_sum(row_sum(relu(x @ w) * 2.0))` and say why `ge(v1, 0)` appears.

    **Answer.** The loss's adjoint is `[[1]]`; `col_sum` and `row_sum` spread it over the elements they summed (`ones * g`); `* 2.0` multiplies by 2; `relu` passes the adjoint where its input was positive, which is `ge(x @ w, 0)` as a 0/1 mask; `matmul` gives `g @ transpose(w)` to `x` and `transpose(x) @ g` to `w`. With `x @ w = [[-2.5, -3], [5, 8]]`, only the second row is positive, so the gradient with respect to `w` is `[[4, 4], [2, 2]]`.

3. Why does the checker compare against a plain-Python reference instead of only against Chapters 33 to 35?

    **Answer.** The hand-derived programs of those chapters do not use every operation: six of the 24 wrong versions (`k - x`, `k / x`, negation, reshape, a column broadcast, ties in a maximum) pass all three chapters' comparisons and are caught only by the small programs and the tie test. The reference also shares no code with the rules, so a mistake in a rule cannot be hidden by the same mistake in the reference.

4. What does a tie in a maximum do to the gradient rule, and why share the gradient?

    **Answer.** `row_max` has no derivative where two entries are equal. Sharing the gradient equally between the tied entries keeps the total over the row equal to the incoming gradient, so a softmax built as `exp(x - row_max(x))` still has a gradient that is unchanged by shifting `x`. Giving each tied entry the full gradient breaks that (the total becomes larger), which the tie test catches.

5. The generated backward pass of Chapter 33 runs in half the instructions of the hand-derived one, and that of Chapter 35 in 11% more. Why the difference?

    **Answer.** Chapter 33's hand-derived gradients are separate functions that each recompute the forward pass, so the program does the forward work several times; the generated program does it once. Chapter 35's hand-derived backward pass shares its intermediates, so the comparison is between two programs that both do the forward pass once, and the generated one pays for not simplifying (for example, spelling out each step of the layer-norm gradient).

6. What does it mean that the generated gradients equal the hand-derived ones, and what does it not mean?

    **Answer.** It means two independent derivations (a person's, and a mechanical one) agree on every printed element of 16 gradient matrices, so they are both very probably right. It does not mean they are identical to the last bit (the programs add in different orders and print six digits), and it does not say anything about operations the chapters never used.

7. Name three limits of the claims on this page.

    **Answer.** Any of: rank 2 and static shapes only; the loss must be a 1 × 1 first `print`; no gradient flows through comparisons; the independent finite-difference reference covers only the ten small programs; the transformation reads printed IR with regular expressions; the 200-step training programs were not attempted; second derivatives were not tried; the generated program keeps all forward values alive.

---

## Chapter 46

*(from [46. Second Derivatives: Differentiating the Backward Pass Again](../part46/46-second-derivatives.md))*

1. Why differentiate `sum(g * v)` and not `g` itself?

    **Answer.** `autograd.py` differentiates a **scalar** loss. The gradient `g` is a matrix, so its derivative with respect to `p` is a whole Jacobian (the Hessian). Taking the dot product with a fixed direction `v` turns it into a scalar whose gradient is `H v`, one matrix-vector product's worth of information, which is all many algorithms need.

2. A first-order checker passes a mutant that lets gradients flow through `ge`. Why, and why does the second-order checker catch it?

    **Answer.** A first-order backward pass only *contains* `ge` (as the relu mask); nothing differentiates through it, so the mutant's wrong rule is never used. In the second pass the mask is part of the program being differentiated, so the rule is used and the mutant produces a nonzero contribution where the correct answer is zero.

3. The first version of the test did not catch a relu mask that is always 1. What was wrong with the test, and how was it fixed?

    **Answer.** It used `relu(x)²`, in which the relu output is already zero wherever the mask would have mattered, so the mask was invisible. Adding `relu(x) * exp(x)`, whose gradient involves the mask directly, makes the wrong mask change the answer.

4. Why is the sum-rule mutant not caught at second order?

    **Answer.** For the programs here, the un-spread adjoint (1 × 1 or N × 1) is always combined with a product or quotient, and Mountain Goat broadcasts it there, so the result is the same as with the spread. It only fails where the adjoint is used alone (as in Chapter 45's reshape program). So the check must be done by Chapter 45's checker; this one does not cover it.

5. What does a Hessian's largest eigenvalue tell you about the learning rate, and how well did that hold here?

    **Answer.** For a quadratic loss, gradient descent converges iff `lr < 2/λ`. For Chapter 33's loss with respect to all four trainable matrices, the loss fell at every step at 0.25, 0.5 and 0.9 times `2/λ` and exploded at 1.1 times: a sharp threshold, with Chapter 33's learning rate 3.0 at about 0.76 of it. For the output matrix `wo0` alone the rule held loosely (the loss rose at some step already at 0.9 times). Both λ estimates had not fully converged (lower bounds), so `2/λ` is an upper bound on each.

6. Name three things this chapter does not establish.

    **Answer.** Any of: the full Hessian or its eigenvalues by another method; third derivatives; the cost of the double-differentiated program; behaviour exactly at a kink; coverage of the sum-spread rule by this checker; learning-rate behaviour beyond one run from one starting point.

---

