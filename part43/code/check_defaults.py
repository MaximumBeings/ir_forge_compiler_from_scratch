#!/usr/bin/env python3
"""Checks the Chapter 43 defaults of mgc (the loops are lowered last to first, and loop nests of big functions are outlined, unless told not to):
  1. WHICH PASSES: with a recording stand-in for mg-opt, the default asks for --mg-outline-loops and --mg-scf-to-cf-reverse and not --convert-scf-to-cf; --no-outline, --no-reverse-loops and both
     remove exactly what they name; the old spellings --outline and --reverse-loops still mean the same as the default;
  2. SAME OUTPUT: on every third Mountain Goat example of the book (under 400 lines, accepted by the front end), `mgc run` with the defaults prints what `mgc run --no-outline --no-reverse-loops`
     prints (the behaviour of Chapter 38's driver);
  3. SMALL PROGRAMS ARE UNTOUCHED: a program with fewer than 32 loop nests in a function gets no outlined function, so its executable is the same program as before;
  4. BIG PROGRAMS ARE OUTLINED: Chapter 35's 10-step training program gets outlined functions by default, none with --no-outline, and the same output either way;
  5. THE RUN-TIME COST AT -O0 IS TINY AND COUNTABLE: the outlined executable runs under 0.1% more instructions, 20 to 60 per call.
Environment variables (CHK_*) change an input; mutation.py edits mgc to check that each claim can fail.   Usage: check_defaults.py     Exit status 0 only if all pass."""
import glob, os, re, subprocess, sys, tempfile
here = os.path.dirname(os.path.abspath(__file__)); root = os.path.join(here, "..", ".."); E = os.environ.get
MGC = E("CHK_MGC") or os.path.join(here, "mgc"); REAL = E("MG_OPT") or os.path.join(root, "part42", "code", "build", "mg-opt"); W = tempfile.mkdtemp(prefix="ch43c_")
failures = 0
def report(ok, name, detail=""):
    global failures; failures += not ok
    print(f"  {'ok  ' if ok else 'FAIL'} {name}" + ("" if ok else f"\n       {detail}"))
norm = lambda s: re.sub(r"base@ = 0x[0-9a-f]+", "base@ = 0x", s)
def mgc(cmd, prog, *flags, env=None, keep=None):
    e = dict(os.environ, MG_OPT=REAL); e.update(env or {})
    if keep: e["MGC_KEEP"] = keep
    return subprocess.run([MGC, cmd, prog, *flags], capture_output=True, text=True, env=e)
# ---- 1
print("-- 1. which passes mgc asks for")
tiny = W + "/tiny.mg"; open(tiny, "w").write("print [[1,2],[3,4]] @ [[1,0],[0,1]]\n")
def passes(*flags):
    log = f"{W}/log.txt"; open(log, "w").close()
    r = mgc("build", tiny, "-o", W + "/tiny.exe", *flags, env=dict(MG_OPT=os.path.join(here, "logopt.sh"), REAL_MG_OPT=REAL, MG_OPT_LOG=log))
    text = open(log).read(); return r.returncode, ("--mg-outline-loops" in text, "--mg-scf-to-cf-reverse" in text, "--convert-scf-to-cf" in text)
cases = {(): (True, True, False), ("--no-outline",): (False, True, False), ("--no-reverse-loops",): (True, False, True), ("--no-outline", "--no-reverse-loops"): (False, False, True), ("--outline", "--reverse-loops"): (True, True, False)}
got = {k: passes(*k) for k in cases}
report(all(got[k] == (0, v) for k, v in cases.items()), "default: outline + reverse; --no-outline, --no-reverse-loops, both, and the old spellings behave as named", str(got))
# ---- 2
print("-- 2. same output as Chapter 38's driver on the book's examples")
progs = [f for f in sorted(glob.glob(root + "/part*/code/examples/*.mg") + glob.glob(root + "/tour/code/*.mg")) if sum(1 for _ in open(f)) < 400]
progs = [f for i, f in enumerate(progs) if i % 3 == 0 and subprocess.run([sys.executable, os.path.join(here, "mgfront.py"), f], capture_output=True).returncode == 0]
same = diff = 0; bad = []
for f in progs:
    a = mgc("run", f); b = mgc("run", f, "--no-outline", "--no-reverse-loops")
    if (a.returncode, norm(a.stdout), norm(a.stderr)) == (b.returncode, norm(b.stdout), norm(b.stderr)): same += 1
    else: diff += 1; bad.append(os.path.relpath(f, root))
report(diff == 0 and same >= 25, f"{same} programs print the same with the defaults and with --no-outline --no-reverse-loops, {diff} differ", ", ".join(bad[:5]))
# ---- 3
print("-- 3. small programs are untouched")
k = W + "/small"; os.makedirs(k); mgc("build", os.path.join(root, "part29", "code", "examples", "08_self_attention_block.mg"), "-o", W + "/s.exe", keep=k)
ll = open(k + "/08_self_attention_block.ll").read()
report("@mg_outlined" not in ll, "the self-attention example (under 32 nests per function) has no outlined function with the defaults")
# ---- 4
print("-- 4. big programs are outlined, and run the same")
big = os.path.join(root, "part35", "code", "examples", "03_train_10_steps.mg"); k1, k2 = W + "/big1", W + "/big2"; os.makedirs(k1); os.makedirs(k2)
r1 = mgc("run", big, keep=k1); r2 = mgc("run", big, "--no-outline", keep=k2)
n1 = len(re.findall(r"define void @mg_outlined", open(k1 + "/03_train_10_steps.ll").read())); n2 = len(re.findall(r"define void @mg_outlined", open(k2 + "/03_train_10_steps.ll").read()))
report(n1 > 20 and n2 == 0, f"Chapter 35's 10-step training program: {n1} outlined functions by default, {n2} with --no-outline", f"{n1}, {n2}")
report(r1.returncode == 0 and r2.returncode == 0 and norm(r1.stdout) == norm(r2.stdout) and len(r1.stdout) > 1000, "and it prints the same %d characters either way" % len(r1.stdout), f"{r1.returncode} {r2.returncode}")
# ---- 5
print("-- 5. what outlining costs at run time, in exact instructions (callgrind, clang -O0)")
def instr(exe):
    cg = exe + ".cg"; subprocess.run(["valgrind", "--tool=callgrind", f"--callgrind-out-file={cg}", exe], capture_output=True); return int(re.search(r"summary: (\d+)", open(cg).read()).group(1))
mgc("build", big, "-o", W + "/b_out"); mgc("build", big, "-o", W + "/b_plain", "--no-outline")
calls = len(re.findall(r"call void @mg_outlined", open(k1 + "/03_train_10_steps.ll").read())); ia, ib = instr(W + "/b_plain"), instr(W + "/b_out")
report(0 <= ib - ia and (ib - ia) / ia < 0.001, "Chapter 35's 10-step program: about %d million instructions plain, %.2f%% more outlined" % (round(ia / 1e6, -1), 100 * (ib - ia) / ia), f"{ia} {ib}")
report(calls > 1000 and 20 <= (ib - ia) / calls <= 60, "the %s calls cost about %d extra instructions each (a call, the arguments, the return)" % (f"{calls:,}", round((ib - ia) / calls, -1)), f"{calls} calls, {ib - ia} extra")
print("all checks pass" if not failures else f"{failures} CHECK(S) FAILED"); sys.exit(1 if failures else 0)
