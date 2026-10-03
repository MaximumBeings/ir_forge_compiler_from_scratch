#!/usr/bin/env python3
"""READ THIS FIRST: this script deliberately feeds check_profile.py WRONG inputs (one change each) and expects the checker to FAIL. A "caught" line is the EXPECTED, wanted result:
it shows that each claim depends on the thing it says it tests. "NOT CAUGHT" would be a gap.   Output: claims_mutation_out.txt"""
import os, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__))
print("NOTE: this script deliberately breaks inputs. 'caught' lines are EXPECTED: they show each check can fail.")
base = subprocess.run([sys.executable, os.path.join(here, "check_profile.py")], capture_output=True, text=True)
print("baseline (nothing broken):", "checker passes (expected)" if base.returncode == 0 else "UNEXPECTED FAILURE")
def mut(label, **env):
    r = subprocess.run([sys.executable, os.path.join(here, "check_profile.py")], capture_output=True, text=True, env=dict(os.environ, **env))
    fails = [l.strip()[5:].strip() for l in r.stdout.split("\n") if l.strip().startswith("FAIL")]
    if r.returncode != 0 and not fails: print(f"{label}: caught (the checker did not even finish: {(r.stderr or r.stdout).strip().splitlines()[-1][:120]})")
    elif fails: print(f"{label}: caught by {len(fails)} failing check(s):\n      " + "\n      ".join(f[:150] for f in fails))
    else: print(f"{label}: NOT CAUGHT")
mut("the 'functions of 100' case is really one function (CHK_PER=100000)", CHK_PER="100000")
mut("the outlining pass is replaced by canonicalize (a pass that does not outline)", CHK_OUTLINE="--canonicalize")
mut("the profile is of --lower-affine only, without SCFToControlFlow (the pass under study)", CHK_PASSES="--lower-affine")
