#' Read in list of parquet files as one table
#'
#' @param file_names list of file locations
#' @return a data frame/tibble
#' @export
read_data <- function(file_names) {
  df_parquet <- purrr::map_dfr(file_names, ~ arrow::read_parquet(.x))

  df_parquet 
}


get_data_age <- function(snapshot_json) {
  data_age <- as.Date(snapshot_json$createdDateTime)
  data_age
}
