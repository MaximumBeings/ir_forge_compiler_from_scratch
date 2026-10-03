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

add_library(MgLowerToAffine lib/LowerToAffine.cpp)
add_dependencies(MgLowerToAffine MgOpsIncGen)
target_link_libraries(MgLowerToAffine PUBLIC
  MgDialect
  MLIRControlFlowDialect
  MLIRIR
  MLIRPass
  MLIRTransforms
  MLIRAffineDialect
  MLIRMemRefDialect
  MLIRTensorDialect
  MLIRArithDialect
  MLIRMathDialect
  MLIRFuncDialect
  MLIRFuncTransforms
)

add_library(MgOutlineLoops lib/OutlineLoops.cpp)
target_link_libraries(MgOutlineLoops PUBLIC MLIRIR MLIRPass MLIRFuncDialect MLIRAffineDialect MLIRArithDialect)

add_library(MgScfToCfReverse lib/ScfToCfReverse.cpp)
target_link_libraries(MgScfToCfReverse PUBLIC MLIRIR MLIRPass MLIRFuncDialect MLIRSCFDialect MLIRControlFlowDialect MLIRArithDialect MLIRTransforms MLIRSCFToControlFlow)

add_library(MgSetFastMath lib/SetFastMath.cpp)
target_link_libraries(MgSetFastMath PUBLIC MLIRIR MLIRPass MLIRArithDialect MLIRFuncDialect)

add_library(MgAssertToStderr lib/AssertToStderr.cpp)
target_link_libraries(MgAssertToStderr PUBLIC MLIRIR MLIRPass MLIRControlFlowDialect MLIRLLVMDialect MLIRTransformUtils)

add_library(MgBufferizableOpInterfaceImpl lib/MgBufferizableOpInterfaceImpl.cpp)
add_dependencies(MgBufferizableOpInterfaceImpl MgOpsIncGen)
target_link_libraries(MgBufferizableOpInterfaceImpl PUBLIC
  MgDialect
  MLIRControlFlowDialect
  MLIRIR
  MLIRBufferizationDialect
  MLIRAffineDialect
  MLIRMemRefDialect
  MLIRArithDialect
)

get_property(MG_CONVERSION_LIBS GLOBAL PROPERTY MLIR_CONVERSION_LIBS)

add_executable(mg-opt tools/mg-opt.cpp)
target_link_libraries(mg-opt PRIVATE
  MgDialect
  MgAssertToStderr
  MgOutlineLoops
  MgScfToCfReverse
  MgSetFastMath
  MLIRControlFlowDialect
  MgLowerToAffine
  MgBufferizableOpInterfaceImpl
  MLIRIR
  MLIRFuncDialect
  MLIROptLib
  MLIRParser
  MLIRSupport
  MLIRTransforms
  MLIRAffineDialect
  MLIRMemRefDialect
  MLIRTensorDialect
  MLIRArithDialect
  MLIRMathDialect
  MLIRLLVMDialect
  MLIRBufferizationDialect
  MLIRBufferizationTransforms
  MLIRAffineTransforms
  MLIRAffineUtils
  MLIRAffineAnalysis
  ${MG_CONVERSION_LIBS}
)
