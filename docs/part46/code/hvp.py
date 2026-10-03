#!/usr/bin/env python3
"""Hessian-vector products by differentiating the generated backward pass: hvp.py prog.mg --wrt NAME --vec "[[...]]"  > hvp.mg
Step 1: autograd.py writes the program that computes the loss and the gradient g of NAME. Step 2: this script rewrites its last print so the program's loss is  sum(g * v)  for the fixed matrix v
(v is a `let`), and step 3: autograd.py differentiates THAT program with respect to NAME. By the chain rule, d/dp sum(g(p) * v) = H(p) v, the Hessian of the original loss times v. Prints H v."""
import argparse, os, re, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); AG = os.environ.get("CH46_AUTOGRAD") or os.path.join(here, "autograd.py")
def run(args):
    r = subprocess.run([sys.executable, AG, *args], capture_output=True, text=True)
    if r.returncode: sys.exit(r.stderr.strip())
    return r.stdout
def main(argv=None):
    ap = argparse.ArgumentParser(); ap.add_argument("program"); ap.add_argument("--wrt", required=True); ap.add_argument("--vec", required=True, help="the direction v, as a literal matrix with the shape of the --wrt matrix"); a = ap.parse_args(argv)
    g1 = run([a.program, "--wrt", a.wrt]).split("\n")
    prints = [i for i, l in enumerate(g1) if l.startswith("print ")]
    grad_var = g1[prints[1]].split()[1]                                   # the second print is the gradient
    body = g1[:prints[0]] + [f"let vdir = {a.vec}", f"let hv_loss = col_sum(row_sum({grad_var} * vdir))", "print hv_loss"]
    tmp = tempfile.NamedTemporaryFile("w", suffix=".mg", delete=False); tmp.write("\n".join(body) + "\n"); tmp.close()
    out = run([tmp.name, "--wrt", a.wrt]); os.unlink(tmp.name)
    sys.stdout.write(out.replace("prints, in order: loss, grad " + a.wrt, "prints, in order: sum(g*v), H*v"))
if __name__ == "__main__": main()
