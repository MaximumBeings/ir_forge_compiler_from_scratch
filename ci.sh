#!/bin/sh
# ci.sh: everything continuous integration does, in one script you can run on your own machine.
#   1. check the tools are installed          4. run the whole test suite (docs/part15/code/run_lit.sh)
#   2. check the workflow file                5. build the documentation site (mkdocs build --strict)
#   3. build the newest compiler (docs/part42/code/build.sh)
# Exit status 0 means every step passed; 1 means at least one failed (the summary at the end says which).
# Knobs: CI_SKIP_BUILD=1 reuses an existing build; CI_SKIP_DOCS=1 skips the site build; MG_OPT=/path/to/mg-opt tests a different build.
ROOT=$(cd "$(dirname "$0")" && pwd); cd "$ROOT"
FAILED=""; SUMMARY=""
step() {  # step "name" command...   (runs the command, records pass/fail and the time it took)
  name=$1; shift
  echo "::group::$name"; echo "=== $name"
  start=$(date +%s)
  if "$@"; then result=PASS; else result=FAIL; FAILED="$FAILED|$name"; fi
  secs=$(( $(date +%s) - start ))
  echo "::endgroup::"; echo "=== $name: $result (${secs}s)"
  SUMMARY="$SUMMARY$(printf '  %-4s %-40s %4ss' "$result" "$name" "$secs")
"
}
skipped() { SUMMARY="$SUMMARY$(printf '  SKIP %-40s' "$1")
"; }

check_tools() {
  missing=""
  for t in clang-18 clang++-18 mlir-opt-18 mlir-translate-18 mlir-cpu-runner-18 FileCheck-18 not-18 valgrind callgrind_annotate cmake make python3 lit mkdocs; do
    command -v $t >/dev/null 2>&1 || missing="$missing $t"
  done
  [ -z "$missing" ] || { echo "missing tools:$missing"; return 1; }
  echo "all tools found: $(clang-18 --version | head -1)"
}
build_compiler() {
  if [ -n "$CI_SKIP_BUILD" ] && [ -x docs/part42/code/build/mg-opt ]; then echo "CI_SKIP_BUILD set: reusing docs/part42/code/build/mg-opt"; return 0; fi
  docs/part42/code/build.sh && [ -x docs/part42/code/build/mg-opt ]
}
run_suite() { docs/part15/code/run_lit.sh; }
build_docs() { mkdocs build --strict; }

step "check tools" check_tools
step "check workflow file" python3 .github/check_ci.py
if [ -n "$MG_OPT" ] && [ -n "$CI_SKIP_BUILD" ]; then skipped "build the compiler (testing MG_OPT=$MG_OPT)"
else step "build the compiler" build_compiler; fi
case "$FAILED" in *"build the compiler"*|*"check tools"*) skipped "run the test suite (a step it depends on failed)";; *) step "run the test suite" run_suite;; esac
if [ -n "$CI_SKIP_DOCS" ]; then skipped "build the documentation"; else step "build the documentation" build_docs; fi

echo; echo "CI summary:"; printf '%s' "$SUMMARY"
if [ -n "$FAILED" ]; then echo "CI FAILED in: $(echo "$FAILED" | sed 's/^|//; s/|/, /g')"; exit 1; fi
echo "CI passed."
