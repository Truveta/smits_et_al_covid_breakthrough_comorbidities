here::i_am('_targets.R')

library(here)
library(targets)


source(here::here('R', 'import_data.R'))
source(here::here('R', 'clean_data.R'))
source(here::here('R', 'export_data.R'))


options(tidyverse.quiet = TRUE)
tar_option_set(
  tidy_eval = TRUE,
  packages =
    c(
      'here',
      'jsonlite',
      'lubridate',
      'rlang',
      'tidyr',
      'tibble',
      'dplyr',
      'magrittr',
      'purrr',
      'broom',
      'forcats',
      'stringr',
      'arrow',
      'janitor'
    )
)


output_dir <- here::here("./results")
shared_dir <- here::here("../results")


setup_targets <-
  list(
    tar_target(data_path, '../data/feature_table.parquet', format = 'file'),
    tar_target(snapshot_json, '../results/snapshot.json', format = 'file'),
    tar_target(
      data_raw,
      read_data(data_path)
    ),
    tar_target(
      snapshot_blob,
      jsonlite::read_json(snapshot_json)
    ),
    tar_target(
      data_age,
      get_data_age(snapshot_blob)
    )
  )

clean_targets <-
  list(
    # clean data
    # breaking this into multiple steps to get sample size along the way
    # missing sex and vaccination date
    tar_target(
      data_no_missing,
      clean_missing(data_raw)
    ),
    # got covid *before* fully vax'd
    tar_target(
      data_no_prev_covid,
      clean_previous_covid(data_no_missing)
    ),
    tar_target(
      data_follow_up,
      clean_no_record(data_no_prev_covid)
    ),
    tar_target(
      data_possible,
      clean_impossible(data_follow_up, data_age)
    ),
    tar_target(
      data_types,
      clean_types(data_possible)
    ),
    tar_target(
      data_clean,
      transform_bin_ages(data_types)
    ),
    tar_target(
      sample_size,
      data.frame(
        raw_sample_size = dplyr::n_distinct(data_raw$patient_id),
        no_missing_sample_size = dplyr::n_distinct(data_no_missing$patient_id),
        no_prev_covid_sample_size =
          dplyr::n_distinct(data_no_prev_covid$patient_id),
        follow_up = dplyr::n_distinct(data_follow_up$patient_id),
        possible_sample_size = dplyr::n_distinct(data_possible$patient_id),
        good_ages_sample_size = dplyr::n_distinct(data_clean$patient_id),
        analysis_sample_size = dplyr::n_distinct(data_clean$patient_id)
      )
    ),
    tar_target(
      sample_size_file,
      save_table(sample_size, 'sample_size', output_dir = !!shared_dir),
      format = 'file'
    ),
    tar_target(
      data_clean_file,
      save_parquet(data_clean, here::here('..', 'data', 'clean_data.parquet')),
      format = 'file'
    )
  )



c(
  setup_targets,
  clean_targets
)
