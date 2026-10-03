#!/usr/bin/env python3
"""READ THIS FIRST: this script deliberately BREAKS the last-to-first pass (it edits ScfToCfReverse.cpp, rebuilds mg-opt, runs check_reverse.py, and restores the original at the end) and expects
the checker to FAIL for each. A "caught" line is the EXPECTED, wanted result: it shows the checker can detect that kind of mistake. "NOT CAUGHT" would be a gap.
Output: mutation_out.txt   (about 10 minutes: each mutant rebuilds the tool)"""
import os, shutil, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); src = os.path.join(here, "ScfToCfReverse.cpp"); orig = open(src).read()
def check(**env):
    r = subprocess.run([sys.executable, os.path.join(here, "check_reverse.py")], capture_output=True, text=True, env=dict(os.environ, **env)); return r
def build(): subprocess.run(["sh", os.path.join(here, "build.sh")], capture_output=True, check=True)
print("NOTE: this script deliberately breaks the pass. 'caught' lines are EXPECTED: they show the checker can detect the mistake.")
r = check(); print("baseline (nothing broken):", "checker passes (expected)" if r.returncode == 0 else "UNEXPECTED FAILURE"); sys.stdout.flush()
def report(label, r):
    fails = [l.strip()[5:].strip() for l in r.stdout.split("\n") if l.strip().startswith("FAIL")]
    if r.returncode != 0 and not fails: print(f"{label}: caught (the checker did not finish: {(r.stderr or r.stdout).strip().splitlines()[-1][:120]})")
    elif fails: print(f"{label}: caught by {len(fails)} failing check(s):\n      " + "\n      ".join(f[:140] for f in fails))
    else: print(f"{label}: NOT CAUGHT")
    sys.stdout.flush()
report("the pass is replaced by MLIR's own --convert-scf-to-cf (CHK_REVERSE)", check(CHK_REVERSE="--convert-scf-to-cf"))
MUT = [
 ("the statements are lowered first to last, not last to first", "for (auto it = tops.rbegin(); it != tops.rend(); ++it) {", "for (auto it = tops.begin(); it != tops.end(); ++it) {"),
 ("the whole function is converted in one call (what --convert-scf-to-cf does)", "for (auto it = tops.rbegin(); it != tops.rend(); ++it) {\n      Operation *one[] = {*it};", "for (auto it = tops.rbegin(); it != tops.rbegin() + (tops.empty() ? 0 : 1); ++it) {\n      Operation *one[] = {func.getOperation()};"),
 ("a top-level scf.if is never lowered", "if (isa<scf::ForOp, scf::IfOp, scf::WhileOp, scf::ExecuteRegionOp, scf::IndexSwitchOp>(&op)) tops.push_back(&op);", "if (isa<scf::ForOp, scf::WhileOp, scf::ExecuteRegionOp, scf::IndexSwitchOp>(&op)) tops.push_back(&op);"),
 ("a top-level scf.while is never lowered", "if (isa<scf::ForOp, scf::IfOp, scf::WhileOp, scf::ExecuteRegionOp, scf::IndexSwitchOp>(&op)) tops.push_back(&op);", "if (isa<scf::ForOp, scf::IfOp, scf::ExecuteRegionOp, scf::IndexSwitchOp>(&op)) tops.push_back(&op);"),
 ("only the first 2500 top-level statements are lowered", "for (auto it = tops.rbegin(); it != tops.rend(); ++it) {", "if (tops.size() > 2500) tops.resize(2500);\n    for (auto it = tops.rbegin(); it != tops.rend(); ++it) {"),
 ("nested loops are never lowered (only statements whose body has no loop: a loop with a loop inside is skipped)", "tops.push_back(&op);", "{ bool nested = false; op.walk([&](scf::ForOp inner) { if (inner.getOperation() != &op) nested = true; }); if (!nested) tops.push_back(&op); }"),
]
try:
    for label, old, new in MUT:
        assert old in orig, label
        open(src, "w").write(orig.replace(old, new, 1)); build(); report(label, check())
finally:
    open(src, "w").write(orig); build()
print(); print("restored: ScfToCfReverse.cpp is back to its original and mg-opt is rebuilt")
