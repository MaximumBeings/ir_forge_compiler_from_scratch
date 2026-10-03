# Only some rows of the stacked matrix are predictions. Here a 4-row logits matrix over 3 words, of which rows 1 and 3 are targets (mr is 1 on them, 0 elsewhere).
# y holds the correct next word one-hot on the target rows and zeros elsewhere. The loss averages over the 2 target rows (hence the 0.5), and the gradient with
# respect to the logits is (softmax(z) * mr - y) * 0.5: the rows that are not targets get exactly zero gradient.
def log_softmax(z: tensor[4x3]) = z - row_max(z) - log(row_sum(exp(z - row_max(z))))
let z = [[1, 2, 3], [0, 0, 0], [5, 1, 1], [1, 3, 2]]
let mr = [[0], [1], [0], [1]]
let y = [[0, 0, 0], [0, 1, 0], [0, 0, 0], [0, 0, 1]]
print col_sum(row_sum(y * log_softmax(z))) * -0.5
print (exp(log_softmax(z)) * mr - y) * 0.5
# Second row: three equal logits give each word 1/3; the correct word is the middle one, so that row's gradient is (1/3, 1/3 - 1, 1/3) / 2 = (0.1667, -0.3333, 0.1667).
