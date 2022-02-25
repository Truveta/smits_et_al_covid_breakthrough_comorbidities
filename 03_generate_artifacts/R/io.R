
write_file <- function(x, filename) {
    stopifnot(is.character(filename), length(filename) == 1)
    readr::write_csv(x, filename)
    return(filename)
}

read_file <- function(filename) {
    stopifnot(is.character(filename), length(filename) == 1)

    data <- readr::read_csv(filename, show_col_types = FALSE)
    return(data)
}

write_vega_plot <- function(spec, filename) {
    stopifnot(is.list(spec))
    stopifnot(is.character(filename), length(filename) == 1)

    vegawidget::vw_write_svg(spec, filename)
    return(filename)
}

write_gt_file <- function(x, filename) {
    stopifnot(inherits(x, "gt_tbl"))
    stopifnot(is.character(filename), length(filename) == 1)

    gt::gtsave(x, filename)
    return(filename)
}
