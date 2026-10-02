# Counting walks in a directed graph. Entry [i][j] of a is 1 if there is an edge from node i to node j.
# Entry [i][j] of (a @ a) counts the 2-step walks from i to j; of (a @ a @ a), the 3-step walks.
let a = [[0, 1, 1, 0], [0, 0, 1, 1], [0, 0, 0, 1], [1, 0, 0, 0]]
print a @ a
print a @ a @ a
