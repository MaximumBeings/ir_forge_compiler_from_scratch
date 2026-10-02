; LLVM IR written by hand: a function that returns the larger of two 32-bit integers.
define i32 @max(i32 %a, i32 %b) {
entry:
  %bigger = icmp sgt i32 %a, %b          ; %bigger is an i1 (a boolean): is a > b?
  %r = select i1 %bigger, i32 %a, i32 %b ; pick one of the two
  ret i32 %r
}
