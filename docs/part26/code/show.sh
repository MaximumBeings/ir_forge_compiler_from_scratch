#!/bin/sh
# What the front end makes of gd.mg, for the chapter to explain. Output: show/gd_front_end.mlir
HERE=$(cd "$(dirname "$0")" && pwd); mkdir -p $HERE/show
$HERE/../../part24/code/mgc mlir $HERE/cpp/gd.mg | sed '/^func.func @main/,$d' > $HERE/show/gd_front_end.mlir
