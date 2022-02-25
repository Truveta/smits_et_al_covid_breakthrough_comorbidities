#' Save a table to disk and return path
#'
#' Saves file to `results` directory with file as name.
#'
#' @param df data frame or tibbe
#' @param file string file name
#' @param type string file format
#' @param output_dir optional output directory
#' @return path of saved file
#' @export
save_table <- function(df, file, output_dir, type = 'csv') {
  fn <- file.path(output_dir, paste0(file, '.', type))

  if (is.data.frame(df)) {
    readr::write_csv(df, file = fn)
  } else {
    write.csv(df, file = fn, row.names = FALSE)
  }

  return(fn)
}


save_parquet <- function(df, filepath) {
  arrow::write_parquet(x = df, sink = filepath)

  return(filepath)
}
