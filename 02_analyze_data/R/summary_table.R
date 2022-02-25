#' Make a table 1 like summary table
#'
#' Uses the `tableone::CreateTableOne` function, applying some useful defaults.
#'
#' I generally dislike the formating of the output, but it is so convenient.
#'
#' Uses subgroups to identify which variables to "summarize".
#'
#' Implicitly ignores the patient_id, prop.score, and weights columns.
#'
#' @param data data frame of (matched) data
#' @param condition vector of strings identifying which columns to summarize
#' @param confounding_features
#' @return object of class `TableOne`
#' @export
make_summary_table <- function(data, condition, confounding_features) {

  condition_bool <- purrr::map_chr(condition, ~ paste0(.x, '_bool'))

  temp <- 
    data %>%
    dplyr::mutate(
      breakthrough = if_else(outcome_breakthrough_days != -1, 1, 0),
      hospitalized = 
        if_else(
          outcome_breakthrough_days != -1 & 
            outcome_hospitalized_has_covid == 1, 
          true = 1, 
          false = 0
        )
    ) %>%
    dplyr::select(
      breakthrough, 
      hospitalized, 
      dplyr::any_of(condition_bool), 
      dplyr::any_of(confounding_features)
    ) %>%
    dplyr::mutate(dplyr::across(dplyr::everything(), ~ as.factor(.x))) %>%
    dplyr::rename_with(
      ~ stringr::str_replace(.x, pattern = '_bool', replacement = ''),
      .cols = dplyr::any_of(condition_bool)
    )


  tab <- 
    tableone::CreateTableOne(
      vars = colnames(temp), 
      data = temp, 
      test = FALSE
    )

  tab
}




summarize_factor <- function(data, feat) {
  feat_feat <- rlang::sym(feat)

  data %>%
    dplyr::count(!!feat_feat, name = 'count', .drop = FALSE) %>%
    dplyr::mutate(feature = feat) %>%
    dplyr::rename(level = !!feat_feat) %>%
    dplyr::relocate(feature, .before = everything()) %>%
    dplyr::ungroup()
}

summary_routine <- function(temp, condition_bool, confounding_features) {
  # summarize conditions
  base_cond_summary <- 
    temp %>%
    dplyr::summarize(
      sample_size = n(),
      dplyr::across(dplyr::any_of(condition_bool), ~ sum(as.numeric(.x)))
    ) %>%
    tidyr::pivot_longer(
      dplyr::everything(), 
      names_to = 'feature', 
      values_to = 'count'
    )

  base_fact_summary <- 
    purrr::map_dfr(confounding_features, ~ summarize_factor(temp, .x))
  
  base_summary <- 
    dplyr::bind_rows(base_cond_summary, base_fact_summary) %>%
    dplyr::relocate(count, .after = dplyr::everything())

  base_summary
}


make_precise_summary <- function(data, condition, confounding_features) {

  condition_bool <- purrr::map_chr(condition, ~ paste0(.x, '_bool'))
  #confounding_features
  #other
  
  # to summarize 
  temp <- 
    data %>%
    dplyr::mutate(
      breakthrough = if_else(outcome_breakthrough_days != -1, 1, 0),
      hospitalized = 
        if_else(
          outcome_breakthrough_days != -1 & 
            outcome_hospitalized_has_covid == 1, 
          true = 1, 
          false = 0
        )
    ) %>%
    dplyr::select(
      breakthrough, 
      hospitalized,
      dplyr::any_of(condition_bool), 
      dplyr::any_of(confounding_features)
    ) %>%
    dplyr::mutate(across(any_of(confounding_features), ~ as.factor(.x)))

  general_summary <- 
    summary_routine(temp, condition_bool, confounding_features) %>%
    dplyr::mutate(population = 'total') %>%
    dplyr::relocate(population, .before = dplyr::everything())

  breakthrough_summary <- 
    temp %>%
    dplyr::filter(breakthrough == 1) %>%
    summary_routine(., condition_bool, confounding_features) %>%
    dplyr::mutate(population = 'COVID breakthrough') %>%
    dplyr::relocate(population, .before = dplyr::everything())
    
  hospital_summary <- 
    temp %>%
    dplyr::filter(hospitalized == 1) %>%
    summary_routine(., condition_bool, confounding_features) %>%
    dplyr::mutate(population = 'Hospitalized') %>%
    dplyr::relocate(population, .before = dplyr::everything())

  out <- 
    dplyr::bind_rows(
      general_summary, 
      breakthrough_summary, 
      hospital_summary
    )

  out
}

# duplicated code because working with a specific transform of the data
make_precise_summary_special <- 
  function(data, confounding_features) {

  # to summarize 
  temp <- 
    data %>%
    dplyr::mutate(
      breakthrough = if_else(outcome_breakthrough_days != -1, 1, 0),
      hospitalized = 
        if_else(
          outcome_breakthrough_days != -1 & 
            outcome_hospitalized_has_covid == 1, 
          true = 1, 
          false = 0
        )
    ) %>%
    dplyr::select(
      breakthrough, 
      hospitalized,
      comorbidity,
      #dplyr::any_of(condition_bool), 
      dplyr::any_of(confounding_features)
    ) %>%
    dplyr::mutate(across(any_of(confounding_features), ~ as.factor(.x)))

  general_summary <- 
    summary_routine(temp, 'bool', confounding_features) %>%
    dplyr::mutate(population = 'total') %>%
    dplyr::relocate(population, .before = dplyr::everything())

  breakthrough_summary <- 
    temp %>%
    dplyr::filter(breakthrough == 1) %>%
    summary_routine(., 'bool', confounding_features) %>%
    dplyr::mutate(population = 'COVID breakthrough') %>%
    dplyr::relocate(population, .before = dplyr::everything())
    
  hospital_summary <- 
    temp %>%
    dplyr::filter(hospitalized == 1) %>%
    summary_routine(., 'bool', confounding_features) %>%
    dplyr::mutate(population = 'Hospitalized') %>%
    dplyr::relocate(population, .before = dplyr::everything())

  out <- 
    dplyr::bind_rows(
      general_summary, 
      breakthrough_summary, 
      hospital_summary
    )

  out
}



# summaries of each of the "groups"
make_group_precise_summary <- 
  function(data, condition, confounding_features) {
  condition_states <- purrr::map_chr(condition, ~ paste0(.x, '_bool'))

  clear_data <- 
    data %>%
    dplyr::filter(dplyr::across(dplyr::contains(condition_states), ~ .x == 0))
  
  comorbid_data <- 
    data %>%
    tidyr::pivot_longer(
      cols = dplyr::contains(condition_states),
      names_to = 'comorbidity',
      values_to = 'bool'
    ) %>%
    dplyr::filter(bool != 0) %>%
    dplyr::group_split(comorbidity)
  

  clear_summary <- 
    make_precise_summary(
      clear_data, 
      condition, 
      confounding_features
    ) %>%
    dplyr::filter(!(feature %in% condition_states))

  comorbid_summary <- 
    purrr::map(
      comorbid_data, 
      ~ make_precise_summary_special(
          .x, 
          confounding_features
        )
    ) %>%
    purrr::set_names(sort(condition))

  summary_list <- comorbid_summary
  summary_list$no_condition <- clear_summary
  

  ideal_levels <- c('sample_size', 'age_bracket', 'sex', 'race', 'ethnicity')
  summary_out <- 
    map(summary_list, 
      ~ .x %>%
        dplyr::filter(
          population == 'total' | feature == 'sample_size'
        ) %>%
        dplyr::mutate(feature = factor(feature, levels = ideal_levels)) %>%
        dplyr::arrange(feature) %>%
        dplyr::mutate(percentage = count / max(count) * 100)
    )
  
  summary_out
}
