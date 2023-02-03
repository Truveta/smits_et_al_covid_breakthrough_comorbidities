make_aic_table <- function(model_list, aic = AIC, name = 'AIC') {
  name_sym <- ensym(name)
  delta_col <- paste0('delta_', name)

  out <-
    Map(\(x) aic(x), model_list) |>
    tibble::as_tibble() |>
    tidyr::pivot_longer(everything(), names_to = 'model', values_to = name) |>
    dplyr::mutate({{ delta_col }} := {{ name_sym }} - min({{ name_sym }}))
    
  out
}