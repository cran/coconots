dGP1 <- function(x, y, par) {
  if ((round(y) != y) | (y < 0)) {
    stop("y must be a non-negative integer")
  }

  if (round(x) != x) {
    stop("x must be an integer")
  }

  if (length(par) != 3) {
    stop("three parameters, lambda, alpha and eta, must be passed to the function")
  }

  lambda <- par[1]
  alpha <- par[2]
  eta <- par[3]

  if (lambda < 0) {
    stop("lambda must be greater than zero")
  }

  if ((alpha < 0) | (alpha > 1) | (eta < 0) | (eta > 1)) {
    stop("alpha and eta must be between or equal to zero and one")
  }


  if (x < 0) {
    result <- 0
  }

  if (x >= 0) {
    result <- dGP1h(x, y, lambda, alpha, eta)
  }

  return(result)
}
