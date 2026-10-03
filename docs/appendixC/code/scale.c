void scale(double *y, const double *x, long n) {
    for (long i = 0; i < n; i++)
        y[i] = x[i] * 2.0;
}
