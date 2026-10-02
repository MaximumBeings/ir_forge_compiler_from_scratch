# log(x) is the natural logarithm: the power e must be raised to in order to get x. It undoes exp.
print log([[1, 2.718281828459045, 10], [0.5, 100, 0.001]])      # log(1) = 0, log(e) = 1, log(10) = 2.30259; numbers below 1 give negative logs
print exp(log([[1, 2, 10], [0.5, 100, 0.001]]))                  # exp undoes log (to the printed digits)
print log([[0]])                                                 # log of 0 is minus infinity: no power of e is 0
print log([[-1]])                                                # log of a negative number is not a number (nan)
# log turns products into sums: log(a*b) = log(a) + log(b). Both lines print the same two numbers.
print log([[6, 0.5]] * [[7, 8]])
print log([[6, 0.5]]) + log([[7, 8]])
