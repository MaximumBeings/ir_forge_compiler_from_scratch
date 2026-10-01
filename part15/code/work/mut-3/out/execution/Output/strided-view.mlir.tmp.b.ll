; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"

declare ptr @malloc(i64)

define { ptr, ptr, i64, [2 x i64], [2 x i64] } @add_dyn(ptr %0, ptr %1, i64 %2, i64 %3, i64 %4, i64 %5, i64 %6, ptr %7, ptr %8, i64 %9, i64 %10, i64 %11, i64 %12, i64 %13) {
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
  %33 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 3
  %34 = alloca [2 x i64], i64 1, align 8
  store [2 x i64] %33, ptr %34, align 4
  %35 = getelementptr [2 x i64], ptr %34, i32 0, i32 1
  %36 = load i64, ptr %35, align 4
  %37 = mul i64 %36, %32
  %38 = getelementptr double, ptr null, i64 %37
  %39 = ptrtoint ptr %38 to i64
  %40 = call ptr @malloc(i64 %39)
  %41 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %40, 0
  %42 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %41, ptr %40, 1
  %43 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %42, i64 0, 2
  %44 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %43, i64 %32, 3, 0
  %45 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %44, i64 %36, 3, 1
  %46 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %45, i64 %36, 4, 0
  %47 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %46, i64 1, 4, 1
  br label %48

48:                                               ; preds = %81, %14
  %49 = phi i64 [ %82, %81 ], [ 0, %14 ]
  %50 = icmp slt i64 %49, %32
  br i1 %50, label %51, label %83

51:                                               ; preds = %48
  br label %52

52:                                               ; preds = %55, %51
  %53 = phi i64 [ %80, %55 ], [ 0, %51 ]
  %54 = icmp slt i64 %53, %36
  br i1 %54, label %55, label %81

55:                                               ; preds = %52
  %56 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 1
  %57 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 2
  %58 = getelementptr double, ptr %56, i64 %57
  %59 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 4, 0
  %60 = mul i64 %49, %59
  %61 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 4, 1
  %62 = mul i64 %53, %61
  %63 = add i64 %60, %62
  %64 = getelementptr double, ptr %58, i64 %63
  %65 = load double, ptr %64, align 8
  %66 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 1
  %67 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 2
  %68 = getelementptr double, ptr %66, i64 %67
  %69 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 4, 0
  %70 = mul i64 %49, %69
  %71 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 4, 1
  %72 = mul i64 %53, %71
  %73 = add i64 %70, %72
  %74 = getelementptr double, ptr %68, i64 %73
  %75 = load double, ptr %74, align 8
  %76 = fadd double %65, %75
  %77 = mul i64 %49, %36
  %78 = add i64 %77, %53
  %79 = getelementptr double, ptr %40, i64 %78
  store double %76, ptr %79, align 8
  %80 = add i64 %53, 1
  br label %52

81:                                               ; preds = %52
  %82 = add i64 %49, 1
  br label %48

83:                                               ; preds = %48
  ret { ptr, ptr, i64, [2 x i64], [2 x i64] } %47
}

define { ptr, ptr, i64, [2 x i64], [2 x i64] } @t_dyn(ptr %0, ptr %1, i64 %2, i64 %3, i64 %4, i64 %5, i64 %6) {
  %8 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %0, 0
  %9 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %8, ptr %1, 1
  %10 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %9, i64 %2, 2
  %11 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %10, i64 %3, 3, 0
  %12 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %11, i64 %5, 4, 0
  %13 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %12, i64 %4, 3, 1
  %14 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %13, i64 %6, 4, 1
  %15 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %14, 3
  %16 = alloca [2 x i64], i64 1, align 8
  store [2 x i64] %15, ptr %16, align 4
  %17 = getelementptr [2 x i64], ptr %16, i32 0, i32 1
  %18 = load i64, ptr %17, align 4
  %19 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %14, 3
  %20 = alloca [2 x i64], i64 1, align 8
  store [2 x i64] %19, ptr %20, align 4
  %21 = getelementptr [2 x i64], ptr %20, i32 0, i32 0
  %22 = load i64, ptr %21, align 4
  %23 = mul i64 %22, %18
  %24 = getelementptr double, ptr null, i64 %23
  %25 = ptrtoint ptr %24 to i64
  %26 = call ptr @malloc(i64 %25)
  %27 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %26, 0
  %28 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %27, ptr %26, 1
  %29 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, i64 0, 2
  %30 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %29, i64 %18, 3, 0
  %31 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %30, i64 %22, 3, 1
  %32 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %31, i64 %22, 4, 0
  %33 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %32, i64 1, 4, 1
  br label %34

34:                                               ; preds = %56, %7
  %35 = phi i64 [ %57, %56 ], [ 0, %7 ]
  %36 = icmp slt i64 %35, %18
  br i1 %36, label %37, label %58

37:                                               ; preds = %34
  br label %38

38:                                               ; preds = %41, %37
  %39 = phi i64 [ %55, %41 ], [ 0, %37 ]
  %40 = icmp slt i64 %39, %22
  br i1 %40, label %41, label %56

41:                                               ; preds = %38
  %42 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %14, 1
  %43 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %14, 2
  %44 = getelementptr double, ptr %42, i64 %43
  %45 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %14, 4, 0
  %46 = mul i64 %39, %45
  %47 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %14, 4, 1
  %48 = mul i64 %35, %47
  %49 = add i64 %46, %48
  %50 = getelementptr double, ptr %44, i64 %49
  %51 = load double, ptr %50, align 8
  %52 = mul i64 %35, %22
  %53 = add i64 %52, %39
  %54 = getelementptr double, ptr %26, i64 %53
  store double %51, ptr %54, align 8
  %55 = add i64 %39, 1
  br label %38

56:                                               ; preds = %38
  %57 = add i64 %35, 1
  br label %34

58:                                               ; preds = %34
  ret { ptr, ptr, i64, [2 x i64], [2 x i64] } %33
}

!llvm.module.flags = !{!0}

!0 = !{i32 2, !"Debug Info Version", i32 3}
