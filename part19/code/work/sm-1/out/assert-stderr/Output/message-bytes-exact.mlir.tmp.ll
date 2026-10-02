; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"

@mg_assert_stderr_msg_0 = private constant [36 x i8] c"bad \22quote\22 100% done, na\C3\AFve caf\C3\A9\0A"

declare void @abort()

declare i64 @write(i32, ptr, i64)

define void @boom() {
  br i1 false, label %3, label %1

1:                                                ; preds = %0
  %2 = call i64 @write(i32 1, ptr @mg_assert_stderr_msg_0, i64 36)
  call void @abort()
  unreachable

3:                                                ; preds = %0
  ret void
}

!llvm.module.flags = !{!0}

!0 = !{i32 2, !"Debug Info Version", i32 3}
