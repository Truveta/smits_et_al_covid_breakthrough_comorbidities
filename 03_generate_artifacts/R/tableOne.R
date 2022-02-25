
create_table_one <- function(no_conditions, conditions, treatments, treatment_labels) {
    stopifnot(tibble::is_tibble(no_conditions))
    stopifnot(is.list(conditions))
    stopifnot(is.character(treatments))

    treatments = tibble::tibble(treatment=treatments) %>% dplyr::left_join(treatment_labels, by=c(treatment='term'))

    prepare_data = function(df) {
        df %>%
            dplyr::mutate(
                rowid = 1:nrow(df),
                label = dplyr::case_when(
                    feature == 'sample_size' & population == 'total' ~ 'N (fully vaccinated patients)',
                    population == 'COVID breakthrough' ~ 'Breakthrough Case',
                    population == 'Hospitalized' ~ 'Hospitalized for Breakthrough Case',
                    TRUE ~ level,
                ),
                row_group = dplyr::case_when(
                    feature == 'sample_size' ~ 'Overall',
                    feature == 'age_bracket' ~ 'Age Group',
                    TRUE ~ tools::toTitleCase(feature)
                ),
                sort_order = dplyr::case_when(
                    row_group == 'Race' & label == 'Other' ~ 171,
                    row_group == 'Ethnicity' & label == 'Hispanic or Latino' ~ 180,
                    row_group == 'Ethnicity' & label == 'Not Hispanic or Latino' ~ 190,
                    TRUE ~ rowid * 10
                )
            ) %>%
            dplyr::arrange(sort_order) %>%
            dplyr::select(row_group, label, count, percentage)
    }

    df = no_conditions %>% prepare_data()

    for(treatment in 1:length(treatments)) {
        treatment_name = treatments$treatment[treatment]
        treatment_table = conditions[[names(conditions)[treatment]]]
        treatment_table = treatment_table %>% 
            prepare_data()
        df = df %>% dplyr::left_join(treatment_table, by=c('row_group', 'label'), suffix = c('', paste0('_', treatment_name)))
    }

    gt_x <- df %>% gt::gt(
        rowname_col = "label",
        groupname_col = "row_group"
    )

    column_labels <- list(label = "", count = "General Population (Comorbidity-free)")
    gt_x <- gt_x %>% 
        gt::fmt_number(columns = tidyselect::starts_with("count"), decimals = 0) %>%
        gt::fmt_number(columns = tidyselect::starts_with("percentage"), decimals = 2, pattern = "({x}%)") %>%
        gt::cols_merge(columns = c("count", "percentage"))

    #
    for (treatment in 1:length(treatments)) {
        treatment_name <- treatments$treatment[treatment]
        treatment_label <- treatments$name[treatment]
        column_labels[[paste0("count_", treatment_name)]] <- treatment_label

        gt_x <- gt_x %>% gt::cols_merge(columns = c(paste0("count_", treatment_name), paste0("percentage_", treatment_name)))
    }
    gt_x <- gt_x %>% gt::cols_label(.list = column_labels)

    return(gt_x)
}

create_chart_table <- function(rates, odds_ratio, title = "") {
    stopifnot(tibble::is_tibble(rates))
    stopifnot(tibble::is_tibble(odds_ratio))
    stopifnot(is.character(title), length(title) == 1)

    rates_comborbidity <- rates %>%
        dplyr::filter(condition_state == 1) %>%
        dplyr::select(name, c_percent = event_percentage, c_low = event_low, c_high = event_high)

    rates_general <- rates %>%
        dplyr::filter(condition_state == 0) %>%
        dplyr::select(name, g_percent = event_percentage, g_low = event_low, g_high = event_high)

    odds <- odds_ratio %>%
        dplyr::select(name, o_value = estimate, o_low = conf.low, o_high = conf.high)

    x <- rates_comborbidity %>%
        dplyr::right_join(rates_general, by = "name") %>%
        dplyr::left_join(odds, by = "name")

    gt_x <- gt::gt(x)

    # weird formatting and merging since I couldn't find a way to hide a missing merged cell (it would look like:` ( - )`)
    gt_x <- gt_x %>%
        gt::fmt_number(columns = c(c_percent, g_percent), scale_by = 100, pattern = "{x}%") %>%
        gt::fmt_number(columns = c(c_low, g_low), scale_by = 100, pattern = " ({x}% &mdash; ") %>%
        gt::fmt_number(columns = c(c_high, g_high), scale_by = 100, pattern = "{x}%)") %>%
        gt::fmt_number(columns = c(o_value)) %>%
        gt::fmt_number(columns = c(o_low), pattern = " ({x} &mdash; ") %>%
        gt::fmt_number(columns = c(o_high), pattern = " {x})")

    gt_x <- gt_x %>%
        gt::fmt_missing(
            columns = c(c_percent, c_low, c_high, g_percent, g_low, g_high, o_value, o_low, o_high),
            rows = name == "General Population",
            missing_text = ""
        ) %>%
        gt::cols_merge(
            columns = c(c_percent, c_low, c_high),
            hide_columns = c(c_low, c_high),
            pattern = "{1}{2}{3}"
        ) %>%
        gt::cols_merge(
            columns = c(g_percent, g_low, g_high),
            hide_columns = c(g_low, g_high),
            pattern = "{1}{2}{3}"
        ) %>%
        gt::cols_merge(
            columns = c(o_value, o_low, o_high),
            hide_columns = c(o_low, o_high),
            pattern = "{1}{2}{3}"
        )

    gt_x <- gt_x %>%
        gt::tab_header(
            title = title
        ) %>%
        gt::opt_row_striping() %>%
        gt::cols_label(
            c_percent = "Comorbidity Population",
            g_percent = "General Population",
            o_value = "Odds Ratio",
            name = ""
        )

    return(gt_x)
}
