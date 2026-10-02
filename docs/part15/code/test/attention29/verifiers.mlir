// Chapter 29: mg.exp's own verifier rejects a result whose shape differs from its input, whatever front end built it.
// RUN: %mg-opt %s --split-input-file --verify-diagnostics

func.func @exp_changes_shape(%x: tensor<2x3xf64>) -> tensor<3x2xf64> {
  // expected-error @+1 {{mg.exp operands must have compatible shapes}}
  %r = mg.exp %x : tensor<2x3xf64> -> tensor<3x2xf64>
  return %r : tensor<3x2xf64>
}
