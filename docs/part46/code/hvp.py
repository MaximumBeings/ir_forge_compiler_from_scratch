#!/usr/bin/env python3
"""Hessian-vector products by differentiating the generated backward pass:
    hvp.py prog.mg --wrt NAME[,NAME...] --vec "[[...]]"[;"[[...]]"...]  > hvp.mg
Step 1: autograd.py writes the program that computes the loss and the gradients g_i of the named matrices. Step 2: this script rewrites the program's loss to  sum_i sum(g_i * v_i)  for fixed direction
matrices v_i (one per name, given in the same order, separated by ';' in --vec). Step 3: autograd.py differentiates THAT program with respect to the same names. By the chain rule the result for name j is
sum_i H_ji v_i, block row j of the Hessian of the ORIGINAL loss times the stacked direction (v_1, v_2, ...): with several names the blocks BETWEEN different matrices are included.
The program prints sum(g * v) first, then one matrix H v per name."""
import argparse, os, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); AG = os.environ.get("CH46_AUTOGRAD") or os.path.join(here, "autograd.py")
def run(args):
    r = subprocess.run([sys.executable, AG, *args], capture_output=True, text=True)
    if r.returncode: sys.exit(r.stderr.strip())
    return r.stdout
def main(argv=None):
    ap = argparse.ArgumentParser(); ap.add_argument("program"); ap.add_argument("--wrt", required=True, help="comma-separated names of let matrices"); ap.add_argument("--vec", required=True, help="one literal matrix per name, in the same order, separated by ';', each with the shape of its matrix"); a = ap.parse_args(argv)
    names = a.wrt.split(","); vecs = [v.strip() for v in a.vec.split(";")]
    if len(vecs) != len(names): sys.exit(f"hvp: {len(names)} names but {len(vecs)} direction matrices in --vec")
    g1 = run([a.program, "--wrt", a.wrt]).split("\n")
    prints = [i for i, l in enumerate(g1) if l.startswith("print ")]
    grads = [g1[p].split()[1] for p in prints[1:]]                       # the prints after the loss are the gradients, in the order of the names
    body = g1[:prints[0]] + [f"let vdir{k} = {v}" for k, v in enumerate(vecs)]
    terms = " + ".join(f"col_sum(row_sum({g} * vdir{k}))" for k, g in enumerate(grads))
    body += [f"let hv_loss = {terms}", "print hv_loss"]
    tmp = tempfile.NamedTemporaryFile("w", suffix=".mg", delete=False); tmp.write("\n".join(body) + "\n"); tmp.close()
    out = run([tmp.name, "--wrt", a.wrt]); os.unlink(tmp.name)
    sys.stdout.write(out.replace("prints, in order: loss, grad " + ", grad ".join(names), "prints, in order: sum(g*v), H*v for " + ", ".join(names)))
if __name__ == "__main__": main()
