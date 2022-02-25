# just a few to start with
packs <-
  c(
    "tidyverse", # should cover most dependencies, but also include explicits
    "tidymodels", # broom plus other things some people like
    "here", # relative pathing
    "jsonlite",
    "rlang",
    "tidyr",
    "tibble",
    "dplyr",
    'magrittr',
    'purrr',
    'broom',
    'stringr',
    'arrow', 
    'janitor'
    "callr",  # execute R subprocesses in new sessions
    "future", # good parallel library
    "future.callr", # callr with future
    "targets", # workflow manager
    "lubridate",
    "forcats",
    "ggplot2",
    "questionr",
    "tableone",
    "vegawidget",
    "gt",
    "bibtex"
  )

install.packages(
  packs,
  repos = "https://cloud.r-project.org/"
)
