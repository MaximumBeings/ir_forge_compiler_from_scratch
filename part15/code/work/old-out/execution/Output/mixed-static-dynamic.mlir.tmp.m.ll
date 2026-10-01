; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"

declare ptr @malloc(i64)

define { ptr, ptr, i64, [2 x i64], [2 x i64] } @mixed(ptr %0, ptr %1, i64 %2, i64 %3, i64 %4, i64 %5, i64 %6, ptr %7, ptr %8, i64 %9, i64 %10, i64 %11, i64 %12, i64 %13) {
  %15 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %0, 0
  %16 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %15, ptr %1, 1
  %17 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %16, i64 %2, 2
  %18 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %17, i64 %3, 3, 0
  %19 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %18, i64 %5, 4, 0
  %20 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %19, i64 %4, 3, 1
  %21 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %20, i64 %6, 4, 1
  %22 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %7, 0
  %23 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %22, ptr %8, 1
  %24 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %23, i64 %9, 2
  %25 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %24, i64 %10, 3, 0
  %26 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %25, i64 %12, 4, 0
  %27 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %26, i64 %11, 3, 1
  %28 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %27, i64 %13, 4, 1
  %29 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 3
  %30 = alloca [2 x i64], i64 1, align 8
  store [2 x i64] %29, ptr %30, align 4
  %31 = getelementptr [2 x i64], ptr %30, i32 0, i32 0
  %32 = load i64, ptr %31, align 4
  %33 = mul i64 %32, 2
  %34 = getelementptr double, ptr null, i64 %33
  %35 = ptrtoint ptr %34 to i64
  %36 = call ptr @malloc(i64 %35)
  %37 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %36, 0
  %38 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %37, ptr %36, 1
  %39 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %38, i64 0, 2
  %40 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %39, i64 %32, 3, 0
  %41 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %40, i64 2, 3, 1
  %42 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %41, i64 2, 4, 0
  %43 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %42, i64 1, 4, 1
  br label %44

44:                                               ; preds = %67, %14
  %45 = phi i64 [ %68, %67 ], [ 0, %14 ]
  %46 = icmp slt i64 %45, %32
  br i1 %46, label %47, label %69

47:                                               ; preds = %44
  br label %48

48:                                               ; preds = %51, %47
  %49 = phi i64 [ %66, %51 ], [ 0, %47 ]
  %50 = icmp slt i64 %49, 2
  br i1 %50, label %51, label %67

51:                                               ; preds = %48
  %52 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 1
  %53 = mul i64 %45, 2
  %54 = add i64 %53, %49
  %55 = getelementptr double, ptr %52, i64 %54
  %56 = load double, ptr %55, align 8
  %57 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 1
  %58 = mul i64 %45, 2
  %59 = add i64 %58, %49
  %60 = getelementptr double, ptr %57, i64 %59
  %61 = load double, ptr %60, align 8
  %62 = fadd double %56, %61
  %63 = mul i64 %45, 2
  %64 = add i64 %63, %49
  %65 = getelementptr double, ptr %36, i64 %64
  store double %62, ptr %65, align 8
  %66 = add i64 %49, 1
  br label %48

67:                                               ; preds = %48
  %68 = add i64 %45, 1
  br label %44

69:                                               ; preds = %44
  ret { ptr, ptr, i64, [2 x i64], [2 x i64] } %43
}

!llvm.module.flags = !{!0}

!0 = !{i32 2, !"Debug Info Version", i32 3}
