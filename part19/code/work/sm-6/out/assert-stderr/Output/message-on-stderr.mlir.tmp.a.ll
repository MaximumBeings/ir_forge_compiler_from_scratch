; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"

@mg_assert_stderr_msg_1 = private constant [56 x i8] c"mg.add: operand shapes differ at runtime in dimension 0\0A"
@mg_assert_stderr_msg_0 = private constant [56 x i8] c"mg.add: operand shapes differ at runtime in dimension 1\0A"

declare ptr @malloc(i64)

declare i64 @write(i32, ptr, i64)

declare void @abort()

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
  %33 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 3
  %34 = alloca [2 x i64], i64 1, align 8
  store [2 x i64] %33, ptr %34, align 4
  %35 = getelementptr [2 x i64], ptr %34, i32 0, i32 0
  %36 = load i64, ptr %35, align 4
  %37 = icmp eq i64 %32, %36
  br i1 %37, label %40, label %38

38:                                               ; preds = %14
  %39 = call i64 @write(i32 2, ptr @mg_assert_stderr_msg_1, i64 56)
  call void @abort()
  unreachable

40:                                               ; preds = %14
  %41 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 3
  %42 = alloca [2 x i64], i64 1, align 8
  store [2 x i64] %41, ptr %42, align 4
  %43 = getelementptr [2 x i64], ptr %42, i32 0, i32 1
  %44 = load i64, ptr %43, align 4
  %45 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 3
  %46 = alloca [2 x i64], i64 1, align 8
  store [2 x i64] %45, ptr %46, align 4
  %47 = getelementptr [2 x i64], ptr %46, i32 0, i32 1
  %48 = load i64, ptr %47, align 4
  %49 = icmp eq i64 %44, %48
  br i1 %49, label %52, label %50

50:                                               ; preds = %40
  %51 = call i64 @write(i32 2, ptr @mg_assert_stderr_msg_0, i64 56)
  call void @abort()
  unreachable

52:                                               ; preds = %40
  %53 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 3
  %54 = alloca [2 x i64], i64 1, align 8
  store [2 x i64] %53, ptr %54, align 4
  %55 = getelementptr [2 x i64], ptr %54, i32 0, i32 0
  %56 = load i64, ptr %55, align 4
  %57 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 3
  %58 = alloca [2 x i64], i64 1, align 8
  store [2 x i64] %57, ptr %58, align 4
  %59 = getelementptr [2 x i64], ptr %58, i32 0, i32 1
  %60 = load i64, ptr %59, align 4
  %61 = mul i64 %60, %56
  %62 = getelementptr double, ptr null, i64 %61
  %63 = ptrtoint ptr %62 to i64
  %64 = call ptr @malloc(i64 %63)
  %65 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %64, 0
  %66 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %65, ptr %64, 1
  %67 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %66, i64 0, 2
  %68 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %67, i64 %56, 3, 0
  %69 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %68, i64 %60, 3, 1
  %70 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %69, i64 %60, 4, 0
  %71 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %70, i64 1, 4, 1
  br label %72

72:                                               ; preds = %97, %52
  %73 = phi i64 [ %98, %97 ], [ 0, %52 ]
  %74 = icmp slt i64 %73, %56
  br i1 %74, label %75, label %99

75:                                               ; preds = %72
  br label %76

76:                                               ; preds = %79, %75
  %77 = phi i64 [ %96, %79 ], [ 0, %75 ]
  %78 = icmp slt i64 %77, %60
  br i1 %78, label %79, label %97

79:                                               ; preds = %76
  %80 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 1
  %81 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 4, 0
  %82 = mul i64 %73, %81
  %83 = add i64 %82, %77
  %84 = getelementptr double, ptr %80, i64 %83
  %85 = load double, ptr %84, align 8
  %86 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 1
  %87 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 4, 0
  %88 = mul i64 %73, %87
  %89 = add i64 %88, %77
  %90 = getelementptr double, ptr %86, i64 %89
  %91 = load double, ptr %90, align 8
  %92 = fadd double %85, %91
  %93 = mul i64 %73, %60
  %94 = add i64 %93, %77
  %95 = getelementptr double, ptr %64, i64 %94
  store double %92, ptr %95, align 8
  %96 = add i64 %77, 1
  br label %76

97:                                               ; preds = %76
  %98 = add i64 %73, 1
  br label %72

99:                                               ; preds = %72
  ret { ptr, ptr, i64, [2 x i64], [2 x i64] } %71
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

34:                                               ; preds = %52, %7
  %35 = phi i64 [ %53, %52 ], [ 0, %7 ]
  %36 = icmp slt i64 %35, %18
  br i1 %36, label %37, label %54

37:                                               ; preds = %34
  br label %38

38:                                               ; preds = %41, %37
  %39 = phi i64 [ %51, %41 ], [ 0, %37 ]
  %40 = icmp slt i64 %39, %22
  br i1 %40, label %41, label %52

41:                                               ; preds = %38
  %42 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %14, 1
  %43 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %14, 4, 0
  %44 = mul i64 %39, %43
  %45 = add i64 %44, %35
  %46 = getelementptr double, ptr %42, i64 %45
  %47 = load double, ptr %46, align 8
  %48 = mul i64 %35, %22
  %49 = add i64 %48, %39
  %50 = getelementptr double, ptr %26, i64 %49
  store double %47, ptr %50, align 8
  %51 = add i64 %39, 1
  br label %38

52:                                               ; preds = %38
  %53 = add i64 %35, 1
  br label %34

54:                                               ; preds = %34
  ret { ptr, ptr, i64, [2 x i64], [2 x i64] } %33
}

!llvm.module.flags = !{!0}

!0 = !{i32 2, !"Debug Info Version", i32 3}
