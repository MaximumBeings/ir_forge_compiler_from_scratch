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
  br i1 %37, label %38, label %264

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
  br i1 %47, label %48, label %265

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

68:                                               ; preds = %180, %48
  %69 = phi i64 [ %181, %180 ], [ 0, %48 ]
  %70 = icmp slt i64 %69, %52
  br i1 %70, label %71, label %182

71:                                               ; preds = %68
  %72 = icmp slt i64 %56, 0
  %73 = sub i64 -1, %56
  %74 = select i1 %72, i64 %73, i64 %56
  %75 = sdiv i64 %74, 4
  %76 = sub i64 -1, %75
  %77 = select i1 %72, i64 %76, i64 %75
  %78 = mul i64 %77, 4
  br label %79

79:                                               ; preds = %82, %71
  %80 = phi i64 [ %150, %82 ], [ 0, %71 ]
  %81 = icmp slt i64 %80, %78
  br i1 %81, label %82, label %151

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
  %117 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 1
  %118 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 4, 0
  %119 = mul i64 %69, %118
  %120 = add i64 %119, %116
  %121 = getelementptr double, ptr %117, i64 %120
  %122 = load double, ptr %121, align 8
  %123 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 1
  %124 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 4, 0
  %125 = mul i64 %69, %124
  %126 = add i64 %125, %116
  %127 = getelementptr double, ptr %123, i64 %126
  %128 = load double, ptr %127, align 8
  %129 = fadd double %122, %128
  %130 = mul i64 %69, %56
  %131 = add i64 %130, %116
  %132 = getelementptr double, ptr %60, i64 %131
  store double %129, ptr %132, align 8
  %133 = add i64 %80, 3
  %134 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 1
  %135 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 4, 0
  %136 = mul i64 %69, %135
  %137 = add i64 %136, %133
  %138 = getelementptr double, ptr %134, i64 %137
  %139 = load double, ptr %138, align 8
  %140 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 1
  %141 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 4, 0
  %142 = mul i64 %69, %141
  %143 = add i64 %142, %133
  %144 = getelementptr double, ptr %140, i64 %143
  %145 = load double, ptr %144, align 8
  %146 = fadd double %139, %145
  %147 = mul i64 %69, %56
  %148 = add i64 %147, %133
  %149 = getelementptr double, ptr %60, i64 %148
  store double %146, ptr %149, align 8
  %150 = add i64 %80, 4
  br label %79

151:                                              ; preds = %79
  %152 = icmp slt i64 %56, 0
  %153 = sub i64 -1, %56
  %154 = select i1 %152, i64 %153, i64 %56
  %155 = sdiv i64 %154, 4
  %156 = sub i64 -1, %155
  %157 = select i1 %152, i64 %156, i64 %155
  %158 = mul i64 %157, 4
  br label %159

159:                                              ; preds = %162, %151
  %160 = phi i64 [ %179, %162 ], [ %158, %151 ]
  %161 = icmp slt i64 %160, %56
  br i1 %161, label %162, label %180

162:                                              ; preds = %159
  %163 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 1
  %164 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 4, 0
  %165 = mul i64 %69, %164
  %166 = add i64 %165, %160
  %167 = getelementptr double, ptr %163, i64 %166
  %168 = load double, ptr %167, align 8
  %169 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 1
  %170 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 4, 0
  %171 = mul i64 %69, %170
  %172 = add i64 %171, %160
  %173 = getelementptr double, ptr %169, i64 %172
  %174 = load double, ptr %173, align 8
  %175 = fadd double %168, %174
  %176 = mul i64 %69, %56
  %177 = add i64 %176, %160
  %178 = getelementptr double, ptr %60, i64 %177
  store double %175, ptr %178, align 8
  %179 = add i64 %160, 1
  br label %159

180:                                              ; preds = %159
  %181 = add i64 %69, 1
  br label %68

182:                                              ; preds = %68
  %183 = mul i64 %52, %56
  %184 = getelementptr double, ptr null, i64 %183
  %185 = ptrtoint ptr %184 to i64
  %186 = call ptr @malloc(i64 %185)
  %187 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %186, 0
  %188 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %187, ptr %186, 1
  %189 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %188, i64 0, 2
  %190 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %189, i64 %56, 3, 0
  %191 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %190, i64 %52, 3, 1
  %192 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %191, i64 %52, 4, 0
  %193 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %192, i64 1, 4, 1
  br label %194

194:                                              ; preds = %261, %182
  %195 = phi i64 [ %262, %261 ], [ 0, %182 ]
  %196 = icmp slt i64 %195, %56
  br i1 %196, label %197, label %263

197:                                              ; preds = %194
  %198 = icmp slt i64 %52, 0
  %199 = sub i64 -1, %52
  %200 = select i1 %198, i64 %199, i64 %52
  %201 = sdiv i64 %200, 4
  %202 = sub i64 -1, %201
  %203 = select i1 %198, i64 %202, i64 %201
  %204 = mul i64 %203, 4
  br label %205

205:                                              ; preds = %208, %197
  %206 = phi i64 [ %240, %208 ], [ 0, %197 ]
  %207 = icmp slt i64 %206, %204
  br i1 %207, label %208, label %241

208:                                              ; preds = %205
  %209 = mul i64 %206, %56
  %210 = add i64 %209, %195
  %211 = getelementptr double, ptr %60, i64 %210
  %212 = load double, ptr %211, align 8
  %213 = mul i64 %195, %52
  %214 = add i64 %213, %206
  %215 = getelementptr double, ptr %186, i64 %214
  store double %212, ptr %215, align 8
  %216 = add i64 %206, 1
  %217 = mul i64 %216, %56
  %218 = add i64 %217, %195
  %219 = getelementptr double, ptr %60, i64 %218
  %220 = load double, ptr %219, align 8
  %221 = mul i64 %195, %52
  %222 = add i64 %221, %216
  %223 = getelementptr double, ptr %186, i64 %222
  store double %220, ptr %223, align 8
  %224 = add i64 %206, 2
  %225 = mul i64 %224, %56
  %226 = add i64 %225, %195
  %227 = getelementptr double, ptr %60, i64 %226
  %228 = load double, ptr %227, align 8
  %229 = mul i64 %195, %52
  %230 = add i64 %229, %224
  %231 = getelementptr double, ptr %186, i64 %230
  store double %228, ptr %231, align 8
  %232 = add i64 %206, 3
  %233 = mul i64 %232, %56
  %234 = add i64 %233, %195
  %235 = getelementptr double, ptr %60, i64 %234
  %236 = load double, ptr %235, align 8
  %237 = mul i64 %195, %52
  %238 = add i64 %237, %232
  %239 = getelementptr double, ptr %186, i64 %238
  store double %236, ptr %239, align 8
  %240 = add i64 %206, 4
  br label %205

241:                                              ; preds = %205
  %242 = icmp slt i64 %52, 0
  %243 = sub i64 -1, %52
  %244 = select i1 %242, i64 %243, i64 %52
  %245 = sdiv i64 %244, 4
  %246 = sub i64 -1, %245
  %247 = select i1 %242, i64 %246, i64 %245
  %248 = mul i64 %247, 4
  br label %249

249:                                              ; preds = %252, %241
  %250 = phi i64 [ %260, %252 ], [ %248, %241 ]
  %251 = icmp slt i64 %250, %52
  br i1 %251, label %252, label %261

252:                                              ; preds = %249
  %253 = mul i64 %250, %56
  %254 = add i64 %253, %195
  %255 = getelementptr double, ptr %60, i64 %254
  %256 = load double, ptr %255, align 8
  %257 = mul i64 %195, %52
  %258 = add i64 %257, %250
  %259 = getelementptr double, ptr %186, i64 %258
  store double %256, ptr %259, align 8
  %260 = add i64 %250, 1
  br label %249

261:                                              ; preds = %249
  %262 = add i64 %195, 1
  br label %194

263:                                              ; preds = %194
  ret { ptr, ptr, i64, [2 x i64], [2 x i64] } %193

264:                                              ; preds = %14
  call void @puts(ptr @assert_msg)
  call void @abort()
  unreachable

265:                                              ; preds = %38
  call void @puts(ptr @assert_msg_0)
  call void @abort()
  unreachable
}

!llvm.module.flags = !{!0}

!0 = !{i32 2, !"Debug Info Version", i32 3}
