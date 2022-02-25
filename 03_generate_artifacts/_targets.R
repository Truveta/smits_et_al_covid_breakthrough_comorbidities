here::i_am("_targets.R")

# _targets.R file
library(here)
library(targets)

source(here::here("R", "io.R"))
source(here::here("R", "plot.R"))
source(here::here("R", "tableOne.R"))
source(here::here("R", 'sample_table.R'))

# which packages are used by functions in targets
options(tidyverse.quiet = TRUE)
tar_option_set(
  tidy_eval = TRUE,
  packages =
    c(
      "here",
      "dplyr",
      "vegawidget",
      "jsonlite",
      "gt",
      "tidyr"
    )
)

input_dir <- here::here("../results")
output_dir <- here::here("../results")
internal_dir <- here::here("results")
templates_dir <- here::here("templates")

if (!dir.exists(internal_dir)) {
  dir.create(internal_dir)
}

plot_helper <- list(
  tar_target(
    vega_template_file,
    file.path(!!templates_dir, "template.vl.json"),
    format = "file"
  ),
  tar_target(
    vega_template,
    jsonlite::read_json(vega_template_file)
  ),
  tar_target(
    vega_event_rates_spec_file,
    file.path(!!templates_dir, "event_rates.vl.json"),
    format = "file"
  ),
  tar_target(
    vega_event_rates_spec,
    integrate_template_spec(jsonlite::read_json(vega_event_rates_spec_file), vega_template)
  ),
  tar_target(
    vega_event_rates2_spec_file,
    file.path(!!templates_dir, "event_rates2.vl.json"),
    format = "file"
  ),
  tar_target(
    vega_event_rates2_spec,
    integrate_template_spec(jsonlite::read_json(vega_event_rates2_spec_file), vega_template)
  ),
  tar_target(
    vega_odds_ratio_spec_file,
    file.path(!!templates_dir, "odds_ratio.vl.json"),
    format = "file"
  ),
  tar_target(
    vega_odds_ratio_spec,
    integrate_template_spec(jsonlite::read_json(vega_odds_ratio_spec_file), vega_template)
  )
)

import_helper_data <- list(
  tar_target(
    treatment_file,
    file.path(!!input_dir, "treatments.csv"),
    format = "file"
  ),
  tar_target(
    treatment,
    read_file(treatment_file)$treatment
  ),
  tar_target(
    treatment_labels_file,
    file.path(!!templates_dir, "comorbidity_labels.csv"),
    format = "file"
  ),
  tar_target(
    treatment_labels,
    read_file(treatment_labels_file)
  )
)

import_summary_data <- list(
  tar_target(
    summary_no_condition_file,
    file.path(!!input_dir, "raw_summary_no_condition.csv"),
    format = "file"
  ),
  tar_target(
    summary_no_condition,
    read_file(summary_no_condition_file)
  ),
  tar_target(
    summary_treatment_file,
    file.path(!!input_dir, paste0("raw_summary_", treatment, ".csv")),
    format = "file",
    pattern = map(treatment)
  ),
  tar_target(
    summary_treatment,
    read_file(summary_treatment_file),
    pattern = map(summary_treatment_file),
    iteration = 'list'
  )
)

import_breakthrough_data <- list(
  tar_target(
    breakthrough_rates_file,
    file.path(!!input_dir, "weight_event_rates.csv"),
    format = "file"
  ),
  tar_target(
    breakthrough_rates,
    read_file(breakthrough_rates_file)
  ),
  tar_target(
    breakthrough_avg_zero_file,
    file.path(!!input_dir, "weight_event_avg_zero.csv"),
    format = "file"
  ),
  tar_target(
    breakthrough_avg_zero,
    read_file(breakthrough_avg_zero_file)
  ),
  tar_target(
    breakthrough_odds_ratio_file,
    file.path(!!input_dir, "weight_odds_ratio.csv"),
    format = "file"
  ),
  tar_target(
    breakthrough_odds_ratio,
    read_file(breakthrough_odds_ratio_file)
  )
)

import_hospitalization_data <- list(
  tar_target(
    hospitalization_rates_file,
    file.path(!!input_dir, "weight_hospital_rates.csv"),
    format = "file"
  ),
  tar_target(
    hospitalization_rates,
    read_file(hospitalization_rates_file)
  ),
  tar_target(
    hospitalization_avg_zero_file,
    file.path(!!input_dir, "weight_hospital_avg_zero.csv"),
    format = "file"
  ),
  tar_target(
    hospitalization_avg_zero,
    read_file(hospitalization_avg_zero_file)
  ),
  tar_target(
    hospitalization_odds_ratio_file,
    file.path(!!input_dir, "weight_hospital_odds_ratio.csv"),
    format = "file"
  ),
  tar_target(
    hospitalization_odds_ratio,
    read_file(hospitalization_odds_ratio_file)
  )
)

make_breakthrough_artifacts <- list(
  tar_target(
    breakthrough_event_rates_plot_data,
    {
      tibble::as_tibble(rbind(
        breakthrough_rates[c("condition", "condition_state", "event_percentage", "event_low", "event_high")],
        breakthrough_avg_zero[c("condition", "condition_state", "event_percentage", "event_low", "event_high")]
      )) %>%
        join_labels(treatment_labels, by = "condition")
    }
  ),
  tar_target(
    breakthrough_event_rates_plot,
    {
      generate_event_rates_plot(
        breakthrough_event_rates_plot_data,
        vega_event_rates_spec,
        c("Percent breakthrough infection among", "vaccinated by comorbidity"),
        "% of vaccinated with breakthrough case"
      )
    }
  ),
  tar_target(
    breakthrough_event_rates_plot_file,
    {
      write_vega_plot(breakthrough_event_rates_plot, file.path(!!output_dir, "breakthrough_event_rates.svg"))
    },
    format = "file"
  ),
  tar_target(
    breakthrough_odds_ratio_plot_data,
    {
      breakthrough_odds_ratio %>% join_labels(treatment_labels, by = "term")
    }
  ),
  tar_target(
    breakthrough_odds_ratio_plot,
    {
      generate_odds_ratio_plot(
        breakthrough_odds_ratio_plot_data,
        vega_odds_ratio_spec,
        c("Odds ratio of breakthrough infection among vaccinated", "by comorbidity")
      )
    }
  ),
  tar_target(
    breakthrough_odds_ratio_plot_file,
    {
      write_vega_plot(breakthrough_odds_ratio_plot, file.path(!!output_dir, "breakthrough_odds_ratio.svg"))
    },
    format = "file"
  ),
  tar_target(
    breakthrough_table,
    {
      create_chart_table(breakthrough_event_rates_plot_data, breakthrough_odds_ratio_plot_data, 'Percentage of vaccinated with breakthrough case (95% CI)')
    }
  ),
  tar_target(
    breakthrough_table_rtf_file,
    {
      write_gt_file(breakthrough_table, file.path(!!output_dir, "breakthrough_table.rtf"))
    },
    format = "file"
  ),
  tar_target(
    breakthrough_table_html_file,
    {
      write_gt_file(breakthrough_table, file.path(!!output_dir, "breakthrough_table.html"))
    },
    format = "file"
  )
)

make_hospitalization_artifacts <- list(
  tar_target(
    hospitalization_event_rates_plot_data,
    {
      tibble::as_tibble(rbind(
        hospitalization_rates[c("condition", "condition_state", "event_percentage", "event_low", "event_high")],
        hospitalization_avg_zero[c("condition", "condition_state", "event_percentage", "event_low", "event_high")]
      )) %>%
        join_labels(treatment_labels, by = "condition")
    }
  ),
  tar_target(
    hospitalization_event_rates_plot,
    {
      generate_event_rates_plot(
        hospitalization_event_rates_plot_data,
        vega_event_rates2_spec,
        list(text = c("Percent hospitalization following breakthrough", "infection among vaccinated by comorbidity"), dx = 13),
        "% of breakthrough cases who are hospitalized"
      )
    }
  ),
  tar_target(
    hospitalization_event_rates_plot_file,
    {
      write_vega_plot(hospitalization_event_rates_plot, file.path(!!output_dir, "hospitalization_event_rates.svg"))
    },
    format = "file"
  ),
  tar_target(
    hospitalization_odds_ratio_plot_data,
    {
      hospitalization_odds_ratio %>% join_labels(treatment_labels, by = "term")
    }
  ),
  tar_target(
    hospitalization_odds_ratio_plot,
    {
      generate_odds_ratio_plot(
        hospitalization_odds_ratio_plot_data,
        vega_odds_ratio_spec,
        c("Odds ratio of hospitalization following breakthrough infection", "among vaccinated by comorbidity")
      )
    }
  ),
  tar_target(
    hospitalization_odds_ratio_plot_file,
    {
      write_vega_plot(hospitalization_odds_ratio_plot, file.path(!!output_dir, "hospitalization_odds_ratio.svg"))
    },
    format = "file"
  ),
  tar_target(
    hospitalization_table,
    {
      create_chart_table(hospitalization_event_rates_plot_data, hospitalization_odds_ratio_plot_data, 'Percentage of breakthrough cases who are hospitalized (95% CI)')
    }
  ),
  tar_target(
    hospitalization_table_rtf_file,
    {
      write_gt_file(hospitalization_table, file.path(!!output_dir, "hospitalization_table.rtf"))
    },
    format = "file"
  ),
  tar_target(
    hospitalization_table_html_file,
    {
      write_gt_file(hospitalization_table, file.path(!!output_dir, "hospitalization_table.html"))
    },
    format = "file"
  )
)

make_table_one <- list(
  tar_target(
    table_one,
    {
      create_table_one(summary_no_condition, summary_treatment, treatment, treatment_labels)
    }
  ),
  tar_target(
    table_one_html_file,
    write_gt_file(table_one, file.path(!!output_dir, "table1.html"))
  ),
  tar_target(
    table_one_rtf_file,
    write_gt_file(table_one, file.path(!!output_dir, "table1.rtf"))
  )
)

make_report <- list(
  tar_target(
    summary_report,
    {
      sprintf(
        "<html><head><style>
          img {
            display: block;
            margin: 2em auto;
          }
          body {
            max-width: 1280px;
            margin: 0 auto;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Helvetica Neue', 'Fira Sans', 'Droid Sans', Arial, sans-serif;
          }</style><body>
          <h1>Summary Report</h1>

          <h2>Table 1</h2>
          %s
          <h2>Breakthrough Infections</h2>
          <img src='./%s'>
          <img src='./%s'>
          %s
          <h2>Hospitalization after Breakthrough</h2>
          <img src='./%s'>
          <img src='./%s'>
          %s
        </body></html>",
        gt::as_raw_html(table_one),
        basename(breakthrough_event_rates_plot_file),
        basename(breakthrough_odds_ratio_plot_file),
        gt::as_raw_html(breakthrough_table),
        basename(hospitalization_event_rates_plot_file),
        basename(hospitalization_odds_ratio_plot_file),
        gt::as_raw_html(hospitalization_table)
      )
    }
  ),
  tar_target(
    summary_report_file,
    write(summary_report, file.path(!!output_dir, "summary_report.html"))
  )
)


make_sample_size <- 
  list(
    tar_target(
      sample_size_path,
      paste0(!!input_dir, '/sample_size.csv')
    ),
    tar_target(
      sample_size,
      read.csv(sample_size_path)
    ),
    tar_target(
      sample_size_table,
      make_sample_size_table(
        sample_size,
        names = 
          c(
            'Raw Sample Size', 
            'No Missing Sex and Vaccination Date',
            'No Previous COVID-19 Infection',
            'No Encounters After Vaccination',
            'No Impossible Times',
            'No Missing Ages or Ages <= 12 years',
            'Final Sample Size'
          )
      )
    ),
    tar_target(
      sample_size_table_html_file,
      write_gt_file(
        sample_size_table, 
        file.path(!!output_dir, 'sample_size.html')
      ),
      format = 'file'
    ),
    tar_target(
      sample_size_table_rtf_file,
      write_gt_file(
        sample_size_table, 
        file.path(!!output_dir, 'sample_size.rtf')
      ),
      format = 'file'
    )
  )


# define target list
c(
  plot_helper,
  import_helper_data,
  import_summary_data,
  import_breakthrough_data,
  import_hospitalization_data,
  make_breakthrough_artifacts,
  make_hospitalization_artifacts,
  make_table_one,
  make_report,
  make_sample_size
)
