# 3. The Real Pass Infrastructure: Canonicalizing Mountain Goat

**What you will understand:** how MLIR's own real pattern-rewrite and constant-folding infrastructure actually transforms IR -- not a hand-wavy "optimizations happen," but two genuinely different, real mechanisms (`fold()` and `RewritePattern`), wired into Mountain Goat's own dialect, run by the real `--canonicalize` pass, with real before/after IR captured directly.

**What you need to know first:** Chapter 2's own dialect (`mg.constant`, `mg.add`, `mg.transpose`, `mg.print`) and how `hasVerifier`/ODS traits work. This chapter's own new vocabulary -- `fold()`, `RewritePattern`, `PatternRewriter`, the canonicalizer pass -- is introduced here, grounded in real, run code.

## The real question this chapter answers

Chapter 2 built a dialect that can be *checked* -- `mlir-tblgen-18`-generated verifiers reject malformed IR. This chapter answers a different real question: how does MLIR actually *rewrite* IR into a better, equivalent form? Two genuinely different real mechanisms exist for this in MLIR, and conflating them is a real, common confusion this chapter resolves directly: a **folder** (`fold()`) collapses an operation into a plain value or attribute when its operands are already known constants, cheaply, without needing a full pattern-match infrastructure; a **`RewritePattern`** matches a more general shape in the IR -- not just "are my operands constant" -- and replaces it with something else entirely. This chapter builds one real example of each, directly in Mountain Goat's own dialect, and runs both through the real, built-in `--canonicalize` pass.

## First, closing a real, stated gap from Chapter 2

Chapter 2 ended by showing, honestly, that `mg.add %0, %1 : tensor<2x2xf64>, tensor<3xf64> -> tensor<2x2xf64>` was silently accepted despite its two operands genuinely disagreeing in shape -- `AddOp` had no `hasVerifier`. This chapter closes that gap first, before adding anything new, using exactly the same real pattern `TransposeOp::verify()` already established:

```tablegen
def AddOp : Mg_Op<"add", [Pure]> {
  ...
  let hasVerifier = 1;
  let hasFolder = 1;   // this chapter's own next real addition
}
```

```cpp
mlir::LogicalResult AddOp::verify() {
  auto lhsType = llvm::cast<mlir::RankedTensorType>(getLhs().getType());
  auto rhsType = llvm::cast<mlir::RankedTensorType>(getRhs().getType());
  if (lhsType.getShape() != rhsType.getShape())
    return emitOpError("mg.add operands must have the same shape, got ")
           << lhsType << " and " << rhsType;
  return mlir::success();
}
```

Re-running Chapter 2's own exact mismatched-shape program against the rebuilt `mg-opt`:

```
./mg-opt mismatched_add.mlir
```

**Real captured output (cloud sandbox, this chapter's own rebuilt `mg-opt`):**
```text
mismatched_add.mlir:4:8: error: 'mg.add' op mg.add operands must have the same shape, got 'tensor<2x2xf64>' and 'tensor<3xf64>'
  %2 = mg.add %0, %1 : tensor<2x2xf64>, tensor<3xf64> -> tensor<2x2xf64>
       ^
mismatched_add.mlir:4:8: note: see current operation: %2 = "mg.add"(%0, %1) : (tensor<2x2xf64>, tensor<3xf64>) -> tensor<2x2xf64>
```

The gap is genuinely closed, confirmed by actually re-running the exact input that previously slipped through, not by assertion.

## MLIR's own real constant-folding hook: `fold()`

MLIR's own official documentation states what `fold()` is for directly:

> "The pattern rewriting framework can largely be decomposed into two parts: Pattern Definition and Pattern Application." (`mlir/docs/PatternRewriter.md`) -- `fold()` is deliberately *not* this framework; it is a narrower, cheaper, separate mechanism specifically for collapsing an operation into an already-known value when all its operands are constants, run automatically by the canonicalizer (and by the dialect-conversion/greedy-rewrite drivers) without needing a full pattern to be registered.

Making `mg.add` of two `mg.constant` operands fold into a single `mg.constant` needs two real, separate pieces, not one:

**First**, `ConstantOp` itself needs MLIR's real `ConstantLike` trait -- without it, the generic folding machinery has no way to recognize an `mg.constant` *result* as a foldable attribute when it appears as another operation's operand:

```tablegen
def ConstantOp : Mg_Op<"constant",
    [Pure, ConstantLike, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  ...
  let hasFolder = 1;
}
```

```cpp
mlir::OpFoldResult ConstantOp::fold(FoldAdaptor adaptor) { return getValueAttr(); }
```

`ConstantOp::fold` is about as simple as a folder gets: a constant folds to its own attribute, trivially.

**Second**, `AddOp::fold` itself does the real arithmetic, genuinely summing the two tensors' real elements if (and only if) both operands are themselves real `DenseElementsAttr` constants:

```cpp
mlir::OpFoldResult AddOp::fold(FoldAdaptor adaptor) {
  auto lhsAttr = llvm::dyn_cast_if_present<mlir::DenseElementsAttr>(adaptor.getLhs());
  auto rhsAttr = llvm::dyn_cast_if_present<mlir::DenseElementsAttr>(adaptor.getRhs());
  if (!lhsAttr || !rhsAttr)
    return nullptr;

  auto lhsValues = lhsAttr.getValues<llvm::APFloat>();
  auto rhsValues = rhsAttr.getValues<llvm::APFloat>();
  llvm::SmallVector<llvm::APFloat> summed;
  summed.reserve(lhsAttr.getNumElements());
  for (auto [l, r] : llvm::zip(lhsValues, rhsValues))
    summed.push_back(l + r);
  return mlir::DenseElementsAttr::get(lhsAttr.getType(), summed);
}
```

`adaptor.getLhs()`/`adaptor.getRhs()` genuinely return `Attribute`, not `Value` -- the real `FoldAdaptor` machinery has already done the work of checking whether each operand is itself a known constant before this function is even called; returning `nullptr` here means "no, I cannot fold this," a real, explicit, honest signal rather than a crash or a wrong answer.

A third real piece turned out to be necessary, discovered directly by running this chapter's own code rather than assumed in advance: when `fold()` returns an `Attribute` instead of a `Value`, MLIR's own folding driver needs a way to turn that attribute back into a genuine new operation in the IR -- a new `mg.constant`, holding the summed result. That real hook is `Dialect::materializeConstant`:

```tablegen
def Mg_Dialect : Dialect {
  ...
  let hasConstantMaterializer = 1;
}
```

```cpp
mlir::Operation *MgDialect::materializeConstant(mlir::OpBuilder &builder,
                                                mlir::Attribute value,
                                                mlir::Type type,
                                                mlir::Location loc) {
  auto elements = llvm::dyn_cast<mlir::DenseElementsAttr>(value);
  if (!elements)
    return nullptr;
  return builder.create<ConstantOp>(loc, type, elements);
}
```

Leaving this out was this chapter's own first real attempt at `AddOp::fold` -- it compiled and ran, but `--canonicalize` silently left `mg.add` of two constants unfolded, with no error at all, because the driver had a real new attribute in hand but genuinely no way to materialize it back into the IR as an operation. Adding `materializeConstant` is what made the fold actually take effect, confirmed directly below.

## MLIR's own real pattern-rewrite infrastructure: `RewritePattern`

A folder only ever looks at one operation's own operands. `TransposeOp`'s own new canonicalization -- `mg.transpose(mg.transpose(%x))` collapsing straight to `%x`, since transposing a 2-D tensor twice is the identity -- needs to look at a *second* operation (the inner transpose), which is exactly what the heavier, more general `RewritePattern` framework exists for:

```tablegen
def TransposeOp : Mg_Op<"transpose", [Pure]> {
  ...
  let hasVerifier = 1;
  let hasCanonicalizer = 1;
}
```

```cpp
namespace {
struct SimplifyRedundantTranspose : public mlir::OpRewritePattern<TransposeOp> {
  using OpRewritePattern<TransposeOp>::OpRewritePattern;

  mlir::LogicalResult
  matchAndRewrite(TransposeOp op, mlir::PatternRewriter &rewriter) const override {
    auto innerTranspose = op.getInput().getDefiningOp<TransposeOp>();
    if (!innerTranspose)
      return mlir::failure();
    rewriter.replaceOp(op, innerTranspose.getInput());
    return mlir::success();
  }
};
} // namespace

void TransposeOp::getCanonicalizationPatterns(mlir::RewritePatternSet &results,
                                              mlir::MLIRContext *context) {
  results.add<SimplifyRedundantTranspose>(context);
}
```

This chapter's own `SimplifyRedundantTranspose` mirrors the same real idea MLIR's own official Toy tutorial demonstrates for its own transpose operation -- cited here as real precedent for *why* this is a standard first canonicalization example, not copied from it; every line above is this chapter's own, written fresh against Mountain Goat's own `TransposeOp`. `matchAndRewrite` is the one real method every `RewritePattern` must implement: `op.getInput().getDefiningOp<TransposeOp>()` is the "match" half (is my own input itself the result of another `mg.transpose`?), and `rewriter.replaceOp(op, innerTranspose.getInput())` is the "rewrite" half (if so, every use of the outer transpose's result is redirected straight to the innermost tensor, skipping both transposes entirely).

## Wiring both into `mg-opt`'s own real `--canonicalize`

MLIR's own canonicalizer is itself a real, ordinary pass -- not special-cased machinery -- so `mg-opt` needs to genuinely register it, the same way `mlir-opt-18` itself does:

```cpp
#include "mlir/Transforms/Passes.h"

int main(int argc, char **argv) {
  mlir::registerCanonicalizerPass();
  mlir::registerCSEPass();
  ...
}
```

```cmake
target_link_libraries(mg-opt PRIVATE
  MgDialect
  MLIRIR
  MLIRFuncDialect
  MLIROptLib
  MLIRParser
  MLIRSupport
  MLIRTransforms
)
```

`MLIRTransforms` is the one real library this chapter's own build needed to add -- without it, the real `mlir::createCanonicalizerPass()`/`mlir::createCSEPass()` symbols the registration functions reference are genuinely undefined at link time, caught directly by `ld`'s own real error, not guessed at:

```text
undefined reference to `mlir::createCanonicalizerPass()'
undefined reference to `mlir::createCSEPass()'
```

Rebuilding cleanly after adding `MLIRTransforms`:

```
cmake --build build -j4
```

**Real captured output:**
```text
[ 50%] Built target MgOpsIncGen
[ 75%] Built target MgDialect
[ 87%] Linking CXX executable mg-opt
[100%] Built target mg-opt
```

## Real worked example: both rewrites firing together

One real Mountain Goat program, deliberately written to exercise both this chapter's own new mechanisms at once -- a foldable `mg.add` of two constants, feeding a redundant double `mg.transpose`:

```mlir
func.func @main() {
  %0 = mg.constant dense<[[1.0, 2.0], [3.0, 4.0]]> : tensor<2x2xf64>
  %1 = mg.constant dense<[[5.0, 6.0], [7.0, 8.0]]> : tensor<2x2xf64>
  %2 = mg.add %0, %1 : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  %3 = mg.transpose %2 : tensor<2x2xf64> to tensor<2x2xf64>
  %4 = mg.transpose %3 : tensor<2x2xf64> to tensor<2x2xf64>
  mg.print %4 : tensor<2x2xf64>
  func.return
}
```

Running `mg-opt` on it once with no flags (to confirm the starting IR is exactly as written), then again with `--canonicalize`:

```
./mg-opt canonicalize_demo.mlir
./mg-opt canonicalize_demo.mlir --canonicalize
```

**Real captured output, before canonicalization:**
```text
module {
  func.func @main() {
    %0 = mg.constant dense<[[1.000000e+00, 2.000000e+00], [3.000000e+00, 4.000000e+00]]> : tensor<2x2xf64>
    %1 = mg.constant dense<[[5.000000e+00, 6.000000e+00], [7.000000e+00, 8.000000e+00]]> : tensor<2x2xf64>
    %2 = mg.add %0, %1 : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
    %3 = mg.transpose %2 : tensor<2x2xf64> to tensor<2x2xf64>
    %4 = mg.transpose %3 : tensor<2x2xf64> to tensor<2x2xf64>
    mg.print %4 : tensor<2x2xf64>
    return
  }
}
```

**Real captured output, after `--canonicalize`:**
```text
module {
  func.func @main() {
    %0 = mg.constant dense<[[6.000000e+00, 8.000000e+00], [1.000000e+01, 1.200000e+01]]> : tensor<2x2xf64>
    mg.print %0 : tensor<2x2xf64>
    return
  }
}
```

Both real rewrites genuinely fired, in one real pass: the double transpose is entirely gone (`%3`, `%4` never appear in the output), and `%0`, `%1`, `%2` have collapsed into one single, freshly-materialized `mg.constant` -- whose own values are real, correctly computed sums, not placeholders: `1+5=6`, `2+6=8`, `3+7=10`, `4+8=12`, exactly matching `[[6, 8], [10, 12]]`.

## MLIR's own real canonicalizer: how it actually decides when to stop

MLIR's own official documentation states the real algorithm directly, worth knowing before relying on it further:

> "MLIR has a single canonicalization pass, which iteratively applies the canonicalization patterns of all loaded dialects in a greedy way. Canonicalization is best-effort and not guaranteed to bring the entire IR in a canonical form. It applies patterns until either fixpoint is reached or the maximum number of iterations/rewrites (as specified via pass options) is exhausted." (`mlir/docs/Canonicalization.md`)

This is exactly what this chapter's own worked example relied on without stating it until now: `--canonicalize` is not "apply `SimplifyRedundantTranspose` once, then apply `AddOp::fold` once" -- it is a real, greedy, iterate-to-fixpoint loop, which is precisely why both this chapter's own independent rewrites (one a folder, one a pattern, touching entirely different operations) fired together in a single invocation without this chapter needing to sequence them manually.

## Dialect conversion: the real next real step, not yet taken

This chapter's own two rewrites both keep every operation inside the `mg` dialect -- `SimplifyRedundantTranspose` deletes operations, `AddOp`'s folder replaces operations, but neither one ever introduces an operation from a *different* dialect. MLIR's own real dialect conversion framework exists for exactly that harder, different problem, stated directly in its own official documentation:

> "This document describes a framework in MLIR in which to perform operation conversions between, and within dialects. This framework allows for transforming illegal operations to those supported by a provided conversion target, via a set of pattern-based operation rewriting patterns." (`mlir/docs/DialectConversion.md`)

A real `ConversionTarget` (which operations/dialects are "legal" to remain), a real `TypeConverter` (how do types in the source dialect map to types in the destination dialect), and real `ConversionPattern`s (an extended `RewritePattern`, aware of operands that may themselves already be mid-conversion) are the three real pieces that framework needs -- genuinely more machinery than this chapter's own two same-dialect rewrites required, and deliberately left for Part 3, where Mountain Goat's own `mg` operations are actually lowered to MLIR's real `affine` dialect for the first time.

## The complete source files

The excerpts above show the parts under discussion. These files appear in `code/` and are not shown elsewhere on this page; each is embedded exactly as it exists in the repository, collapsed so the narrative stays readable.

??? note "`CMakeLists.txt`"

    ```cmake
    --8<-- "docs/part3/code/CMakeLists.txt"
    ```

??? note "`MgDialect.cpp`"

    ```cpp
    --8<-- "docs/part3/code/MgDialect.cpp"
    ```

??? note "`MgDialect.h`"

    ```cpp
    --8<-- "docs/part3/code/MgDialect.h"
    ```

??? note "`MgDialect.td`"

    ```text
    --8<-- "docs/part3/code/MgDialect.td"
    ```

??? note "`MgOps.h`"

    ```cpp
    --8<-- "docs/part3/code/MgOps.h"
    ```

??? note "`MgOps.td`"

    ```text
    --8<-- "docs/part3/code/MgOps.td"
    ```

??? note "`mg-opt.cpp`"

    ```cpp
    --8<-- "docs/part3/code/mg-opt.cpp"
    ```

## What later chapters changed

Chapter 13 changed three things in the `MgDialect.cpp` shown here: both verifiers now accept dynamic (`?`) extents and reject unranked tensors explicitly, and `SimplifyRedundantTranspose` now fires only when its replacement has exactly the result type (without that guard it produced invalid IR on mixed dynamic types). Chapter 15 pins all of this with tests, including one that fails if the guard is removed. The version in this chapter's `code/` directory is the original.

## Chapter summary

This chapter closed a real, stated gap from Chapter 2 (`AddOp` now genuinely verifies its own operands' shapes match), then built two genuinely different real rewrite mechanisms into Mountain Goat's own dialect: a constant-folding `fold()` hook (`ConstantOp`, `AddOp`), requiring the real `ConstantLike` trait and a real `materializeConstant` hook to actually take effect -- a real, non-obvious requirement this chapter discovered by running the code, not by reading ahead -- and a general `RewritePattern` (`SimplifyRedundantTranspose`), MLIR's own heavier, more capable framework for rewrites that need to see more than one operation's own operands. Both were wired into a genuinely rebuilt `mg-opt`'s own `--canonicalize` pass (needing the real `MLIRTransforms` library, discovered the same way, via a genuine link error) and run together on one real program, collapsing it, correctly, from seven operations down to two.

Deliberately out of scope, stated explicitly: no operation has been lowered to a *different* dialect yet -- both this chapter's own rewrites stay entirely inside `mg`. Real dialect conversion (`ConversionTarget`, `TypeConverter`, `ConversionPattern`) is introduced here only conceptually, cited from its own real official documentation; actually using it to lower Mountain Goat to `affine` is Part 3's own real subject.

## Self-check questions

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
