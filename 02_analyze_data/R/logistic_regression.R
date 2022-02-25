make_binary_response <- function(data, response) {

  resp <- rlang::sym(response)

  new_data <-
    data %>%
    dplyr::mutate(
      # 0 = no brekthrough
      # 1 = breakthrough
      breakthrough = if_else(!!resp == -1, 0, 1)
    )

  new_data
}


make_logistic_regression <- 
  function(data, response, condition, covariates = NULL, weight_col = NULL) {

  if(!is.null(weight_col)) {
    weights <- dplyr::pull(data[, weight_col])
  } else {
    weights <- NULL
  }

  treat <- paste0(condition, '_bool')
  
  # doubly robust
  if(!is.null(covariates)) {
    covs <- paste0(treat, ' + ', paste0(covariates, collapse = ' + '))
  } else {
    covs <- treat
  }

  form <- formula(paste0(response, ' ~ ', covs))

  fit <- 
    glm(formula = form, data = data, family = 'binomial', weights = weights)

  fit
}


make_odds_table <- function(fit, condition) {

  condition_bool <- paste0(condition, '_bool')

  broom::tidy(fit, conf.int = TRUE, exponentiate = TRUE) %>%
    dplyr::filter(term == condition_bool)

}


make_odds_plot <- function(table, title) {
  out <- 
    ggplot2::ggplot(table, ggplot2::aes(x = term, y = estimate)) +
    ggplot2::geom_hline(yintercept = 1, linetype = 'dashed') +
    ggplot2::geom_crossbar(
      mapping = ggplot2::aes(ymin = conf.low, ymax = conf.high)
    ) +
    ggplot2::theme_bw() +
    ggplot2::labs(
      x = 'Comorbidity', 
      y = 'Odds ratio',
      title = title
    ) +
    ggplot2::coord_flip()

  out
}


# make a regression summary table
# use broom because that's super standardized
make_logistic_table <- function(fit, condition) {
  out <- 
    purrr::map(fit, ~ broom::tidy(.x, conf.int = TRUE)) %>%
    purrr::map2(., condition, 
      ~ .x %>% 
          dplyr::mutate(comorbidity = .y) %>%
          dplyr::relocate(comorbidity, .before = dplyr::everything())
    ) %>%
    dplyr::bind_rows()

  out
}

