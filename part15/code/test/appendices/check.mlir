// Appendices (language reference and self-check answers): every snippet of the language reference gives the result the appendix states (27 programs run through the real compiler), and the self-check appendix is exactly what the chapter pages produce now.
// RUN: env MG_OPT=%mg-opt python3 %apxA/verify_reference.py | %FileCheck %s --check-prefix=A
// RUN: python3 %apxD/make_appendix_d.py --check | %FileCheck %s --check-prefix=D
// A: 27 of 27 snippets give the stated result
// D: appendix D is up to date with the chapter pages
