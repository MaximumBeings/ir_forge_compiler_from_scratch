// Chapter 32: mg.ge's own verifier rejects operands of different shapes (and a result of a different shape), whatever front end built it.
// RUN: %mg-opt %s --split-input-file --verify-diagnostics

func.func @ge_shapes_differ(%a: tensor<2x3xf64>, %b: tensor<3x2xf64>) -> tensor<2x3xf64> {
  // expected-error @+1 {{mg.ge operands must have compatible shapes}}
  %r = mg.ge %a, %b : tensor<2x3xf64>, tensor<3x2xf64> -> tensor<2x3xf64>
  return %r : tensor<2x3xf64>
}
