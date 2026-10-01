; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"

declare ptr @malloc(i64)

define { ptr, ptr, i64, [2 x i64], [2 x i64] } @add_tensors(ptr %0, ptr %1, i64 %2, i64 %3, i64 %4, i64 %5, i64 %6, ptr %7, ptr %8, i64 %9, i64 %10, i64 %11, i64 %12, i64 %13) {
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
  %29 = call ptr @malloc(i64 ptrtoint (ptr getelementptr (double, ptr null, i32 4) to i64))
  %30 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %29, 0
  %31 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %30, ptr %29, 1
  %32 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %31, i64 0, 2
  %33 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %32, i64 2, 3, 0
  %34 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %33, i64 2, 3, 1
  %35 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %34, i64 2, 4, 0
  %36 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %35, i64 1, 4, 1
  br label %37

37:                                               ; preds = %70, %14
  %38 = phi i64 [ %71, %70 ], [ 0, %14 ]
  %39 = icmp slt i64 %38, 2
  br i1 %39, label %40, label %72

40:                                               ; preds = %37
  br label %41

41:                                               ; preds = %44, %40
  %42 = phi i64 [ %69, %44 ], [ 0, %40 ]
  %43 = icmp slt i64 %42, 2
  br i1 %43, label %44, label %70

44:                                               ; preds = %41
  %45 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 1
  %46 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 2
  %47 = getelementptr double, ptr %45, i64 %46
  %48 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 4, 0
  %49 = mul i64 %38, %48
  %50 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 4, 1
  %51 = mul i64 %42, %50
  %52 = add i64 %49, %51
  %53 = getelementptr double, ptr %47, i64 %52
  %54 = load double, ptr %53, align 8
  %55 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 1
  %56 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 2
  %57 = getelementptr double, ptr %55, i64 %56
  %58 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 4, 0
  %59 = mul i64 %38, %58
  %60 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 4, 1
  %61 = mul i64 %42, %60
  %62 = add i64 %59, %61
  %63 = getelementptr double, ptr %57, i64 %62
  %64 = load double, ptr %63, align 8
  %65 = fadd double %54, %64
  %66 = mul i64 %38, 2
  %67 = add i64 %66, %42
  %68 = getelementptr double, ptr %29, i64 %67
  store double %65, ptr %68, align 8
  %69 = add i64 %42, 1
  br label %41

70:                                               ; preds = %41
  %71 = add i64 %38, 1
  br label %37

72:                                               ; preds = %37
  ret { ptr, ptr, i64, [2 x i64], [2 x i64] } %36
}

!llvm.module.flags = !{!0}

!0 = !{i32 2, !"Debug Info Version", i32 3}
