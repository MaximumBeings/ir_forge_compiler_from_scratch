// Chapter 31: mg.log's own verifier rejects a result whose shape differs from its input, whatever front end built it.
// RUN: %mg-opt %s --split-input-file --verify-diagnostics

func.func @log_changes_shape(%x: tensor<2x3xf64>) -> tensor<3x2xf64> {
  // expected-error @+1 {{mg.log operands must have compatible shapes}}
  %r = mg.log %x : tensor<2x3xf64> -> tensor<3x2xf64>
  return %r : tensor<3x2xf64>
}
