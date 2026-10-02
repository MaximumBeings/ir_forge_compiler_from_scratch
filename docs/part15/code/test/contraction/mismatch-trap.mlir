// The appendix's trap: with the axis check on, a mismatched pair is an exception. With the check SKIPPED, the mismatch reaches Mountain
// Goat's matrix product, whose own run-time check aborts with a message on stderr instead of silently computing a wrong answer.
// RUN: %mgc24 lib %cpp27/contract.mg -o %t.d
// RUN: %cxx -std=c++17 -Wall -Wextra -Werror -I%t.d -I%cpp27 %cpp27/contract_demo.cpp %t.d/contract.o -o %t.demo
// RUN: %t.demo trap | %FileCheck %s --check-prefix=CHECKED
// RUN: %not --crash %t.demo trap skip > %t.out 2> %t.err
// RUN: %FileCheck %s --input-file=%t.err --check-prefix=ABORT
// RUN: %FileCheck %s --input-file=%t.out --check-prefix=BEFORE
// CHECKED: caught std::invalid_argument: "contract: mismatched dimension on contracted axis pair 0 (A.shape[1]=2 vs B.shape[0]=4)"
// ABORT: mg.matmul: inner dimensions differ at runtime
// BEFORE: with the axis check SKIPPED
// BEFORE-NOT: not reached
