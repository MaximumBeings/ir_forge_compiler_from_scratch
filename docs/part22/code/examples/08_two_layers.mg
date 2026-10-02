# Two layers, and the largest output of each row, the "prediction" of a tiny network.
def net(x: tensor[2x2]) = row_max(relu(relu(x @ [[1, -1], [2, 1]] + [[0, 1]]) @ [[1], [-1]] + [[0]]) @ [[1, 2]])
print net([[1, 1], [-1, 2]])
