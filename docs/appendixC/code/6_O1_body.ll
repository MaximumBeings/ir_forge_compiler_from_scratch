define dso_local void @scale(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, i64 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i64 %2, 0
  br i1 %4, label %6, label %5
5:                                                ; preds = %6, %3
  ret void
6:                                                ; preds = %3, %6
  %7 = phi i64 [ %12, %6 ], [ 0, %3 ]
  %8 = getelementptr inbounds double, ptr %1, i64 %7
  %9 = load double, ptr %8, align 8, !tbaa !5
  %10 = fmul double %9, 2.000000e+00
  %11 = getelementptr inbounds double, ptr %0, i64 %7
  store double %10, ptr %11, align 8, !tbaa !5
  %12 = add nuw nsw i64 %7, 1
  %13 = icmp eq i64 %12, %2
  br i1 %13, label %5, label %6, !llvm.loop !9
}
