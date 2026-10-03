#!/usr/bin/env python3
"""READ THIS FIRST: this script deliberately feeds check_llvm.py WRONG inputs (one change each: the 'ijk' program built in the other loop order, the reassoc flag not applied,
a flag that does change the assembly standing in for -ffast-math, no -march=native, a fast-math flag that does not allow fusing, opt run without a target) and expects the
checker to FAIL. A "caught" line is the EXPECTED, wanted result: it shows that the check depends on the thing it claims to test. "NOT CAUGHT" would be a gap.
Output: claims_mutation_out.txt"""
import os, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__))
print("NOTE: this script deliberately breaks inputs. 'caught' lines are EXPECTED: they show each check can fail.")
base = subprocess.run([sys.executable, os.path.join(here, "check_llvm.py")], capture_output=True, text=True)
print("baseline (nothing broken):", "checker passes (expected)" if base.returncode == 0 else "UNEXPECTED FAILURE")
def mut(label, **env):
    r = subprocess.run([sys.executable, os.path.join(here, "check_llvm.py")], capture_output=True, text=True, env=dict(os.environ, **env))
    fails = [l.strip()[5:].strip() for l in r.stdout.split("\n") if l.strip().startswith("FAIL")]
    if r.returncode != 0 and not fails: print(f"{label}: caught (the checker did not even finish: {(r.stderr or r.stdout).strip().splitlines()[-1][:120]})")
    elif fails: print(f"{label}: caught by {len(fails)} failing check(s):\n      " + "\n      ".join(f[:140] for f in fails))
    else: print(f"{label}: NOT CAUGHT")
mut("the 'ijk' program is built in ikj order", CHK_ORDER_IJK="ikj")
mut("the reassoc flag is not applied (the edit changes nothing)", CHK_REASSOC="fadd double")
mut("the second assembly is built with -O1 in place of -ffast-math (a flag that does matter)", CHK_FAST_FLAG="-O1")
mut("no -march=native (plain x86-64: SSE2 instructions, not the v-prefixed AVX ones the checks count)", CHK_MARCH="-mno-avx")
mut("the contract flag is replaced by nsz (a flag that does not allow fusing)", CHK_CONTRACT="nsz")
mut("opt is run without a target (no -mtriple, no -mcpu)", CHK_TRIPLE="")
