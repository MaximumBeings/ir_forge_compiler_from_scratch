cmake_minimum_required(VERSION 3.20)
project(ch9_engine)

find_package(MLIR REQUIRED CONFIG)

list(APPEND CMAKE_MODULE_PATH "${MLIR_CMAKE_DIR}")
list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddLLVM)
include(AddMLIR)
include(HandleLLVMOptions)

include_directories(${LLVM_INCLUDE_DIRS})
include_directories(${MLIR_INCLUDE_DIRS})
add_definitions(${LLVM_DEFINITIONS})

add_executable(run_engine run_engine.cpp)
target_link_libraries(run_engine PRIVATE
  MLIRIR
  MLIRParser
  MLIRSupport
  MLIRFuncDialect
  MLIRLLVMDialect
  MLIRLLVMToLLVMIRTranslation
  MLIRExecutionEngine
  MLIRExecutionEngineUtils
  MLIRTargetLLVMIRExport
)
