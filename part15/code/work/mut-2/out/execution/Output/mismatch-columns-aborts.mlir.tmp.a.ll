; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"

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
  br i1 %37, label %38, label %86

38:                                               ; preds = %14
  %39 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 3
  %40 = alloca [2 x i64], i64 1, align 8
  store [2 x i64] %39, ptr %40, align 4
  %41 = getelementptr [2 x i64], ptr %40, i32 0, i32 0
  %42 = load i64, ptr %41, align 4
  %43 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 3
  %44 = alloca [2 x i64], i64 1, align 8
  store [2 x i64] %43, ptr %44, align 4
  %45 = getelementptr [2 x i64], ptr %44, i32 0, i32 1
  %46 = load i64, ptr %45, align 4
  %47 = mul i64 %46, %42
  %48 = getelementptr double, ptr null, i64 %47
  %49 = ptrtoint ptr %48 to i64
  %50 = call ptr @malloc(i64 %49)
  %51 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %50, 0
  %52 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %51, ptr %50, 1
  %53 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %52, i64 0, 2
  %54 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %53, i64 %42, 3, 0
  %55 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %54, i64 %46, 3, 1
  %56 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %55, i64 %46, 4, 0
  %57 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %56, i64 1, 4, 1
  br label %58

58:                                               ; preds = %83, %38
  %59 = phi i64 [ %84, %83 ], [ 0, %38 ]
  %60 = icmp slt i64 %59, %42
  br i1 %60, label %61, label %85

61:                                               ; preds = %58
  br label %62

62:                                               ; preds = %65, %61
  %63 = phi i64 [ %82, %65 ], [ 0, %61 ]
  %64 = icmp slt i64 %63, %46
  br i1 %64, label %65, label %83

65:                                               ; preds = %62
  %66 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 1
  %67 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 4, 0
  %68 = mul i64 %59, %67
  %69 = add i64 %68, %63
  %70 = getelementptr double, ptr %66, i64 %69
  %71 = load double, ptr %70, align 8
  %72 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 1
  %73 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 4, 0
  %74 = mul i64 %59, %73
  %75 = add i64 %74, %63
  %76 = getelementptr double, ptr %72, i64 %75
  %77 = load double, ptr %76, align 8
  %78 = fadd double %71, %77
  %79 = mul i64 %59, %46
  %80 = add i64 %79, %63
  %81 = getelementptr double, ptr %50, i64 %80
  store double %78, ptr %81, align 8
  %82 = add i64 %63, 1
  br label %62

83:                                               ; preds = %62
  %84 = add i64 %59, 1
  br label %58

85:                                               ; preds = %58
  ret { ptr, ptr, i64, [2 x i64], [2 x i64] } %57

86:                                               ; preds = %14
  call void @puts(ptr @assert_msg)
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
