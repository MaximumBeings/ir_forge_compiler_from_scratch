# Blurring a tiny image, one row at a time, is a matrix product: the blur matrix averages each pixel with its neighbours.
let image = [[0, 0, 9, 0, 0], [0, 9, 9, 9, 0], [9, 9, 9, 9, 9]]     # 3 rows of 5 pixels
let blur = [[0.5, 0.5, 0, 0, 0], [0.25, 0.5, 0.25, 0, 0], [0, 0.25, 0.5, 0.25, 0], [0, 0, 0.25, 0.5, 0.25], [0, 0, 0, 0.5, 0.5]]
print image @ blur                      # (3x5) @ (5x5): every pixel becomes a weighted average of itself and its left and right neighbours
