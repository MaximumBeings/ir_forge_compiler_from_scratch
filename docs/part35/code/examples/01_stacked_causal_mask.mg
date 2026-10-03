# Two sequences of three tokens are stacked into one 6-row matrix, so attention is computed over all 6 rows at once. The mask must let row r look at
# column c only if c is in the SAME sequence and c <= r. Entries that must not be seen get -1000000000, which softmax turns into exactly 0.
# (Rows 0-2 are sequence one, rows 3-5 sequence two.) The scores are made up: each is 1, so without the mask every row would be uniform.
def softmax_rows(m: tensor[6x6]) = exp(m - row_max(m)) / row_sum(exp(m - row_max(m)))
let mask = [[0, -1000000000, -1000000000, -1000000000, -1000000000, -1000000000], [0, 0, -1000000000, -1000000000, -1000000000, -1000000000], [0, 0, 0, -1000000000, -1000000000, -1000000000], [-1000000000, -1000000000, -1000000000, 0, -1000000000, -1000000000], [-1000000000, -1000000000, -1000000000, 0, 0, -1000000000], [-1000000000, -1000000000, -1000000000, 0, 0, 0]]
let scores = [[1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1]]
print softmax_rows(scores + mask)
# Each row sums to 1; row 0 is all on itself, row 2 is 1/3 each on rows 0-2, row 5 is 1/3 each on rows 3-5, and nothing leaks between the two sequences.
print row_sum(softmax_rows(scores + mask))
