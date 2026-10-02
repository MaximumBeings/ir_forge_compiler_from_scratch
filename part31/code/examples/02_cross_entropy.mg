# Cross-entropy: how surprised a model is by what really happened. For each case, y is a one-hot row marking the token that really came next and p is
# the model's probability row; y * log(p) keeps only the log-probability the model gave the right token, and minus its average is the loss.
# Four cases (rows) over three tokens: a model with no idea, a confident correct model, a confident WRONG model, and a coin-flip between two.
let p = [[0.3333333333333333, 0.3333333333333333, 0.3333333333333333], [0.98, 0.01, 0.01], [0.01, 0.98, 0.01], [0.5, 0.5, 0.0000001]]
let y = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
print row_sum(y * log(p)) * -1                      # the surprise of each case: log(3) = 1.0986, 0.0202, 4.6052 (very wrong), 0.6931 (one bit)
print col_sum(row_sum(y * log(p))) * -0.25          # the loss: the average surprise, (1.0986 + 0.0202 + 4.6052 + 0.6931) / 4 = 1.6043
