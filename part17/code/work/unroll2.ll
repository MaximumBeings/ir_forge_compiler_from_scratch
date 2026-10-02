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
  br i1 %37, label %38, label %214

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
  br i1 %47, label %48, label %215

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

68:                                               ; preds = %146, %48
  %69 = phi i64 [ %147, %146 ], [ 0, %48 ]
  %70 = icmp slt i64 %69, %52
  br i1 %70, label %71, label %148

71:                                               ; preds = %68
  %72 = icmp slt i64 %56, 0
  %73 = sub i64 -1, %56
  %74 = select i1 %72, i64 %73, i64 %56
  %75 = sdiv i64 %74, 2
  %76 = sub i64 -1, %75
  %77 = select i1 %72, i64 %76, i64 %75
  %78 = mul i64 %77, 2
  br label %79

79:                                               ; preds = %82, %71
  %80 = phi i64 [ %116, %82 ], [ 0, %71 ]
  %81 = icmp slt i64 %80, %78
  br i1 %81, label %82, label %117

82:                                               ; preds = %79
  %83 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 1
  %84 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 4, 0
  %85 = mul i64 %69, %84
  %86 = add i64 %85, %80
  %87 = getelementptr double, ptr %83, i64 %86
  %88 = load double, ptr %87, align 8
  %89 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 1
  %90 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 4, 0
  %91 = mul i64 %69, %90
  %92 = add i64 %91, %80
  %93 = getelementptr double, ptr %89, i64 %92
  %94 = load double, ptr %93, align 8
  %95 = fadd double %88, %94
  %96 = mul i64 %69, %56
  %97 = add i64 %96, %80
  %98 = getelementptr double, ptr %60, i64 %97
  store double %95, ptr %98, align 8
  %99 = add i64 %80, 1
  %100 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 1
  %101 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 4, 0
  %102 = mul i64 %69, %101
  %103 = add i64 %102, %99
  %104 = getelementptr double, ptr %100, i64 %103
  %105 = load double, ptr %104, align 8
  %106 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 1
  %107 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 4, 0
  %108 = mul i64 %69, %107
  %109 = add i64 %108, %99
  %110 = getelementptr double, ptr %106, i64 %109
  %111 = load double, ptr %110, align 8
  %112 = fadd double %105, %111
  %113 = mul i64 %69, %56
  %114 = add i64 %113, %99
  %115 = getelementptr double, ptr %60, i64 %114
  store double %112, ptr %115, align 8
  %116 = add i64 %80, 2
  br label %79

117:                                              ; preds = %79
  %118 = icmp slt i64 %56, 0
  %119 = sub i64 -1, %56
  %120 = select i1 %118, i64 %119, i64 %56
  %121 = sdiv i64 %120, 2
  %122 = sub i64 -1, %121
  %123 = select i1 %118, i64 %122, i64 %121
  %124 = mul i64 %123, 2
  br label %125

125:                                              ; preds = %128, %117
  %126 = phi i64 [ %145, %128 ], [ %124, %117 ]
  %127 = icmp slt i64 %126, %56
  br i1 %127, label %128, label %146

128:                                              ; preds = %125
  %129 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 1
  %130 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 4, 0
  %131 = mul i64 %69, %130
  %132 = add i64 %131, %126
  %133 = getelementptr double, ptr %129, i64 %132
  %134 = load double, ptr %133, align 8
  %135 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 1
  %136 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 4, 0
  %137 = mul i64 %69, %136
  %138 = add i64 %137, %126
  %139 = getelementptr double, ptr %135, i64 %138
  %140 = load double, ptr %139, align 8
  %141 = fadd double %134, %140
  %142 = mul i64 %69, %56
  %143 = add i64 %142, %126
  %144 = getelementptr double, ptr %60, i64 %143
  store double %141, ptr %144, align 8
  %145 = add i64 %126, 1
  br label %125

146:                                              ; preds = %125
  %147 = add i64 %69, 1
  br label %68

148:                                              ; preds = %68
  %149 = mul i64 %52, %56
  %150 = getelementptr double, ptr null, i64 %149
  %151 = ptrtoint ptr %150 to i64
  %152 = call ptr @malloc(i64 %151)
  %153 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %152, 0
  %154 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %153, ptr %152, 1
  %155 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %154, i64 0, 2
  %156 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %155, i64 %56, 3, 0
  %157 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %156, i64 %52, 3, 1
  %158 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %157, i64 %52, 4, 0
  %159 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %158, i64 1, 4, 1
  br label %160

160:                                              ; preds = %211, %148
  %161 = phi i64 [ %212, %211 ], [ 0, %148 ]
  %162 = icmp slt i64 %161, %56
  br i1 %162, label %163, label %213

163:                                              ; preds = %160
  %164 = icmp slt i64 %52, 0
  %165 = sub i64 -1, %52
  %166 = select i1 %164, i64 %165, i64 %52
  %167 = sdiv i64 %166, 2
  %168 = sub i64 -1, %167
  %169 = select i1 %164, i64 %168, i64 %167
  %170 = mul i64 %169, 2
  br label %171

171:                                              ; preds = %174, %163
  %172 = phi i64 [ %190, %174 ], [ 0, %163 ]
  %173 = icmp slt i64 %172, %170
  br i1 %173, label %174, label %191

174:                                              ; preds = %171
  %175 = mul i64 %172, %56
  %176 = add i64 %175, %161
  %177 = getelementptr double, ptr %60, i64 %176
  %178 = load double, ptr %177, align 8
  %179 = mul i64 %161, %52
  %180 = add i64 %179, %172
  %181 = getelementptr double, ptr %152, i64 %180
  store double %178, ptr %181, align 8
  %182 = add i64 %172, 1
  %183 = mul i64 %182, %56
  %184 = add i64 %183, %161
  %185 = getelementptr double, ptr %60, i64 %184
  %186 = load double, ptr %185, align 8
  %187 = mul i64 %161, %52
  %188 = add i64 %187, %182
  %189 = getelementptr double, ptr %152, i64 %188
  store double %186, ptr %189, align 8
  %190 = add i64 %172, 2
  br label %171

191:                                              ; preds = %171
  %192 = icmp slt i64 %52, 0
  %193 = sub i64 -1, %52
  %194 = select i1 %192, i64 %193, i64 %52
  %195 = sdiv i64 %194, 2
  %196 = sub i64 -1, %195
  %197 = select i1 %192, i64 %196, i64 %195
  %198 = mul i64 %197, 2
  br label %199

199:                                              ; preds = %202, %191
  %200 = phi i64 [ %210, %202 ], [ %198, %191 ]
  %201 = icmp slt i64 %200, %52
  br i1 %201, label %202, label %211

202:                                              ; preds = %199
  %203 = mul i64 %200, %56
  %204 = add i64 %203, %161
  %205 = getelementptr double, ptr %60, i64 %204
  %206 = load double, ptr %205, align 8
  %207 = mul i64 %161, %52
  %208 = add i64 %207, %200
  %209 = getelementptr double, ptr %152, i64 %208
  store double %206, ptr %209, align 8
  %210 = add i64 %200, 1
  br label %199

211:                                              ; preds = %199
  %212 = add i64 %161, 1
  br label %160

213:                                              ; preds = %160
  ret { ptr, ptr, i64, [2 x i64], [2 x i64] } %159

214:                                              ; preds = %14
  call void @puts(ptr @assert_msg)
  call void @abort()
  unreachable

215:                                              ; preds = %38
  call void @puts(ptr @assert_msg_0)
  call void @abort()
  unreachable
}

!llvm.module.flags = !{!0}

!0 = !{i32 2, !"Debug Info Version", i32 3}
