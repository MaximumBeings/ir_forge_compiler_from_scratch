# --gpu-module-to-binary stores the PTX as a hex-escaped string attribute (\0A for newline).
# This pulls it back out as plain PTX text: python3 decode_ptx.py add_bin.mlir > out.ptx
import re, sys
s = open(sys.argv[1]).read()
m = re.search(r'assembly\s*=\s*"((?:[^"\\]|\\.)*)"', s)
t = re.sub(r'\\([0-9A-Fa-f]{2})', lambda x: chr(int(x.group(1), 16)), m.group(1))
sys.stdout.write(t.replace('\x00', ''))
