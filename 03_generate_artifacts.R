library(targets)

here::i_am("03_generate_artifacts.R")

setwd(here::here("03_generate_artifacts"))
tar_make()
