// Chapter 9's C++ program, built from the chapter's own CMakeLists and run: it loads Chapter 8's lowered MLIR text and calls the
// function through MLIR's ExecutionEngine (a JIT). Needs cmake and the LLVM/MLIR development packages; takes about a minute.
// RUN: cmake -S %docs/part9/code -B %t.build -DMLIR_DIR=/usr/lib/llvm-18/lib/cmake/mlir -DLLVM_DIR=/usr/lib/llvm-18/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release > %t.cmake.log
// RUN: cmake --build %t.build -j4 > %t.build.log
// RUN: %t.build/run_engine %docs/part9/code/add_tensors_llvm.mlir | %FileCheck %s
// CHECK: add_tensors({{.*}}) =
// CHECK: 6 8
// CHECK: 10 12
