define dso_local void @scale(ptr noundef %0, ptr noundef %1, i64 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i64, align 8
  %7 = alloca i64, align 8
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  store i64 %2, ptr %6, align 8
  store i64 0, ptr %7, align 8
  br label %8
8:                                                ; preds = %21, %3
  %9 = load i64, ptr %7, align 8
  %10 = load i64, ptr %6, align 8
  %11 = icmp slt i64 %9, %10
  br i1 %11, label %12, label %24
12:                                               ; preds = %8
  %13 = load ptr, ptr %5, align 8
  %14 = load i64, ptr %7, align 8
  %15 = getelementptr inbounds double, ptr %13, i64 %14
  %16 = load double, ptr %15, align 8
  %17 = fmul double %16, 2.000000e+00
  %18 = load ptr, ptr %4, align 8
  %19 = load i64, ptr %7, align 8
  %20 = getelementptr inbounds double, ptr %18, i64 %19
  store double %17, ptr %20, align 8
  br label %21
21:                                               ; preds = %12
  %22 = load i64, ptr %7, align 8
  %23 = add nsw i64 %22, 1
  store i64 %23, ptr %7, align 8
  br label %8, !llvm.loop !6
24:                                               ; preds = %8
  ret void
}
