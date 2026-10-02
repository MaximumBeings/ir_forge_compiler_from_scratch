#map = affine_map<(d0) -> (d0)>
module {
  func.func private @printMemrefF64(memref<*xf64>) attributes {llvm.emit_c_interface}
  func.func @addt(%arg0: memref<?x?xf64>, %arg1: memref<?x?xf64>) -> memref<?x?xf64> {
    %c0 = arith.constant 0 : index
    %dim = memref.dim %arg0, %c0 : memref<?x?xf64>
    %c0_0 = arith.constant 0 : index
    %dim_1 = memref.dim %arg1, %c0_0 : memref<?x?xf64>
    %0 = arith.cmpi eq, %dim, %dim_1 : index
    cf.assert %0, "mg.add: operand shapes differ at runtime in dimension 0"
    %c1 = arith.constant 1 : index
    %dim_2 = memref.dim %arg0, %c1 : memref<?x?xf64>
    %c1_3 = arith.constant 1 : index
    %dim_4 = memref.dim %arg1, %c1_3 : memref<?x?xf64>
    %1 = arith.cmpi eq, %dim_2, %dim_4 : index
    cf.assert %1, "mg.add: operand shapes differ at runtime in dimension 1"
    %c0_5 = arith.constant 0 : index
    %dim_6 = memref.dim %arg0, %c0_5 : memref<?x?xf64>
    %c1_7 = arith.constant 1 : index
    %dim_8 = memref.dim %arg0, %c1_7 : memref<?x?xf64>
    %alloc = memref.alloc(%dim_6, %dim_8) : memref<?x?xf64>
    %c0_9 = arith.constant 0 : index
    affine.for %arg2 = #map(%c0_9) to #map(%dim_6) {
      affine.for %arg3 = #map(%c0_9) to #map(%dim_8) {
        %2 = affine.load %arg0[%arg2, %arg3] : memref<?x?xf64>
        %3 = affine.load %arg1[%arg2, %arg3] : memref<?x?xf64>
        %4 = arith.addf %2, %3 : f64
        affine.store %4, %alloc[%arg2, %arg3] : memref<?x?xf64>
      }
    }
    %c1_10 = arith.constant 1 : index
    %dim_11 = memref.dim %alloc, %c1_10 : memref<?x?xf64>
    %c0_12 = arith.constant 0 : index
    %dim_13 = memref.dim %alloc, %c0_12 : memref<?x?xf64>
    %alloc_14 = memref.alloc(%dim_11, %dim_13) : memref<?x?xf64>
    %c0_15 = arith.constant 0 : index
    affine.for %arg2 = #map(%c0_15) to #map(%dim_11) {
      affine.for %arg3 = #map(%c0_15) to #map(%dim_13) {
        %2 = affine.load %alloc[%arg3, %arg2] : memref<?x?xf64>
        affine.store %2, %alloc_14[%arg2, %arg3] : memref<?x?xf64>
      }
    }
    return %alloc_14 : memref<?x?xf64>
  }
  func.func @main() -> i32 {
    %alloc = memref.alloc() : memref<2x3xf64>
    %cst = arith.constant 1.000000e+00 : f64
    %c0 = arith.constant 0 : index
    %c0_0 = arith.constant 0 : index
    affine.store %cst, %alloc[%c0, %c0_0] : memref<2x3xf64>
    %cst_1 = arith.constant 2.000000e+00 : f64
    %c0_2 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    affine.store %cst_1, %alloc[%c0_2, %c1] : memref<2x3xf64>
    %cst_3 = arith.constant 3.000000e+00 : f64
    %c0_4 = arith.constant 0 : index
    %c2 = arith.constant 2 : index
    affine.store %cst_3, %alloc[%c0_4, %c2] : memref<2x3xf64>
    %cst_5 = arith.constant 4.000000e+00 : f64
    %c1_6 = arith.constant 1 : index
    %c0_7 = arith.constant 0 : index
    affine.store %cst_5, %alloc[%c1_6, %c0_7] : memref<2x3xf64>
    %cst_8 = arith.constant 5.000000e+00 : f64
    %c1_9 = arith.constant 1 : index
    %c1_10 = arith.constant 1 : index
    affine.store %cst_8, %alloc[%c1_9, %c1_10] : memref<2x3xf64>
    %cst_11 = arith.constant 6.000000e+00 : f64
    %c1_12 = arith.constant 1 : index
    %c2_13 = arith.constant 2 : index
    affine.store %cst_11, %alloc[%c1_12, %c2_13] : memref<2x3xf64>
    %alloc_14 = memref.alloc() : memref<2x3xf64>
    %cst_15 = arith.constant 1.000000e+01 : f64
    %c0_16 = arith.constant 0 : index
    %c0_17 = arith.constant 0 : index
    affine.store %cst_15, %alloc_14[%c0_16, %c0_17] : memref<2x3xf64>
    %cst_18 = arith.constant 2.000000e+01 : f64
    %c0_19 = arith.constant 0 : index
    %c1_20 = arith.constant 1 : index
    affine.store %cst_18, %alloc_14[%c0_19, %c1_20] : memref<2x3xf64>
    %cst_21 = arith.constant 3.000000e+01 : f64
    %c0_22 = arith.constant 0 : index
    %c2_23 = arith.constant 2 : index
    affine.store %cst_21, %alloc_14[%c0_22, %c2_23] : memref<2x3xf64>
    %cst_24 = arith.constant 4.000000e+01 : f64
    %c1_25 = arith.constant 1 : index
    %c0_26 = arith.constant 0 : index
    affine.store %cst_24, %alloc_14[%c1_25, %c0_26] : memref<2x3xf64>
    %cst_27 = arith.constant 5.000000e+01 : f64
    %c1_28 = arith.constant 1 : index
    %c1_29 = arith.constant 1 : index
    affine.store %cst_27, %alloc_14[%c1_28, %c1_29] : memref<2x3xf64>
    %cst_30 = arith.constant 6.000000e+01 : f64
    %c1_31 = arith.constant 1 : index
    %c2_32 = arith.constant 2 : index
    affine.store %cst_30, %alloc_14[%c1_31, %c2_32] : memref<2x3xf64>
    %cast = memref.cast %alloc : memref<2x3xf64> to memref<?x?xf64>
    %cast_33 = memref.cast %alloc_14 : memref<2x3xf64> to memref<?x?xf64>
    %0 = call @addt(%cast, %cast_33) : (memref<?x?xf64>, memref<?x?xf64>) -> memref<?x?xf64>
    %cast_34 = memref.cast %0 : memref<?x?xf64> to memref<*xf64>
    call @printMemrefF64(%cast_34) : (memref<*xf64>) -> ()
    %alloc_35 = memref.alloc() : memref<3x1xf64>
    %cst_36 = arith.constant 1.000000e+00 : f64
    %c0_37 = arith.constant 0 : index
    %c0_38 = arith.constant 0 : index
    affine.store %cst_36, %alloc_35[%c0_37, %c0_38] : memref<3x1xf64>
    %cst_39 = arith.constant 2.000000e+00 : f64
    %c1_40 = arith.constant 1 : index
    %c0_41 = arith.constant 0 : index
    affine.store %cst_39, %alloc_35[%c1_40, %c0_41] : memref<3x1xf64>
    %cst_42 = arith.constant 3.000000e+00 : f64
    %c2_43 = arith.constant 2 : index
    %c0_44 = arith.constant 0 : index
    affine.store %cst_42, %alloc_35[%c2_43, %c0_44] : memref<3x1xf64>
    %alloc_45 = memref.alloc() : memref<3x1xf64>
    %cst_46 = arith.constant 5.000000e-01 : f64
    %c0_47 = arith.constant 0 : index
    %c0_48 = arith.constant 0 : index
    affine.store %cst_46, %alloc_45[%c0_47, %c0_48] : memref<3x1xf64>
    %cst_49 = arith.constant 5.000000e-01 : f64
    %c1_50 = arith.constant 1 : index
    %c0_51 = arith.constant 0 : index
    affine.store %cst_49, %alloc_45[%c1_50, %c0_51] : memref<3x1xf64>
    %cst_52 = arith.constant 5.000000e-01 : f64
    %c2_53 = arith.constant 2 : index
    %c0_54 = arith.constant 0 : index
    affine.store %cst_52, %alloc_45[%c2_53, %c0_54] : memref<3x1xf64>
    %cast_55 = memref.cast %alloc_35 : memref<3x1xf64> to memref<?x?xf64>
    %cast_56 = memref.cast %alloc_45 : memref<3x1xf64> to memref<?x?xf64>
    %1 = call @addt(%cast_55, %cast_56) : (memref<?x?xf64>, memref<?x?xf64>) -> memref<?x?xf64>
    %cast_57 = memref.cast %1 : memref<?x?xf64> to memref<*xf64>
    call @printMemrefF64(%cast_57) : (memref<*xf64>) -> ()
    %c0_i32 = arith.constant 0 : i32
    return %c0_i32 : i32
  }
}

