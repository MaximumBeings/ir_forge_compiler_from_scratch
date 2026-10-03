// Chapter 38: outlining must not change what a program computes. Each example is run with and without --outline (the memory address in the printed descriptor is removed:
// it differs from run to run) and the two outputs must be identical; the values themselves are pinned from a calculation by hand (see the comments in the examples).
// RUN: sh -c '%mgc38 run %ex38/01_four_distinct_nests.mg | sed "s/base@ = 0x[0-9a-f]*//" > %t.1a; %mgc38 run %ex38/01_four_distinct_nests.mg --outline | sed "s/base@ = 0x[0-9a-f]*//" > %t.1b; cmp %t.1a %t.1b'
// RUN: sh -c '%mgc38 run %ex38/02_one_nest_forty_times.mg | sed "s/base@ = 0x[0-9a-f]*//" > %t.2a; %mgc38 run %ex38/02_one_nest_forty_times.mg --outline | sed "s/base@ = 0x[0-9a-f]*//" > %t.2b; cmp %t.2a %t.2b'
// RUN: sh -c '%mgc38 run %ex38/03_dynamic_shapes.mg | sed "s/base@ = 0x[0-9a-f]*//" > %t.3a; %mgc38 run %ex38/03_dynamic_shapes.mg --outline | sed "s/base@ = 0x[0-9a-f]*//" > %t.3b; cmp %t.3a %t.3b'
// RUN: sh -c '%mgc38 run %ex38/04_below_threshold.mg | sed "s/base@ = 0x[0-9a-f]*//" > %t.4a; %mgc38 run %ex38/04_below_threshold.mg --outline | sed "s/base@ = 0x[0-9a-f]*//" > %t.4b; cmp %t.4a %t.4b'
// RUN: %mgc38 run %ex38/01_four_distinct_nests.mg --outline | %FileCheck %s --check-prefix=X1
// RUN: %mgc38 run %ex38/02_one_nest_forty_times.mg --outline | %FileCheck %s --check-prefix=X2
// RUN: %mgc38 run %ex38/03_dynamic_shapes.mg --outline | %FileCheck %s --check-prefix=X3
// RUN: %mgc38 run %ex38/04_below_threshold.mg --outline | %FileCheck %s --check-prefix=X4
// X1: 13,   26],
// X1: 39,   52]]
// X1: 1,   32,   243],
// X1: 1024,   3125,   7776],
// X1: 16807,   32768,   59049]]
// X1: 1,   2,   3],
// X1: 7,   8,   9]]
// X2: 41,   82],
// X2: 123,   164]]
// X3: 40,   80,   120],
// X3: 160,   200,   240]]
// X4: 1,   9],
// X4: 4,   16]]
