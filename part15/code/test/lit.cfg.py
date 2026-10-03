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
# Chapter 40: GA-1, a cycle-counting model of a matrix accelerator (pure Python; no compiler involved).
ch40 = os.path.join(config.test_source_root, "..", "..", "..", "part40", "code")
config.substitutions += [("%ch40", ch40)]
# Chapter 39: a differential profile (valgrind callgrind) of the lowering pass. No compiler change.
ch39 = os.path.join(config.test_source_root, "..", "..", "..", "part39", "code")
config.substitutions += [("%ch39", ch39)]
# Chapter 38: outlining loop nests (--mg-outline-loops, mgc --outline). '%mgc38' must come before the shorter '%mgc'.
ch38 = os.path.join(config.test_source_root, "..", "..", "..", "part38", "code")
config.substitutions += [
    ("%mgc38", "env MG_OPT=" + mg_opt + " " + os.path.join(ch38, "mgc")),
    ("%ex38", os.path.join(ch38, "examples")),
    ("%ch38", ch38),
]
# Chapter 37: inside the LLVM stage (reading the IR, the passes, the vectorizer's reasons, the backend). No new compiler operation; the tests run LLVM's own tools.
ch37 = os.path.join(config.test_source_root, "..", "..", "..", "part37", "code")
config.substitutions += [
    ("%ex37", os.path.join(ch37, "examples")),
    ("%ch37", ch37),
]
# Chapter 36: Chapter 30's architecture (two blocks, two heads each) trained with a hand-derived backward pass. No new compiler operation ('%mgc32' runs the examples).
ch36 = os.path.join(config.test_source_root, "..", "..", "..", "part36", "code")
config.substitutions += [
    ("%ex36", os.path.join(ch36, "examples")),
    ("%ch36", ch36),
]
# Chapter 35: a one-block causal transformer language model trained with a hand-derived backward pass. No new compiler operation ('%mgc32' runs the examples).
ch35 = os.path.join(config.test_source_root, "..", "..", "..", "part35", "code")
config.substitutions += [
    ("%ex35", os.path.join(ch35, "examples")),
    ("%ch35", ch35),
]
# Chapter 34: why a block has a feed-forward network (backward through layer norm, relu and residuals). No new compiler operation ('%mgc32' runs the examples).
ch34 = os.path.join(config.test_source_root, "..", "..", "..", "part34", "code")
config.substitutions += [
    ("%ex34", os.path.join(ch34, "examples")),
    ("%ch34", ch34),
]
# Chapter 33: an attention classifier trained by hand-derived backpropagation. No new compiler operation: the examples run with Chapter 32's driver ('%mgc32').
ch33 = os.path.join(config.test_source_root, "..", "..", "..", "part33", "code")
config.substitutions += [
    ("%ex33", os.path.join(ch33, "examples")),
    ("%ch33", ch33),
]
# Chapter 32: held-out data, weight decay and greedy generation ('%mgc32' etc. must come before the shorter '%mgc').
ch32 = os.path.join(config.test_source_root, "..", "..", "..", "part32", "code")
config.substitutions += [
    ("%mgc32", "env MG_OPT=" + mg_opt + " " + os.path.join(ch32, "mgc")),
    ("%ex32", os.path.join(ch32, "examples")),
    ("%ch32", ch32),
]
# Chapter 31: training a bigram model ('%mgc31' etc. must come before the shorter '%mgc').
ch31 = os.path.join(config.test_source_root, "..", "..", "..", "part31", "code")
config.substitutions += [
    ("%mgc31", "env MG_OPT=" + mg_opt + " " + os.path.join(ch31, "mgc")),
    ("%ex31", os.path.join(ch31, "examples")),
    ("%ch31", ch31),
]
# Chapter 30: a small transformer ('%mgc30' etc. must come before the shorter '%mgc').
ch30 = os.path.join(config.test_source_root, "..", "..", "..", "part30", "code")
config.substitutions += [
    ("%mgc30", "env MG_OPT=" + mg_opt + " " + os.path.join(ch30, "mgc")),
    ("%ex30", os.path.join(ch30, "examples")),
    ("%ch30", ch30),
]
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
# Chapter 41: a back end from the mg dialect to GA-1 (Python over `mgc mlir` text).
ch41 = os.path.join(config.test_source_root, "..", "..", "..", "part41", "code")
config.substitutions += [("%ch41", ch41)]
# Chapter 42: lowering scf to cf last to first (--mg-scf-to-cf-reverse, mgc --reverse-loops); mg-opt of this chapter is the newest build.
ch42 = os.path.join(config.test_source_root, "..", "..", "..", "part42", "code")
config.substitutions += [("%ch42", ch42)]
# Chapter 43: mgc's defaults changed (loops lowered last to first, big functions outlined); the driver is part43/code/mgc, its mg-opt is Chapter 42's.
ch43 = os.path.join(config.test_source_root, "..", "..", "..", "part43", "code")
config.substitutions += [("%ch43", ch43)]
# Chapter 44: fast-math flags (--mg-set-fastmath, mgc --fast-math); the newest mg-opt build is this chapter's.
ch44 = os.path.join(config.test_source_root, "..", "..", "..", "part44", "code")
config.substitutions += [("%ch44", ch44)]
# Chapter 45: automatic differentiation (autograd.py, a source-to-source transformation; it runs programs with mgc and needs mg-opt of Chapter 44's build).
ch45 = os.path.join(config.test_source_root, "..", "..", "..", "part45", "code")
config.substitutions += [("%ch45", ch45)]
