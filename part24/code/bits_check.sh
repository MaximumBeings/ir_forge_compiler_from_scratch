#!/bin/sh
# Are the ijk and ikj products identical to the last bit, and is that check able to notice a different order of additions?
# Output: bits_check_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); W=$HERE/work/bits; mkdir -p $W
for o in ijk ikj; do
  $HERE/mgc lib $HERE/../../part21/code/cpp/ops.mg -o $W/$o --matmul-order $o >/dev/null
  clang++-18 -std=c++17 -I$W/$o $HERE/cpp/bits.cpp $W/$o/ops.o -o $W/bits.$o
  $W/bits.$o > $W/out.$o
done
if cmp -s $W/out.ijk $W/out.ikj; then echo "ijk and ikj outputs: identical ($(wc -l < $W/out.ijk) elements, every bit)"; else echo "ijk and ikj outputs: DIFFER"; fi
python3 - $W/out.ikj <<'PY'
import sys
m,k,n=5,7,4
a=[0.1*(i%13)+1.0/(i+3) for i in range(m*k)]
b=[0.7/(i%11+1)-0.01*i for i in range(k*n)]
def mm(order):
    out=[]
    for i in range(m):
        for j in range(n):
            s=0.0
            for kk in order: s+=a[i*k+kk]*b[kk*n+j]
            out.append(float.hex(s))
    return out
fwd, rev = mm(range(k)), mm(reversed(range(k)))
got=[float.hex(float.fromhex(x)) for x in open(sys.argv[1]).read().split()]
print("compiled ikj output equals an independent Python sum in increasing k:", got == fwd)
print("the same sum in DECREASING k order differs from it in", sum(1 for x,y in zip(fwd,rev) if x!=y), "of", len(fwd), "elements (so this check would notice a changed order)")
PY
