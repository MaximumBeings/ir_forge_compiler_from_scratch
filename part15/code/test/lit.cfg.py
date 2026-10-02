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
    ("%lower-with-stderr", "--lower-affine --convert-scf-to-cf --mg-lower-assert-to-stderr --convert-arith-to-llvm "
                           "--finalize-memref-to-llvm --convert-func-to-llvm --reconcile-unrealized-casts"),
    ("%to-gpu", to_gpu),
]
# The language tour (docs/tour): its examples are run in place, like the chapters' examples.
config.substitutions += [("%tour", os.path.join(config.test_source_root, "..", "..", "..", "tour", "code"))]
# Chapter 29: exp, softmax and attention ('%mgc29' etc. must come before the shorter '%mgc').
ch29 = os.path.join(config.test_source_root, "..", "..", "..", "part29", "code")
config.substitutions += [
    ("%mgc29", "env MG_OPT=" + mg_opt + " " + os.path.join(ch29, "mgc")),
    ("%ex29", os.path.join(ch29, "examples")),
    ("%ch29", ch29),
]
# Chapter 28: tensors of any rank and contract(...) in Mountain Goat itself ('%mgc28' etc. must come before the shorter '%mgc').
ch28 = os.path.join(config.test_source_root, "..", "..", "..", "part28", "code")
config.substitutions += [
    ("%mgc28", "env MG_OPT=" + mg_opt + " " + os.path.join(ch28, "mgc")),
    ("%ex28", os.path.join(ch28, "examples")),
    ("%ch28", ch28),
]
# Chapter 27: tensor contractions through Mountain Goat's matrix product (files used in place).
config.substitutions += [("%cpp27", os.path.join(config.test_source_root, "..", "..", "..", "part27", "code", "cpp"))]
# Chapter 26: the gradient-descent trainer (its Mountain Goat file and C++ driver are used in place).
config.substitutions += [("%cpp26", os.path.join(config.test_source_root, "..", "..", "..", "part26", "code", "cpp"))]
# Chapter 25: tests for the early chapters' own files, run in place ('%docs' is the book's docs directory).
config.substitutions += [("%docs", os.path.join(config.test_source_root, "..", "..", ".."))]
# Chapter 24: the matmul loop-order option ('%mgc24' must come before '%mgc').
ch24 = os.path.join(config.test_source_root, "..", "..", "..", "part24", "code")
config.substitutions += [
    ("%mgc24", "env MG_OPT=" + mg_opt + " " + os.path.join(ch24, "mgc")),
    ("%ex24", os.path.join(ch24, "examples")),
    ("%cpp21b", os.path.join(config.test_source_root, "..", "..", "..", "part21", "code", "cpp")),
]
# Chapter 23: mgc's -O and --passes options, and the benchmark examples ('%mgc23' must come before '%mgc').
ch23 = os.path.join(config.test_source_root, "..", "..", "..", "part23", "code")
config.substitutions += [
    ("%mgc23", "env MG_OPT=" + mg_opt + " " + os.path.join(ch23, "mgc")),
    ("%ex23", os.path.join(ch23, "examples")),
]
# Chapter 22: broadcasting, reductions, relu. (Listed before Chapter 21's: lit replaces by prefix, so '%mgc22' must come before '%mgc'.)
ch22 = os.path.join(config.test_source_root, "..", "..", "..", "part22", "code")
config.substitutions += [
    ("%mgc22", "env MG_OPT=" + mg_opt + " " + os.path.join(ch22, "mgc")),
    ("%mgfront22", "python3 " + os.path.join(ch22, "mgfront.py")),
    ("%ex22", os.path.join(ch22, "examples")),
    ("%cpp22", os.path.join(ch22, "cpp")),
]
# Chapter 21: the extended driver/front end (more operations), also referenced in place.
ch21 = os.path.join(config.test_source_root, "..", "..", "..", "part21", "code")
config.substitutions += [
    ("%mgc21", "env MG_OPT=" + mg_opt + " " + os.path.join(ch21, "mgc")),
    ("%mgfront21", "python3 " + os.path.join(ch21, "mgfront.py")),
    ("%ex21", os.path.join(ch21, "examples")),
    ("%cpp21", os.path.join(ch21, "cpp")),
]
# Chapter 20: the surface-syntax driver and its examples (they live in part20/code, not copied, so tests cannot drift from the book).
ch20 = os.path.join(config.test_source_root, "..", "..", "..", "part20", "code")
config.substitutions += [
    ("%mgc", "env MG_OPT=" + mg_opt + " " + os.path.join(ch20, "mgc")),
    ("%mgfront", "python3 " + os.path.join(ch20, "mgfront.py")),
    ("%ex", os.path.join(ch20, "examples")),
    ("%cpp", os.path.join(ch20, "cpp")),
    ("%cxx", "clang++-18"),
]
config.environment["PATH"] = os.environ["PATH"]
