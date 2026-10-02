// Chapter 30: mg.sqrt's own verifier rejects a result whose shape differs from its input, whatever front end built it.
// RUN: %mg-opt %s --split-input-file --verify-diagnostics

func.func @sqrt_changes_shape(%x: tensor<2x3xf64>) -> tensor<3x2xf64> {
  // expected-error @+1 {{mg.sqrt operands must have compatible shapes}}
  %r = mg.sqrt %x : tensor<2x3xf64> -> tensor<3x2xf64>
  return %r : tensor<3x2xf64>
}
