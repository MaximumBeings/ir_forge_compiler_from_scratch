# 6. Real Bufferization: Closing Chapter 4's Own Honest Gap

<p style="text-align:center"><img src="../assets/goats/ch-06.svg" alt="Mountain goats on the mountain in a storm" style="max-width:100%;height:auto;border-radius:6px"></p>

**What you will understand:** how to make MLIR's own real, built-in `--one-shot-bufferize` pass genuinely succeed on a custom dialect, by implementing the real `BufferizableOpInterface` -- the exact extension point Chapter 4 named but did not use, when it ran into a real, honest failure (`error: op was not bufferized`) and deferred the fix. This chapter closes that gap for real, and the result is a second, entirely independent way to get Mountain Goat's own tensor IR down to memrefs -- not a replacement for Chapter 4's hand-written pass, a second real path, compared directly against the first.

**What you need to know first:** Chapter 4's own `ConvertMgToAffinePass` and its real negative result against `--one-shot-bufferize`; Chapter 3's own constant-folding discussion; Chapter 5's own `printMemrefF64` mechanism, reused directly in this chapter rather than reinvented.

!!! tip "Compile and run"
    ```sh
    cd docs/part6/code
    ./build.sh        # -> ./build/mg-opt (with the bufferization models)
    ./run.sh          # one-shot-bufferize on the examples, then lower and run
    ```
    Same prerequisites as Chapter 5. Every listing and output on this page comes from these commands (and the chapter's own embedded files).


## The real question this chapter answers

Chapter 4 cited MLIR's own real documentation stating plainly what `BufferizableOpInterface` requires (`bufferizesToMemoryRead`, `bufferizesToMemoryWrite`, at minimum) and predicted, without yet testing it, that implementing the real interface would be *more* work than the hand-written `ConvertMgToAffinePass` -- because One-Shot Bufferize's own whole-function analysis asks each op to correctly answer questions about aliasing and in-place reuse that a simple, always-allocate-fresh pass never has to consider. This chapter tests that prediction directly: implement the real interface for all four `mg` operations, and find out, by actually running it, whether `--one-shot-bufferize` now succeeds -- and what, concretely, the extra work turned out to be.

## Four real external models, one per operation

MLIR's own real mechanism for attaching an interface to an operation *after* it is already defined -- exactly Mountain Goat's own situation, since `mg`'s ODS definitions (Chapter 2) were written before this chapter existed -- is an "external model," registered once via a `DialectRegistry` extension rather than baked into the `.td` file itself.

### `mg.constant`: the simplest real case

```cpp
struct ConstantOpInterface
    : public BufferizableOpInterface::ExternalModel<ConstantOpInterface,
                                                     mg::ConstantOp> {
  bool bufferizesToAllocation(Operation *op, Value value) const {
    return true;
  }

  LogicalResult bufferize(Operation *op, RewriterBase &rewriter,
                          const BufferizationOptions &options) const {
    auto constantOp = cast<mg::ConstantOp>(op);
    auto loc = op->getLoc();
    auto tensorType =
        cast<RankedTensorType>(constantOp.getResult().getType());
    auto memrefType =
        MemRefType::get(tensorType.getShape(), tensorType.getElementType());
    auto alloc = rewriter.create<memref::AllocOp>(loc, memrefType);

    llvm::SmallVector<double> values;
    for (auto v : constantOp.getValue().getValues<llvm::APFloat>())
      values.push_back(v.convertToDouble());

    auto shape = tensorType.getShape();
    int64_t idx = 0;
    for (int64_t i = 0; i < shape[0]; ++i) {
      for (int64_t j = 0; j < shape[1]; ++j) {
        Value cst = rewriter.create<arith::ConstantOp>(
            loc, rewriter.getF64FloatAttr(values[idx++]));
        Value iIdx = rewriter.create<arith::ConstantIndexOp>(loc, i);
        Value jIdx = rewriter.create<arith::ConstantIndexOp>(loc, j);
        rewriter.create<affine::AffineStoreOp>(loc, cst, alloc,
                                               ValueRange{iIdx, jIdx});
      }
    }

    replaceOpWithBufferizedValues(rewriter, op, alloc.getResult());
    return success();
  }
};
```

`mg.constant` has no tensor *operands* at all -- only a result, produced from an attribute it already owns outright. `bufferizesToAllocation` returning `true` is this chapter's own first real, required answer: it tells One-Shot Bufferize's own analysis that this value is a genuinely fresh buffer, never aliasing anything else in the function. The `bufferize()` body itself is, element for element, the same real logic as Chapter 4's own `ConstantOpLowering` -- a different real entry point into MLIR's own machinery, not different work.

### `mg.add` and `mg.transpose`: real answers about reading, writing, and aliasing

```cpp
struct AddOpInterface
    : public BufferizableOpInterface::ExternalModel<AddOpInterface,
                                                     mg::AddOp> {
  bool bufferizesToMemoryRead(Operation *op, OpOperand &opOperand,
                              const AnalysisState &state) const {
    return true;
  }
  bool bufferizesToMemoryWrite(Operation *op, OpOperand &opOperand,
                               const AnalysisState &state) const {
    return false;
  }
  bool bufferizesToAllocation(Operation *op, Value value) const {
    return true;
  }
  AliasingValueList getAliasingValues(Operation *op, OpOperand &opOperand,
                                      const AnalysisState &state) const {
    return {};
  }

  LogicalResult bufferize(Operation *op, RewriterBase &rewriter,
                          const BufferizationOptions &options) const {
    auto addOp = cast<mg::AddOp>(op);
    auto loc = op->getLoc();

    FailureOr<Value> lhsBuffer = getBuffer(rewriter, addOp.getLhs(), options);
    if (failed(lhsBuffer))
      return failure();
    FailureOr<Value> rhsBuffer = getBuffer(rewriter, addOp.getRhs(), options);
    if (failed(rhsBuffer))
      return failure();

    auto tensorType = cast<RankedTensorType>(addOp.getResult().getType());
    auto memrefType =
        MemRefType::get(tensorType.getShape(), tensorType.getElementType());
    auto alloc = rewriter.create<memref::AllocOp>(loc, memrefType);
    auto shape = tensorType.getShape();

    affine::buildAffineLoopNest(
        rewriter, loc, {0, 0}, {shape[0], shape[1]}, {1, 1},
        [&](OpBuilder &nestedBuilder, Location nestedLoc, ValueRange ivs) {
          Value lhsVal = nestedBuilder.create<affine::AffineLoadOp>(
              nestedLoc, *lhsBuffer, ivs);
          Value rhsVal = nestedBuilder.create<affine::AffineLoadOp>(
              nestedLoc, *rhsBuffer, ivs);
          Value sum =
              nestedBuilder.create<arith::AddFOp>(nestedLoc, lhsVal, rhsVal);
          nestedBuilder.create<affine::AffineStoreOp>(nestedLoc, sum, alloc,
                                                      ivs);
        });

    replaceOpWithBufferizedValues(rewriter, op, alloc.getResult());
    return success();
  }
};
```

Four real, specific claims, each one load-bearing for the analysis, not boilerplate: `bufferizesToMemoryRead` (true -- `mg.add` genuinely reads through both operands), `bufferizesToMemoryWrite` (false -- it never writes through either operand's own buffer), `bufferizesToAllocation` (true -- its result is always a fresh buffer), and `getAliasingValues` (empty -- the result aliases neither operand). One real, concrete consequence of getting any of these wrong: a `false` answer where `true` was required could let One-Shot Bufferize's own analysis permit an in-place reuse that silently corrupts a buffer still needed elsewhere -- exactly why MLIR's own documentation, cited in Chapter 3, insists these methods "must be implemented conservatively."

`getBuffer(rewriter, addOp.getLhs(), options)` is the one real, new API this chapter needed that Chapter 4's own `ConversionPatternRewriter`-based code never did -- Chapter 4's `adaptor.getLhs()` already handed back the converted operand directly, a convenience of the dialect-conversion framework specifically; One-Shot Bufferize's own `bufferize()` hook has to ask explicitly for each operand's own buffer.

`mg.transpose`'s own real interface implementation is the same shape, with one operand instead of two and the same index-swap between load and store Chapter 4 already established -- omitted here for space, included in full in this chapter's own real code.

### `mg.print`: reusing Chapter 5's own real mechanism, not reinventing it

```cpp
struct PrintOpInterface
    : public BufferizableOpInterface::ExternalModel<PrintOpInterface,
                                                     mg::PrintOp> {
  bool bufferizesToMemoryRead(Operation *op, OpOperand &opOperand,
                              const AnalysisState &state) const {
    return true;
  }
  bool bufferizesToMemoryWrite(Operation *op, OpOperand &opOperand,
                               const AnalysisState &state) const {
    return false;
  }
  AliasingValueList getAliasingValues(Operation *op, OpOperand &opOperand,
                                      const AnalysisState &state) const {
    return {};
  }

  LogicalResult bufferize(Operation *op, RewriterBase &rewriter,
                          const BufferizationOptions &options) const {
    auto printOp = cast<mg::PrintOp>(op);
    auto loc = op->getLoc();
    FailureOr<Value> inputBuffer =
        getBuffer(rewriter, printOp.getInput(), options);
    if (failed(inputBuffer))
      return failure();

    auto module = op->getParentOfType<ModuleOp>();
    auto printRef = getOrInsertPrintMemrefF64(rewriter, module);
    auto memrefType = cast<MemRefType>(inputBuffer->getType());
    auto unrankedType =
        UnrankedMemRefType::get(memrefType.getElementType(), /*memorySpace=*/0);
    Value cast =
        rewriter.create<memref::CastOp>(loc, unrankedType, *inputBuffer);
    rewriter.create<func::CallOp>(loc, printRef, TypeRange{}, ValueRange{cast});
    rewriter.eraseOp(op);
    return success();
  }
};
```

`getOrInsertPrintMemrefF64` is, verbatim, Chapter 5's own real helper -- declaring `@printMemrefF64` with the real `llvm.emit_c_interface` attribute. Reaching for it again here, rather than writing a second version, is itself the real point: once a real mechanism for calling into MLIR's own runtime support library exists, any later real pass -- hand-written conversion or interface-based bufferization alike -- can reuse it directly.

## Registering the four real external models

```cpp
namespace mg {
void registerBufferizableOpInterfaceExternalModels(DialectRegistry &registry) {
  registry.addExtension(+[](MLIRContext *ctx, MgDialect *dialect) {
    ConstantOp::attachInterface<ConstantOpInterface>(*ctx);
    AddOp::attachInterface<AddOpInterface>(*ctx);
    TransposeOp::attachInterface<TransposeOpInterface>(*ctx);
    PrintOp::attachInterface<PrintOpInterface>(*ctx);
  });
}
} // namespace mg
```

```cpp
mg::registerBufferizableOpInterfaceExternalModels(registry);
mlir::bufferization::func_ext::registerBufferizableOpInterfaceExternalModels(
    registry);
```

The second line is a real gap this chapter hit directly, the same way Chapter 4 hit the `func.func` signature-conversion gap: registering `mg`'s own four interfaces was not enough to bufferize a function taking real tensor *arguments* -- `func.func` itself needs its own real external model too, which MLIR already ships, in `mlir/Dialect/Bufferization/Transforms/FuncBufferizableOpInterfaceImpl.h`, simply not registered by default.

## Real worked example: the negative result from Chapter 4, reversed

Chapter 4's own exact real test, re-run against this chapter's own rebuilt `mg-opt`:

```mlir
func.func @main() {
  %0 = mg.constant dense<[[1.0, 2.0], [3.0, 4.0]]> : tensor<2x2xf64>
  %1 = mg.constant dense<[[5.0, 6.0], [7.0, 8.0]]> : tensor<2x2xf64>
  %2 = mg.add %0, %1 : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  %3 = mg.transpose %2 : tensor<2x2xf64> to tensor<2x2xf64>
  mg.print %3 : tensor<2x2xf64>
  func.return
}
```

```
./mg-opt mountain_goat_const.mlir --one-shot-bufferize
```

**Real captured output (relevant excerpt -- full output is longer):**
```mlir
module {
  func.func @main() {
    %alloc = memref.alloc() : memref<2x2xf64>
    ... (four affine.store ops writing 1.0, 2.0, 3.0, 4.0)
    %alloc_9 = memref.alloc() : memref<2x2xf64>
    ... (four affine.store ops writing 5.0, 6.0, 7.0, 8.0)
    %alloc_22 = memref.alloc() : memref<2x2xf64>
    affine.for %arg0 = 0 to 2 {
      affine.for %arg1 = 0 to 2 {
        %0 = affine.load %alloc[%arg0, %arg1] : memref<2x2xf64>
        %1 = affine.load %alloc_9[%arg0, %arg1] : memref<2x2xf64>
        %2 = arith.addf %0, %1 : f64
        affine.store %2, %alloc_22[%arg0, %arg1] : memref<2x2xf64>
      }
    }
    %alloc_23 = memref.alloc() : memref<2x2xf64>
    affine.for %arg0 = 0 to 2 {
      affine.for %arg1 = 0 to 2 {
        %0 = affine.load %alloc_22[%arg1, %arg0] : memref<2x2xf64>
        affine.store %0, %alloc_23[%arg0, %arg1] : memref<2x2xf64>
      }
    }
    return
  }
}
```

Where Chapter 4 reported `error: op was not bufferized`, this chapter's own rebuilt tool now genuinely succeeds -- the real, documented fix (implement `BufferizableOpInterface`) genuinely closes the real gap it was named for.

## A real, honest surprise: no constant-folding this time

Chapter 4's own hand-written `--convert-mg-to-affine` genuinely folded the `mg.add` of two constants away before ever emitting a loop, because MLIR's dialect-conversion driver tries an operation's own `fold()` hook before reaching for a `ConversionPattern`. The real captured output directly above shows a genuine `affine.for` loop nest for the exact same constant-operand `mg.add` -- meaning One-Shot Bufferize's own driver did not fold it away first. This is a real, structural difference between the two real frameworks, not a bug in either: dialect conversion (`applyPartialConversion`) is built around *legalizing* operations, for which trying a cheaper `fold()` first is a natural optimization; One-Shot Bufferize's own driver is built around a *bufferization* analysis and rewrite, which has no equivalent reason to also attempt unrelated constant folding along the way. Running `--canonicalize` before `--one-shot-bufferize` would fold the add away here too -- the two passes' own real responsibilities simply do not overlap the same way dialect conversion's own legalization does.

## A second real, honest difference: function-argument buffer types

Bufferizing a function taking real tensor arguments surfaces one more real, concrete difference between the two approaches:

```
./mg-opt mountain_goat_run.mlir --one-shot-bufferize="bufferize-function-boundaries"
```

**Real captured output (excerpt):**
```mlir
func.func @add_tensors(%arg0: memref<2x2xf64, strided<[?, ?], offset: ?>>,
                       %arg1: memref<2x2xf64, strided<[?, ?], offset: ?>>) {
  ...
}
```

Chapter 4's own hand-written `MgToAffineTypeConverter` always produced a plain `memref<2x2xf64>` for a converted argument. One-Shot Bufferize's own real function-boundary conversion instead produces a `memref<2x2xf64, strided<[?, ?], offset: ?>>` -- a real, more general layout, because its own whole-program analysis cannot assume every real caller will pass a plain, contiguous buffer, and must allow for one that does not.

## Real worked example: genuinely re-running the full pipeline to the same real answer

The real test program designed, in Chapter 5, so the add's own loop survives (two functions, so no same-function constant folding chain exists regardless) -- carried this time through the entirely new bufferization path, then Chapter 5's own exact real `affine`-to-`llvm` pipeline, unmodified:

```mlir
func.func @add_tensors(%a: tensor<2x2xf64>, %b: tensor<2x2xf64>) {
  %0 = mg.add %a, %b : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  mg.print %0 : tensor<2x2xf64>
  func.return
}

func.func @main() {
  %0 = mg.constant dense<[[1.0, 2.0], [3.0, 4.0]]> : tensor<2x2xf64>
  %1 = mg.constant dense<[[5.0, 6.0], [7.0, 8.0]]> : tensor<2x2xf64>
  func.call @add_tensors(%0, %1) : (tensor<2x2xf64>, tensor<2x2xf64>) -> ()
  func.return
}
```

```
./mg-opt mountain_goat_run.mlir \
  --one-shot-bufferize="bufferize-function-boundaries" \
  --lower-affine --convert-scf-to-cf --convert-arith-to-llvm \
  --finalize-memref-to-llvm --convert-func-to-llvm \
  --reconcile-unrealized-casts \
  -o mountain_goat_llvm.mlir

mlir-cpu-runner-18 mountain_goat_llvm.mlir \
  --shared-libs=/usr/lib/llvm-18/lib/libmlir_runner_utils.so \
  --shared-libs=/usr/lib/llvm-18/lib/libmlir_c_runner_utils.so \
  -e main -entry-point-result=void
```

**Real captured output:**
```text
Unranked Memref base@ = 0x559b27f1d1f0 rank = 2 offset = 0 sizes = [2, 2] strides = [2, 1] data =
[[6,   8],
 [10,   12]]
```

The identical real, correct answer Chapter 5 produced through its own entirely different, hand-written `ConvertMgToAffinePass` -- genuinely confirmed here through a second, independent real path (MLIR's own production `--one-shot-bufferize`, Mountain Goat's own real `BufferizableOpInterface` implementations), reusing every later real stage of the pipeline (`--lower-affine` onward) completely unchanged.

## The complete source files

The excerpts above show the parts under discussion. These files appear in `code/` and are not shown elsewhere on this page; each is embedded exactly as it exists in the repository, collapsed so the narrative stays readable.

??? note "`CMakeLists.txt`"

    ```cmake
    --8<-- "docs/part6/code/CMakeLists.txt"
    ```

??? note "`MgBufferizableOpInterfaceImpl.cpp`"

    ```cpp
    --8<-- "docs/part6/code/MgBufferizableOpInterfaceImpl.cpp"
    ```

??? note "`mg-opt.cpp`"

    ```cpp
    --8<-- "docs/part6/code/mg-opt.cpp"
    ```

## What later chapters changed

Chapters 13 and 14 changed the bufferization models in `MgBufferizableOpInterfaceImpl.cpp`: they now handle dynamic shapes and emit the same runtime shape check as the hand-written path. Chapter 14 also found that any op a bufferization model creates needs its dialect loaded by the model's own registration (`cf` was registered but not loaded, which aborted `mg-opt`). The function-boundary strided layout this chapter found became observable in Chapter 13, where only this path could honor a column-major view. The version in this chapter's `code/` directory is the original.

## Chapter summary

This chapter closed Chapter 4's own honestly-stated gap: `BufferizableOpInterface` is now genuinely implemented for all four `mg` operations, via real external models (`ConstantOpInterface`, `AddOpInterface`, `TransposeOpInterface`, `PrintOpInterface`), and MLIR's own real, built-in `--one-shot-bufferize` pass now genuinely succeeds where it previously, honestly, failed. Chapter 4's own prediction -- that this would be more work than the hand-written pass, not less -- held up directly: four real methods per operation (`bufferizesToMemoryRead`/`Write`, `bufferizesToAllocation`, `getAliasingValues`), each a specific, conservative claim the whole-function analysis depends on, plus a second real gap (`func.func`'s own external model, not registered by default) this chapter hit the same way Chapter 4 hit its own signature-conversion gap. Two real, honest differences from Chapter 4's own hand-written path emerged directly from running the code, not predicted in advance: One-Shot Bufferize does not fold constant adds away the way dialect conversion did, and its own function-boundary conversion produces a more general, strided memref layout rather than a plain contiguous one. The chapter closed by running this entirely new path through Chapter 5's own unmodified `affine`-to-`llvm` pipeline and `mlir-cpu-runner-18`, producing the identical, real, correct answer Chapter 5 obtained through a completely different route.

Deliberately out of scope, stated explicitly: no real loop-level transform (fusion, tiling, unrolling) has been applied to any of Mountain Goat's own `affine.for` loops yet -- that, and the real reason canonicalization/CSE needs to run again at every IR level, remain Part 4's own next real subject.

## Self-check questions

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
