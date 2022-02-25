get_condition_data <- function(df, condition, all_condition) {

  # people who have none of these conditions and form the baseline population
  condition_states <- purrr::map_chr(all_condition, ~ paste0(.x, '_bool'))
  clear_data <- 
    df %>%
    dplyr::filter(dplyr::across(dplyr::contains(condition_states), ~ .x == 0))

  # now with the condition data
  condition_bool <- rlang::sym(paste0(condition, '_bool'))
  condition_first_date <- rlang::sym(paste0(condition, '_first_date'))

  condition_data <-
    df %>%
    dplyr::filter(
      !!condition_bool == 1,
      !!condition_first_date < has_fully_vaccinated_index_date
    ) %>%
    dplyr::mutate(
      age_bracket = as.factor(as.character(age_bracket)),
      race = as.factor(as.character(race)),
      race = forcats::fct_infreq(race),
      ethnicity = as.factor(as.character(ethnicity)),
      ethnicity = forcats::fct_infreq(ethnicity),
      sex = as.factor(as.character(sex))
    )

  output <- bind_rows(condition_data, clear_data)
  output
}



get_hospital_data <- function(data) { 
  output <- 
    data %>%
    dplyr::filter(outcome_breakthrough_days != -1)

  output
}
  
