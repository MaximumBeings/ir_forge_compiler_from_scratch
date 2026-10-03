#!/bin/sh
# Appendix E: what the tools themselves say. Writes passes_out.txt (every pass this book's mg-opt registers that starts with mg- or convert-mg-, with its own one-line description), mgc_usage_out.txt and
# autograd_usage_out.txt, which the page embeds.
cd "$(dirname "$0")"; MO=../../part44/code/build/mg-opt
$MO --help | grep -E '^\s+--(mg-|convert-mg-)' | sed 's/^ *//' > passes_out.txt
../../part44/code/mgc 2>&1 | head -1 > mgc_usage_out.txt
python3 ../../part46/code/autograd.py --help > autograd_usage_out.txt 2>&1
python3 ../../part46/code/hvp.py --help | head -4 >> autograd_usage_out.txt 2>&1
wc -l passes_out.txt
# the chapter index (a markdown list with links), generated from each chapter page's first heading so it cannot drift
for n in $(seq 1 46); do d=../../part$n; f=$(ls $d/[0-9]*.md | head -1); t=$(grep -m1 '^# ' $f | sed 's/^# //'); echo "- [$t](../$(basename $d)/$(basename $f))"; done > chapter_index.txt
wc -l chapter_index.txt
