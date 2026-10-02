# Inner dimensions 3 and 2 do not agree. The front end cannot see this (both are ?), so the program
# compiles and the run-time check aborts with a message on stderr.
def mm(a: tensor[?x?], b: tensor[?x?]) = a @ b
print mm([[1, 2, 3], [4, 5, 6]], [[1, 2], [3, 4]])
