#!/bin/sh
# Chapter 38: the Chapter 36 training program at its full 200 steps (29,552 lines), compiled with --outline, timed, and its output compared with the output Chapter 36 recorded
# (without outlining; examples_out.txt there). Output: full200_out.txt
HERE=$(cd "$(dirname "$0")" && pwd); W=$HERE/work/full200; mkdir -p $W
P=$HERE/../../part36/code/examples/04_train_200_steps.mg
s=$(date +%s); MGC_KEEP=$W $HERE/mgc build $P -o $W/train.exe --outline; m=$(date +%s)
echo "compile with --outline: $((m - s)) seconds (29,552-line program; Chapter 36 measured about 40 minutes for compile and run without it)"
$W/train.exe > $W/out.txt; e=$(date +%s); echo "run: $((e - m)) seconds"
sed 's/base@ = 0x[0-9a-f]*/base@ = 0x…/' $W/out.txt > $W/out_norm.txt
sed -n '/^################ mgc run 04_train_200_steps.mg/,/exit status/p' $HERE/../../part36/code/examples_out.txt | sed '1,3d;$d' | sed '/^$/d' > $W/ch36.txt
sed '/^$/d' $W/out_norm.txt > $W/mine.txt
if cmp -s $W/ch36.txt $W/mine.txt; then echo "output identical to Chapter 36's recorded output ($(wc -l < $W/mine.txt) lines: all 8 checkpoints, the held-out result, the chunk counts and the four attention patterns)"; else echo "OUTPUT DIFFERS"; diff $W/ch36.txt $W/mine.txt | head; fi
echo "distinct outlined functions: $(grep -c 'define.*@mg_outlined' $W/04_train_200_steps.ll)"
