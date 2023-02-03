aic_c <- function(model) {
  aic <- AIC(model)
  ll <- logLik(model)
  ll_at <- attributes(ll)
  nobs <- ll_at$nobs
  k <- ll_at$df
  
  num <- (2 * k)^2 + 2 * k
  denom <- nobs - k - 1
  aicc <- aic + (num / denom)
  aicc
}