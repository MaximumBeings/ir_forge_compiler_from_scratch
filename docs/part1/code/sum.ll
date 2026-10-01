; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"

define i32 @sum_array(ptr %0, ptr %1, i64 %2, i64 %3, i64 %4) {
  %6 = insertvalue { ptr, ptr, i64, [1 x i64], [1 x i64] } undef, ptr %0, 0
  %7 = insertvalue { ptr, ptr, i64, [1 x i64], [1 x i64] } %6, ptr %1, 1
  %8 = insertvalue { ptr, ptr, i64, [1 x i64], [1 x i64] } %7, i64 %2, 2
  %9 = insertvalue { ptr, ptr, i64, [1 x i64], [1 x i64] } %8, i64 %3, 3, 0
  %10 = insertvalue { ptr, ptr, i64, [1 x i64], [1 x i64] } %9, i64 %4, 4, 0
  br label %11

11:                                               ; preds = %15, %5
  %12 = phi i64 [ %20, %15 ], [ 0, %5 ]
  %13 = phi i32 [ %19, %15 ], [ 0, %5 ]
  %14 = icmp slt i64 %12, 5
  br i1 %14, label %15, label %21

15:                                               ; preds = %11
  %16 = extractvalue { ptr, ptr, i64, [1 x i64], [1 x i64] } %10, 1
  %17 = getelementptr i32, ptr %16, i64 %12
  %18 = load i32, ptr %17, align 4
  %19 = add i32 %13, %18
  %20 = add i64 %12, 1
  br label %11

21:                                               ; preds = %11
  ret i32 %13
}

!llvm.module.flags = !{!0}

!0 = !{i32 2, !"Debug Info Version", i32 3}
