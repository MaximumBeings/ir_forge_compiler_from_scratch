#!/usr/bin/env python3
"""mgfront: the Mountain Goat surface-syntax front end. Reads .mg source, writes MLIR (mg dialect) to stdout.

Tensors of any rank (Chapter 28): reshape(x, d0, d1, ...) views a static value as another shape with the same number of elements; permute(x, p0, p1, ...)
reorders the axes (result axis i is input axis pi); contract(a, (i, j, ...), b, (k, l, ...)) sums products over the paired axes (the result's axes are a's
free axes, then b's). Values of rank other than 2 can only be reshaped, permuted, contracted, bound with let, or printed; everything else needs a matrix.
Built-in functions (Chapter 22): relu(m); (Chapter 29) exp(m), elementwise e^x; row_sum, row_max, row_mean (one value per row, an Mx1 result) and col_sum, col_max, col_mean
(one value per column, 1xN). Elementwise operators broadcast a static dimension of size 1 (e.g. a 2x3 plus a 1x3).
Operators (Chapter 21): + - * / are elementwise on matrices ('*' is the Hadamard product) and also combine a matrix
with a scalar; '@' is the matrix product; unary '-' negates. Scalars are numbers known at compile time.
Grammar (one statement per line, '#' starts a comment):
  program := (def | stmt)*
  def     := 'def' NAME '(' [NAME ':' type (',' NAME ':' type)*] ')' '=' expr      -- a function of tensors
  stmt    := 'let' NAME '=' expr | 'print' expr
  type    := 'tensor' '[' dim 'x' dim ']'      dim := INT | '?'
  expr    := product (('+'|'-') product)*
  product := unary (('*'|'/'|'@') unary)*     unary := '-' unary | term
  term    := NAME | NUMBER | matrix | 'transpose' '(' expr ')' | NAME '(' expr (',' expr)* ')' | '(' expr ')'
  matrix  := '[' row (',' row)* ']'   row := '[' NUM (',' NUM)* ']'
Every value is a rank-2 f64 tensor. A dimension is an int or None (dynamic, written '?').
"""
import re, sys

class MgError(Exception):
    def __init__(self, line, msg): self.line, self.msg = line, msg

TOKEN = re.compile(r"\s*(?:(?P<num>\d+\.?\d*(?:[eE][-+]?\d+)?)|(?P<id>[A-Za-z_]\w*)|(?P<sym>[()\[\],+\-*/@=:?]))")

def tokenize(text, line):
    toks, pos = [], 0
    text = text.rstrip()
    while pos < len(text):
        m = TOKEN.match(text, pos)
        if not m:
            raise MgError(line, f"unexpected character {text[pos:].lstrip()[0]!r}")
        pos = m.end()
        kind = m.lastgroup
        toks.append((kind, m.group(kind)))
    return toks

def mlir_float(text):
    """MLIR's float literals need a decimal point before any exponent: '3e2' is rejected, '3.0e2' is accepted."""
    t = repr(float(text))                      # '300.0', '0.25', '1e+16', '1.5e-07'
    if "e" in t and "." not in t:
        mantissa, exp = t.split("e"); t = mantissa + ".0e" + exp
    return t

def fmt(shape):  # (2,None) -> 'tensor<2x?xf64>'
    return "tensor<" + "x".join("?" if d is None else str(d) for d in shape) + "xf64>"

def shape_str(s):
    return "x".join("?" if d is None else str(d) for d in s)

class Emitter:
    def __init__(self):
        self.funcs = {}      # name -> (param shapes, result shape)
        self.out = []

class Func:
    """One function body under construction: SSA counter, environment, emitted lines."""
    def __init__(self, em, line_of):
        self.em, self.env, self.lines, self.n = em, {}, [], 0
    def tmp(self):
        self.n += 1; return f"%t{self.n}"
    def emit(self, s): self.lines.append("  " + s)

class Parser:
    def __init__(self, toks, line, fn):
        self.t, self.i, self.line, self.fn = toks, 0, line, fn
    def peek(self): return self.t[self.i] if self.i < len(self.t) else (None, None)
    def take(self, want=None):
        k, v = self.peek()
        if k is None: raise MgError(self.line, "unexpected end of line")
        if want is not None and v != want:
            raise MgError(self.line, f"expected {want!r} but found {v!r}")
        self.i += 1; return k, v
    # A value is (ssa_name, shape) for a matrix, or (None, float) for a compile-time scalar.
    OPNAME = {"+": "add", "-": "sub", "*": "mul", "/": "div"}
    VERB = {"+": "add", "-": "subtract", "*": "multiply", "/": "divide", "@": "multiply (matmul)"}
    def expr(self):                       # additive level: + and -
        x = self.product()
        while self.peek()[1] in ("+", "-"):
            op = self.take()[1]; y = self.product(); x = self.binary(op, x, y)
        return x
    def product(self):                    # multiplicative level: * (elementwise), / (elementwise), @ (matmul)
        x = self.unary()
        while self.peek()[1] in ("*", "/", "@"):
            op = self.take()[1]; y = self.unary(); x = self.binary(op, x, y)
        return x
    def unary(self):
        if self.peek()[1] == "-":
            self.take("-"); v, s = self.unary()
            if v is None: return None, -s
            self.need2(s, "unary '-'")
            r = self.fn.tmp(); self.fn.emit(f"{r} = mg.neg {v} : {fmt(s)} -> {fmt(s)}"); return r, s
        return self.term()
    def need2(self, s, what):
        if len(s) != 2:
            raise MgError(self.line, f"{what} works on matrices (rank 2), but this value has shape {shape_str(s)} (rank {len(s)}); use reshape, permute or contract")
    def binary(self, op, x, y):
        (v, s), (w, s2) = x, y
        if v is not None: self.need2(s, f"'{op}'")
        if w is not None: self.need2(s2, f"'{op}'")
        if op == "@":
            if v is None or w is None: raise MgError(self.line, "'@' (matrix product) needs two matrices, not a scalar")
            if s[1] is not None and s2[0] is not None and s[1] != s2[0]:
                raise MgError(self.line, f"cannot multiply (matmul) shapes {s[0]}x{s[1]} and {s2[0]}x{s2[1]}: inner dimensions differ")
            shape = (s[0], s2[1]); r = self.fn.tmp()
            self.fn.emit(f"{r} = mg.matmul {v}, {w} : {fmt(s)}, {fmt(s2)} -> {fmt(shape)}")
            return r, shape
        if v is None and w is None:       # scalar op scalar: folded here
            if op == "/" and s2 == 0: raise MgError(self.line, "division of a scalar by zero")
            return None, {"+": s + s2, "-": s - s2, "*": s * s2, "/": (s / s2 if op == "/" else 0)}[op]
        if v is None or w is None:        # matrix with a scalar: mg.scalar, reversed when the scalar is on the left
            rev = v is None
            m, shp, c = (w, s2, s) if rev else (v, s, s2)
            r = self.fn.tmp()
            self.fn.emit(f'{r} = mg.scalar {m} {{op = "{self.OPNAME[op]}", value = {mlir_float(str(c))} : f64, reversed = {"true" if rev else "false"}}} : {fmt(shp)} -> {fmt(shp)}')
            return r, shp
        v, s, w, s2 = self.broadcast_pair(op, v, s, w, s2)
        shape = tuple(a if a is not None else b for a, b in zip(s, s2)); r = self.fn.tmp()
        self.fn.emit(f"{r} = mg.{self.OPNAME[op]} {v}, {w} : {fmt(s)}, {fmt(s2)} -> {fmt(shape)}")
        return r, shape
    def broadcast_pair(self, op, v, s, w, s2):
        """Make two shapes agree for an elementwise operator. A static dimension of size 1 grows to match the other
        operand's (explicit mg.broadcast); equal sizes and '?' are left alone; anything else is an error."""
        target = []
        for a, b in zip(s, s2):
            if a is None or b is None or a == b: target.append(b if a is None else a)
            elif a == 1: target.append(b)
            elif b == 1: target.append(a)
            else: raise MgError(self.line, f"cannot {self.VERB[op]} shapes {'x'.join('?' if d is None else str(d) for d in s)} and {'x'.join('?' if d is None else str(d) for d in s2)}: "
                                           f"dimensions {a} and {b} differ and neither is 1")
        target = tuple(target)
        return (*self.grow(v, s, target), *self.grow(w, s2, target))
    def grow(self, v, s, target):
        if s == target or all(a is None or a == t for a, t in zip(s, target)): return v, s
        if None in s or None in target: raise MgError(self.line, "broadcasting needs static shapes; this operand has a '?' dimension")
        r = self.fn.tmp(); self.fn.emit(f"{r} = mg.broadcast {v} : {fmt(s)} -> {fmt(target)}")
        return r, target
    def term(self):
        k, v = self.peek()
        if k is None: raise MgError(self.line, "expected an expression, found the end of the line")
        if v == "(":
            self.take("("); r = self.expr(); self.take(")"); return r
        if v == "[": return self.matrix()
        if k == "num": self.take(); return None, float(v)
        if k == "id":
            self.take()
            if v == "transpose":
                self.take("("); x, s = self.expr(); self.take(")")
                self.need2(s, "transpose")
                shape = (s[1], s[0]); r = self.fn.tmp()
                self.fn.emit(f"{r} = mg.transpose {x} : {fmt(s)} to {fmt(shape)}")
                return r, shape
            if v in ("reshape", "permute", "contract") and self.peek()[1] == "(":
                return getattr(self, "t_" + v)()
            if v in self.BUILTINS and self.peek()[1] == "(":
                return self.builtin(v)
            if self.peek()[1] == "(":
                return self.call(v)
            if v not in self.fn.env: raise MgError(self.line, f"unknown name {v!r}")
            return self.fn.env[v]
        raise MgError(self.line, f"unexpected {v!r}")
    BUILTINS = {"relu", "exp", "row_sum", "col_sum", "row_max", "col_max", "row_mean", "col_mean"}
    def builtin(self, name):
        self.take("("); v, s = self.expr(); self.take(")")
        if v is None: raise MgError(self.line, f"{name} needs a matrix, not a scalar")
        self.need2(s, name)
        if name == "relu":
            r = self.fn.tmp(); self.fn.emit(f"{r} = mg.relu {v} : {fmt(s)} -> {fmt(s)}"); return r, s
        if name == "exp":
            r = self.fn.tmp(); self.fn.emit(f"{r} = mg.exp {v} : {fmt(s)} -> {fmt(s)}"); return r, s
        axis = 1 if name.startswith("row_") else 0              # row_*: one value per row (axis 1); col_*: one per column (axis 0)
        kind = "sum" if name.endswith("sum") else "max" if name.endswith("max") else "mean"
        shape = (s[0], 1) if axis == 1 else (1, s[1])
        r = self.fn.tmp()
        self.fn.emit(f'{r} = mg.reduce {v} {{axis = {axis} : i64, kind = "{"sum" if kind == "mean" else kind}"}} : {fmt(s)} -> {fmt(shape)}')
        if kind == "mean":                                       # mean = sum / count; the count must be known now
            if s[axis] is None: raise MgError(self.line, f"{name} needs a static size along the averaged axis, not '?'")
            q = self.fn.tmp()
            self.fn.emit(f'{q} = mg.scalar {r} {{op = "div", value = {mlir_float(str(s[axis]))} : f64, reversed = false}} : {fmt(shape)} -> {fmt(shape)}')
            r = q
        return r, shape
    # ---- Chapter 28: tensors of any rank ----
    def int_list(self, what):
        """',' INT (',' INT)* -- the dimension or axis numbers after the first argument of reshape/permute."""
        out = []
        while self.peek()[1] == ",":
            self.take(",")
            k, v = self.take()
            if k != "num" or not v.isdigit(): raise MgError(self.line, f"{what}: expected a whole number, found {v!r}")
            out.append(int(v))
        return out
    def static_tensor(self, name):
        v, s = self.expr()
        if v is None: raise MgError(self.line, f"{name} needs a tensor, not a scalar")
        if None in s: raise MgError(self.line, f"{name} needs a static shape; this value has a '?' dimension ({shape_str(s)})")
        return v, s
    def reshape_to(self, v, s, dims):
        if tuple(dims) == tuple(s): return v, s
        r = self.fn.tmp(); self.fn.emit(f"{r} = mg.reshape {v} : {fmt(s)} -> {fmt(dims)}"); return r, tuple(dims)
    def permute_by(self, v, s, perm):
        if list(perm) == list(range(len(s))): return v, s
        shape = tuple(s[p] for p in perm); r = self.fn.tmp()
        self.fn.emit(f"{r} = mg.permute {v} {{permutation = array<i64: {', '.join(map(str, perm))}>}} : {fmt(s)} -> {fmt(shape)}")
        return r, shape
    def t_reshape(self):
        self.take("("); v, s = self.static_tensor("reshape"); dims = self.int_list("reshape"); self.take(")")
        if not dims or 0 in dims: raise MgError(self.line, "reshape: give one or more positive dimensions after the tensor")
        n_in = 1; n_out = 1
        for d in s: n_in *= d
        for d in dims: n_out *= d
        if n_in != n_out:
            raise MgError(self.line, f"cannot reshape {shape_str(s)} ({n_in} elements) to {shape_str(dims)} ({n_out} elements)")
        return self.reshape_to(v, s, dims)
    def t_permute(self):
        self.take("("); v, s = self.static_tensor("permute"); perm = self.int_list("permute"); self.take(")")
        if sorted(perm) != list(range(len(s))):
            raise MgError(self.line, f"permute: a rank-{len(s)} tensor needs each of the axes 0..{len(s) - 1} listed exactly once, got {', '.join(map(str, perm)) or 'none'}")
        return self.permute_by(v, s, perm)
    def axis_group(self):
        """'(' [INT (',' INT)*] ')' -- a (possibly empty) list of axis numbers."""
        self.take("("); axes = []
        while self.peek()[1] != ")":
            k, v = self.take()
            if k != "num" or not v.isdigit(): raise MgError(self.line, f"contract: expected an axis number, found {v!r}")
            axes.append(int(v))
            if self.peek()[1] == ",": self.take(",")
        self.take(")"); return axes
    def t_contract(self):
        """contract(a, (axes of a), b, (axes of b)): permute, reshape, matrix product, reshape -- all Mountain Goat operations."""
        self.take("("); a, sa = self.static_tensor("contract"); self.take(",")
        ia = self.axis_group(); self.take(",")
        b, sb = self.static_tensor("contract"); self.take(",")
        ib = self.axis_group(); self.take(")")
        if len(ia) != len(ib): raise MgError(self.line, "contract: the two axis lists must have the same length")
        for name, s, axes in (("the first tensor", sa, ia), ("the second tensor", sb, ib)):
            for k, ax in enumerate(axes):
                if ax >= len(s): raise MgError(self.line, f"contract: axis {ax} is out of range for {name} (shape {shape_str(s)})")
                if ax in axes[:k]: raise MgError(self.line, f"contract: axis {ax} is listed twice for {name}")
        for x, y in zip(ia, ib):
            if sa[x] != sb[y]:
                raise MgError(self.line, f"contract: axis {x} of the first tensor has size {sa[x]} but axis {y} of the second has size {sb[y]}")
        fa = [d for d in range(len(sa)) if d not in ia]; fb = [d for d in range(len(sb)) if d not in ib]
        m = 1
        for d in fa: m *= sa[d]
        n = 1
        for d in fb: n *= sb[d]
        k = 1
        for d in ia: k *= sa[d]
        a, sa2 = self.permute_by(a, sa, fa + ia); a, _ = self.reshape_to(a, sa2, (m, k))     # A: free axes first, contracted axes last
        b, sb2 = self.permute_by(b, sb, ib + fb); b, _ = self.reshape_to(b, sb2, (k, n))     # B: contracted axes first, free axes last
        r = self.fn.tmp(); self.fn.emit(f"{r} = mg.matmul {a}, {b} : {fmt((m, k))}, {fmt((k, n))} -> {fmt((m, n))}")
        out = tuple(sa[d] for d in fa) + tuple(sb[d] for d in fb)
        if not out: return r, (1, 1)                  # every axis contracted: the scalar is returned as a 1x1 matrix
        return self.reshape_to(r, (m, n), out)
    def call(self, name):
        if name not in self.fn.em.funcs: raise MgError(self.line, f"unknown function {name!r}")
        params, result = self.fn.em.funcs[name]
        self.take("("); args = [self.expr()]
        while self.peek()[1] == ",": self.take(","); args.append(self.expr())
        self.take(")")
        if len(args) != len(params):
            raise MgError(self.line, f"{name} takes {len(params)} arguments, got {len(args)}")
        vals = []
        for (v, s), p in zip(args, params):
            if v is None: raise MgError(self.line, f"{name}: a scalar cannot be passed where a matrix is expected")
            self.need2(s, f"{name}'s argument")
            for a, b in zip(s, p):
                if b is not None and a != b:
                    raise MgError(self.line, f"argument shape {'x'.join('?' if d is None else str(d) for d in s)} does not fit parameter {'x'.join('?' if d is None else str(d) for d in p)}")
            if s != p:  # static -> dynamic (or the reverse): a tensor.cast
                c = self.fn.tmp(); self.fn.emit(f"{c} = tensor.cast {v} : {fmt(s)} to {fmt(p)}"); v = c
            vals.append(v)
        r = self.fn.tmp()
        sig = ", ".join(fmt(p) for p in params)
        self.fn.emit(f"{r} = func.call @{name}({', '.join(vals)}) : ({sig}) -> {fmt(result)}")
        return r, result
    def entry(self):
        neg = self.peek()[1] == "-"
        if neg: self.take("-")
        return ("-" if neg else "") + self.take()[1]
    def matrix(self):
        rows = []
        self.take("[")
        while True:
            self.take("["); row = [self.entry()]
            while self.peek()[1] == ",": self.take(","); row.append(self.entry())
            self.take("]"); rows.append(row)
            if self.peek()[1] == ",": self.take(","); continue
            break
        self.take("]")
        if len({len(r) for r in rows}) != 1: raise MgError(self.line, "matrix rows have different lengths")
        def f(x):
            if not re.fullmatch(r"-?\d+\.?\d*(?:[eE][-+]?\d+)?", x): raise MgError(self.line, f"{x!r} is not a number")
            return mlir_float(x)
        body = "[" + ", ".join("[" + ", ".join(f(x) for x in r) + "]" for r in rows) + "]"
        shape = (len(rows), len(rows[0])); r = self.fn.tmp()
        self.fn.emit(f"{r} = mg.constant dense<{body}> : {fmt(shape)}")
        return r, shape

def parse_type(p):
    """tensor[RxC] where each of R, C is an integer or '?'."""
    p.take("tensor"); p.take("[")
    dims = []
    for i in range(2):
        v = p.take()[1]
        if v == "?": dims.append(None)
        elif v.isdigit() and int(v) > 0: dims.append(int(v))
        else: raise MgError(p.line, f"bad dimension {v!r}: use a positive integer or '?'")
        if i == 0 and p.take()[1] != "x": raise MgError(p.line, "expected 'x' between dimensions")
    p.take("]"); return tuple(dims)

def compile_source(src, lib=False, header=False, guard="MG_GENERATED_H"):
    em, funcs_text, main = Emitter(), [], None
    em.defs = []
    main = Func(em, None)
    for ln, raw in enumerate(src.splitlines(), 1):
        text = raw.split("#", 1)[0].strip()
        if not text: continue
        text = re.sub(r"(\d|\?)x(?=\d|\?)", r"\1 x ", text)   # '2x3' -> '2 x 3' so the tokenizer sees three tokens
        toks = tokenize(text, ln)
        if toks[0][1] == "def":
            fn = Func(em, ln); p = Parser(toks, ln, fn); p.take("def")
            name = p.take()[1]; p.take("(")
            params, names = [], []
            while p.peek()[1] != ")":
                n = p.take()[1]; p.take(":"); shp = parse_type(p)
                names.append(n); params.append(shp)
                if p.peek()[1] == ",": p.take(",")
            p.take(")"); p.take("=")
            for i, (n, shp) in enumerate(zip(names, params)): fn.env[n] = (f"%{n}", shp)
            v, s = p.expr()
            if v is None: raise MgError(ln, f"def {name}: a function must return a matrix, not a scalar")
            if len(s) != 2: raise MgError(ln, f"def {name}: a function must return a matrix (rank 2), not shape {shape_str(s)}; reshape the result first")
            if p.i != len(toks): raise MgError(ln, f"unexpected {p.peek()[1]!r}")
            em.funcs[name] = (params, s)
            em.defs.append((name, names, params, s))
            sig = ", ".join(f"%{n}: {fmt(sh)}" for n, sh in zip(names, params))
            funcs_text.append(f"func.func @{name}({sig}) -> {fmt(s)} {{\n" + "\n".join(fn.lines) + f"\n  func.return {v} : {fmt(s)}\n}}")
            continue
        p = Parser(toks, ln, main); kw = p.take()[1]
        if kw == "let":
            n = p.take()[1]; p.take("="); v, s = p.expr(); main.env[n] = (v, s)
        elif kw == "print":
            v, s = p.expr()
            if v is None: raise MgError(ln, "print needs a matrix; a scalar has no shape to print")
            main.emit(f"mg.print {v} : {fmt(s)}")
        else:
            raise MgError(ln, f"a statement must start with 'let', 'print' or 'def', not {kw!r}")
        if p.i != len(toks): raise MgError(ln, f"unexpected {p.peek()[1]!r}")
    if header: return make_header(em.defs, guard)
    if lib:
        if main.lines: raise MgError(0, "lib mode: top-level 'let'/'print' statements are not allowed (only 'def')")
        return "\n".join(funcs_text) + "\n"
    main.emit("%zero = arith.constant 0 : i32")
    return "\n".join(funcs_text + ["func.func @main() -> i32 {\n" + "\n".join(main.lines) + "\n  func.return %zero : i32\n}"]) + "\n"

HEADER_TOP = """// Generated by mgfront.py -- do not edit. C++ view of compiled Mountain Goat functions.
#pragma once
#include <cstdint>
#include <cstdlib>
#include <stdexcept>
#include <string>
#include <vector>

namespace mg {
// A dense row-major f64 matrix that owns its storage.
struct Matrix {
  int64_t rows = 0, cols = 0;
  std::vector<double> data;
  Matrix() = default;
  Matrix(int64_t r, int64_t c, std::vector<double> d) : rows(r), cols(c), data(std::move(d)) {
    if ((int64_t)data.size() != r * c) throw std::invalid_argument("Matrix: data size != rows*cols");
  }
  double &operator()(int64_t i, int64_t j) { return data[i * cols + j]; }
  double operator()(int64_t i, int64_t j) const { return data[i * cols + j]; }
};
// The memref descriptor the compiled code returns (rank 2).
struct Desc { double *allocated, *aligned; int64_t offset, sizes[2], strides[2]; };
inline Matrix take(Desc d) {   // copy out through the strides, then release the callee's malloc
  Matrix m; m.rows = d.sizes[0]; m.cols = d.sizes[1]; m.data.resize(m.rows * m.cols);
  for (int64_t i = 0; i < m.rows; i++)
    for (int64_t j = 0; j < m.cols; j++)
      m.data[i * m.cols + j] = d.aligned[d.offset + i * d.strides[0] + j * d.strides[1]];
  std::free(d.allocated);
  return m;
}
inline void expect(const Matrix &m, int64_t r, int64_t c, const char *fn, const char *arg) {
  if ((r >= 0 && m.rows != r) || (c >= 0 && m.cols != c))
    throw std::invalid_argument(std::string(fn) + ": argument '" + arg + "' has the wrong shape");
}
}  // namespace mg
"""

def make_header(defs, guard):
    out = [HEADER_TOP, 'extern "C" {']
    for name, names, params, _ in defs:
        out.append(f"mg::Desc {name}(" + ", ".join("double*, double*, int64_t, int64_t, int64_t, int64_t, int64_t" for _ in params) + ");")
    out.append('}\n\nnamespace mg {')
    for name, names, params, _ in defs:
        sig = ", ".join(f"const Matrix &{n}" for n in names)
        out.append(f"// {name}(" + ", ".join(f"{n}: " + "x".join('?' if d is None else str(d) for d in p) for n, p in zip(names, params)) + ")")
        out.append(f"inline Matrix {name}({sig}) {{")
        for n, p in zip(names, params):
            r = -1 if p[0] is None else p[0]; c = -1 if p[1] is None else p[1]
            if r >= 0 or c >= 0: out.append(f'  expect({n}, {r}, {c}, "{name}", "{n}");')
        args = []
        for n in names:
            d = f"const_cast<double*>({n}.data.data())"
            args.append(f"{d}, {d}, 0, {n}.rows, {n}.cols, {n}.cols, 1")
        out.append(f"  return take(::{name}(" + ", ".join(args) + "));")
        out.append("}")
    out.append("}  // namespace mg")
    return "\n".join(out) + "\n"

if __name__ == "__main__":
    flags = [a for a in sys.argv[1:] if a.startswith("--")]; path = [a for a in sys.argv[1:] if not a.startswith("--")][0]
    try:
        sys.stdout.write(compile_source(open(path).read(), lib="--lib" in flags, header="--header" in flags))
    except MgError as e:
        print(f"{path}:{e.line}: error: {e.msg}", file=sys.stderr); sys.exit(1)
