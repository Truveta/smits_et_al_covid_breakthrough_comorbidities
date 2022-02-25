# also removes ages that don't compute to a bracket
transform_bin_ages <- function(df) {
  df %>%
    dplyr::mutate(
      age_period = lubridate::seconds_to_period(age)$day,
      age_numeric = age_period / 365.25,
      age_bracket = dplyr::case_when(
        age_numeric < 18 ~ '<18',
        age_numeric >= 18 & age_numeric < 50 ~ '18-49',
        age_numeric >= 50 & age_numeric < 65 ~ '50-64',
        age_numeric >= 65 & age_numeric < 75 ~ '65-74',
        age_numeric >= 75 ~ '75+',
        TRUE ~ 'other'
      )
    ) %>%
    dplyr::filter(
      age_bracket != 'other',
      age_numeric >= 12
    )
}

clean_missing <- function(data) {
  new_df <-
    data %>%
    dplyr::filter(
      #race != 'Unknown',
      #ethnicity != 'Unknown',
      sex != 'Unknown',
      !is.na(has_fully_vaccinated_index_date)
    )

  new_df
}

clean_previous_covid <- function(data) {

  new_df <-
    data %>%
    dplyr::mutate(
      dplyr::across(dplyr::ends_with('_date'), ~ as.numeric(.x))
    ) %>%
    dplyr::filter(
      is.na(has_covid_index_date) |
      has_covid_index_date > has_fully_vaccinated_index_date
    )

  new_df
}

clean_no_record <- function(data) {
  new_df <-
    data %>%
    dplyr::mutate(
      time_to_last_encounter =
        encounter_last_date - has_fully_vaccinated_index_date,
      time_to_last_encounter =
        lubridate::seconds_to_period(time_to_last_encounter)$day
    ) %>%
    dplyr::filter(time_to_last_encounter > 0)

  new_df
}

clean_impossible <- function(data, data_age) {
  new_df <-
    data %>%
    dplyr::filter(
      time_to_last_encounter < (as.Date(data_age) - as.Date('2020-12-01')),
      outcome_breakthrough_days < (as.Date(data_age) - as.Date('2020-12-01'))
    )

  new_df
}

clean_types <- function(data) {
  new_df <-
    data %>%
    dplyr::mutate(
      race = as.factor(as.character(race)),
      race = forcats::fct_infreq(race),
      ethnicity = as.factor(as.character(ethnicity)),
      ethnicity = forcats::fct_infreq(ethnicity),
      sex = as.factor(as.character(sex))
    )

  new_df
}
