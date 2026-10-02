; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"

@mg_assert_stderr_msg_1 = private constant [56 x i8] c"mg.add: operand shapes differ at runtime in dimension 0\0A"
@mg_assert_stderr_msg_0 = private constant [56 x i8] c"mg.add: operand shapes differ at runtime in dimension 1\0A"

declare ptr @malloc(i64)

declare void @abort()

declare i64 @write(i32, ptr, i64)

define { ptr, ptr, i64, [2 x i64], [2 x i64] } @chain(ptr %0, ptr %1, i64 %2, i64 %3, i64 %4, i64 %5, i64 %6, ptr %7, ptr %8, i64 %9, i64 %10, i64 %11, i64 %12, i64 %13) {
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
  %39 = call i64 @write(i32 2, ptr @mg_assert_stderr_msg_1, i64 54)
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
  %51 = call i64 @write(i32 2, ptr @mg_assert_stderr_msg_0, i64 54)
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
  %100 = mul i64 %56, %60
  %101 = getelementptr double, ptr null, i64 %100
  %102 = ptrtoint ptr %101 to i64
  %103 = call ptr @malloc(i64 %102)
  %104 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %103, 0
  %105 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %104, ptr %103, 1
  %106 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %105, i64 0, 2
  %107 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %106, i64 %60, 3, 0
  %108 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %107, i64 %56, 3, 1
  %109 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %108, i64 %56, 4, 0
  %110 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %109, i64 1, 4, 1
  br label %111

111:                                              ; preds = %127, %99
  %112 = phi i64 [ %128, %127 ], [ 0, %99 ]
  %113 = icmp slt i64 %112, %60
  br i1 %113, label %114, label %129

114:                                              ; preds = %111
  br label %115

115:                                              ; preds = %118, %114
  %116 = phi i64 [ %126, %118 ], [ 0, %114 ]
  %117 = icmp slt i64 %116, %56
  br i1 %117, label %118, label %127

118:                                              ; preds = %115
  %119 = mul i64 %116, %60
  %120 = add i64 %119, %112
  %121 = getelementptr double, ptr %64, i64 %120
  %122 = load double, ptr %121, align 8
  %123 = mul i64 %112, %56
  %124 = add i64 %123, %116
  %125 = getelementptr double, ptr %103, i64 %124
  store double %122, ptr %125, align 8
  %126 = add i64 %116, 1
  br label %115

127:                                              ; preds = %115
  %128 = add i64 %112, 1
  br label %111

129:                                              ; preds = %111
  ret { ptr, ptr, i64, [2 x i64], [2 x i64] } %110
}

!llvm.module.flags = !{!0}

!0 = !{i32 2, !"Debug Info Version", i32 3}
