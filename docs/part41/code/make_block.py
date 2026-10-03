#!/usr/bin/env python3
"""Chapter 41: writes Mountain Goat programs for the forward pass of ONE transformer block (single head, causal, pre-norm, ReLU feed-forward, residual connections) at a size
chosen on the command line, with seeded weights, and the programs of the decode-versus-prefill study. Usage: make_block.py  (writes examples/block_*.mg and examples/ffn_*.mg)"""
import os, sys
here = os.path.dirname(os.path.abspath(__file__))
def lcg(seed):
    x = seed
    while True: x = (x * 1103515245 + 12345) % (2 ** 31); yield x / 2 ** 31
def mat(r, rows, cols, scale): return "[" + ", ".join("[" + ", ".join(repr(round((next(r) - 0.5) * 2 * scale, 3)) for _ in range(cols)) + "]" for _ in range(rows)) + "]"
def block(n, d, f, seed=1):
    r = lcg(seed); sc = 1 / d ** 0.5
    mask = "[" + ", ".join("[" + ", ".join("0" if j <= i else "-1000000000" for j in range(n)) + "]" for i in range(n)) + "]"
    T = lambda a, b: f"tensor[{a}x{b}]"
    L = [f"# One transformer block (pre-norm, single head, causal, ReLU feed-forward) on {n} tokens of width {d}, feed-forward width {f}; seeded weights. Forward pass only.",
         f"def softmax(s: {T(n, n)}) = exp(s - row_max(s)) / row_sum(exp(s - row_max(s)))",
         f"def layer_norm(x: {T(n, d)}, g: {T(1, d)}, b: {T(1, d)}) = (x - row_mean(x)) / sqrt(row_mean((x - row_mean(x)) * (x - row_mean(x))) + 0.00001) * g + b",
         f"def attention(x: {T(n, d)}, wq: {T(d, d)}, wk: {T(d, d)}, wv: {T(d, d)}, wo: {T(d, d)}, mask: {T(n, n)}) = softmax((x @ wq) @ transpose(x @ wk) * {sc!r} + mask) @ (x @ wv) @ wo",
         f"def ffn(x: {T(n, d)}, w1: {T(d, f)}, b1: {T(1, f)}, w2: {T(f, d)}, b2: {T(1, d)}) = relu(x @ w1 + b1) @ w2 + b2",
         f"let x = {mat(r, n, d, 1.0)}", f"let mask = {mask}",
         f"let g1 = {mat(r, 1, d, 0.1)}", f"let b1n = {mat(r, 1, d, 0.1)}", f"let g2 = {mat(r, 1, d, 0.1)}", f"let b2n = {mat(r, 1, d, 0.1)}"]
    for nm in ("wq", "wk", "wv", "wo"): L.append(f"let {nm} = {mat(r, d, d, sc)}")
    L += [f"let w1 = {mat(r, d, f, sc)}", f"let b1 = {mat(r, 1, f, 0.1)}", f"let w2 = {mat(r, f, d, 1 / f ** 0.5)}", f"let b2 = {mat(r, 1, d, 0.1)}",
          "let h = x + attention(layer_norm(x, g1, b1n), wq, wk, wv, wo, mask)", "let y = h + ffn(layer_norm(h, g2, b2n), w1, b1, w2, b2)", "print y"]
    return "\n".join(L) + "\n"
def ffn_only(tokens, d, f, seed=1):
    r = lcg(seed); T = lambda a, b: f"tensor[{a}x{b}]"
    return "\n".join([f"# The feed-forward network alone on {tokens} token(s) of width {d} (feed-forward width {f}): relu(x @ w1 + b1) @ w2 + b2. Used by the decode-versus-prefill study.",
        f"def ffn(x: {T(tokens, d)}, w1: {T(d, f)}, b1: {T(1, f)}, w2: {T(f, d)}, b2: {T(1, d)}) = relu(x @ w1 + b1) @ w2 + b2",
        f"let x = {mat(r, tokens, d, 1.0)}", f"let w1 = {mat(r, d, f, 1 / d ** 0.5)}", f"let b1 = {mat(r, 1, f, 0.1)}", f"let w2 = {mat(r, f, d, 1 / f ** 0.5)}", f"let b2 = {mat(r, 1, d, 0.1)}",
        "print ffn(x, w1, b1, w2, b2)"]) + "\n"
if __name__ == "__main__":
    out = os.path.join(here, "examples"); os.makedirs(out, exist_ok=True)
    for n, d, f in ((8, 16, 32), (32, 32, 64), (64, 64, 128)): open(os.path.join(out, f"block_n{n}_d{d}.mg"), "w").write(block(n, d, f))
    for t in (1, 2, 4, 8, 16, 32, 64): open(os.path.join(out, f"ffn_tokens{t:02d}.mg"), "w").write(ffn_only(t, 64, 256))
    print("wrote", sorted(os.listdir(out)))
