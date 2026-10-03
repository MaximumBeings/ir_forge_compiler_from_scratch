; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"

declare ptr @malloc(i64)

define private void @printMemrefF64(i64 %0, ptr %1) {
  %3 = insertvalue { i64, ptr } undef, i64 %0, 0
  %4 = insertvalue { i64, ptr } %3, ptr %1, 1
  %5 = alloca { i64, ptr }, i64 1, align 8
  store { i64, ptr } %4, ptr %5, align 8
  call void @_mlir_ciface_printMemrefF64(ptr %5)
  ret void
}

declare void @_mlir_ciface_printMemrefF64(ptr)

define { ptr, ptr, i64, [2 x i64], [2 x i64] } @scale_add(ptr %0, ptr %1, i64 %2, i64 %3, i64 %4, i64 %5, i64 %6, ptr %7, ptr %8, i64 %9, i64 %10, i64 %11, i64 %12, i64 %13) {
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
  %29 = call ptr @malloc(i64 ptrtoint (ptr getelementptr (double, ptr null, i32 3) to i64))
  %30 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %29, 0
  %31 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %30, ptr %29, 1
  %32 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %31, i64 0, 2
  %33 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %32, i64 1, 3, 0
  %34 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %33, i64 3, 3, 1
  %35 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %34, i64 3, 4, 0
  %36 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %35, i64 1, 4, 1
  br label %37

37:                                               ; preds = %55, %14
  %38 = phi i64 [ %56, %55 ], [ 0, %14 ]
  %39 = icmp slt i64 %38, 1
  br i1 %39, label %40, label %57

40:                                               ; preds = %37
  br label %41

41:                                               ; preds = %44, %40
  %42 = phi i64 [ %54, %44 ], [ 0, %40 ]
  %43 = icmp slt i64 %42, 3
  br i1 %43, label %44, label %55

44:                                               ; preds = %41
  %45 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 1
  %46 = mul i64 %38, 3
  %47 = add i64 %46, %42
  %48 = getelementptr double, ptr %45, i64 %47
  %49 = load double, ptr %48, align 8
  %50 = fmul double %49, 2.000000e+00
  %51 = mul i64 %38, 3
  %52 = add i64 %51, %42
  %53 = getelementptr double, ptr %29, i64 %52
  store double %50, ptr %53, align 8
  %54 = add i64 %42, 1
  br label %41

55:                                               ; preds = %41
  %56 = add i64 %38, 1
  br label %37

57:                                               ; preds = %37
  %58 = call ptr @malloc(i64 ptrtoint (ptr getelementptr (double, ptr null, i32 3) to i64))
  %59 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %58, 0
  %60 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %59, ptr %58, 1
  %61 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %60, i64 0, 2
  %62 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %61, i64 1, 3, 0
  %63 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %62, i64 3, 3, 1
  %64 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %63, i64 3, 4, 0
  %65 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %64, i64 1, 4, 1
  br label %66

66:                                               ; preds = %88, %57
  %67 = phi i64 [ %89, %88 ], [ 0, %57 ]
  %68 = icmp slt i64 %67, 1
  br i1 %68, label %69, label %90

69:                                               ; preds = %66
  br label %70

70:                                               ; preds = %73, %69
  %71 = phi i64 [ %87, %73 ], [ 0, %69 ]
  %72 = icmp slt i64 %71, 3
  br i1 %72, label %73, label %88

73:                                               ; preds = %70
  %74 = mul i64 %67, 3
  %75 = add i64 %74, %71
  %76 = getelementptr double, ptr %29, i64 %75
  %77 = load double, ptr %76, align 8
  %78 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 1
  %79 = mul i64 %67, 3
  %80 = add i64 %79, %71
  %81 = getelementptr double, ptr %78, i64 %80
  %82 = load double, ptr %81, align 8
  %83 = fadd double %77, %82
  %84 = mul i64 %67, 3
  %85 = add i64 %84, %71
  %86 = getelementptr double, ptr %58, i64 %85
  store double %83, ptr %86, align 8
  %87 = add i64 %71, 1
  br label %70

88:                                               ; preds = %70
  %89 = add i64 %67, 1
  br label %66

90:                                               ; preds = %66
  ret { ptr, ptr, i64, [2 x i64], [2 x i64] } %65
}

define i32 @main() {
  %1 = call ptr @malloc(i64 ptrtoint (ptr getelementptr (double, ptr null, i32 3) to i64))
  %2 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %1, 0
  %3 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %2, ptr %1, 1
  %4 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %3, i64 0, 2
  %5 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %4, i64 1, 3, 0
  %6 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %5, i64 3, 3, 1
  %7 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %6, i64 3, 4, 0
  %8 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %7, i64 1, 4, 1
  %9 = getelementptr double, ptr %1, i64 0
  store double 1.000000e+00, ptr %9, align 8
  %10 = getelementptr double, ptr %1, i64 1
  store double 2.000000e+00, ptr %10, align 8
  %11 = getelementptr double, ptr %1, i64 2
  store double 3.000000e+00, ptr %11, align 8
  %12 = call ptr @malloc(i64 ptrtoint (ptr getelementptr (double, ptr null, i32 3) to i64))
  %13 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %12, 0
  %14 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %13, ptr %12, 1
  %15 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %14, i64 0, 2
  %16 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %15, i64 1, 3, 0
  %17 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %16, i64 3, 3, 1
  %18 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %17, i64 3, 4, 0
  %19 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %18, i64 1, 4, 1
  %20 = getelementptr double, ptr %12, i64 0
  store double 1.000000e+01, ptr %20, align 8
  %21 = getelementptr double, ptr %12, i64 1
  store double 2.000000e+01, ptr %21, align 8
  %22 = getelementptr double, ptr %12, i64 2
  store double 3.000000e+01, ptr %22, align 8
  %23 = call { ptr, ptr, i64, [2 x i64], [2 x i64] } @scale_add(ptr %1, ptr %1, i64 0, i64 1, i64 3, i64 3, i64 1, ptr %12, ptr %12, i64 0, i64 1, i64 3, i64 3, i64 1)
  %24 = alloca { ptr, ptr, i64, [2 x i64], [2 x i64] }, i64 1, align 8
  store { ptr, ptr, i64, [2 x i64], [2 x i64] } %23, ptr %24, align 8
  %25 = insertvalue { i64, ptr } { i64 2, ptr undef }, ptr %24, 1
  call void @printMemrefF64(i64 2, ptr %24)
  ret i32 0
}

!llvm.module.flags = !{!0}

!0 = !{i32 2, !"Debug Info Version", i32 3}
