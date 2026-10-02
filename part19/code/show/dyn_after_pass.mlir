module {
  llvm.mlir.global private constant @mg_assert_stderr_msg_1("mg.add: operand shapes differ at runtime in dimension 0\0A") {addr_space = 0 : i32}
  llvm.func @abort()
  llvm.func @write(i32, !llvm.ptr, i64) -> i64
  llvm.mlir.global private constant @mg_assert_stderr_msg_0("mg.add: operand shapes differ at runtime in dimension 1\0A") {addr_space = 0 : i32}
  func.func @add_dyn(%arg0: memref<?x?xf64>, %arg1: memref<?x?xf64>) -> memref<?x?xf64> {
    %0 = llvm.mlir.constant(56 : i64) : i64
    %1 = llvm.mlir.constant(2 : i32) : i32
    %c1 = arith.constant 1 : index
    %c0 = arith.constant 0 : index
    %dim = memref.dim %arg0, %c0 : memref<?x?xf64>
    %dim_0 = memref.dim %arg1, %c0 : memref<?x?xf64>
    %2 = arith.cmpi eq, %dim, %dim_0 : index
    cf.cond_br %2, ^bb2, ^bb1
  ^bb1:  // pred: ^bb0
    %3 = llvm.mlir.addressof @mg_assert_stderr_msg_1 : !llvm.ptr
    %4 = llvm.call @write(%1, %3, %0) : (i32, !llvm.ptr, i64) -> i64
    llvm.call @abort() : () -> ()
    llvm.unreachable
  ^bb2:  // pred: ^bb0
    %dim_1 = memref.dim %arg0, %c1 : memref<?x?xf64>
    %dim_2 = memref.dim %arg1, %c1 : memref<?x?xf64>
    %5 = arith.cmpi eq, %dim_1, %dim_2 : index
    cf.cond_br %5, ^bb4, ^bb3
  ^bb3:  // pred: ^bb2
    %6 = llvm.mlir.addressof @mg_assert_stderr_msg_0 : !llvm.ptr
    %7 = llvm.call @write(%1, %6, %0) : (i32, !llvm.ptr, i64) -> i64
    llvm.call @abort() : () -> ()
    llvm.unreachable
  ^bb4:  // pred: ^bb2
    %dim_3 = memref.dim %arg0, %c0 : memref<?x?xf64>
    %dim_4 = memref.dim %arg0, %c1 : memref<?x?xf64>
    %alloc = memref.alloc(%dim_3, %dim_4) : memref<?x?xf64>
    affine.for %arg2 = 0 to %dim_3 {
      affine.for %arg3 = 0 to %dim_4 {
        %8 = affine.load %arg0[%arg2, %arg3] : memref<?x?xf64>
        %9 = affine.load %arg1[%arg2, %arg3] : memref<?x?xf64>
        %10 = arith.addf %8, %9 : f64
        affine.store %10, %alloc[%arg2, %arg3] : memref<?x?xf64>
      }
    }
    return %alloc : memref<?x?xf64>
  }
  func.func @t_dyn(%arg0: memref<?x?xf64>) -> memref<?x?xf64> {
    %c0 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    %dim = memref.dim %arg0, %c1 : memref<?x?xf64>
    %dim_0 = memref.dim %arg0, %c0 : memref<?x?xf64>
    %alloc = memref.alloc(%dim, %dim_0) : memref<?x?xf64>
    affine.for %arg1 = 0 to %dim {
      affine.for %arg2 = 0 to %dim_0 {
        %0 = affine.load %arg0[%arg2, %arg1] : memref<?x?xf64>
        affine.store %0, %alloc[%arg1, %arg2] : memref<?x?xf64>
      }
    }
    return %alloc : memref<?x?xf64>
  }
}

