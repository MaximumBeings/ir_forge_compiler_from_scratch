; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"

@assert_msg = private constant [56 x i8] c"mg.add: operand shapes differ at runtime in dimension 0\00"

declare void @abort()

declare void @puts(ptr)

declare ptr @malloc(i64)

define { ptr, ptr, i64, [2 x i64], [2 x i64] } @mixed(ptr %0, ptr %1, i64 %2, i64 %3, i64 %4, i64 %5, i64 %6, ptr %7, ptr %8, i64 %9, i64 %10, i64 %11, i64 %12, i64 %13) {
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
  %33 = icmp eq i64 %32, 3
  br i1 %33, label %34, label %76

34:                                               ; preds = %14
  %35 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 3
  %36 = alloca [2 x i64], i64 1, align 8
  store [2 x i64] %35, ptr %36, align 4
  %37 = getelementptr [2 x i64], ptr %36, i32 0, i32 0
  %38 = load i64, ptr %37, align 4
  %39 = mul i64 %38, 2
  %40 = getelementptr double, ptr null, i64 %39
  %41 = ptrtoint ptr %40 to i64
  %42 = call ptr @malloc(i64 %41)
  %43 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } undef, ptr %42, 0
  %44 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %43, ptr %42, 1
  %45 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %44, i64 0, 2
  %46 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %45, i64 %38, 3, 0
  %47 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %46, i64 2, 3, 1
  %48 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %47, i64 2, 4, 0
  %49 = insertvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %48, i64 1, 4, 1
  br label %50

50:                                               ; preds = %73, %34
  %51 = phi i64 [ %74, %73 ], [ 0, %34 ]
  %52 = icmp slt i64 %51, %38
  br i1 %52, label %53, label %75

53:                                               ; preds = %50
  br label %54

54:                                               ; preds = %57, %53
  %55 = phi i64 [ %72, %57 ], [ 0, %53 ]
  %56 = icmp slt i64 %55, 2
  br i1 %56, label %57, label %73

57:                                               ; preds = %54
  %58 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %21, 1
  %59 = mul i64 %51, 2
  %60 = add i64 %59, %55
  %61 = getelementptr double, ptr %58, i64 %60
  %62 = load double, ptr %61, align 8
  %63 = extractvalue { ptr, ptr, i64, [2 x i64], [2 x i64] } %28, 1
  %64 = mul i64 %51, 2
  %65 = add i64 %64, %55
  %66 = getelementptr double, ptr %63, i64 %65
  %67 = load double, ptr %66, align 8
  %68 = fadd double %62, %67
  %69 = mul i64 %51, 2
  %70 = add i64 %69, %55
  %71 = getelementptr double, ptr %42, i64 %70
  store double %68, ptr %71, align 8
  %72 = add i64 %55, 1
  br label %54

73:                                               ; preds = %54
  %74 = add i64 %51, 1
  br label %50

75:                                               ; preds = %50
  ret { ptr, ptr, i64, [2 x i64], [2 x i64] } %49

76:                                               ; preds = %14
  call void @puts(ptr @assert_msg)
  call void @abort()
  unreachable
}

!llvm.module.flags = !{!0}

!0 = !{i32 2, !"Debug Info Version", i32 3}
