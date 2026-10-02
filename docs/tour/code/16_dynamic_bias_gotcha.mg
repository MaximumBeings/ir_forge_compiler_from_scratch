# THE GOTCHA: adding a fixed 1x2 bias directly to a result with a '?' row count compiles, because '?' might turn out to be 1,
# but a '?' is never broadcast. With one sample the sizes happen to match; with three the program stops with an error message.
def scale_and_shift(batch: tensor[?x2], w: tensor[2x2], b: tensor[1x2]) = batch @ w + b
print scale_and_shift([[1, 1]], [[1, 0], [0, 2]], [[10, 20]])                        # fine: one row against one row
print scale_and_shift([[1, 1], [2, 2], [3, 3]], [[1, 0], [0, 2]], [[10, 20]])        # three rows against one: aborts at run time
