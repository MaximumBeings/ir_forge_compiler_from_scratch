#map = affine_map<(d0)[s0, s1] -> (d0 * s0 + s1)>
module attributes {gpu.container_module} {
  func.func @add_tensors(%arg0: memref<2x2xf64>, %arg1: memref<2x2xf64>) -> memref<2x2xf64> {
    %0 = gpu.wait async
    %memref, %asyncToken = gpu.alloc async [%0] () : memref<2x2xf64>
    %memref_0, %asyncToken_1 = gpu.alloc async [%asyncToken] () : memref<2x2xf64>
    %memref_2, %asyncToken_3 = gpu.alloc async [%asyncToken_1] () : memref<2x2xf64>
    %1 = gpu.memcpy async [%asyncToken_3] %memref, %arg0 : memref<2x2xf64>, memref<2x2xf64>
    %2 = gpu.memcpy async [%1] %memref_0, %arg1 : memref<2x2xf64>, memref<2x2xf64>
    %c0 = arith.constant 0 : index
    %c1 = arith.constant 1 : index
    %c2 = arith.constant 2 : index
    %3 = gpu.launch_func async [%2] @add_tensors_kernel::@add_tensors_kernel blocks in (%c2, %c1, %c1) threads in (%c2, %c1, %c1)  args(%c1 : index, %c0 : index, %memref : memref<2x2xf64>, %memref_0 : memref<2x2xf64>, %memref_2 : memref<2x2xf64>)
    gpu.wait [%3]
    %alloc = memref.alloc() : memref<2x2xf64>
    %4 = gpu.wait async
    %5 = gpu.memcpy async [%4] %alloc, %memref_2 : memref<2x2xf64>, memref<2x2xf64>
    %6 = gpu.dealloc async [%5] %memref : memref<2x2xf64>
    %7 = gpu.dealloc async [%6] %memref_0 : memref<2x2xf64>
    %8 = gpu.dealloc async [%7] %memref_2 : memref<2x2xf64>
    gpu.wait [%8]
    return %alloc : memref<2x2xf64>
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
      %12 = affine.apply #map(%0)[%arg0, %arg1]
      %c0 = arith.constant 0 : index
      %c2 = arith.constant 2 : index
      %c1 = arith.constant 1 : index
      %c1_0 = arith.constant 1 : index
      %c0_1 = arith.constant 0 : index
      %13 = affine.apply #map(%3)[%c1_0, %c0_1]
      %14 = memref.load %arg2[%12, %13] : memref<2x2xf64>
      %15 = memref.load %arg3[%12, %13] : memref<2x2xf64>
      %16 = arith.addf %14, %15 : f64
      memref.store %16, %arg4[%12, %13] : memref<2x2xf64>
      gpu.return
    }
  }
}

