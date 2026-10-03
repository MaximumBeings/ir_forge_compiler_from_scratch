#!/usr/bin/env python3
"""Sanity-check .github/workflows/ci.yml without GitHub: it must parse, trigger on push to main and on pull requests, and every
file and script it mentions must exist in the repository. (A parse is not a run: see Chapter 25 for what this does not establish.)"""
import os, re, sys, yaml
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
path = os.path.join(root, ".github", "workflows", "ci.yml")
text = open(path).read()
doc = yaml.safe_load(text)
problems = []
triggers = doc.get(True) or doc.get("on")                      # YAML 1.1 reads the key `on` as the boolean True
if "pull_request" not in triggers: problems.append("workflow does not run on pull requests")
if "main" not in (triggers.get("push") or {}).get("branches", []): problems.append("workflow does not run on pushes to main")
job = doc["jobs"]["suite"]
if not job["runs-on"].startswith("ubuntu-24"): problems.append("expected an ubuntu-24.04 runner (LLVM/MLIR 18 packages)")
steps = job["steps"]
runs = "\n".join(s.get("run", "") for s in steps)
if "./ci.sh" not in runs: problems.append("no step runs ./ci.sh")
for pkg in ("clang-18", "llvm-18-dev", "llvm-18-tools", "libmlir-18-dev", "mlir-18-tools", "cmake"):
    if pkg not in runs: problems.append(f"package {pkg} is not installed by the workflow")
# every path under docs/ that the workflow mentions (cache path and hash globs) must have a real directory behind it
for m in set(re.findall(r"docs/[A-Za-z0-9_./-]+", text)):
    base = m.split("*")[0].rstrip("/")
    if not os.path.exists(os.path.join(root, base)) and not os.path.exists(os.path.join(root, os.path.dirname(base))):
        problems.append(f"workflow mentions {m}, which does not exist")
for f in ("ci.sh", "requirements.txt", "docs/part42/code/build.sh", "docs/part15/code/run_lit.sh"):
    if not os.path.exists(os.path.join(root, f)): problems.append(f"missing file the workflow depends on: {f}")
if problems:
    print("CI workflow check FAILED:"); [print("  -", p) for p in problems]; sys.exit(1)
print(f"CI workflow check passed: {len(steps)} steps, triggers {sorted(k for k in triggers)}, runner {job['runs-on']}")
