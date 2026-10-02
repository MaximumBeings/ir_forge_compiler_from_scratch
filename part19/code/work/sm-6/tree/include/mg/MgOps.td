#ifndef MG_OPS_TD
#define MG_OPS_TD

include "mg/MgDialect.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/IR/BuiltinAttributeInterfaces.td"

def ConstantOp : Mg_Op<"constant",
    [Pure, ConstantLike, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let summary = "dense tensor constant, Mountain Goat's own array literal";
  let description = [{
    The result type is never written out separately: it is inferred
    straight from the dense attribute's own type, since a constant's shape
    is already fully determined by its literal value. `dense<[[1.0, 2.0],
    [3.0, 4.0]]> : tensor<2x2xf64>` carries its own type, so repeating it
    after the op would just be the same fact spelled twice. The real
    `ConstantLike` trait is what lets MLIR's own generic constant-folding
    machinery recognize an `mg.constant` operand as a foldable attribute
    in the first place, rather than an opaque SSA value -- `AddOp::fold`
    below genuinely depends on it.
  }];
  let arguments = (ins F64ElementsAttr:$value);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$value attr-dict";
  let hasFolder = 1;
}

def AddOp : Mg_Op<"add", [Pure]> {
  let summary = "elementwise add of two equal-shaped tensors";
  let description = [{
    `hasVerifier = 1` closes a real, deliberately-left-open gap from this
    dialect's first chapter: without it, ODS's own `F64Tensor` constraint
    on `$lhs`/`$rhs` says nothing about the two operands' shapes agreeing
    with each other. `hasFolder = 1` additionally lets two real
    `mg.constant` operands be folded together at compile time into one
    `mg.constant`, through MLIR's own real constant-folding hook -- a
    second, distinct mechanism from `TransposeOp`'s own pattern-based
    canonicalization below.
  }];
  let arguments = (ins F64Tensor:$lhs, F64Tensor:$rhs);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` type($lhs) `,` type($rhs) `->` type($result)";
  let hasVerifier = 1;
  let hasFolder = 1;
}

def TransposeOp : Mg_Op<"transpose", [Pure]> {
  let summary = "transpose of a 2-D tensor";
  let arguments = (ins F64Tensor:$input);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$input attr-dict `:` type($input) `to` type($result)";
  let hasVerifier = 1;
  let hasCanonicalizer = 1;
}

def PrintOp : Mg_Op<"print"> {
  let summary = "print a tensor at runtime";
  let arguments = (ins F64Tensor:$input);
  let assemblyFormat = "$input attr-dict `:` type($input)";
}

#endif // MG_OPS_TD
