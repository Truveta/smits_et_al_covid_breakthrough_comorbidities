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


save_match_table <- function(match_tables, output_dir) {
  out <- purrr::imap_chr(match_tables, ~ save_table(df = .x, file = .y, output_dir = output_dir))
  out
}


save_table_list <- function(table_list, prefix, output_dir, type = 'csv') {
  out <- 
    purrr::imap_chr(
      table_list, 
      ~ save_table(df = .x, file = paste0(prefix, "_", .y), type = type, output_dir = output_dir)
    )

  out
}


save_summary_table <- function(tableone, file, output_dir, type = 'csv') {
  out_percentage <- 
    print(
      tableone, 
      format = 'p',
      #quote = FALSE, 
      #noSpace = TRUE, 
      printToggle = FALSE,
      showAllLevels = TRUE
    )
  out_count <- 
    print(
      tableone,
      format = 'f',
      #quote = FALSE,
      #noSpace = TRUE,
      printToggle = FALSE,
      showAllLevels = TRUE
    )

  pp <- rownames_to_column(as.data.frame(out_percentage))
  cc <- rownames_to_column(as.data.frame(out_count))

  out <- cbind(pp, subset(cc, select = -c(level, rowname)))
  out <- 
    as_tibble(out, .name_repair = 'universal') %>%
    dplyr::rename(
      feature = rowname,
      overall_percentage = Overall...3,
      overall_count = Overall...4
    )


  save_table(out, file, output_dir, type)
}

save_precise_summary_table <- function(df, file, output_dir, type = 'csv') {
  out <- 
    df %>% 
    tidyr::pivot_wider(
      names_from = population, 
      values_from = count
    )
  
  save_table(out, file, output_dir, type)
}




#' Save a plot to disk and return path
#'
#' Saves file to `results` directory with file as name.
#' 
#' @param plot object of type `ggplot2`
#' @param file string file name
#' @param type string file format
#' @return path of saved file
#' @export
save_figure <- function(plot, file, output_dir, type = 'survival', format = 'png') {
  fn <- file.path(output_dir, paste0(type, '_', file, '.', format))

  ggplot2::ggsave(filename = fn, plot = plot)

  return(fn)
}
