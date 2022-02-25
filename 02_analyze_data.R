library(targets)

here::i_am("02_analyze_data.R")

setwd(here::here("02_analyze_data"))
tar_make()
