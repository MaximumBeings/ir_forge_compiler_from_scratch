; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"

@mg_assert_stderr_msg_0 = private constant [13 x i8] c"value is NaN\0A"

declare void @abort()

declare i64 @write(i32, ptr, i64)

define void @nanloop(ptr %0, ptr %1, i64 %2, i64 %3, i64 %4, i64 %5) {
  %7 = insertvalue { ptr, ptr, i64, [1 x i64], [1 x i64] } undef, ptr %0, 0
  %8 = insertvalue { ptr, ptr, i64, [1 x i64], [1 x i64] } %7, ptr %1, 1
  %9 = insertvalue { ptr, ptr, i64, [1 x i64], [1 x i64] } %8, i64 %2, 2
  %10 = insertvalue { ptr, ptr, i64, [1 x i64], [1 x i64] } %9, i64 %3, 3, 0
  %11 = insertvalue { ptr, ptr, i64, [1 x i64], [1 x i64] } %10, i64 %4, 4, 0
  br label %12

12:                                               ; preds = %22, %6
  %13 = phi i64 [ %23, %22 ], [ 0, %6 ]
  %14 = icmp slt i64 %13, %5
  br i1 %14, label %15, label %24

15:                                               ; preds = %12
  %16 = extractvalue { ptr, ptr, i64, [1 x i64], [1 x i64] } %11, 1
  %17 = getelementptr double, ptr %16, i64 %13
  %18 = load double, ptr %17, align 8
  %19 = fcmp oeq double %18, %18
  br i1 %19, label %22, label %20

20:                                               ; preds = %15
  %21 = call i64 @write(i32 2, ptr @mg_assert_stderr_msg_0, i64 13)
  call void @abort()
  unreachable

22:                                               ; preds = %15
  %23 = add i64 %13, 1
  br label %12

24:                                               ; preds = %12
  ret void
}

!llvm.module.flags = !{!0}

!0 = !{i32 2, !"Debug Info Version", i32 3}
