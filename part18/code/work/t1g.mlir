#map = affine_map<(d0, d1) -> (d0, d1)>
#map1 = affine_map<(d0) -> (d0)>
#map2 = affine_map<(d0, d1) -> (d1 + 4, d0)>
"builtin.module"() ({
  "func.func"() <{function_type = (memref<?x?xf64>, memref<?x?xf64>) -> memref<?x?xf64>, sym_name = "chain"}> ({
  ^bb0(%arg0: memref<?x?xf64>, %arg1: memref<?x?xf64>):
    %0 = "arith.constant"() <{value = 0 : index}> : () -> index
    %1 = "memref.dim"(%arg0, %0) : (memref<?x?xf64>, index) -> index
    %2 = "arith.constant"() <{value = 0 : index}> : () -> index
    %3 = "memref.dim"(%arg1, %2) : (memref<?x?xf64>, index) -> index
    %4 = "arith.cmpi"(%1, %3) <{predicate = 0 : i64}> : (index, index) -> i1
    "cf.assert"(%4) <{msg = "mg.add: operand shapes differ at runtime in dimension 0"}> : (i1) -> ()
    %5 = "arith.constant"() <{value = 1 : index}> : () -> index
    %6 = "memref.dim"(%arg0, %5) : (memref<?x?xf64>, index) -> index
    %7 = "arith.constant"() <{value = 1 : index}> : () -> index
    %8 = "memref.dim"(%arg1, %7) : (memref<?x?xf64>, index) -> index
    %9 = "arith.cmpi"(%6, %8) <{predicate = 0 : i64}> : (index, index) -> i1
    "cf.assert"(%9) <{msg = "mg.add: operand shapes differ at runtime in dimension 1"}> : (i1) -> ()
    %10 = "arith.constant"() <{value = 0 : index}> : () -> index
    %11 = "memref.dim"(%arg0, %10) : (memref<?x?xf64>, index) -> index
    %12 = "arith.constant"() <{value = 1 : index}> : () -> index
    %13 = "memref.dim"(%arg0, %12) : (memref<?x?xf64>, index) -> index
    %14 = "memref.alloc"(%11, %13) <{operandSegmentSizes = array<i32: 2, 0>}> : (index, index) -> memref<?x?xf64>
    %15 = "arith.constant"() <{value = 0 : index}> : () -> index
    "affine.for"(%15, %11) <{lowerBoundMap = #map1, operandSegmentSizes = array<i32: 1, 1, 0>, step = 4 : index, upperBoundMap = #map1}> ({
    ^bb0(%arg2: index):
      "affine.for"(%15, %13) <{lowerBoundMap = #map1, operandSegmentSizes = array<i32: 1, 1, 0>, step = 4 : index, upperBoundMap = #map1}> ({
      ^bb0(%arg3: index):
        "affine.for"(%arg2, %11, %arg2) <{lowerBoundMap = #map1, operandSegmentSizes = array<i32: 1, 2, 0>, step = 1 : index, upperBoundMap = #map2}> ({
        ^bb0(%arg4: index):
          "affine.for"(%arg3, %13, %arg3) <{lowerBoundMap = #map1, operandSegmentSizes = array<i32: 1, 2, 0>, step = 1 : index, upperBoundMap = #map2}> ({
          ^bb0(%arg5: index):
            %22 = "affine.load"(%arg0, %arg4, %arg5) <{map = #map}> : (memref<?x?xf64>, index, index) -> f64
            %23 = "affine.load"(%arg1, %arg4, %arg5) <{map = #map}> : (memref<?x?xf64>, index, index) -> f64
            %24 = "arith.addf"(%22, %23) <{fastmath = #arith.fastmath<none>}> : (f64, f64) -> f64
            "affine.store"(%24, %14, %arg4, %arg5) <{map = #map}> : (f64, memref<?x?xf64>, index, index) -> ()
            "affine.yield"() : () -> ()
          }) : (index, index, index) -> ()
          "affine.yield"() : () -> ()
        }) : (index, index, index) -> ()
        "affine.yield"() : () -> ()
      }) : (index, index) -> ()
      "affine.yield"() : () -> ()
    }) : (index, index) -> ()
    %16 = "arith.constant"() <{value = 1 : index}> : () -> index
    %17 = "memref.dim"(%14, %16) : (memref<?x?xf64>, index) -> index
    %18 = "arith.constant"() <{value = 0 : index}> : () -> index
    %19 = "memref.dim"(%14, %18) : (memref<?x?xf64>, index) -> index
    %20 = "memref.alloc"(%17, %19) <{operandSegmentSizes = array<i32: 2, 0>}> : (index, index) -> memref<?x?xf64>
    %21 = "arith.constant"() <{value = 0 : index}> : () -> index
    "affine.for"(%21, %17) <{lowerBoundMap = #map1, operandSegmentSizes = array<i32: 1, 1, 0>, step = 4 : index, upperBoundMap = #map1}> ({
    ^bb0(%arg2: index):
      "affine.for"(%21, %19) <{lowerBoundMap = #map1, operandSegmentSizes = array<i32: 1, 1, 0>, step = 4 : index, upperBoundMap = #map1}> ({
      ^bb0(%arg3: index):
        "affine.for"(%arg2, %17, %arg2) <{lowerBoundMap = #map1, operandSegmentSizes = array<i32: 1, 2, 0>, step = 1 : index, upperBoundMap = #map2}> ({
        ^bb0(%arg4: index):
          "affine.for"(%arg3, %19, %arg3) <{lowerBoundMap = #map1, operandSegmentSizes = array<i32: 1, 2, 0>, step = 1 : index, upperBoundMap = #map2}> ({
          ^bb0(%arg5: index):
            %22 = "affine.load"(%14, %arg5, %arg4) <{map = #map}> : (memref<?x?xf64>, index, index) -> f64
            "affine.store"(%22, %20, %arg4, %arg5) <{map = #map}> : (f64, memref<?x?xf64>, index, index) -> ()
            "affine.yield"() : () -> ()
          }) : (index, index, index) -> ()
          "affine.yield"() : () -> ()
        }) : (index, index, index) -> ()
        "affine.yield"() : () -> ()
      }) : (index, index) -> ()
      "affine.yield"() : () -> ()
    }) : (index, index) -> ()
    "func.return"(%20) : (memref<?x?xf64>) -> ()
  }) : () -> ()
}) : () -> ()

