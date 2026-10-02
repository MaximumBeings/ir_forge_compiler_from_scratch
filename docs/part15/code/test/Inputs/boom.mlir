func.func @boom() {
  %f = arith.constant false
  cf.assert %f, "bad \"quote\" 100% done, naïve café"
  return
}
