#!/bin/sh
# Recomputes the numbers in Chapter 10's comparison table from the three PTX files. Output: compare_out.txt
cd "$(dirname "$0")"
printf "%-34s %8s %13s\n" file ".param" "instructions"
for f in add_tensors_mlir.ptx add_tensors_mlir_idx32.ptx cuda_add.ptx; do
  p=$(grep -cE '^[[:space:]]*\.param' $f)
  i=$(grep -cE '^[[:space:]]+(ld|st|mul|add|shl|cvt|mad|cvta|mov|ret)' $f)
  printf "%-34s %8s %13s\n" $f $p $i
done
echo
echo "memory operations in each file (global loads / stores):"
for f in add_tensors_mlir.ptx add_tensors_mlir_idx32.ptx cuda_add.ptx; do
  printf "%-34s %s loads, %s stores\n" $f $(grep -c 'ld.global.f64' $f) $(grep -c 'st.global.f64' $f)
done
