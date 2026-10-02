; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"

@assert_msg_0 = private constant [56 x i8] c"mg.add: operand shapes differ at runtime in dimension 1\00"
@assert_msg = private constant [56 x i8] c"mg.add: operand shapes differ at runtime in dimension 0\00"

declare void @abort()

declare void @puts(ptr)

declare ptr @malloc(i64)

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
  br i1 %37, label %38, label %126

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
  br i1 %47, label %48, label %127

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

68:                                               ; preds = %93, %48
  %69 = phi i64 [ %94, %93 ], [ 0, %48 ]
  %70 = icmp slt i64 %69, %52
  br i1 %70, label %71, label %95

71:                                               ; preds = %68
  br label %72

72:                                               ; preds = %75, %71
  %73 = phi i64 [ %92, %75 ], [ 0, %71 ]
  %74 = icmp slt i64 %73, %56
  br i1 %74, label %75, label %93

75:                                               ; preds = %72
  %76 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 1
  %77 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 4, 0
  %78 = mul i64 %69, %77
  %79 = add i64 %78, %73
  %80 = getelementptr double, ptr %76, i64 %79
  %81 = load double, ptr %80, align 8
  %82 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 1
  %83 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 4, 0
  %84 = mul i64 %69, %83
  %85 = add i64 %84, %73
  %86 = getelementptr double, ptr %82, i64 %85
  %87 = load double, ptr %86, align 8
  %88 = fsub double %81, %87
  %89 = mul i64 %69, %56
  %90 = add i64 %89, %73
  %91 = getelementptr double, ptr %60, i64 %90
  store double %88, ptr %91, align 8
  %92 = add i64 %73, 1
  br label %72

93:                                               ; preds = %72
  %94 = add i64 %69, 1
  br label %68

95:                                               ; preds = %68
  %96 = mul i64 %52, %56
  %97 = getelementptr double, ptr null, i64 %96
  %98 = ptrtoint ptr %97 to i64
  %99 = call ptr @malloc(i64 %98)
  %100 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %99, 0
  %101 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %100, ptr %99, 1
  %102 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %101, i64 0, 2
  %103 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %102, i64 %56, 3, 0
  %104 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %103, i64 %52, 3, 1
  %105 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %104, i64 %52, 4, 0
  %106 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %105, i64 1, 4, 1
  br label %107

107:                                              ; preds = %123, %95
  %108 = phi i64 [ %124, %123 ], [ 0, %95 ]
  %109 = icmp slt i64 %108, %56
  br i1 %109, label %110, label %125

110:                                              ; preds = %107
  br label %111

111:                                              ; preds = %114, %110
  %112 = phi i64 [ %122, %114 ], [ 0, %110 ]
  %113 = icmp slt i64 %112, %52
  br i1 %113, label %114, label %123

114:                                              ; preds = %111
  %115 = mul i64 %112, %56
  %116 = add i64 %115, %108
  %117 = getelementptr double, ptr %60, i64 %116
  %118 = load double, ptr %117, align 8
  %119 = mul i64 %108, %52
  %120 = add i64 %119, %112
  %121 = getelementptr double, ptr %99, i64 %120
  store double %118, ptr %121, align 8
  %122 = add i64 %112, 1
  br label %111

123:                                              ; preds = %111
  %124 = add i64 %108, 1
  br label %107

125:                                              ; preds = %107
  ret { ptr, ptr, i64, [2 x i64], [2 x i64] } %106

126:                                              ; preds = %14
  call void @puts(ptr @assert_msg)
  call void @abort()
  unreachable

127:                                              ; preds = %38
  call void @puts(ptr @assert_msg_0)
  call void @abort()
  unreachable
}

!llvm.module.flags = !{!0}

!0 = !{i32 2, !"Debug Info Version", i32 3}
