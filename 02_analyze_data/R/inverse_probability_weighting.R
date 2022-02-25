#' Calculate inverse probability (of treatment) weights 
#'
#' Calculate inverse probability weights.
#'
#' Uses logistic regression.
#'
#' @param data data frame
#' @param treatment string name of treatment column
#' @param covariates covariates used for estimating the propensity
#' @param estimand string value of interset to calculate IPW around ('att',
#' 'att', 'atc', 'atm', 'ato'). Default is `att`.
#' @param max_weight
#' @return data with one additional column called 'ipw'
#' @export
calculate_weights <- 
  function(data, treatment, covariates, estimand = 'att', max_weight = 10) {

  terms <- paste0(covariates, collapse = ' + ')
  form <- formula(paste0(treatment, ' ~ ', terms))
  fit <- glm(formula = form, family = binomial, data = data)
 
  prop_score <- predict(fit, type = 'response')

  treat <- dplyr::pull(data[, treatment])

  if(estimand == 'ate') {
    ipw <- (treat / prop_score) + ((1 - treat) / (1 - prop_score))
  } else if(estimand == 'att') {
    ipw <- 
      ((prop_score * treat) / prop_score) + 
      ((prop_score * (1 - treat)) / (1 - prop_score))
  } else if(estimand == 'atc') {
    ipw <- 
      (((1 - prop_score) * treat) / prop_score) + 
      (((1 - prop_score) * (1 - treat)) / (1 - prop_score))
  } else if(estmand == 'atm') {
    ipw <- 
      pmin(prop_score, 1 - prop_score) / 
      (treat* prop_score + (1 - treat) * (1 - prop_score))
  } else if(estimand == 'ato') {
    ipw <- (1 - prop_score) * treat + prop_score * (1 - treat)
  }


  if(!is.null(max_weight)) {
    ipw <- ifelse(ipw > max_weight, max_weight, ipw)
  }

  ipw
}


add_weights <- function(data, weights, col_name =  'ipw') {
  data[, col_name] <- weights
  data
}


make_ipw_column <- function(
                      data, 
                      treatment, 
                      covariates, 
                      estimand = 'att', 
                      max_weight = 10, 
                      col_name = 'ipw'
                    ) {

  treat_var <- paste0(treatment, '_bool')

  wts <- calculate_weights(data, treat_var, covariates, estimand, max_weight)

  data <- add_weights(data, wts)

  data
}


#weightit(formula = form, data = data_hospital[[1]], estimate = 'ate')$weight
