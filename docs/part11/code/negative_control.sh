#!/bin/sh
# Negative control: the same host code and harness, linked with a stub whose kernel arithmetic is REMOVED.
# If the real stub's answer did not depend on the launch parameters being read correctly, this would still print 6 8 / 10 12.
# Needs ./host.o from pipeline.sh. Output: negative_control_out.txt
cd "$(dirname "$0")"
sed 's/c\[i\] = a\[i\] + b\[i\];/(void)a;(void)b;(void)c;(void)i;/' stub_gpu_runtime.c > /tmp/stub_noop_ch11.c
clang-18 harness.c host.o /tmp/stub_noop_ch11.c -o /tmp/noop_demo_ch11 2>/dev/null && /tmp/noop_demo_ch11 2>/dev/null
rm -f /tmp/stub_noop_ch11.c /tmp/noop_demo_ch11
