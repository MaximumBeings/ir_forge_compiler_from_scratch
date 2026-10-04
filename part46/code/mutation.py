#!/usr/bin/env python3
"""READ THIS FIRST: this script deliberately BREAKS autograd.py (one rule at a time, in a copy named _mutant_autograd.py, removed at the end) and runs check_hvp.py against each broken copy through
CHK_AUTOGRAD. It expects the checker to FAIL every time (a mutant that this chapter's second-order checker misses is also tried on Chapter 45's first-order checker); "caught" is the wanted result, "NOT CAUGHT" would be a gap. The first mutants are ones the FIRST-order checks of Chapter 45 cannot see:
the gradient of a loss is unchanged by them, only the gradient of the gradient is wrong. Output: mutation_out.txt   (about 4 minutes)"""
import os, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); orig = open(os.path.join(here, "autograd.py")).read(); mut = os.path.join(here, "_mutant_autograd.py")
def check():
    open(mut, "w").write(CURRENT); return subprocess.run([sys.executable, os.path.join(here, "check_hvp.py")], capture_output=True, text=True, env=dict(os.environ, CHK_AUTOGRAD=mut))
print("NOTE: this script deliberately breaks autograd.py. 'caught' lines are EXPECTED: they show the checker can detect the mistake.")
CURRENT = orig; r = check(); print("baseline (nothing broken):", "checker passes (expected)" if r.returncode == 0 else "UNEXPECTED FAILURE"); sys.stdout.flush()
MUT = [
 ("ge: the gradient flows through a comparison (second-order only: the first-order gradient of relu is unchanged)", 'elif o.op == "ge": pass ', 'elif o.op == "ge": add_adj(o.args[0], g)\n            elif o.op == "ge_unused": pass '),
 ("relu: the mask is applied with ge against the input itself instead of zero", 'add_adj(o.args[0], f"({g} * ge({a[0]}, {zero11()}))")', 'add_adj(o.args[0], f"({g} * ge({a[0]}, {a[0]}))")'),
 ("mul: each operand's gradient uses its own value", 'add_adj(o.args[0], f"({g} * {a[1]})"); add_adj(o.args[1], f"({g} * {a[0]})")', 'add_adj(o.args[0], f"({g} * {a[0]})"); add_adj(o.args[1], f"({g} * {a[1]})")'),
 ("div: the denominator's gradient divides by b, not by b squared", '({a[1]} * {a[1]})))")', '{a[1]}))")'),
 ("exp: the gradient uses the input, not the output", 'elif o.op == "exp": add_adj(o.args[0], f"({g} * {r})")', 'elif o.op == "exp": add_adj(o.args[0], f"({g} * {a[0]})")'),
 ("log: the gradient multiplies by x instead of dividing", 'elif o.op == "log": add_adj(o.args[0], f"({g} / {a[0]})")', 'elif o.op == "log": add_adj(o.args[0], f"({g} * {a[0]})")'),
 ("sqrt: the factor 2 is forgotten", 'f"({g} / ({r} * 2.0))"', 'f"({g} / {r})"'),
 ("matmul: the left gradient does not transpose b", 'add_adj(o.args[0], f"({g} @ transpose({a[1]}))")', 'add_adj(o.args[0], f"({g} @ {a[1]})")'),
 ("a value used twice: the second contribution replaces the first", 'out.append(f"let {v} = ({adj[x]} + {expr})"); adj[x] = v', 'out.append(f"let {v} = {expr}"); adj[x] = v'),
 ("sum: the gradient is not broadcast over the reduced axis", 'add_adj(o.args[0], f"({ones_of(s)} * {g})")', 'add_adj(o.args[0], g)'),
 ("broadcast: the gradient of a column vector is summed over the wrong axis", 'if s_in == (s_out[0], 1) and s_out[1] != 1: e = f"row_sum({g})"', 'if s_in == (s_out[0], 1) and s_out[1] != 1: e = f"col_sum({g})"'),
]
try:
    for label, old, new in MUT:
        assert old in orig, label
        CURRENT = orig.replace(old, new, 1); r = check(); fails = [l.strip()[5:].strip() for l in r.stdout.split("\n") if l.strip().startswith("FAIL")]
        if r.returncode != 0 and not fails: print(f"{label}: caught (the checker did not finish: {(r.stderr or r.stdout).strip().splitlines()[-1][:110]})")
        elif fails: print(f"{label}: caught by {len(fails)} failing check(s):\n      " + "\n      ".join(f[:130] for f in fails))
        else:
            r1 = subprocess.run([sys.executable, os.path.join(here, "..", "..", "part45", "code", "check_autograd.py")], capture_output=True, text=True, env=dict(os.environ, CHK_AUTOGRAD=mut))
            f1 = [l.strip()[5:].strip() for l in r1.stdout.split("\n") if l.strip().startswith("FAIL")]
            if r1.returncode != 0: print(f"{label}: NOT caught by this chapter's checker, but CAUGHT by Chapter 45's first-order checker ({str(len(f1)) + ' failing check(s)' if f1 else 'its checker could not finish: the generated program does not compile'}): the two checkers together cover it")
            else: print(f"{label}: NOT CAUGHT by either checker")
        sys.stdout.flush()
finally:
    if os.path.exists(mut): os.remove(mut)
print(); print("done (autograd.py itself was never edited; the broken copy is removed)")
