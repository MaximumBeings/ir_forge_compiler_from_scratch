# 9. MLIR's Own Real C++ `ExecutionEngine` API, Called In-Process

**What you will understand:** a third, genuinely different way to run a real Mountain Goat program -- not `mlir-cpu-runner-18`'s CLI (Chapters 5 through 7), not an ahead-of-time compiled, standalone executable (Chapter 8), but MLIR's own real C++ `mlir::ExecutionEngine` class, driven directly from a small, hand-written host program that JIT-compiles and invokes Mountain Goat code in-process. This chapter also recounts, honestly, a real multi-step debugging process -- two genuine, non-obvious calling-convention rules this book's own first attempts got wrong, each one found only by crashing, inspecting registers, and fixing it for real.

**What you need to know first:** Chapter 1's own "unpacked memref descriptor" convention and Chapter 8's own struct-return convention for `_mlir_ciface_` wrappers. This chapter's own new ground: `mlir::ExecutionEngine`'s own real, separate packed-argument calling convention, genuinely different from both.

!!! tip "Compile and run"
    ```sh
    cd docs/part9/code
    ./run.sh          # cmake-build run_engine, then JIT-run add_tensors_llvm.mlir
    ```
    Needs `cmake`, `make`, `llvm-18-dev`, `libmlir-18-dev`. The program loads MLIR text produced in Chapter 8. Every listing and output on this page comes from these commands (and the chapter's own embedded files).


## The real question this chapter answers

`mlir-cpu-runner-18` and Chapter 8's own standalone executable are both real, but neither one is C++ code calling into a JIT-compiled Mountain Goat function *from inside the same process*, the way a real embedding application -- a database engine JIT-compiling a query plan, a numerical library JIT-compiling a kernel -- would actually use MLIR. This chapter answers directly: what does that real, embedded use look like in actual C++, using `mlir::ExecutionEngine` itself rather than a pre-built tool?

## A real, minimal C++ host program

```cpp
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/ExecutionEngine/CRunnerUtils.h"
#include "mlir/ExecutionEngine/ExecutionEngine.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/Parser/Parser.h"
#include "mlir/Target/LLVMIR/Dialect/Builtin/BuiltinToLLVMIRTranslation.h"
#include "mlir/Target/LLVMIR/Dialect/LLVMIR/LLVMToLLVMIRTranslation.h"

#include "llvm/Support/TargetSelect.h"

int main(int argc, char **argv) {
  llvm::InitializeNativeTarget();
  llvm::InitializeNativeTargetAsmPrinter();

  mlir::DialectRegistry registry;
  registry.insert<mlir::LLVM::LLVMDialect, mlir::func::FuncDialect>();
  mlir::registerLLVMDialectTranslation(registry);
  mlir::registerBuiltinDialectTranslation(registry);

  mlir::MLIRContext context(registry);
  context.loadAllAvailableDialects();

  mlir::OwningOpRef<mlir::ModuleOp> module =
      mlir::parseSourceFile<mlir::ModuleOp>(argv[1], &context);

  mlir::ExecutionEngineOptions options;
  auto maybeEngine = mlir::ExecutionEngine::create(module.get(), options);
  // ... (error handling omitted here, shown in full below)
}
```

Real, necessary setup this chapter's own program needs that neither prior execution path required directly: `llvm::InitializeNativeTarget()`/`InitializeNativeTargetAsmPrinter()` (ORC's own JIT needs the host's real native backend registered before it can compile anything), and `mlir::registerLLVMDialectTranslation`/`registerBuiltinDialectTranslation` -- real, specific translation interfaces `mlir::ExecutionEngine::create` needs to convert the parsed `ModuleOp` to real LLVM IR internally, the same real conversion Chapter 1's own `mlir-translate-18` performs as a separate command-line step.

## Real, honest debugging: three crashes, three real fixes

This chapter's own first real attempt to invoke `add_tensors` -- passing `lhs`, `rhs`, and a `result()`-wrapped output directly, mirroring `ExecutionEngine.h`'s own documented example for a plain scalar function -- genuinely crashed:

```text
Thread 1 "run_engine" received signal SIGSEGV, Segmentation fault.
0x00007ffff7fb9060 in add_tensors ()
#0  0x00007ffff7fb9060 in add_tensors ()
#1  0x00007ffff7fb9115 in _mlir_ciface_add_tensors ()
#2  0x00007ffff7fb9238 in _mlir__mlir_ciface_add_tensors ()
#3  0x00005555559670b8 in mlir::ExecutionEngine::invokePacked(...)
```

Genuinely real, non-obvious information in that one backtrace: a *third* function, `_mlir__mlir_ciface_add_tensors`, exists -- neither `add_tensors` (Chapter 4's own lowered function) nor `_mlir_ciface_add_tensors` (Chapter 8's own real C-interface wrapper), but a separate, generic "packed" adapter `mlir::ExecutionEngine::invokePacked` synthesizes internally, at JIT time, specifically to support `invoke<>`'s own generic, templated calling convention. Inspecting registers at the crash site (`r14 = 0x4000000000000000`, the exact real IEEE-754 bit pattern of `2.0`) revealed real, concrete evidence: a value from the *input array itself* had ended up in a register meant to hold a *pointer*.

**Real fix 1 -- memref arguments need one real, extra level of indirection.** `Argument<T>::pack`'s own real default pushes `&val` -- the address of the argument itself. For a plain scalar (this chapter's own first, simpler test, `scale(x: f64)`, confirmed working with this default), that is exactly what `_mlir_ciface_scale` expects: a pointer *to* the `f64` value. But a memref's own real `_mlir_ciface_` parameter type is already `!llvm.ptr` -- a pointer to the descriptor struct. The generic packed convention needs `args[i]` to point to *whatever the real ciface parameter's own type already is*, so for a memref, that means `args[i]` must be the address of a *pointer* variable holding `&descriptor`, not the address of the descriptor struct directly:

```cpp
// Wrong -- one level short:
engine->invoke("sum_memref", m, ...);
// Right -- m's own address, not m itself:
engine->invoke("sum_memref", &m, ...);
```

Confirmed directly on an isolated, minimal real test (`sum_memref`, one memref argument, scalar result): `sum_memref([1,2,3,4]) = 10`, genuinely correct.

**Real fix 2 -- a struct-typed result needs the same real extra indirection.** An isolated test returning a memref with no arguments at all (`make_ones() -> memref<4xf64>`) crashed the same real way, inside `_mlir_ciface_make_ones` itself this time -- the real `sret` destination pointer it received was invalid. The fix is the same real principle applied to the result side: `mlir::ExecutionEngine::result(...)` must wrap a *pointer* variable, not the descriptor struct directly:

```cpp
StridedMemRefType<double, 1> result{...};
StridedMemRefType<double, 1> *resultPtr = &result;
engine->invoke("make_ones", mlir::ExecutionEngine::result(resultPtr));
```

Confirmed directly: `make_ones() = [1, 1, 1, 1]`, genuinely correct.

**Real fix 3 -- combining both needs the result wrapper placed first, not last.** With both real fixes applied, `add_tensors` (two memref arguments *and* a memref result) still produced silently wrong output -- no crash, but `[[0, 0], [0, 0]]`, with `result.data` still pointing at this chapter's own original, untouched stack buffer rather than a freshly-allocated one. `_mlir_ciface_add_tensors`'s own real, fixed parameter order (confirmed directly in Chapter 8) places the `sret` result pointer *first*, ahead of the real arguments -- and the real packed convention, it turns out, mirrors that same real positional order rather than the documented scalar-return example's own "arguments, then result" order:

```cpp
// Silently wrong -- result last, doesn't match ciface's own real sret-first order:
engine->invoke("add_tensors", &lhs, &rhs, mlir::ExecutionEngine::result(resultPtr));
// Right -- result first, matching _mlir_ciface_add_tensors's own real parameter order:
engine->invoke("add_tensors", mlir::ExecutionEngine::result(resultPtr), &lhs, &rhs);
```

None of these three real rules are stated directly in `ExecutionEngine.h`'s own comments for the memref/struct case -- each one was found exactly the way this book's own stated discipline requires: by running real code, hitting a real failure, inspecting it directly (`gdb`, register values, backtraces), and fixing it, not by assuming the API's own scalar-case documentation generalizes without changes.

## Real worked example: the complete, correctly-invoked program

```mlir
func.func @add_tensors(%a: tensor<2x2xf64>, %b: tensor<2x2xf64>) -> tensor<2x2xf64> {
  %0 = mg.add %a, %b : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  func.return %0 : tensor<2x2xf64>
}
```

```cpp
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/ExecutionEngine/CRunnerUtils.h"
#include "mlir/ExecutionEngine/ExecutionEngine.h"
#include "mlir/ExecutionEngine/OptUtils.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/Parser/Parser.h"
#include "mlir/Target/LLVMIR/Dialect/Builtin/BuiltinToLLVMIRTranslation.h"
#include "mlir/Target/LLVMIR/Dialect/LLVMIR/LLVMToLLVMIRTranslation.h"

#include "llvm/Support/TargetSelect.h"

#include <iostream>

int main(int argc, char **argv) {
  if (argc != 2) {
    std::cerr << "usage: run_engine <llvm-dialect.mlir>\n";
    return 1;
  }

  llvm::InitializeNativeTarget();
  llvm::InitializeNativeTargetAsmPrinter();

  mlir::DialectRegistry registry;
  registry.insert<mlir::LLVM::LLVMDialect, mlir::func::FuncDialect>();
  mlir::registerLLVMDialectTranslation(registry);
  mlir::registerBuiltinDialectTranslation(registry);

  mlir::MLIRContext context(registry);
  context.loadAllAvailableDialects();

  mlir::OwningOpRef<mlir::ModuleOp> module =
      mlir::parseSourceFile<mlir::ModuleOp>(argv[1], &context);
  if (!module) {
    std::cerr << "failed to parse " << argv[1] << "\n";
    return 1;
  }

  mlir::ExecutionEngineOptions options;
  auto maybeEngine = mlir::ExecutionEngine::create(module.get(), options);
  if (!maybeEngine) {
    llvm::errs() << "failed to construct an execution engine: "
                 << maybeEngine.takeError() << "\n";
    return 1;
  }
  std::unique_ptr<mlir::ExecutionEngine> engine = std::move(*maybeEngine);

  double lhsData[4] = {1.0, 2.0, 3.0, 4.0};
  double rhsData[4] = {5.0, 6.0, 7.0, 8.0};
  double resultData[4] = {0.0, 0.0, 0.0, 0.0};

  StridedMemRefType<double, 2> lhs{
      lhsData, lhsData, 0, {2, 2}, {2, 1}};
  StridedMemRefType<double, 2> rhs{
      rhsData, rhsData, 0, {2, 2}, {2, 1}};
  StridedMemRefType<double, 2> result{
      resultData, resultData, 0, {2, 2}, {2, 1}};

  StridedMemRefType<double, 2> *resultPtr = &result;
  llvm::Error error = engine->invoke("add_tensors",
                                     mlir::ExecutionEngine::result(resultPtr),
                                     &lhs, &rhs);
  if (error) {
    llvm::errs() << "JIT invocation failed: " << error << "\n";
    return 1;
  }

  std::cout << "add_tensors([[1,2],[3,4]], [[5,6],[7,8]]) =\n";
  for (int64_t i = 0; i < 2; ++i) {
    for (int64_t j = 0; j < 2; ++j)
      std::cout << result.data[i * result.strides[0] + j * result.strides[1]]
                 << " ";
    std::cout << "\n";
  }
  return 0;
}
```

```
cmake --build build -j4
./run_engine add_tensors_llvm.mlir
```

**Real captured output:**
```text
add_tensors([[1,2],[3,4]], [[5,6],[7,8]]) =
6 8
10 12
```

The real, correct answer -- `[[1, 2], [3, 4]] + [[5, 6], [7, 8]] = [[6, 8], [10, 12]]` -- genuinely computed by a Mountain Goat function, JIT-compiled and invoked entirely in-process, through MLIR's own real `ExecutionEngine` C++ API, with no `mlir-cpu-runner-18` process and no separately-linked executable involved at all.

## How this chapter's own three execution paths actually differ

A real, concrete summary, now that all three exist in this book:

- **`mlir-cpu-runner-18`** (Chapters 5-7): a real, pre-built MLIR tool. It reads LLVM-dialect IR as input and JITs it, but the program itself never becomes an independent artifact -- nothing to copy elsewhere, nothing that exists once the tool exits.
- **A standalone executable** (Chapter 8): genuinely ahead-of-time compiled (`mlir-translate-18` + `clang-18`), producing a real, independent binary this chapter's own `ldd` check confirmed needs no MLIR runtime at all -- but that compilation step is fixed once and for all, at build time, not something a running program can do to new IR it receives later.
- **`mlir::ExecutionEngine`** (this chapter): genuinely embedded. A real host C++ program -- which could itself be any larger real application -- decides, at its own runtime, which MLIR module to compile and invoke, directly in-process, with no separate tool and no separate compile step a human runs beforehand.

## The complete source files

The excerpts above show the parts under discussion. These files appear in `code/` and are not shown elsewhere on this page; each is embedded exactly as it exists in the repository, collapsed so the narrative stays readable.

??? note "`CMakeLists.txt`"

    ```cmake
    --8<-- "docs/part9/code/CMakeLists.txt"
    ```

??? note "`add_tensors.mlir`"

    ```mlir
    --8<-- "docs/part9/code/add_tensors.mlir"
    ```

??? note "`run_engine.cpp`"

    ```cpp
    --8<-- "docs/part9/code/run_engine.cpp"
    ```

## What later chapters changed

No later chapter changed this chapter's code, and the Chapter 15/16 suite does not cover it: the `ExecutionEngine` host program is still tested only by the recorded run shown above.

## Chapter summary

This chapter built a real, minimal C++ host program using MLIR's own `mlir::ExecutionEngine` class directly, JIT-compiling and invoking a real Mountain Goat function entirely in-process -- a third, genuinely distinct execution mechanism from both `mlir-cpu-runner-18`'s CLI and Chapter 8's own ahead-of-time compiled executable. Getting there needed three real, non-obvious fixes, each one found by actually crashing the program and inspecting it directly rather than guessing from the API's own documented scalar-argument example: memref arguments and memref/struct results both need an extra real level of pointer indirection beyond what a plain scalar needs, and when a function has both memref arguments and a memref result, the `result()` wrapper has to be placed first in the `invoke<>()` call, matching the real, fixed `sret`-first parameter order Chapter 8 already established for `_mlir_ciface_` wrappers.

Deliberately out of scope, stated explicitly: this chapter's own host program hard-codes its one function's own specific shape (two `2x2` arguments, one `2x2` result) -- no general-purpose, shape-agnostic invocation helper is built here. `mlir::ExecutionEngine`'s own real support for loading external shared libraries at JIT time (`--shared-libs`'s own real C++-API equivalent, which this chapter's own program never needed since it uses no runtime-library calls like `printMemrefF64`) is not demonstrated.

## Self-check questions

**1. The chapter's own first, working test (`scale`, a plain `f64` argument and result) needed none of the three real fixes this chapter ultimately found. What real, specific property of a plain scalar type explains why?**

Worked answer: `_mlir_ciface_scale`'s own real parameter and return types are both plain `f64` -- not pointers to anything. `Argument<T>::pack`'s own real default (`args.push_back(&val)`) already produces exactly what a plain scalar ciface parameter needs: a pointer *to* the value. The real complication this chapter's own later fixes address only arises when the ciface parameter or return type is *itself* already a pointer (as every memref descriptor's own real ciface representation is) -- a case the scalar example never exercises at all.

**2. Why did the chapter's own second real fix (wrapping the result in an extra pointer, `StridedMemRefType<double,1> *resultPtr = &result;`) have to come before the *third* fix (reordering `result()` to be first), rather than either one alone being sufficient for `add_tensors`?**

Worked answer: these two real fixes address two genuinely separate real problems. The indirection fix (fix 2) addresses *what value* each packed argument slot must actually hold -- a pointer-to-pointer for a struct-typed result, confirmed in isolation on `make_ones` (no arguments at all, so argument *order* was never in question there). The ordering fix (fix 3) addresses *which position in the call* that correctly-built value has to occupy, a question that genuinely could not arise until a real test combined a struct result with real arguments, which `make_ones`'s own isolated test never did. Both real, independent facts had to be true simultaneously for `add_tensors` to work; fixing only one left the other real bug fully intact.

**3. The chapter states the third real fix was found because `add_tensors` "produced silently wrong output -- no crash." Why is a silent wrong answer a more concerning kind of real bug than the earlier crashes, from a debugging-discipline standpoint?**

Worked answer: a real crash is self-announcing -- `gdb`'s own backtrace pointed directly at the faulting instruction and the garbage register values, making the first two real bugs comparatively fast to diagnose. A silently wrong answer produces no error at all; the program runs to completion and prints a plausible-looking (if incorrect) result. Catching it at all depended entirely on this book's own stated discipline of comparing every real captured output against the independently-known correct answer (`[[6, 8], [10, 12]]`, confirmed in Chapters 5, 6, and 8 through three unrelated execution paths) rather than trusting that "it ran without crashing" means "it ran correctly."

**4. Why does the chapter claim `mlir::ExecutionEngine` is "genuinely embedded" in a way Chapter 8's own standalone executable is not, given both ultimately run the exact same real computation on the exact same real hardware?**

Worked answer: Chapter 8's own executable has its one specific function's own native machine code fixed permanently at the moment `clang-18` links it -- running it again, or on another machine, executes that exact same pre-compiled code, with no opportunity for the program itself to decide, while running, to compile some *different* MLIR module it has not seen before. This chapter's own host program, by contrast, parses and JIT-compiles whatever module its one command-line argument names, *while it is already running* -- the real, defining property of genuine embedding: the decision of what to compile is made at the embedding application's own runtime, not fixed in advance at the embedding application's own build time.

**5. This chapter's own host program calls both `mlir::registerLLVMDialectTranslation` and `mlir::registerBuiltinDialectTranslation` before parsing its input module. What real, concrete failure did omitting the second of these two calls produce, and why specifically that error?**

Worked answer: omitting `registerBuiltinDialectTranslation` produced a real, genuine failure directly from `mlir::ExecutionEngine::create` itself: `"cannot be converted to LLVM IR: missing LLVMTranslationDialectInterface registration for dialect for op: builtin.module"`. Every real MLIR module, including one already fully lowered to the `llvm` dialect, is still wrapped in a real `builtin.module` operation at its own top level -- and translating that wrapper to real LLVM IR needs its own real, separate translation interface registered, exactly as the `llvm` dialect's own operations (`llvm.func`, `llvm.call`, and so on) needed `registerLLVMDialectTranslation` registered for them specifically.
