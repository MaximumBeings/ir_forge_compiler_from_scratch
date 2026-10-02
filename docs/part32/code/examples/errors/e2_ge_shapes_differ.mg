# The shapes must agree or broadcast: 2x3 and 3x2 do not.
print ge([[1, 2, 3], [4, 5, 6]], [[1, 2], [3, 4], [5, 6]])
