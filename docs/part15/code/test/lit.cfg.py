# lit configuration for the Mountain Goat (mg) regression suite.
# Which mg-opt is tested is chosen by the MG_OPT environment variable, so the same suite can be pointed at
# different builds (Chapter 15 does exactly that to prove the tests can fail).
import os
import lit.formats

config.name = "IR Forge / Mountain Goat"
config.test_format = lit.formats.ShTest(execute_external=False)
config.suffixes = [".mlir"]
config.excludes = ["Inputs"]
config.test_source_root = os.path.dirname(__file__)
config.test_exec_root = os.environ.get("MG_TEST_TMP", "/tmp/mg-lit-tmp")

mg_opt = os.environ.get("MG_OPT")
if not mg_opt:
    raise RuntimeError("set MG_OPT to the mg-opt binary under test")

inputs = os.path.join(config.test_source_root, "Inputs")
# Chapter 10's recipe: mg.add's affine loops -> a gpu.module kernel (blocks = rows, threads = columns).
to_gpu = ("--pass-pipeline='builtin.module(func.func(affine-parallelize,lower-affine,gpu-map-parallel-loops,"
          "convert-parallel-loops-to-gpu),gpu-kernel-outlining)'")
lower = ("--lower-affine --convert-scf-to-cf --convert-arith-to-llvm --finalize-memref-to-llvm "
         "--convert-func-to-llvm --reconcile-unrealized-casts")

config.substitutions += [
    ("%mg-opt", mg_opt),
    ("%mlir-translate", "mlir-translate-18"),
    ("%mlir-opt", "mlir-opt-18"),
    ("%decode-ptx", "python3 " + os.environ.get("DECODE_PTX", os.path.join(config.test_source_root, "..", "..", "..", "part10", "code", "decode_ptx.py"))),
    ("%clang", "clang-18"),
    ("%FileCheck", "FileCheck-18"),
    ("%not", "not-18"),
    ("%inputs", inputs),
    ("%lower-to-llvm", lower),
    ("%to-gpu", to_gpu),
]
config.environment["PATH"] = os.environ["PATH"]
