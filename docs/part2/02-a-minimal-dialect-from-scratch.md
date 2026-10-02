# 2. A Minimal Dialect From Scratch: Mountain Goat's Own `mg` Dialect

**What you will understand:** how a real MLIR dialect is actually defined -- not sketched, but genuinely built, through MLIR's own real TableGen/ODS (Operation Definition Specification) system, compiled by the real `mlir-tblgen-18` generator, and wired into a real, custom command-line tool (`mg-opt`) that parses, prints, and verifies it. This chapter introduces **Mountain Goat**, this book's own toy source language (tensor/array expressions and functions), and builds its own real dialect, `mg`, from nothing.

**What you need to know first:** Chapter 1's own vocabulary (dialects, operations, `mlir-opt-18`'s role as parser/verifier/pass-driver) and enough C++ to read a class definition. TableGen itself -- the declarative language the `.td` files in this chapter are written in -- is explained here, for the first time, from its own real official documentation.

## The real question this chapter answers

Chapter 1 used only dialects MLIR already ships with (`func`, `arith`, `scf`, `memref`, `llvm`). Those are real and useful, but Mountain Goat is not one of MLIR's built-in languages -- it is this book's own toy language, and it needs its own real vocabulary: a way to write "add these two tensors," "transpose this one," that is specific to Mountain Goat rather than borrowed wholesale from a dialect meant for something else. The real question this chapter answers: how does a real MLIR dialect actually get defined, in genuine, compilable code, rather than invented ad hoc as bare strings the parser happens to accept?

## Mountain Goat, briefly

Mountain Goat is a small toy language of tensor/array expressions and functions -- the same real category of toy language MLIR's own official tutorial uses for exactly this purpose. That tutorial (read directly from `mlir/examples/toy/` and `mlir/docs/Tutorials/Toy/` in the real `llvm/llvm-project` repository, its own rendered site being unreachable from this book's own sandbox, the same workaround Chapter 1 used) states its own goal plainly:

> "This tutorial runs through the implementation of a basic toy language... This tutorial assumes you have cloned and built MLIR... Toy is a tensor-based language that allows you to define functions, perform some math computation, and print results." (`mlir/docs/Tutorials/Toy/Ch-1.md`)

This chapter cites that tutorial as real precedent for the *shape* of a toy tensor language -- it does not copy the tutorial's own code. Mountain Goat's own dialect, built fresh in this chapter, covers a smaller, genuinely independent slice: a dense tensor constant, elementwise addition, and 2-D transpose, with real functions represented by MLIR's own built-in `func` dialect rather than a second, reinvented `mg.func`. A real Mountain Goat program, using only dialects that exist by the end of this chapter, looks like this:

```mlir
func.func @main() {
  %0 = mg.constant dense<[[1.0, 2.0], [3.0, 4.0]]> : tensor<2x2xf64>
  %1 = mg.constant dense<[[1.0, 1.0], [1.0, 1.0]]> : tensor<2x2xf64>
  %2 = mg.add %0, %1 : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  %3 = mg.transpose %2 : tensor<2x2xf64> to tensor<2x2xf64>
  mg.print %3 : tensor<2x2xf64>
  func.return
}
```

Four real, new operations appear here -- `mg.constant`, `mg.add`, `mg.transpose`, `mg.print` -- none of which exist anywhere in MLIR until this chapter defines them.

## MLIR's own real TableGen/ODS mechanism

MLIR's own official documentation on defining dialects states directly why a declarative specification, rather than hand-written C++, is the expected way to do this:

> "MLIR provides a powerful declaratively specification mechanism via TableGen; a generic language with tooling to maintain records of domain-specific information; that simplifies the definition process by automatically generating all of the necessary boilerplate C++ code, significantly reduces maintainence burden when changing aspects of dialect definitions, and also provides additional tools on top (such as documentation generation)." (`mlir/docs/DefiningDialects/_index.md`)

Concretely, this means: a dialect and its operations are written once as declarative records in a `.td` file, and a real tool -- `mlir-tblgen-18`, installed alongside `mlir-opt-18` since Chapter 1 -- reads that file and genuinely generates the C++ classes (`.h.inc`/`.cpp.inc` files) that implement parsing, printing, verification boilerplate, and accessor methods for every operation. This chapter writes two real `.td` files: one declaring the `mg` dialect itself, one declaring its four operations.

### The dialect's own `.td` file

```tablegen
#ifndef MG_DIALECT_TD
#define MG_DIALECT_TD

include "mlir/IR/OpBase.td"

def Mg_Dialect : Dialect {
  let name = "mg";
  let summary = "Mountain Goat: a minimal tensor/array-expression dialect";
  let description = [{
    The Mountain Goat (`mg`) dialect represents the small subset of the
    Mountain Goat toy language that is specific to it: dense tensor
    constants, elementwise addition, and 2-D transpose. Function
    definitions and calls are deliberately represented with the real
    builtin `func` dialect instead of a reinvented `mg.func` -- Mountain
    Goat's own dialect stays minimal, covering only what `func` does not
    already cover.
  }];
  let cppNamespace = "::mg";
}

class Mg_Op<string mnemonic, list<Trait> traits = []> :
    Op<Mg_Dialect, mnemonic, traits>;

#endif // MG_DIALECT_TD
```

`Dialect` is a real TableGen class MLIR itself ships (`mlir/IR/OpBase.td`); `Mg_Dialect` is this chapter's own real specialization of it, naming the dialect `mg` and the C++ namespace it generates into (`::mg`). `Mg_Op`, defined just below it, is a small real convenience: every one of Mountain Goat's own operations is declared as `Mg_Op<"name", [traits]>` rather than repeating `Op<Mg_Dialect, "name", [traits]>` four separate times.

### The operations' own `.td` file

```tablegen
#ifndef MG_OPS_TD
#define MG_OPS_TD

include "mg/MgDialect.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/IR/BuiltinAttributeInterfaces.td"

def ConstantOp : Mg_Op<"constant", [Pure, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let summary = "dense tensor constant, Mountain Goat's own array literal";
  let description = [{
    The result type is never written out separately: it is inferred
    straight from the dense attribute's own type, since a constant's shape
    is already fully determined by its literal value. `dense<[[1.0, 2.0],
    [3.0, 4.0]]> : tensor<2x2xf64>` carries its own type, so repeating it
    after the op would just be the same fact spelled twice.
  }];
  let arguments = (ins F64ElementsAttr:$value);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$value attr-dict";
}

def AddOp : Mg_Op<"add", [Pure]> {
  let summary = "elementwise add of two equal-shaped tensors";
  let arguments = (ins F64Tensor:$lhs, F64Tensor:$rhs);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` type($lhs) `,` type($rhs) `->` type($result)";
}

def TransposeOp : Mg_Op<"transpose", [Pure]> {
  let summary = "transpose of a 2-D tensor";
  let arguments = (ins F64Tensor:$input);
  let results = (outs F64Tensor:$result);
  let assemblyFormat = "$input attr-dict `:` type($input) `to` type($result)";
  let hasVerifier = 1;
}

def PrintOp : Mg_Op<"print"> {
  let summary = "print a tensor at runtime";
  let arguments = (ins F64Tensor:$input);
  let assemblyFormat = "$input attr-dict `:` type($input)";
}

#endif // MG_OPS_TD
```

Four real things are genuinely worth pointing out in this one file, each a real decision this dialect actually had to make:

- **`ConstantOp`'s `assemblyFormat` has no `type($result)`.** A `dense<...> : tensor<2x2xf64>` attribute already carries its own type -- writing `type($result)` as well would make the same fact appear twice in the text. Instead, `ConstantOp` declares `DeclareOpInterfaceMethods<InferTypeOpInterface>`, MLIR's own real interface for "this operation's result type is computed, not written down separately" -- the real C++ implementation is in `MgDialect.cpp`, below.
- **`AddOp`'s `assemblyFormat` spells out `type($lhs)`, `type($rhs)`, and `type($result)` explicitly.** Unlike `ConstantOp`, there is no attribute here to infer a type from -- two tensor operands, genuinely unconstrained to match each other at the ODS level, so every one of the three types has to appear in the text for the parser to reconstruct them.
- **`TransposeOp` declares `let hasVerifier = 1;`**, meaning `mlir-tblgen-18` generates a call out to a real, hand-written C++ function (`TransposeOp::verify()`, in `MgDialect.cpp`) rather than relying only on ODS's own declarative type constraints -- because "the output shape is the input shape, reversed" is a relationship ODS's own constraint language cannot express directly.
- **`PrintOp` has no `Pure` trait.** `ConstantOp`, `AddOp`, and `TransposeOp` are all marked `Pure` -- MLIR's real trait meaning "has no side effects, safe to delete if its result is unused, safe to reorder." `mg.print` is genuinely not pure: it performs real I/O, and marking it `Pure` would be a real, incorrect claim a later optimization pass could act on (deleting a "dead" print because nothing uses its non-existent result).

## The real generated C++

`mlir-tblgen-18` turns `MgOps.td` into real C++ header and source fragments, driven by four separate `mlir_tablegen()` invocations in this chapter's own `CMakeLists.txt` (shown in full below): `-gen-op-decls`, `-gen-op-defs`, `-gen-dialect-decls`, `-gen-dialect-defs`. These are genuinely generated, not hand-written -- running the real command directly shows exactly what `ConstantOp`'s own generated class declaration looks like:

```
mlir-tblgen-18 -gen-op-decls -I /usr/lib/llvm-18/include MgOps.td
```

**Real captured excerpt (cloud sandbox, `mlir-tblgen-18`, Ubuntu LLVM 18.1.3):**
```cpp
class ConstantOp : public ::mlir::Op<ConstantOp, ::mlir::OpTrait::ZeroRegions, ::mlir::OpTrait::OneResult,
    ::mlir::OpTrait::OneTypedResult<::mlir::TensorType>::Impl, ::mlir::OpTrait::ZeroSuccessors,
    ::mlir::OpTrait::ZeroOperands, ::mlir::OpTrait::OpInvariants, ::mlir::BytecodeOpInterface::Trait,
    ::mlir::ConditionallySpeculatable::Trait, ::mlir::OpTrait::AlwaysSpeculatableImplTrait,
    ::mlir::MemoryEffectOpInterface::Trait, ::mlir::InferTypeOpInterface::Trait> {
public:
  using Op::Op;
  using Op::print;
  using Adaptor = ConstantOpAdaptor;
  ...
  static ::mlir::LogicalResult inferReturnTypes(::mlir::MLIRContext *context,
      ::std::optional<::mlir::Location> location, ::mlir::ValueRange operands,
      ::mlir::DictionaryAttr attributes, ::mlir::OpaqueProperties properties,
      ::mlir::RegionRange regions, ::llvm::SmallVectorImpl<::mlir::Type>&inferredReturnTypes);
  ...
};
```

Every real trait this chapter's own `MgOps.td` asked for -- `Pure` (expanded here into `ConditionallySpeculatable`/`AlwaysSpeculatableImplTrait`/`MemoryEffectOpInterface`), `DeclareOpInterfaceMethods<InferTypeOpInterface>` (the real `inferReturnTypes` declaration) -- is genuinely present in this generated class, produced by `mlir-tblgen-18` from nothing but the declarative `.td` file above.

Two real, hand-written C++ pieces complete the dialect: the header that pulls the generated fragments together, and the source file supplying the two methods ODS could not generate (`TransposeOp::verify`, `ConstantOp::inferReturnTypes`).

```cpp
#ifndef MG_MGDIALECT_H
#define MG_MGDIALECT_H

#include "mlir/IR/Dialect.h"

#include "mg/MgOpsDialect.h.inc"

#endif // MG_MGDIALECT_H
```

```cpp
#ifndef MG_MGOPS_H
#define MG_MGOPS_H

#include "mlir/Bytecode/BytecodeOpInterface.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/Interfaces/InferTypeOpInterface.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

#include "mg/MgDialect.h"

#define GET_OP_CLASSES
#include "mg/MgOps.h.inc"

#endif // MG_MGOPS_H
```

```cpp
#include "mg/MgDialect.h"
#include "mg/MgOps.h"

#include "mlir/IR/Builders.h"
#include "mlir/IR/OpImplementation.h"

using namespace mg;

#include "mg/MgOpsDialect.cpp.inc"

void MgDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "mg/MgOps.cpp.inc"
      >();
}

#define GET_OP_CLASSES
#include "mg/MgOps.cpp.inc"

mlir::LogicalResult ConstantOp::inferReturnTypes(
    mlir::MLIRContext *context, std::optional<mlir::Location> location,
    mlir::ValueRange operands, mlir::DictionaryAttr attributes,
    mlir::OpaqueProperties properties, mlir::RegionRange regions,
    llvm::SmallVectorImpl<mlir::Type> &inferredReturnTypes) {
  Adaptor adaptor(operands, attributes, properties, regions);
  inferredReturnTypes.push_back(adaptor.getValue().getType());
  return mlir::success();
}

mlir::LogicalResult TransposeOp::verify() {
  auto inputType = llvm::cast<mlir::RankedTensorType>(getInput().getType());
  auto resultType = llvm::cast<mlir::RankedTensorType>(getResult().getType());
  if (inputType.getRank() != 2 || resultType.getRank() != 2)
    return emitOpError("mg.transpose only supports rank-2 tensors");
  auto inShape = inputType.getShape();
  auto outShape = resultType.getShape();
  if (inShape[0] != outShape[1] || inShape[1] != outShape[0])
    return emitOpError("mg.transpose result shape must be the input shape reversed");
  return mlir::success();
}
```

`TransposeOp::verify()` is genuine, real shape-checking C++: it reads both the input's and result's real `RankedTensorType`, confirms both are rank 2, and confirms the result's own dimensions are the input's own dimensions reversed -- exactly the relationship `hasVerifier = 1` exists for. `ConstantOp::inferReturnTypes` is the other half of the `InferTypeOpInterface` promise from `MgOps.td`: given the operation's real operands and attributes (wrapped in a real `Adaptor`), it reads the `value` attribute's own real type straight off and hands it back as the one inferred result type.

## A real tool to parse and verify Mountain Goat: `mg-opt`

A dialect by itself is a library, not something runnable from the command line. This chapter builds one more small real thing: `mg-opt`, a genuine standalone tool built on MLIR's own real `MlirOptMain` entry point (`mlir/Tools/mlir-opt/MlirOptMain.h`) -- the same real machinery `mlir-opt-18` itself is built on -- registering Mountain Goat's own `mg` dialect alongside the built-in `func` dialect.

```cpp
#include "mg/MgDialect.h"

#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/InitAllDialects.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"

int main(int argc, char **argv) {
  mlir::DialectRegistry registry;
  registry.insert<mlir::func::FuncDialect>();
  registry.insert<mg::MgDialect>();
  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "Mountain Goat (mg) dialect driver\n", registry));
}
```

```cmake
cmake_minimum_required(VERSION 3.20)
project(mg_dialect)

find_package(MLIR REQUIRED CONFIG)

list(APPEND CMAKE_MODULE_PATH "${MLIR_CMAKE_DIR}")
list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(TableGen)
include(AddLLVM)
include(AddMLIR)
include(HandleLLVMOptions)

include_directories(${LLVM_INCLUDE_DIRS})
include_directories(${MLIR_INCLUDE_DIRS})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)
include_directories(${CMAKE_CURRENT_BINARY_DIR}/include)
add_definitions(${LLVM_DEFINITIONS})

set(LLVM_TARGET_DEFINITIONS include/mg/MgOps.td)
mlir_tablegen(include/mg/MgOps.h.inc -gen-op-decls)
mlir_tablegen(include/mg/MgOps.cpp.inc -gen-op-defs)
mlir_tablegen(include/mg/MgOpsDialect.h.inc -gen-dialect-decls)
mlir_tablegen(include/mg/MgOpsDialect.cpp.inc -gen-dialect-defs)
add_public_tablegen_target(MgOpsIncGen)

add_library(MgDialect lib/MgDialect.cpp)
add_dependencies(MgDialect MgOpsIncGen)
target_link_libraries(MgDialect PUBLIC MLIRIR MLIRFuncDialect)

add_executable(mg-opt tools/mg-opt.cpp)
target_link_libraries(mg-opt PRIVATE
  MgDialect
  MLIRIR
  MLIRFuncDialect
  MLIROptLib
  MLIRParser
  MLIRSupport
)
```

Building this real out-of-tree dialect needs two real CMake config files this chapter's own authoring environment did not have located by default: `MLIRConfig.cmake` and `LLVMConfig.cmake`, both installed by `libmlir-18-dev`/`llvm-18-dev` but not on CMake's own default search path, so both are passed explicitly:

```
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
  -DMLIR_DIR=/usr/lib/llvm-18/lib/cmake/mlir \
  -DLLVM_DIR=/usr/lib/llvm-18/lib/cmake/llvm
cmake --build build -j4
```

**Real captured configure output (tail):**
```text
-- Looking for os_signpost_interval_begin
-- Looking for os_signpost_interval_begin - not found
-- Configuring done (4.4s)
-- Generating done (0.0s)
-- Build files have been written to: <build-dir>/build
```

**Real captured build output:**
```text
[ 12%] Building include/mg/MgOps.cpp.inc...
[ 25%] Building include/mg/MgOpsDialect.cpp.inc...
[ 37%] Building include/mg/MgOps.h.inc...
[ 50%] Building include/mg/MgOpsDialect.h.inc...
[ 50%] Built target MgOpsIncGen
[ 62%] Building CXX object CMakeFiles/MgDialect.dir/lib/MgDialect.cpp.o
[ 75%] Linking CXX static library libMgDialect.a
[ 75%] Built target MgDialect
[ 87%] Building CXX object CMakeFiles/mg-opt.dir/tools/mg-opt.cpp.o
[100%] Linking CXX executable mg-opt
[100%] Built target mg-opt
```

Both steps genuinely succeeded: `MgOpsIncGen` (the four real `mlir-tblgen-18` invocations), `MgDialect` (the real static library), and `mg-opt` (the real executable) all built without error.

## Real worked example: a Mountain Goat program, parsed and verified

Feeding this chapter's own opening example straight to the real, just-built `mg-opt`:

```
./mg-opt mountain_goat.mlir
```

```mlir
func.func @main() {
  %0 = mg.constant dense<[[1.0, 2.0], [3.0, 4.0]]> : tensor<2x2xf64>
  %1 = mg.constant dense<[[1.0, 1.0], [1.0, 1.0]]> : tensor<2x2xf64>
  %2 = mg.add %0, %1 : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
  %3 = mg.transpose %2 : tensor<2x2xf64> to tensor<2x2xf64>
  mg.print %3 : tensor<2x2xf64>
  func.return
}
```

**Real captured output (cloud sandbox, this chapter's own `mg-opt`):**
```text
module {
  func.func @main() {
    %0 = mg.constant dense<[[1.000000e+00, 2.000000e+00], [3.000000e+00, 4.000000e+00]]> : tensor<2x2xf64>
    %1 = mg.constant dense<1.000000e+00> : tensor<2x2xf64>
    %2 = mg.add %0, %1 : tensor<2x2xf64>, tensor<2x2xf64> -> tensor<2x2xf64>
    %3 = mg.transpose %2 : tensor<2x2xf64> to tensor<2x2xf64>
    mg.print %3 : tensor<2x2xf64>
    return
  }
}
```

Genuinely parsed, genuinely verified, and printed back out -- the one-element `dense<1.000000e+00>` on `%1` is `mg-opt`'s own real, canonical printed form for a uniform (all-elements-equal) dense constant, MLIR's own real printer choosing the shortest form that still round-trips to the same value.

## Real worked example: the verifier genuinely rejects a bad shape

`TransposeOp::verify()` is not decoration -- it is real code the real `mg-opt` genuinely runs on every `mg.transpose` it parses. Feeding it a deliberately wrong transpose, where the declared result shape is not the input shape reversed:

```mlir
func.func @main() {
  %0 = mg.constant dense<[[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]> : tensor<2x3xf64>
  %1 = mg.transpose %0 : tensor<2x3xf64> to tensor<2x3xf64>
  mg.print %1 : tensor<2x3xf64>
  func.return
}
```

```
./mg-opt bad_transpose.mlir
```

**Real captured output:**
```text
bad_transpose.mlir:3:8: error: 'mg.transpose' op mg.transpose result shape must be the input shape reversed
  %1 = mg.transpose %0 : tensor<2x3xf64> to tensor<2x3xf64>
       ^
bad_transpose.mlir:3:8: note: see current operation: %1 = "mg.transpose"(%0) : (tensor<2x3xf64>) -> tensor<2x3xf64>
```

`mg-opt` genuinely refuses this input and prints nothing but the real diagnostic -- the exact same real contract Chapter 1 relied on for `mlir-opt-18` itself: a verifier that fails stops the tool from pretending the IR is valid.

## An honest gap: `mg.add` does not yet check its own operand shapes

This chapter's own `AddOp` has no `hasVerifier`, and ODS's own built-in type constraints (`F64Tensor` on each operand) say nothing about the operands' shapes *matching* each other. Feeding `mg-opt` a real `mg.add` whose two operands are genuinely different shapes (`tensor<2x2xf64>` and `tensor<3xf64>`) is revealing, run directly rather than assumed:

```
./mg-opt mismatched_add.mlir
```

**Real captured output:**
```text
module {
  func.func @main() {
    %0 = mg.constant dense<[[1.000000e+00, 2.000000e+00], [3.000000e+00, 4.000000e+00]]> : tensor<2x2xf64>
    %1 = mg.constant dense<[1.000000e+00, 2.000000e+00, 3.000000e+00]> : tensor<3xf64>
    %2 = mg.add %0, %1 : tensor<2x2xf64>, tensor<3xf64> -> tensor<2x2xf64>
    mg.print %2 : tensor<2x2xf64>
    return
  }
}
```

`mg-opt` genuinely accepts this -- silently. This is a real, honest gap, stated outright rather than quietly worked around: Mountain Goat's own dialect, as built in this chapter, does not yet verify that `mg.add`'s two operands agree in shape. Fixing it is ordinary, mechanical work (a `hasVerifier = 1` on `AddOp`, mirroring `TransposeOp`'s own real pattern above) -- deliberately left undone here so this chapter's own self-check questions below can ask about it directly, and so Part 2's own real canonicalization/verification-pass work has a genuine, motivating gap to close rather than a strawman.

## The complete source files

The excerpts above show the parts under discussion. These files appear in `code/` and are not shown elsewhere on this page; each is embedded exactly as it exists in the repository, collapsed so the narrative stays readable.

??? note "`cmake_build_out.txt`"

    ```text
    --8<-- "docs/part2/code/cmake_build_out.txt"
    ```

??? note "`cmake_configure_out.txt`"

    ```text
    --8<-- "docs/part2/code/cmake_configure_out.txt"
    ```

## What later chapters changed

Chapter 3 closed this chapter's stated `mg.add` shape-check gap. Chapter 13 later replaced both verifiers in `MgDialect.cpp` (plain shape equality became a dynamic-aware compatibility check, and the unchecked `cast` to a ranked tensor became a `dyn_cast` with an explicit diagnostic), and Chapter 14 added the `cf` dialect to `mg-opt`'s registry. The dialect's own build, shown here, is not covered by the Chapter 15 test suite.

## Chapter summary

This chapter built Mountain Goat's own real dialect, `mg`, from nothing: a real `.td` dialect declaration and a real `.td` operation declaration file, compiled by the genuine `mlir-tblgen-18` generator into real C++ classes; two real hand-written C++ methods (`TransposeOp::verify`, `ConstantOp::inferReturnTypes`) supplying what ODS's own declarative language could not express directly; and a real, genuinely-built `mg-opt` tool, constructed on MLIR's own real `MlirOptMain` entry point, that parses, prints, and verifies real Mountain Goat programs. Every real claim in this chapter was run, not asserted: the dialect genuinely compiled, `mg-opt` genuinely parsed a real program, and its real verifier genuinely rejected a real bad input -- and, honestly, genuinely failed to reject another bad input this chapter deliberately left unguarded.

Deliberately out of scope, stated explicitly: no real frontend exists yet that parses Mountain Goat's own *source syntax* (as opposed to its MLIR textual form) into this dialect -- every example in this chapter was written directly in MLIR's own generic/custom assembly syntax. No lowering of `mg` operations to any other dialect has happened yet; that begins in Part 2. And, as shown directly above, `mg.add`'s own shape verification is genuinely incomplete.

## Self-check questions

**1. Why does `ConstantOp` use `DeclareOpInterfaceMethods<InferTypeOpInterface>` instead of just writing `type($result)` in its `assemblyFormat`, the way `AddOp` does?**

Worked answer: `ConstantOp`'s one operand is a `dense<...> : tensor<2x2xf64>` attribute, which already carries a full, real type as part of its own attribute syntax. Writing `type($result)` as well would ask the person reading or writing Mountain Goat IR to state that same tensor type a second time, with no way for the parser to catch it if the two ever disagreed. `AddOp` has no such attribute to read a type from -- both its operands are plain `Value`s, so without `InferTypeOpInterface`, its own result type genuinely cannot be reconstructed from anything else already in the text.

**2. `TransposeOp` declares `let hasVerifier = 1;` in `MgOps.td`. What, concretely, does `mlir-tblgen-18` generate in response to that one line, and what does this chapter's own code supply that ODS could not generate on its own?**

Worked answer: `mlir-tblgen-18` generates a real call to `TransposeOp::verify()` inside the operation's generated `verifyInvariantsImpl()`, but generates no body for `verify()` itself -- `hasVerifier = 1` is a real request for hand-written C++, not an instruction ODS can fulfill declaratively. This chapter's own `MgDialect.cpp` supplies that body: reading both tensor types' real ranks and shapes and confirming the result is the input reversed, a relationship about two different operands' shapes that ODS's own declarative constraint language has no way to express directly.

**3. This chapter showed `mg-opt` silently accepting `mg.add %0, %1 : tensor<2x2xf64>, tensor<3xf64> -> tensor<2x2xf64>` without error. Precisely why does the dialect, as built in this chapter, allow that, and what real, minimal change would close the gap?**

Worked answer: `AddOp`'s two operands are each independently constrained to `F64Tensor` (any rank, any shape, so long as the element type is `f64`), and nothing in `MgOps.td` relates the two operands' own shapes to each other or to the result's shape -- ODS enforces exactly the constraints it is told to enforce, no more. Closing the gap needs exactly the pattern `TransposeOp` already demonstrates: adding `let hasVerifier = 1;` to `AddOp` and writing a real `AddOp::verify()` that checks `getLhs().getType()`, `getRhs().getType()`, and `getResult().getType()` are all the same shape.

**4. Why does this chapter's own `CMakeLists.txt` need both `-DMLIR_DIR=` and `-DLLVM_DIR=` passed explicitly on the `cmake` command line, rather than CMake finding them on its own the way it finds, say, `ZLIB`?**

Worked answer: CMake's `find_package(... CONFIG)` mode searches a fixed, conventional set of installation prefixes (and `CMAKE_PREFIX_PATH`, when set) for a package's own `*Config.cmake` file. Ubuntu's `libmlir-18-dev`/`llvm-18-dev` packages genuinely install `MLIRConfig.cmake`/`LLVMConfig.cmake` at `/usr/lib/llvm-18/lib/cmake/{mlir,llvm}/` -- a real, valid location, but one versioned by LLVM major version specifically so that LLVM 17, 18, and 19 can coexist on one real system without colliding, and precisely because of that versioning, it is not a path CMake's own default search covers. Passing both variables explicitly is this chapter's own real, confirmed fix, not a guess.

**5. The chapter's opening Mountain Goat example uses `func.func`/`func.return` rather than a hypothetical `mg.func`/`mg.return`. What real design decision does that reflect, and what would be lost by instead reinventing function definition inside the `mg` dialect?**

Worked answer: MLIR's own built-in `func` dialect already provides a real, complete, well-tested representation of function definition, arguments, and return -- genuinely independent of anything tensor- or array-specific. Reinventing an `mg.func`/`mg.return` pair would duplicate that real functionality for no real gain, and would also mean every later real MLIR pass, tool, or interface that already understands `func.func` (inlining, symbol resolution, calling-convention lowering) would need Mountain Goat-specific support added before it could be reused. Keeping `mg`'s own dialect minimal -- covering only what `func` does not already cover -- is this chapter's own real, deliberate scope decision, not an oversight.
