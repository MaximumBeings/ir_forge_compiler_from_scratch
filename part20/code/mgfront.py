#!/usr/bin/env python3
"""mgfront: the Mountain Goat surface-syntax front end. Reads .mg source, writes MLIR (mg dialect) to stdout.

Grammar (one statement per line, '#' starts a comment):
  program := (def | stmt)*
  def     := 'def' NAME '(' [NAME ':' type (',' NAME ':' type)*] ')' '=' expr      -- a function of tensors
  stmt    := 'let' NAME '=' expr | 'print' expr
  type    := 'tensor' '[' dim 'x' dim ']'      dim := INT | '?'
  expr    := term ('+' term)*
  term    := NAME | matrix | 'transpose' '(' expr ')' | NAME '(' expr (',' expr)* ')' | '(' expr ')'
  matrix  := '[' row (',' row)* ']'   row := '[' NUM (',' NUM)* ']'
Every value is a rank-2 f64 tensor. A dimension is an int or None (dynamic, written '?').
"""
import re, sys

class MgError(Exception):
    def __init__(self, line, msg): self.line, self.msg = line, msg

TOKEN = re.compile(r"\s*(?:(?P<num>-?\d+\.?\d*(?:[eE][-+]?\d+)?)|(?P<id>[A-Za-z_]\w*)|(?P<sym>[()\[\],+=:?]))")

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

def fmt(shape):  # (2,None) -> 'tensor<2x?xf64>'
    return "tensor<" + "x".join("?" if d is None else str(d) for d in shape) + "xf64>"

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
    def expr(self):
        v, s = self.term()
        while self.peek()[1] == "+":
            self.take("+"); w, s2 = self.term()
            for a, b in zip(s, s2):
                if a is not None and b is not None and a != b:
                    raise MgError(self.line, f"cannot add shapes {'x'.join(map(str,s))} and {'x'.join(map(str,s2))}")
            shape = tuple(a if a is not None else b for a, b in zip(s, s2))
            r = self.fn.tmp()
            self.fn.emit(f"{r} = mg.add {v}, {w} : {fmt(s)}, {fmt(s2)} -> {fmt(shape)}")
            v, s = r, shape
        return v, s
    def term(self):
        k, v = self.peek()
        if v == "(":
            self.take("("); r = self.expr(); self.take(")"); return r
        if v == "[": return self.matrix()
        if k == "id":
            self.take()
            if v == "transpose":
                self.take("("); x, s = self.expr(); self.take(")")
                shape = (s[1], s[0]); r = self.fn.tmp()
                self.fn.emit(f"{r} = mg.transpose {x} : {fmt(s)} to {fmt(shape)}")
                return r, shape
            if self.peek()[1] == "(":
                return self.call(v)
            if v not in self.fn.env: raise MgError(self.line, f"unknown name {v!r}")
            return self.fn.env[v]
        raise MgError(self.line, f"unexpected {v!r}")
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
    def matrix(self):
        rows = []
        self.take("[")
        while True:
            self.take("["); row = [self.take()[1]]
            while self.peek()[1] == ",": self.take(","); row.append(self.take()[1])
            self.take("]"); rows.append(row)
            if self.peek()[1] == ",": self.take(","); continue
            break
        self.take("]")
        if len({len(r) for r in rows}) != 1: raise MgError(self.line, "matrix rows have different lengths")
        def f(x):
            if not re.fullmatch(r"-?\d+\.?\d*(?:[eE][-+]?\d+)?", x): raise MgError(self.line, f"{x!r} is not a number")
            return x if ("." in x or "e" in x.lower()) else x + ".0"
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
        elif v.isdigit(): dims.append(int(v))
        else: raise MgError(p.line, f"bad dimension {v!r}")
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
            v, s = p.expr(); main.emit(f"mg.print {v} : {fmt(s)}")
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
