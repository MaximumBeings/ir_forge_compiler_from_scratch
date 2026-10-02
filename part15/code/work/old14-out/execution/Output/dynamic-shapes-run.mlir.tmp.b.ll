; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"

@assert_msg_0 = private constant [56 x i8] c"mg.add: operand shapes differ at runtime in dimension 1\00"
@assert_msg = private constant [56 x i8] c"mg.add: operand shapes differ at runtime in dimension 0\00"

declare void @abort()

declare void @puts(ptr)

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
  %33 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 3
  %34 = alloca [2 x i64], i64 1, align 8
  store [2 x i64] %33, ptr %34, align 4
  %35 = getelementptr [2 x i64], ptr %34, i32 0, i32 0
  %36 = load i64, ptr %35, align 4
  %37 = icmp eq i64 %32, %36
  br i1 %37, label %38, label %104

38:                                               ; preds = %14
  %39 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 3
  %40 = alloca [2 x i64], i64 1, align 8
  store [2 x i64] %39, ptr %40, align 4
  %41 = getelementptr [2 x i64], ptr %40, i32 0, i32 1
  %42 = load i64, ptr %41, align 4
  %43 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 3
  %44 = alloca [2 x i64], i64 1, align 8
  store [2 x i64] %43, ptr %44, align 4
  %45 = getelementptr [2 x i64], ptr %44, i32 0, i32 1
  %46 = load i64, ptr %45, align 4
  %47 = icmp eq i64 %42, %46
  br i1 %47, label %48, label %105

48:                                               ; preds = %38
  %49 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 3
  %50 = alloca [2 x i64], i64 1, align 8
  store [2 x i64] %49, ptr %50, align 4
  %51 = getelementptr [2 x i64], ptr %50, i32 0, i32 0
  %52 = load i64, ptr %51, align 4
  %53 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 3
  %54 = alloca [2 x i64], i64 1, align 8
  store [2 x i64] %53, ptr %54, align 4
  %55 = getelementptr [2 x i64], ptr %54, i32 0, i32 1
  %56 = load i64, ptr %55, align 4
  %57 = mul i64 %56, %52
  %58 = getelementptr double, ptr null, i64 %57
  %59 = ptrtoint ptr %58 to i64
  %60 = call ptr @malloc(i64 %59)
  %61 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %60, 0
  %62 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %61, ptr %60, 1
  %63 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %62, i64 0, 2
  %64 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %63, i64 %52, 3, 0
  %65 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %64, i64 %56, 3, 1
  %66 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %65, i64 %56, 4, 0
  %67 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %66, i64 1, 4, 1
  br label %68

68:                                               ; preds = %101, %48
  %69 = phi i64 [ %102, %101 ], [ 0, %48 ]
  %70 = icmp slt i64 %69, %52
  br i1 %70, label %71, label %103

71:                                               ; preds = %68
  br label %72

72:                                               ; preds = %75, %71
  %73 = phi i64 [ %100, %75 ], [ 0, %71 ]
  %74 = icmp slt i64 %73, %56
  br i1 %74, label %75, label %101

75:                                               ; preds = %72
  %76 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 1
  %77 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 2
  %78 = getelementptr double, ptr %76, i64 %77
  %79 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 4, 0
  %80 = mul i64 %69, %79
  %81 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 4, 1
  %82 = mul i64 %73, %81
  %83 = add i64 %80, %82
  %84 = getelementptr double, ptr %78, i64 %83
  %85 = load double, ptr %84, align 8
  %86 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 1
  %87 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 2
  %88 = getelementptr double, ptr %86, i64 %87
  %89 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 4, 0
  %90 = mul i64 %69, %89
  %91 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 4, 1
  %92 = mul i64 %73, %91
  %93 = add i64 %90, %92
  %94 = getelementptr double, ptr %88, i64 %93
  %95 = load double, ptr %94, align 8
  %96 = fadd double %85, %95
  %97 = mul i64 %69, %56
  %98 = add i64 %97, %73
  %99 = getelementptr double, ptr %60, i64 %98
  store double %96, ptr %99, align 8
  %100 = add i64 %73, 1
  br label %72

101:                                              ; preds = %72
  %102 = add i64 %69, 1
  br label %68

103:                                              ; preds = %68
  ret { ptr, ptr, i64, [2 x i64], [2 x i64] } %67

104:                                              ; preds = %14
  call void @puts(ptr @assert_msg)
  call void @abort()
  unreachable

105:                                              ; preds = %38
  call void @puts(ptr @assert_msg_0)
  call void @abort()
  unreachable
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
