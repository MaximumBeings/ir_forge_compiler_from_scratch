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
  let hasConstantMaterializer = 1;
}

class Mg_Op<string mnemonic, list<Trait> traits = []> :
    Op<Mg_Dialect, mnemonic, traits>;

#endif // MG_DIALECT_TD
