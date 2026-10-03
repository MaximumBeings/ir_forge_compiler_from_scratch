#!/usr/bin/env python3
"""READ THIS FIRST: this script deliberately BREAKS the driver (it writes broken copies of mgc into work/ and runs check_defaults.py against each through CHK_MGC) and expects the checker to FAIL for
each. A "caught" line is the EXPECTED, wanted result: it shows the checker can detect that kind of mistake. "NOT CAUGHT" would be a gap.   Output: mutation_out.txt   (about 5 minutes)"""
import os, shutil, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); W = os.path.join(here, "work"); os.makedirs(W, exist_ok=True); orig = open(os.path.join(here, "mgc")).read()
shutil.copy(os.path.join(here, "mgfront.py"), W)
def check(mgc_text):
    p = os.path.join(W, "mgc"); open(p, "w").write(mgc_text); os.chmod(p, 0o755)
    return subprocess.run([sys.executable, os.path.join(here, "check_defaults.py")], capture_output=True, text=True, env=dict(os.environ, CHK_MGC=p))
print("NOTE: this script deliberately breaks the driver. 'caught' lines are EXPECTED: they show the checker can detect the mistake.")
r = check(orig); print("baseline (nothing broken):", "checker passes (expected)" if r.returncode == 0 else "UNEXPECTED FAILURE"); sys.stdout.flush()
MUT = [
 ("outlining is off by default", "OUTLINE=--mg-outline-loops; SCF=--mg-scf-to-cf-reverse", "OUTLINE=; SCF=--mg-scf-to-cf-reverse"),
 ("lowering last to first is off by default", "OUTLINE=--mg-outline-loops; SCF=--mg-scf-to-cf-reverse", "OUTLINE=--mg-outline-loops; SCF=--convert-scf-to-cf"),
 ("--no-outline is accepted but does nothing", "--no-outline) OUTLINE=; shift;;", "--no-outline) shift;;"),
 ("--no-reverse-loops is accepted but does nothing", "--no-reverse-loops) SCF=--convert-scf-to-cf; shift;;", "--no-reverse-loops) shift;;"),
 ("--no-reverse-loops asks for the wrong pass (canonicalize)", "--no-reverse-loops) SCF=--convert-scf-to-cf; shift;;", "--no-reverse-loops) SCF=--canonicalize; shift;;"),
 ("the lowering pass is dropped from the pipeline (loops are never lowered)", '--lower-affine $SCF ', '--lower-affine '),
 ("outlining runs on the already-lowered IR (after the lowering stage) so it finds nothing", "--convert-mg-to-affine$CONVOPT $PASSES $OUTLINE -o", "--convert-mg-to-affine$CONVOPT $PASSES -o"),
]
for label, old, new in MUT:
    assert old in orig, label
    r = check(orig.replace(old, new, 1)); fails = [l.strip()[5:].strip() for l in r.stdout.split("\n") if l.strip().startswith("FAIL")]
    if r.returncode != 0 and not fails: print(f"{label}: caught (the checker did not finish: {(r.stderr or r.stdout).strip().splitlines()[-1][:120]})")
    elif fails: print(f"{label}: caught by {len(fails)} failing check(s):\n      " + "\n      ".join(f[:140] for f in fails))
    else: print(f"{label}: NOT CAUGHT")
    sys.stdout.flush()
print(); print("done (the real mgc was never edited; the broken copies live in work/)")
