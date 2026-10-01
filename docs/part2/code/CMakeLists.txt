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
