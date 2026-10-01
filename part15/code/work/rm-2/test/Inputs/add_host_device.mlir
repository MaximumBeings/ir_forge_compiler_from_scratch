#map = affine_map<(d0)[s0, s1] -> ((d0 - s0) ceildiv s1)>
#map1 = affine_map<(d0)[s0, s1] -> (d0 * s0 + s1)>
module attributes {gpu.container_module} {
  func.func @add_tensors(%a: memref<2x2xf64>, %b: memref<2x2xf64>) -> memref<2x2xf64> {
    %da = gpu.alloc () : memref<2x2xf64>
    %db = gpu.alloc () : memref<2x2xf64>
    %dc = gpu.alloc () : memref<2x2xf64>
    gpu.memcpy %da, %a : memref<2x2xf64>, memref<2x2xf64>
    gpu.memcpy %db, %b : memref<2x2xf64>, memref<2x2xf64>
    %c0 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    %c2 = arith.constant 2 : index
    gpu.launch_func @add_tensors_kernel::@add_tensors_kernel blocks in (%c2, %c1, %c1) threads in (%c2, %c1, %c1) args(%c1 : index, %c0 : index, %da : memref<2x2xf64>, %db : memref<2x2xf64>, %dc : memref<2x2xf64>)
    %r = memref.alloc() : memref<2x2xf64>
    gpu.memcpy %r, %dc : memref<2x2xf64>, memref<2x2xf64>
    gpu.dealloc %da : memref<2x2xf64>
    gpu.dealloc %db : memref<2x2xf64>
    gpu.dealloc %dc : memref<2x2xf64>
    return %r : memref<2x2xf64>
  }
  gpu.module @add_tensors_kernel {
    gpu.func @add_tensors_kernel(%arg0: index, %arg1: index, %arg2: memref<2x2xf64>, %arg3: memref<2x2xf64>, %arg4: memref<2x2xf64>) kernel {
      %0 = gpu.block_id  x
      %1 = gpu.block_id  y
      %2 = gpu.block_id  z
      %3 = gpu.thread_id  x
      %4 = gpu.thread_id  y
      %5 = gpu.thread_id  z
      %6 = gpu.grid_dim  x
      %7 = gpu.grid_dim  y
      %8 = gpu.grid_dim  z
      %9 = gpu.block_dim  x
      %10 = gpu.block_dim  y
      %11 = gpu.block_dim  z
      cf.br ^bb1
    ^bb1:  // pred: ^bb0
      %12 = affine.apply #map1(%0)[%arg0, %arg1]
      %c0 = arith.constant 0 : index
      %c2 = arith.constant 2 : index
      %c1 = arith.constant 1 : index
      %c1_0 = arith.constant 1 : index
      %c0_1 = arith.constant 0 : index
      %13 = affine.apply #map1(%3)[%c1_0, %c0_1]
      %14 = memref.load %arg2[%12, %13] : memref<2x2xf64>
      %15 = memref.load %arg3[%12, %13] : memref<2x2xf64>
      %16 = arith.addf %14, %15 : f64
      memref.store %16, %arg4[%12, %13] : memref<2x2xf64>
      gpu.return
    }
  }
}

