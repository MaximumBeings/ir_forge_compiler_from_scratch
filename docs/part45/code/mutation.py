#!/usr/bin/env python3
"""READ THIS FIRST: this script deliberately BREAKS autograd.py (one rule or one line at a time, in a copy named _mutant_autograd.py that is removed at the end) and runs check_autograd.py against
each broken copy through CHK_AUTOGRAD. It expects the checker to FAIL every time. A "caught" line is the EXPECTED, wanted result: it shows the checker can detect that mistake.
"NOT CAUGHT" would be a gap. Output: mutation_out.txt   (about 6 minutes)"""
import os, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__)); orig = open(os.path.join(here, "autograd.py")).read(); mut = os.path.join(here, "_mutant_autograd.py")
def check():
    open(mut, "w").write(CURRENT); return subprocess.run([sys.executable, os.path.join(here, "check_autograd.py")], capture_output=True, text=True, env=dict(os.environ, CHK_AUTOGRAD=mut))
print("NOTE: this script deliberately breaks autograd.py. 'caught' lines are EXPECTED: they show the checker can detect the mistake.")
CURRENT = orig; r = check(); print("baseline (nothing broken):", "checker passes (expected)" if r.returncode == 0 else "UNEXPECTED FAILURE"); sys.stdout.flush()
MUT = [
 ("mul: each operand's gradient uses its OWN value (not the other's)", 'add_adj(o.args[0], f"({g} * {a[1]})"); add_adj(o.args[1], f"({g} * {a[0]})")', 'add_adj(o.args[0], f"({g} * {a[0]})"); add_adj(o.args[1], f"({g} * {a[1]})")'),
 ("sub: the second operand's gradient has the wrong sign", 'add_adj(o.args[1], f"(0.0 - {g})")', 'add_adj(o.args[1], g)'),
 ("div: the denominator's gradient has the wrong sign", 'f"(0.0 - (({g} * {a[0]}) / ({a[1]} * {a[1]})))"', 'f"(({g} * {a[0]}) / ({a[1]} * {a[1]}))"'),
 ("div: the denominator's gradient divides by b, not by b squared", '({a[1]} * {a[1]})))")', '{a[1]}))")'),
 ("k - x: the gradient has the wrong sign", 'elif sym == "sub": add_adj(o.args[0], f"(0.0 - {g})" if rev else g)', 'elif sym == "sub": add_adj(o.args[0], g)'),
 ("k / x: the gradient has the wrong sign", 'f"(0.0 - (({g} * {k!r}) / ({a[0]} * {a[0]})))" if rev', 'f"(({g} * {k!r}) / ({a[0]} * {a[0]}))" if rev'),
 ("x * k: the gradient ignores k", 'elif sym == "mul": add_adj(o.args[0], f"({g} * {k!r})")', 'elif sym == "mul": add_adj(o.args[0], g)'),
 ("neg: the gradient has the wrong sign", 'elif o.op == "neg": add_adj(o.args[0], f"(0.0 - {g})")', 'elif o.op == "neg": add_adj(o.args[0], g)'),
 ("matmul: the left gradient does not transpose b", 'add_adj(o.args[0], f"({g} @ transpose({a[1]}))")', 'add_adj(o.args[0], f"({g} @ {a[1]})")'),
 ("matmul: the right gradient is g @ transpose(a) instead of transpose(a) @ g", 'add_adj(o.args[1], f"(transpose({a[0]}) @ {g})")', 'add_adj(o.args[1], f"({g} @ transpose({a[0]}))")'),
 ("transpose: the gradient is not transposed back", 'add_adj(o.args[0], f"transpose({g})")', 'add_adj(o.args[0], g)'),
 ("reshape: the gradient is not reshaped back", 'add_adj(o.args[0], f"reshape({g}, {s[0]}, {s[1]})")', 'add_adj(o.args[0], g)'),
 ("exp: the gradient uses the input, not the output", 'elif o.op == "exp": add_adj(o.args[0], f"({g} * {r})")', 'elif o.op == "exp": add_adj(o.args[0], f"({g} * {a[0]})")'),
 ("log: the gradient multiplies by x instead of dividing", 'elif o.op == "log": add_adj(o.args[0], f"({g} / {a[0]})")', 'elif o.op == "log": add_adj(o.args[0], f"({g} * {a[0]})")'),
 ("sqrt: the factor 2 is forgotten", 'f"({g} / ({r} * 2.0))"', 'f"({g} / {r})"'),
 ("relu: no mask (the gradient flows through negative inputs too)", 'add_adj(o.args[0], f"({g} * ge({a[0]}, {zero11()}))")', 'add_adj(o.args[0], g)'),
 ("sum: the gradient is not broadcast over the reduced axis", 'add_adj(o.args[0], f"({ones_of(s)} * {g})")', 'add_adj(o.args[0], g)'),
 ("max: tied maxima each get the FULL gradient (no sharing)", 'f"({mask} * ({g} / {fn}({mask})))"', 'f"({mask} * {g})"'),
 ("a value used twice: the second contribution replaces the first", 'out.append(f"let {v} = ({adj[x]} + {expr})"); adj[x] = v', 'out.append(f"let {v} = {expr}"); adj[x] = v'),
 ("broadcast: the gradient of a column vector is summed over the wrong axis", 'if s_in == (s_out[0], 1) and s_out[1] != 1: e = f"row_sum({g})"', 'if s_in == (s_out[0], 1) and s_out[1] != 1: e = f"col_sum({g})"'),
 ("naming: constants are matched by value only, ignoring order (equal-valued lets collide)", "for k in range(pos, len(consts)):", "for k in range(0, len(consts)):"),
 ("descent: the update ADDS the gradient (climbs the loss instead of descending)", 'out.append(f"let {v} = ({params[w]} - ({adj[w]} * {lr!r}))")', 'out.append(f"let {v} = ({params[w]} + ({adj[w]} * {lr!r}))")'),
 ("descent: the learning rate is ignored (always 1)", 'out.append(f"let {v} = ({params[w]} - ({adj[w]} * {lr!r}))")', 'out.append(f"let {v} = ({params[w]} - {adj[w]})")'),
 ("descent: the weights are never updated (every step uses the starting weights)", "                params = upd\n", "                pass\n"),
 ("the loss is differentiated with a seed of 2 instead of 1", 'out.append(f"let {seed} = [[1.0]]")', 'out.append(f"let {seed} = [[2.0]]")'),
]
try:
    for label, old, new in MUT:
        assert old in orig, label
        CURRENT = orig.replace(old, new, 1); r = check(); fails = [l.strip()[5:].strip() for l in r.stdout.split("\n") if l.strip().startswith("FAIL")]
        if r.returncode != 0 and not fails: print(f"{label}: caught (the checker did not finish: {(r.stderr or r.stdout).strip().splitlines()[-1][:110]})")
        elif fails: print(f"{label}: caught by {len(fails)} failing check(s):\n      " + "\n      ".join(f[:130] for f in fails))
        else: print(f"{label}: NOT CAUGHT")
        sys.stdout.flush()
finally:
    if os.path.exists(mut): os.remove(mut)
print(); print("done (autograd.py itself was never edited; the broken copy is removed)")
