#!/usr/bin/env python3
"""Writes the Chapter 30 example programs. Short ones are assembled from lines of transformer.mg.defs, so a page example cannot drift from the definitions."""
import os, re
import transformer_lib as T
here = os.path.join(os.path.dirname(os.path.abspath(__file__)), "examples")
defs = {m.group(1): l for l in T.DEFS.split("\n") for m in [re.match(r"def (\w+)\(", l)] if m}
def write(name, text): open(os.path.join(here, name), "w").write(text)

write("01_layer_norm.mg", f"""# Layer normalisation shifts each ROW (one token's features) to mean 0 and scales it to variance 1, then applies a per-feature scale g and shift b.
# Here g is all ones and b all zeros, so what is left is pure normalisation. The first row is 1 2 3 4: mean 2.5, variance 1.25, standard deviation 1.118.
{defs['layer_norm']}
let x = [[1, 2, 3, 4], [10, 10, 10, 10], [-1, 0, 1, 0], [0, 0, 0, 8]]
print layer_norm(x, [[1, 1, 1, 1]], [[0, 0, 0, 0]])
# The same rows with a scale of 2 and a shift of 5: every normalised number is doubled, then 5 is added.
print layer_norm(x, [[2, 2, 2, 2]], [[5, 5, 5, 5]])
""")
write("02_feed_forward.mg", f"""# The feed-forward network: expand to 8 features, keep only the positive ones (relu), contract back to 4.
# With w1 = [I | -I] (an identity next to a negated identity) and w2 = [I ; -I] the hidden layer holds relu(x) next to relu(-x), and the output
# is relu(x) - relu(-x), which is x itself: two relus can build a straight line. The numbers below confirm it.
{defs['ffn']}
let x = [[1, -2, 0, 3], [-1, 1, -1, 1], [0, 0, 0, 0], [5, -5, 2, -2]]
let w1 = [[1, 0, 0, 0, -1, 0, 0, 0], [0, 1, 0, 0, 0, -1, 0, 0], [0, 0, 1, 0, 0, 0, -1, 0], [0, 0, 0, 1, 0, 0, 0, -1]]
let w2 = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1], [-1, 0, 0, 0], [0, -1, 0, 0], [0, 0, -1, 0], [0, 0, 0, -1]]
let zero8 = [[0, 0, 0, 0, 0, 0, 0, 0]]
let zero4 = [[0, 0, 0, 0]]
print ffn(x, w1, zero8, w2, zero4)
# A bias moves the hidden features before the relu: a bias of -1 on the first four hides every value below 1.
print ffn(x, w1, [[-1, -1, -1, -1, 0, 0, 0, 0]], w2, zero4)
""")
w = T.make_weights(1)
write("03_tiny_transformer.mg", T.program(w, [1, 3, 0, 2]))
write("04_last_token_changed.mg", T.program(w, [1, 3, 0, 4]))
write("errors/e1_wrong_number_of_tokens.mg", f"""# The model was written for 4 tokens. Three tokens do not fit the 4x4 parameter of layer_norm, and the compiler says so.
{defs['layer_norm']}
print layer_norm([[1, 2, 3, 4], [4, 3, 2, 1], [0, 1, 0, 1]], [[1, 1, 1, 1]], [[0, 0, 0, 0]])
""")
write("errors/e2_missing_argument.mg", f"""# attention_sublayer takes twelve arguments. Eleven is an arity error, reported before any code exists.
{defs['softmax']}
{defs['layer_norm']}
{defs['head']}
{defs['attention']}
{defs['attention_sublayer']}
let m = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
let h = [[1, 0], [0, 1], [1, 1], [0, 0]]
let g = [[1, 1, 1, 1]]
print attention_sublayer(m, m, g, g, h, h, h, [[1, 0, 0, 0], [0, 1, 0, 0]], h, h, h)
""")
write("errors/e3_sqrt_of_a_scalar.mg", "# sqrt is applied to a matrix. A bare number in the source is a compile-time scalar.\nprint sqrt(16)\n")
write("errors/e4_residual_shapes_differ.mg", f"""# A residual connection adds the sublayer's output to its input, so their shapes must be equal. A 4x2 head output cannot be added to a 4x4 input.
let x = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
let head_output = [[1, 0], [0, 1], [1, 1], [0, 0]]
print x + head_output
""")
