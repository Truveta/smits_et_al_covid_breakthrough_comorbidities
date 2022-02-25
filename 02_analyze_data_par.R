library(targets)
library(parallel)
library(future)
library(future.callr)

plan(callr)

here::i_am("02_analyze_data.R")

setwd(here::here("02_analyze_data"))
# tar_make()
tar_make_future(workers = parallel::detectCores())
