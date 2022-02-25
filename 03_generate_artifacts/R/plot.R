
integrate_template_spec <- function(spec, template) {
    stopifnot(is.list(spec))
    stopifnot(is.list(template))

    # merge list
    out <- c(template[setdiff(names(template), names(spec))], spec)
    # but concat layers
    out$layer <- c(template$layer, spec$layer)
    return(out)
}

join_labels <- function(data, data_labels, by = "term") {
  if (by == "term") {
    data <- dplyr::mutate(data, term=stringr::str_replace(term, '_bool', ''))
  }
  by_d = c()
  by_d[by] = 'term'
  return(dplyr::left_join(data, data_labels, by=by_d))
}

generate_odds_ratio_plot <- function(data, spec, title) {
    stopifnot(tibble::is_tibble(data))
    stopifnot(is.list(spec))
    stopifnot(is.character(title) || is.list(title))

    spec$title <- title
    spec$data <- list(values = data)

    return(spec)
}

generate_event_rates_plot <- function(data, spec, title, axis_title) {
    stopifnot(tibble::is_tibble(data))
    stopifnot(is.list(spec))
    stopifnot(is.character(title) || is.list(title))
    stopifnot(is.character(axis_title))

    spec$layer[[2]]$encoding$x$axis$title <- axis_title
    spec$title <- title
    spec$data <- list(values = data)

    return(spec)
}