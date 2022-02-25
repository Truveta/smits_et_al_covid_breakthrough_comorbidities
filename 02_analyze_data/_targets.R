here::i_am('_targets.R')

# _targets.R file
library(here)
library(targets)
library(tarchetypes)
library(future)
library(future.callr)

future::plan(callr)

# source functions from R
source(here::here('R', 'import_data.R'))
source(here::here('R', 'condition_data.R'))
source(here::here('R', 'event_rates.R'))
source(here::here('R', 'inverse_probability_weighting.R'))
source(here::here('R', 'logistic_regression.R'))
source(here::here("R", "summary_table.R"))
source(here::here('R', 'export_results.R'))
source(here::here('R', 'misc.R'))


# targets behavior
options(tidyverse.quiet = TRUE)
tar_option_set(
  tidy_eval = TRUE,
  packages = 
    c(
      'here',
      'jsonlite',
      'rlang',
      'tidyr',
      'tibble', 
      'dplyr',
      'magrittr',
      'purrr',
      'forcats',
      'broom',
      'stringr',
      'arrow', 
      'janitor',
      'questionr',
      'tableone',
      "ggplot2",
      "bibtex"
    )
)


internal_dir <- here::here("results")
if (!dir.exists(internal_dir)) {
  dir.create(internal_dir)
}


# identifies the prexisting condition we're concerned about?
treatment <- 
  c(
    'ckd_diagnosis',
    'chronic_pulmonary_disease',
    'diabetes', 
    'immunocompromised'
  )
#treatment <- sort(treatment)

max_interaction <- length(treatment)

# not used as features in PSM
misc <- 
  c(
    'ethnicity'
  )
misc <- sort(misc)

# outcome/response variables
response <- 
  c(
    'outcome_breakthrough_days'
  )
response <- sort(response)

# if no event happened, what is last time observed?
back_stop <- 'time_to_last_encounter'

# which features for propensity scores 
confounding <- 
  c(
    'age_bracket',
    'race',
    'ethnicity',
    'sex'#, 'has_fully_vaccinated_index_manufacturer"
  )
confounding <- sort(confounding)

# feature table
output_dir <- here::here("./results")
shared_dir <- here::here("../results")

setup_targets <- 
  list(
    tar_target(
      data_path, 
      '../data/clean_data.parquet', 
      format = 'file'
    ),
    tar_target(
      data_clean,
      arrow::read_parquet(data_path)
    ),
    # translate above constants into targets
    tar_target(outcome, response),
    tar_target(condition, treatment),
    tar_target(all_condition, treatment),
    #tar_target(max_time, back_stop),
    tar_target(other, misc),
    tar_target(confounding_features, confounding),
    tar_target(order, max_interaction),
    tar_target(order_seq, seq(order))
  )


analysis_targets <- 
  list(
    # data by condition
    tar_target(
      data_condition,
      get_condition_data(data_clean, condition, all_condition),
      pattern = map(condition),
      iteration = 'list'
    ),
    # unweighted event rates
    tar_target(
      raw_event_rates,
      calculate_event_rates(
        data = data_condition, 
        condition = condition, 
        response = outcome
      ),
      pattern = map(data_condition, condition),
      iteration = 'vector'
    ),
    tar_target(
      raw_event_rates_table,
      save_table(raw_event_rates, file = 'raw_event_rates', output_dir = !!output_dir),
      format = 'file'
    ),
    tar_target(
      raw_event_rates_plot,
      make_event_rate_plot(
        raw_event_rates, 
        title = 'COVID breakthrough rate associated with comorbidities'
      )
    ),
    tar_target(
      raw_event_rates_plot_file,
      save_figure(raw_event_rates_plot, file = 'raw_event', type = 'rates', output_dir = !!output_dir),
      format = 'file'
    ),
    # inverse probability weighting
    tar_target(
      weight_data,
      make_ipw_column(data_condition, condition, confounding_features),
      pattern = map(data_condition, condition),
      iteration = 'list'
    ),
    # logistic regression
    # split data by condition group
    tar_target(
      weight_data_binary,
      make_binary_response(weight_data, outcome),
      pattern = map(weight_data),
      iteration = 'list'
    ),
    tar_target(
      weight_logistic_fit,
      make_logistic_regression(
        weight_data_binary,
        response = 'breakthrough',
        condition,
        #covariates = confounding_features,
        weight_col = 'ipw'
      ),
      pattern = map(weight_data_binary, condition),
      iteration = 'list'
    ),
    tar_target(
      weight_logistic_summary,
      make_logistic_table(weight_logistic_fit, condition)
    ),
    tar_target(
      weight_logistic_summary_file,
      save_table(weight_logistic_summary, 'breakthrough_logistic_summary', output_dir = !!output_dir),
      format = 'file'
    ),
    tar_target(
      weight_odds_ratio,
      make_odds_table(weight_logistic_fit, condition),
      pattern = map(weight_logistic_fit, condition),
      iteration = 'vector'
    ),
    tar_target(
      weight_odds_ratio_file,
      save_table(weight_odds_ratio, file = 'weight_odds_ratio', output_dir = !!shared_dir),
      format = 'file'
    ),
    tar_target(
      weight_odds_plot,
      make_odds_plot(
        weight_odds_ratio, 
        title = 
          paste0(
            'Odds ratio of breakthrough COVID infection for vaccinated people with ',
            'comorbidity'
          )
      )
    ),
    tar_target(
      weight_odds_plot_file,
      save_figure(weight_odds_plot, file = 'weight', type = 'odds_ratio', output_dir = !!output_dir),
      format = 'file'
    ),
    # hospitalized with covid
    tar_target(
      data_hospital,
      get_hospital_data(data_condition),
      pattern = map(data_condition),
      iteration = 'list'
    ),
    tar_target(
      raw_hospital_rates,
      calculate_event_rates(
        data = data_hospital,
        condition = condition,
        response = 'outcome_hospitalized_has_covid'
      ),
      pattern = map(data_hospital, condition),
      iteration = 'list'
    ),
    tar_target(
      raw_hospital_rates_table,
      save_table(raw_hospital_rates, file = 'raw_hospital_rates', output_dir = !!output_dir),
      format = 'file'
    ),
    tar_target(
      raw_hospital_rates_plot,
      make_event_rate_plot(
        bind_rows(raw_hospital_rates),
        title = 
          paste0(
            'Hospitalization after COVID breakthrough ',
            'associated with comorbidities'
          )
      )
    ),
    tar_target(
      raw_hospital_rates_file,
      save_figure(raw_hospital_rates_plot, file = 'raw_hospital', type = 'rates', output_dir = !!output_dir),
      format = 'file'
    ),
    # inverse probability weighting for hospital outcome
    tar_target(
      weight_hospital_data,
      make_ipw_column(data_hospital, condition, confounding_features),
      pattern = map(data_hospital, condition),
      iteration = 'list'
    ),
    tar_target(
      weight_hospital_logistic_fit,
      make_logistic_regression(
        weight_hospital_data,
        response = 'outcome_hospitalized_has_covid',
        condition,
        #covariates = confounding_features,
        weight_col = 'ipw'
      ),
      pattern = map(weight_hospital_data, condition),
      iteration = 'list'
    ),
    tar_target(
      weight_hospital_logistic_summary,
      make_logistic_table(weight_hospital_logistic_fit, condition)
    ),
    tar_target(
      weight_hospital_logistic_summary_file,
      save_table(weight_hospital_logistic_summary, 'hospital_logistic_summary', output_dir = !!output_dir),
      format = 'file'
    ),
    tar_target(
      weight_hospital_odds_ratio,
      make_odds_table(weight_hospital_logistic_fit, condition),
      pattern = map(weight_hospital_logistic_fit, condition),
      iteration = 'vector'
    ),
    tar_target(
      weight_hospital_odds_ratio_file,
      save_table(weight_hospital_odds_ratio, file = 'weight_hospital_odds_ratio', output_dir = !!shared_dir),
      format = 'file'
    ),
    tar_target(
      weight_hospital_odds_plot,
      make_odds_plot(
        weight_hospital_odds_ratio,
        title = 
          paste0(
            'Odds ratio of hospitalization following breakthrough COVID ',
            'infection for people with comorbidity'
          )
      )
    ),
    tar_target(
      weight_hospital_odds_plot_file,
      save_figure(
        weight_hospital_odds_plot, 
        file = 'weight_hospital',
        output_dir = !!output_dir,
        type = 'odds_ratio'
      ),
      format = 'file'
    ),
    # weighted rates
    tar_target(
      weight_event_rates,
      calculate_event_rates_weighted(
        data = weight_data,
        condition = condition,
        response = outcome
      ),
      pattern = map(weight_data, condition),
      iteration = 'vector'
    ),
    tar_target(
      weight_event_rates_table,
      save_table(weight_event_rates, file = 'weight_event_rates', output_dir = !!shared_dir),
      format = 'file'
    ),
    tar_target(
      weight_event_avg_zero,
      make_avg_population(weight_event_rates)
    ),
    tar_target(
      weight_event_avg_zero_table,
      save_table(weight_event_avg_zero, file = 'weight_event_avg_zero', output_dir = !!shared_dir),
      format = 'file'
    ),
    tar_target(
      weight_event_rates_plot,
      make_event_rate_plot(
        weight_event_rates, 
        title = 
          paste0(
            'COVID breakthrough rate associated with comorbidities \n ',
            'calculated from weighted data'
          )
      )
    ),
    tar_target(
      weight_event_rates_plot_file,
      save_figure(weight_event_rates_plot, file = 'weight_event', type = 'rates', output_dir = !!output_dir),
      format = 'file'
    ),
    tar_target(
      weight_hospital_rates,
      calculate_event_rates_weighted(
        data = weight_hospital_data,
        condition = condition,
        response = 'outcome_hospitalized_has_covid'
      ),
      pattern = map(weight_hospital_data, condition),
      iteration = 'vector'
    ),
    tar_target(
      weight_hospital_rates_table,
      save_table(weight_hospital_rates, file = 'weight_hospital_rates', output_dir = !!shared_dir),
      format = 'file'
    ),
    tar_target(
      weight_hospital_avg_zero,
      make_avg_population(weight_hospital_rates)
    ),
    tar_target(
      weight_hospital_avg_zero_table,
      save_table(weight_hospital_avg_zero, file = 'weight_hospital_avg_zero', output_dir = !!shared_dir),
      format = 'file'
    ),
    tar_target(
      weight_hospital_rates_plot,
      make_event_rate_plot(
        weight_hospital_rates, 
        title = 
          paste0(
            'Hospitalization after COVID breakthrough ',
            'associated with comorbidities, \n',
            'calculated from weighted data'
          )
      )
    ),
    tar_target(
      weight_hospital_rates_plot_file,
      save_figure(
        weight_hospital_rates_plot, 
        file = 'weight_hospital',
        output_dir = !!output_dir,
        type = 'rates'
      ),
      format = 'file'
    ),
    # general summary output
    tar_target(
      raw_table_one,
      make_summary_table(data_clean, condition, confounding_features)
    ),
    tar_target(
      raw_table_one_file,
      save_summary_table(raw_table_one, "raw_table_one", output_dir = !!output_dir)
    ),
    tar_target(
      custom_table_one,
      make_precise_summary(data_clean, condition, confounding_features)
    ),
    tar_target(
      custom_table_one_file,
      save_precise_summary_table(custom_table_one, 'raw_custom_table_one', output_dir = !!output_dir),
      format = 'file'
    ),
    # summaries by "subgroups"
    tar_target(
      custom_table_one_groups,
      make_group_precise_summary(
        data_clean, 
        condition, 
        confounding_features
      )
    ),
    tar_target(
      custom_table_one_groups_file,
      save_table_list(custom_table_one_groups, 'raw_summary', output_dir = !!shared_dir),
      format = 'file'
    ),
    # save treatment list
    tar_target(
      treatment_file,
      save_table(data.frame(treatment=treatment), 'treatments', output_dir = !!shared_dir),
      format = 'file'
    ),
    # citation and meta work
    tar_target(
      package_bibtex,
      make_bibtex(
        tar_option_get('packages'),
        output_dir = here::here('results', ''),
        filename = 'package_bibtex.bib'
      ),
      format = 'file'
    )
  )


c(
  setup_targets,
  analysis_targets
)
