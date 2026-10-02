// Chapter 28: the new operations' own verifiers reject bad IR, so even a front end that skipped its checks could not build an invalid reshape or permute.
// RUN: %mg-opt %s --split-input-file --verify-diagnostics

func.func @reshape_wrong_count(%x: tensor<2x3xf64>) -> tensor<4x2xf64> {
  // expected-error @+1 {{mg.reshape: 'tensor<2x3xf64>' has 6 elements but 'tensor<4x2xf64>' has 8}}
  %r = mg.reshape %x : tensor<2x3xf64> -> tensor<4x2xf64>
  return %r : tensor<4x2xf64>
}

// -----

func.func @reshape_dynamic(%x: tensor<?x3xf64>) -> tensor<3x3xf64> {
  // expected-error @+1 {{mg.reshape only supports static ranked tensors}}
  %r = mg.reshape %x : tensor<?x3xf64> -> tensor<3x3xf64>
  return %r : tensor<3x3xf64>
}

// -----

func.func @permute_repeats_an_axis(%x: tensor<2x3x4xf64>) -> tensor<2x2x4xf64> {
  // expected-error @+1 {{mg.permute: the permutation must list each axis exactly once}}
  %r = mg.permute %x {permutation = array<i64: 0, 0, 2>} : tensor<2x3x4xf64> -> tensor<2x2x4xf64>
  return %r : tensor<2x2x4xf64>
}

// -----

func.func @permute_wrong_result_shape(%x: tensor<2x3x4xf64>) -> tensor<2x3x4xf64> {
  // expected-error @+1 {{mg.permute: result axis 0 must have the size of input axis 2}}
  %r = mg.permute %x {permutation = array<i64: 2, 0, 1>} : tensor<2x3x4xf64> -> tensor<2x3x4xf64>
  return %r : tensor<2x3x4xf64>
}

// -----

func.func @permute_wrong_length(%x: tensor<2x3x4xf64>) -> tensor<3x2xf64> {
  // expected-error @+1 {{mg.permute: the permutation must list each of the 3 axes once}}
  %r = mg.permute %x {permutation = array<i64: 1, 0>} : tensor<2x3x4xf64> -> tensor<3x2xf64>
  return %r : tensor<3x2xf64>
}
