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

def SubOp : Mg_Op<"sub", [Pure]> {
  let summary = "elementwise subtract of two compatible-shaped tensors (lhs - rhs)";
  let arguments = (ins F64Tensor:$lhs, F64Tensor:$rhs);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` type($lhs) `,` type($rhs) `->` type($result)";
  let hasVerifier = 1;
}

def MulOp : Mg_Op<"mul", [Pure]> {
  let summary = "elementwise (Hadamard) product of two compatible-shaped tensors";
  let arguments = (ins F64Tensor:$lhs, F64Tensor:$rhs);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` type($lhs) `,` type($rhs) `->` type($result)";
  let hasVerifier = 1;
}

def DivOp : Mg_Op<"div", [Pure]> {
  let summary = "elementwise division of two compatible-shaped tensors (lhs / rhs, IEEE: x/0 is inf or nan)";
  let arguments = (ins F64Tensor:$lhs, F64Tensor:$rhs);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` type($lhs) `,` type($rhs) `->` type($result)";
  let hasVerifier = 1;
}

def ScalarOp : Mg_Op<"scalar", [Pure]> {
  let summary = "combine every element with one scalar constant";
  let description = [{
    `op` is one of "add", "sub", "mul", "div". With `reversed = false` each element becomes
    `x OP value`; with `reversed = true` it becomes `value OP x` (so `10 - x` and `1 / x` exist).
    Works for any shape, including dynamic ones, because no second tensor is involved.
  }];
  let arguments = (ins F64Tensor:$input, StrAttr:$op, F64Attr:$value, BoolAttr:$reversed);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$input attr-dict `:` type($input) `->` type($result)";
  let hasVerifier = 1;
}

def ReluOp : Mg_Op<"relu", [Pure]> {
  let summary = "elementwise max(x, 0), the rectified linear unit";
  let arguments = (ins F64Tensor:$input);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$input attr-dict `:` type($input) `->` type($result)";
  let hasVerifier = 1;
}

def ExpOp : Mg_Op<"exp", [Pure]> {
  let summary = "elementwise e^x";
  let arguments = (ins F64Tensor:$input);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$input attr-dict `:` type($input) `->` type($result)";
  let hasVerifier = 1;
}

def SqrtOp : Mg_Op<"sqrt", [Pure]> {
  let summary = "elementwise square root (NaN for a negative input, as IEEE 754 says)";
  let arguments = (ins F64Tensor:$input);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$input attr-dict `:` type($input) `->` type($result)";
  let hasVerifier = 1;
}

def LogOp : Mg_Op<"log", [Pure]> {
  let summary = "elementwise natural logarithm (-inf for 0, NaN for a negative input, as IEEE 754 says)";
  let arguments = (ins F64Tensor:$input);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$input attr-dict `:` type($input) `->` type($result)";
  let hasVerifier = 1;
}

def ReduceOp : Mg_Op<"reduce", [Pure]> {
  let summary = "reduce a matrix along one axis with sum or max";
  let description = [{
    `axis = 1` combines the elements of each row, giving an M x 1 result; `axis = 0` combines the
    elements of each column, giving a 1 x N result. `kind` is "sum" or "max".
  }];
  let arguments = (ins F64Tensor:$input, I64Attr:$axis, StrAttr:$kind);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$input attr-dict `:` type($input) `->` type($result)";
  let hasVerifier = 1;
}

def BroadcastOp : Mg_Op<"broadcast", [Pure]> {
  let summary = "repeat a matrix along every dimension of size 1 to fill a larger static shape";
  let arguments = (ins F64Tensor:$input);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$input attr-dict `:` type($input) `->` type($result)";
  let hasVerifier = 1;
}

def NegOp : Mg_Op<"neg", [Pure]> {
  let summary = "elementwise negation";
  let arguments = (ins F64Tensor:$input);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$input attr-dict `:` type($input) `->` type($result)";
  let hasVerifier = 1;
}

def MatmulOp : Mg_Op<"matmul", [Pure]> {
  let summary = "matrix product: (m x k) times (k x n) gives (m x n)";
  let arguments = (ins F64Tensor:$lhs, F64Tensor:$rhs);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` type($lhs) `,` type($rhs) `->` type($result)";
  let hasVerifier = 1;
}

def TransposeOp : Mg_Op<"transpose", [Pure]> {
  let summary = "transpose of a 2-D tensor";
  let arguments = (ins F64Tensor:$input);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$input attr-dict `:` type($input) `to` type($result)";
  let hasVerifier = 1;
  let hasCanonicalizer = 1;
}

def ReshapeOp : Mg_Op<"reshape", [Pure]> {
  let summary = "view a static tensor as another static shape with the same number of elements (row-major, no data moves)";
  let arguments = (ins F64Tensor:$input);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$input attr-dict `:` type($input) `->` type($result)";
  let hasVerifier = 1;
}

def PermuteOp : Mg_Op<"permute", [Pure]> {
  let summary = "reorder the axes of a static tensor: result axis i is input axis permutation[i]";
  let arguments = (ins F64Tensor:$input, DenseI64ArrayAttr:$permutation);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$input attr-dict `:` type($input) `->` type($result)";
  let hasVerifier = 1;
}

def PrintOp : Mg_Op<"print"> {
  let summary = "print a tensor at runtime";
  let arguments = (ins F64Tensor:$input);
  let assemblyFormat = "$input attr-dict `:` type($input)";
}

#endif // MG_OPS_TD
