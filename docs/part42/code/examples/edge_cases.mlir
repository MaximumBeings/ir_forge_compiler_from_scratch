// Chapter 42: structured control flow that is NOT a plain run of loops, to see that lowering the top-level statements last to first still gives the right program:
// a loop with a result (iter_args) used by a later loop, an scf.if with results, an scf.while, loops nested inside loops, and a loop whose bounds come from an earlier result.
module {
  func.func private @printF64(f64)
  func.func private @printNewline()
  func.func @main() {
    %c0 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    %c5 = arith.constant 5 : index
    %c10 = arith.constant 10 : index
    %z = arith.constant 0.0 : f64
    %one = arith.constant 1.0 : f64
    // 1: a loop with a result: the sum 0+1+2+3+4 = 10
    %s = scf.for %i = %c0 to %c5 step %c1 iter_args(%acc = %z) -> (f64) {
      %fi = arith.index_cast %i : index to i64
      %f = arith.sitofp %fi : i64 to f64
      %n = arith.addf %acc, %f : f64
      scf.yield %n : f64
    }
    call @printF64(%s) : (f64) -> ()
    call @printNewline() : () -> ()
    // 2: an scf.if with a result that uses the result of loop 1: 10 > 5, so 1000
    %lim = arith.constant 5.0 : f64
    %cond = arith.cmpf ogt, %s, %lim : f64
    %pick = scf.if %cond -> (f64) {
      %big = arith.constant 1000.0 : f64
      scf.yield %big : f64
    } else {
      %small = arith.constant -1.0 : f64
      scf.yield %small : f64
    }
    call @printF64(%pick) : (f64) -> ()
    call @printNewline() : () -> ()
    // 3: an scf.while that doubles until the value passes 100, starting from 1: 128
    %w = scf.while (%v = %one) : (f64) -> f64 {
      %hundred = arith.constant 100.0 : f64
      %go = arith.cmpf olt, %v, %hundred : f64
      scf.condition(%go) %v : f64
    } do {
    ^bb0(%u: f64):
      %two = arith.constant 2.0 : f64
      %d = arith.mulf %u, %two : f64
      scf.yield %d : f64
    }
    call @printF64(%w) : (f64) -> ()
    call @printNewline() : () -> ()
    // 4: nested loops: 5 x 5 times adding 1, starting from the result of 3: 128 + 25 = 153
    %nest = scf.for %i = %c0 to %c5 step %c1 iter_args(%a0 = %w) -> (f64) {
      %inner = scf.for %j = %c0 to %c5 step %c1 iter_args(%a1 = %a0) -> (f64) {
        %n = arith.addf %a1, %one : f64
        scf.yield %n : f64
      }
      scf.yield %inner : f64
    }
    call @printF64(%nest) : (f64) -> ()
    call @printNewline() : () -> ()
    // 5: a loop whose upper bound is computed (from 4 steps of loop 1's count): 10 iterations adding the loop-2 pick, 153 + 10 * 1000 = 10153
    %last = scf.for %i = %c0 to %c10 step %c1 iter_args(%a2 = %nest) -> (f64) {
      %n = arith.addf %a2, %pick : f64
      scf.yield %n : f64
    }
    call @printF64(%last) : (f64) -> ()
    call @printNewline() : () -> ()
    return
  }
}
