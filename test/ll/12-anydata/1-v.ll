@_bal_stack_guard = external global i8*
declare i8 addrspace(1)* @_bal_panic_construct(i64) cold
declare void @_bal_panic(i8 addrspace(1)*) noreturn cold
declare i8 addrspace(1)* @_bal_tagged_clear_exact_any(i8 addrspace(1)*) readnone
declare void @_Bb02ioprintln(i8 addrspace(1)*)
declare i8 addrspace(1)* @_bal_int_to_tagged(i64)
declare i8 addrspace(1)* @_bal_float_to_tagged(double)
define void @_B04rootmain() !dbg !5 {
  %val = alloca i8 addrspace(1)*
  %1 = alloca i8 addrspace(1)*
  %2 = alloca i8 addrspace(1)*
  %3 = alloca i8 addrspace(1)*
  %4 = alloca i8 addrspace(1)*
  %5 = alloca i8
  %6 = load i8*, i8** @_bal_stack_guard
  %7 = icmp ult i8* %5, %6
  br i1 %7, label %19, label %8
8:
  store i8 addrspace(1)* null, i8 addrspace(1)** %val
  %9 = load i8 addrspace(1)*, i8 addrspace(1)** %val, !dbg !8
  %10 = call i8 addrspace(1)* @_bal_tagged_clear_exact_any(i8 addrspace(1)* %9), !dbg !8
  call void @_Bb02ioprintln(i8 addrspace(1)* %10), !dbg !8
  store i8 addrspace(1)* null, i8 addrspace(1)** %1, !dbg !8
  %11 = call i8 addrspace(1)* @_bal_int_to_tagged(i64 5)
  store i8 addrspace(1)* %11, i8 addrspace(1)** %val
  %12 = load i8 addrspace(1)*, i8 addrspace(1)** %val, !dbg !9
  %13 = call i8 addrspace(1)* @_bal_tagged_clear_exact_any(i8 addrspace(1)* %12), !dbg !9
  call void @_Bb02ioprintln(i8 addrspace(1)* %13), !dbg !9
  store i8 addrspace(1)* null, i8 addrspace(1)** %2, !dbg !9
  %14 = call i8 addrspace(1)* @_bal_float_to_tagged(double 7.5)
  store i8 addrspace(1)* %14, i8 addrspace(1)** %val
  %15 = load i8 addrspace(1)*, i8 addrspace(1)** %val, !dbg !10
  %16 = call i8 addrspace(1)* @_bal_tagged_clear_exact_any(i8 addrspace(1)* %15), !dbg !10
  call void @_Bb02ioprintln(i8 addrspace(1)* %16), !dbg !10
  store i8 addrspace(1)* null, i8 addrspace(1)** %3, !dbg !10
  store i8 addrspace(1)* getelementptr(i8, i8 addrspace(1)* null, i64 3098476541289653620), i8 addrspace(1)** %val
  %17 = load i8 addrspace(1)*, i8 addrspace(1)** %val, !dbg !11
  %18 = call i8 addrspace(1)* @_bal_tagged_clear_exact_any(i8 addrspace(1)* %17), !dbg !11
  call void @_Bb02ioprintln(i8 addrspace(1)* %18), !dbg !11
  store i8 addrspace(1)* null, i8 addrspace(1)** %4, !dbg !11
  ret void
19:
  %20 = call i8 addrspace(1)* @_bal_panic_construct(i64 516), !dbg !7
  call void @_bal_panic(i8 addrspace(1)* %20)
  unreachable
}
!llvm.module.flags = !{!0}
!llvm.dbg.cu = !{!2}
!0 = !{i32 2, !"Debug Info Version", i32 3}
!1 = !DIFile(filename:"../../../compiler/testSuite/12-anydata/1-v.bal", directory:"")
!2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false)
!3 = !DISubroutineType(types: !4)
!4 = !{}
!5 = distinct !DISubprogram(name:"main", linkageName:"_B04rootmain", scope: !1, file: !1, line: 2, type: !3, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !2, retainedNodes: !6)
!6 = !{}
!7 = !DILocation(line: 0, column: 0, scope: !5)
!8 = !DILocation(line: 4, column: 4, scope: !5)
!9 = !DILocation(line: 6, column: 4, scope: !5)
!10 = !DILocation(line: 8, column: 4, scope: !5)
!11 = !DILocation(line: 10, column: 4, scope: !5)