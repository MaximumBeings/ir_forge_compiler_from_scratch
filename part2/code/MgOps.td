#ifndef MG_OPS_TD
#define MG_OPS_TD

include "mg/MgDialect.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/IR/BuiltinAttributeInterfaces.td"

def ConstantOp : Mg_Op<"constant", [Pure, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let summary = "dense tensor constant, Mountain Goat's own array literal";
  let description = [{
    The result type is never written out separately: it is inferred
    straight from the dense attribute's own type, since a constant's shape
    is already fully determined by its literal value. `dense<[[1.0, 2.0],
    [3.0, 4.0]]> : tensor<2x2xf64>` carries its own type, so repeating it
    after the op would just be the same fact spelled twice.
  }];
  let arguments = (ins F64ElementsAttr:$value);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$value attr-dict";
}

def AddOp : Mg_Op<"add", [Pure]> {
  let summary = "elementwise add of two equal-shaped tensors";
  let arguments = (ins F64Tensor:$lhs, F64Tensor:$rhs);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` type($lhs) `,` type($rhs) `->` type($result)";
}

def TransposeOp : Mg_Op<"transpose", [Pure]> {
  let summary = "transpose of a 2-D tensor";
  let arguments = (ins F64Tensor:$input);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$input attr-dict `:` type($input) `to` type($result)";
  let hasVerifier = 1;
}

def PrintOp : Mg_Op<"print"> {
  let summary = "print a tensor at runtime";
  let arguments = (ins F64Tensor:$input);
  let assemblyFormat = "$input attr-dict `:` type($input)";
}

#endif // MG_OPS_TD
