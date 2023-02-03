write_table_1 <- function(table1, filepath, type = 'latex', ...) {
  tt <- as.data.frame(table1)

  rownames(tt) <- NULL

  xtable::xtable(tt, ...) |>
    xtable::print.xtable(
      type = type, 
      file = filepath,
      include.rownames = FALSE,
      comment = FALSE,
      table.placement = '!htbp',
      format.args = list(big.mark = ',')
    )

  return(filepath)
}