make_sample_size_table <- function(data, names) {

  sst <- 
    tidyr::pivot_longer(
      data, 
      dplyr::everything(), 
      values_to = 'sample_size'
    )
  
  sst$step_name <- names

  sst <- sst[, c(3, 2)]
  
  sst <- dplyr::mutate(sst, change = c(NA, abs(diff(sample_size))))
  
  
  gsst <- 
    gt::gt(sst, rowname_col = 'step_name') %>%
    gt::fmt_missing(columns = 'change') %>%
    gt::cols_label(
      sample_size = 'Sample Size', 
      change = 'Change in Sample Size'
    )
  
  gsst
}
