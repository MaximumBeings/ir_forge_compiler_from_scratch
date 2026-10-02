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
  br i1 %37, label %38, label %162

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
  br i1 %47, label %48, label %163

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

68:                                               ; preds = %111, %48
  %69 = phi i64 [ %112, %111 ], [ 0, %48 ]
  %70 = icmp slt i64 %69, %52
  br i1 %70, label %71, label %113

71:                                               ; preds = %68
  br label %72

72:                                               ; preds = %109, %71
  %73 = phi i64 [ %110, %109 ], [ 0, %71 ]
  %74 = icmp slt i64 %73, %56
  br i1 %74, label %75, label %111

75:                                               ; preds = %72
  %76 = add i64 %69, 2
  %77 = icmp slt i64 %76, %52
  %78 = select i1 %77, i64 %76, i64 %52
  br label %79

79:                                               ; preds = %107, %75
  %80 = phi i64 [ %108, %107 ], [ %69, %75 ]
  %81 = icmp slt i64 %80, %78
  br i1 %81, label %82, label %109

82:                                               ; preds = %79
  %83 = add i64 %73, 2
  %84 = icmp slt i64 %83, %56
  %85 = select i1 %84, i64 %83, i64 %56
  br label %86

86:                                               ; preds = %89, %82
  %87 = phi i64 [ %106, %89 ], [ %73, %82 ]
  %88 = icmp slt i64 %87, %85
  br i1 %88, label %89, label %107

89:                                               ; preds = %86
  %90 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 1
  %91 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 4, 0
  %92 = mul i64 %80, %91
  %93 = add i64 %92, %87
  %94 = getelementptr double, ptr %90, i64 %93
  %95 = load double, ptr %94, align 8
  %96 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 1
  %97 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 4, 0
  %98 = mul i64 %80, %97
  %99 = add i64 %98, %87
  %100 = getelementptr double, ptr %96, i64 %99
  %101 = load double, ptr %100, align 8
  %102 = fadd double %95, %101
  %103 = mul i64 %80, %56
  %104 = add i64 %103, %87
  %105 = getelementptr double, ptr %60, i64 %104
  store double %102, ptr %105, align 8
  %106 = add i64 %87, 1
  br label %86

107:                                              ; preds = %86
  %108 = add i64 %80, 1
  br label %79

109:                                              ; preds = %79
  %110 = add i64 %73, 2
  br label %72

111:                                              ; preds = %72
  %112 = add i64 %69, 2
  br label %68

113:                                              ; preds = %68
  %114 = mul i64 %52, %56
  %115 = getelementptr double, ptr null, i64 %114
  %116 = ptrtoint ptr %115 to i64
  %117 = call ptr @malloc(i64 %116)
  %118 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %117, 0
  %119 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %118, ptr %117, 1
  %120 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %119, i64 0, 2
  %121 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %120, i64 %56, 3, 0
  %122 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %121, i64 %52, 3, 1
  %123 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %122, i64 %52, 4, 0
  %124 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %123, i64 1, 4, 1
  br label %125

125:                                              ; preds = %159, %113
  %126 = phi i64 [ %160, %159 ], [ 0, %113 ]
  %127 = icmp slt i64 %126, %56
  br i1 %127, label %128, label %161

128:                                              ; preds = %125
  br label %129

129:                                              ; preds = %157, %128
  %130 = phi i64 [ %158, %157 ], [ 0, %128 ]
  %131 = icmp slt i64 %130, %52
  br i1 %131, label %132, label %159

132:                                              ; preds = %129
  %133 = add i64 %126, 2
  %134 = icmp slt i64 %133, %56
  %135 = select i1 %134, i64 %133, i64 %56
  br label %136

136:                                              ; preds = %155, %132
  %137 = phi i64 [ %156, %155 ], [ %126, %132 ]
  %138 = icmp slt i64 %137, %135
  br i1 %138, label %139, label %157

139:                                              ; preds = %136
  %140 = add i64 %130, 2
  %141 = icmp slt i64 %140, %52
  %142 = select i1 %141, i64 %140, i64 %52
  br label %143

143:                                              ; preds = %146, %139
  %144 = phi i64 [ %154, %146 ], [ %130, %139 ]
  %145 = icmp slt i64 %144, %142
  br i1 %145, label %146, label %155

146:                                              ; preds = %143
  %147 = mul i64 %144, %56
  %148 = add i64 %147, %137
  %149 = getelementptr double, ptr %60, i64 %148
  %150 = load double, ptr %149, align 8
  %151 = mul i64 %137, %52
  %152 = add i64 %151, %144
  %153 = getelementptr double, ptr %117, i64 %152
  store double %150, ptr %153, align 8
  %154 = add i64 %144, 1
  br label %143

155:                                              ; preds = %143
  %156 = add i64 %137, 1
  br label %136

157:                                              ; preds = %136
  %158 = add i64 %130, 2
  br label %129

159:                                              ; preds = %129
  %160 = add i64 %126, 2
  br label %125

161:                                              ; preds = %125
  ret { ptr, ptr, i64, [2 x i64], [2 x i64] } %124

162:                                              ; preds = %14
  call void @puts(ptr @assert_msg)
  call void @abort()
  unreachable

163:                                              ; preds = %38
  call void @puts(ptr @assert_msg_0)
  call void @abort()
  unreachable
}

!llvm.module.flags = !{!0}

!0 = !{i32 2, !"Debug Info Version", i32 3}
