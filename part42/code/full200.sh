#!/bin/sh
# Chapter 42: the Chapter 36 training program at its full 200 steps (29,552 lines, 190,636 loop nests in `main`) compiled WITHOUT outlining and with the loops lowered last to first
# (and, for comparison, with both), stage by stage, and its output compared with the output Chapter 36 recorded (examples_out.txt there). Output: full200_out.txt   (about 6 minutes)
HERE=$(cd "$(dirname "$0")" && pwd)
P=$HERE/../../part36/code/examples/04_train_200_steps.mg
want=$(sed -n '/^################ mgc run 04_train_200_steps.mg/,/exit status/p' $HERE/../../part36/code/examples_out.txt | sed '1,3d;$d' | sed '/^$/d' | sed -E 's/base@ = 0x(…|[0-9a-f]+)/base@ = 0x/' | md5sum | cut -c1-12)
echo "Chapter 36's recorded output (addresses and blank lines removed): md5 $want"
for fl in "--reverse-loops" "--reverse-loops --outline"; do
  echo "flags: $fl"; r=$($HERE/stage_times.sh $P $fl); echo "$r"
  if echo "$r" | grep -q "md5 of the output with addresses and blank lines removed: $want"; then echo "  -> output IDENTICAL to Chapter 36's recorded output (compiled without outlining and with the ordinary lowering)"; else echo "  -> OUTPUT DIFFERS"; fi
done
