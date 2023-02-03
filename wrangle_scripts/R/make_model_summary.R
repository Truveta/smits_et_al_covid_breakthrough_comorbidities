make_model_summary <- function(model_list) {
  summary_table <- 
    parallel::mcMap(
      \(x) broom::tidy(x, exponentiate = TRUE, conf.int = TRUE), 
      model_list,
      mc.cores = 4
    ) |>
    bind_rows(.id = 'model') |>
    dplyr::select(-c(statistic, std.error, statistic, p.value)) |>
    janitor::clean_names()

  summary_table
}