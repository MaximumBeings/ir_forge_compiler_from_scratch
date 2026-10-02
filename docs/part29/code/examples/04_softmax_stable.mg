# The fix: subtract each row's largest score first. That changes nothing mathematically (the factor e^(-max) cancels between the top
# and the bottom of the fraction) but it makes every exponent <= 0, so every exp is <= 1 and nothing can overflow.
def softmax(x: tensor[2x3]) = exp(x - row_max(x)) / row_sum(exp(x - row_max(x)))
print softmax([[1000, 1001, 1002], [1, 2, 3]])     # both rows have the same gaps between scores, so the same probabilities
print softmax([[1, 2, 3], [1, 2, 3]] + 100)        # adding 100 to every score changes nothing (shift invariance)
print softmax([[-1000, -1001, -1002], [0, 0, 0]])  # very negative scores: exp underflows to 0 harmlessly, the largest one still wins
