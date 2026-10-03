#!/bin/sh
# Chapter 43: a stand-in for mg-opt that records its arguments in $MG_OPT_LOG and then runs the real one ($REAL_MG_OPT), so a test can see exactly which passes mgc asks for.
echo "$@" >> "$MG_OPT_LOG"
exec "$REAL_MG_OPT" "$@"
