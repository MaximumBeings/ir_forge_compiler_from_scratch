#!/usr/bin/env python3
"""READ THIS FIRST: this script deliberately BREAKS the fast-math pass (it edits SetFastMath.cpp, rebuilds mg-opt, runs check_fastmath.py, and restores the original at the end) and the driver (broken
copies of mgc in work/, run through CHK_MGC), and expects the checker to FAIL for each. A "caught" line is the EXPECTED, wanted result. "NOT CAUGHT" would be a gap.
Output: mutation_out.txt   (about 8 minutes: each pass mutant rebuilds the tool)"""
import os, shutil, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); src = os.path.join(here, "SetFastMath.cpp"); orig = open(src).read(); W = os.path.join(here, "work"); os.makedirs(W, exist_ok=True)
mgc_orig = open(os.path.join(here, "mgc")).read(); shutil.copy(os.path.join(here, "mgfront.py"), W)
def check(**env):
    r = subprocess.run([sys.executable, os.path.join(here, "check_fastmath.py")], capture_output=True, text=True, env=dict(os.environ, **env)); return r
def build(): subprocess.run(["sh", os.path.join(here, "build.sh")], capture_output=True, check=True)
def report(label, r):
    fails = [l.strip()[5:].strip() for l in r.stdout.split("\n") if l.strip().startswith("FAIL")]
    if r.returncode != 0 and not fails: print(f"{label}: caught (the checker did not finish: {(r.stderr or r.stdout).strip().splitlines()[-1][:120]})")
    elif fails: print(f"{label}: caught by {len(fails)} failing check(s):\n      " + "\n      ".join(f[:140] for f in fails))
    else: print(f"{label}: NOT CAUGHT")
    sys.stdout.flush()
print("NOTE: this script deliberately breaks the pass and the driver. 'caught' lines are EXPECTED: they show the checker can detect the mistake.")
r = check(); print("baseline (nothing broken):", "checker passes (expected)" if r.returncode == 0 else "UNEXPECTED FAILURE"); sys.stdout.flush()
# driver mutants: broken copies of mgc, no rebuild
DRV = [
 ("fast-math is ON by default", "FASTMATH=\n", "FASTMATH=--mg-set-fastmath\n"),
 ("--fast-math=FLAGS ignores FLAGS (always the default flags)", '--fast-math=*) FASTMATH="--mg-set-fastmath=flags=${1#--fast-math=}"; shift;;', "--fast-math=*) FASTMATH=--mg-set-fastmath; shift;;"),
 ("--fast-math is accepted but the pass is never run", "$PASSES $FASTMATH $OUTLINE", "$PASSES $OUTLINE"),
]
for label, old, new in DRV:
    assert old in mgc_orig, label
    p = os.path.join(W, "mgc"); open(p, "w").write(mgc_orig.replace(old, new, 1)); os.chmod(p, 0o755); report(label, check(CHK_MGC=p))
MUT = [
 ("the default flags include nnan (no NaNs)", 'llvm::cl::init("reassoc,contract")', 'llvm::cl::init("reassoc,contract,nnan")'),
 ("the default flags lack contract", 'llvm::cl::init("reassoc,contract")', 'llvm::cl::init("reassoc")'),
 ("multiplications are skipped", "if (auto iface = dyn_cast<arith::ArithFastMathInterface>(op)) {", "if (isa<arith::MulFOp>(op)) return;\n      if (auto iface = dyn_cast<arith::ArithFastMathInterface>(op)) {"),
 ("the flags option is ignored (always the default)", "StringRef(flags).split(parts, ',', -1, false);", 'StringRef("reassoc,contract").split(parts, \',\', -1, false);'),
 ("an unknown flag is silently ignored", 'if (!parsed) { getOperation().emitError("unknown fast-math flag \'" + p.str() + "\'"); return signalPassFailure(); }', "if (!parsed) continue;"),
]
try:
    for label, old, new in MUT:
        assert old in orig, label
        open(src, "w").write(orig.replace(old, new, 1)); build(); report(label, check())
finally:
    open(src, "w").write(orig); build()
print(); print("restored: SetFastMath.cpp is back to its original and mg-opt is rebuilt")
