#!/usr/bin/env python3
# READ THIS FIRST: this script injects deliberate bugs into the mgc driver and re-runs the Chapter 23 tests (test/perf).
#   "caught by <tests>" lines are the EXPECTED, wanted result: a test noticed the bug. "NOT CAUGHT" would be a test gap.
#   mgc is restored afterwards. Output: mgc_mutation_out.txt
import os, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__)); MGC = os.path.join(HERE, "mgc")
LIT = os.path.join(HERE, "..", "..", "part15", "code", "run_lit.sh")
print("NOTE: this script deliberately breaks mgc. 'caught by' lines are EXPECTED: they show the tests can detect the bug.")
def run(label, baseline=False):
    r = subprocess.run(["sh", LIT, "--filter", ":: perf/"], capture_output=True, text=True,
                       env={**os.environ, "MG_OPT": os.path.join(HERE, "..", "..", "part22", "code", "build", "mg-opt"), "MG_TEST_TMP": os.path.join(HERE, "work", "perfmut")})
    fails = [l.split("::")[1].strip().split(" (")[0] for l in r.stdout.splitlines() if l.startswith("FAIL")]
    if baseline: print(f"{label}: " + ("all tests pass (expected)" if not fails else "UNEXPECTED FAILURES: " + ", ".join(fails)))
    else: print(f"{label}: " + ("caught by " + ", ".join(fails) if fails else "NOT CAUGHT (a test gap)"))
orig = open(MGC).read()
base = "run baseline (no bug)"
run(base, baseline=True)
muts = [("old `[ ... ] && exec` bug (build exits 1 on success)", 'if [ "$cmd" = run ]; then exec "$exe"; fi   # (Chapter 23: this used to be `[ ... ] && exec`, which made `mgc build` exit with status 1 on success)', '[ "$cmd" = run ] && exec "$exe"'),
        ("--passes ignored", '--convert-mg-to-affine $PASSES -o', '--convert-mg-to-affine -o'),
        ("-O ignored when building executables", '${MGC_CLANG:-clang-18} $OPT $MGC_CFLAGS "$W/$base.ll"', '${MGC_CLANG:-clang-18} $MGC_CFLAGS "$W/$base.ll"'),
        ("-O ignored when building libraries", '${MGC_CLANG:-clang-18} $OPT $MGC_CFLAGS -c', '${MGC_CLANG:-clang-18} $MGC_CFLAGS -c'),
        ("MGC_CFLAGS ignored", '$OPT $MGC_CFLAGS "$W/$base.ll"', '$OPT "$W/$base.ll"')]
try:
    for label, a, b in muts:
        if a not in orig: print(label, ": MUTATION DID NOT APPLY"); continue
        open(MGC, "w").write(orig.replace(a, b, 1)); run(label)
finally:
    open(MGC, "w").write(orig)
run("restored (baseline again)", baseline=True)
