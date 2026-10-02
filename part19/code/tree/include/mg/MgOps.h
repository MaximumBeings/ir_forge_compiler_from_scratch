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
