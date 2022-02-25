prop_ci <- function(count, pop) {
  prop.test(count, pop, conf.level = 0.95)$conf.int
}

split_event_count <- function(x, state) {
  tab <- rev(questionr::wtd.table(x = x$breakthrough, weights = x$ipw))
  prop <- prop.test(tab)

  out <- 
    data.frame(
      condition_state = state,
      population_count = sum(tab),
      event_count = as.numeric(tab[1]),
      event_percentage = as.numeric(prop$estimate),
      event_low = prop$conf.int[1],
      event_high = prop$conf.int[2]
    ) %>%
    dplyr::mutate(
      rate_100k = event_percentage * 100000,
      rate_100k_low = event_low * 100000,
      rate_100k_high = event_high * 100000
    )

  out
}


calculate_event_rates <- function(data, condition, response) {
  
  condition_name <- paste0(condition, '_bool')
  condition_bool <- rlang::sym(condition_name)

  data$breakthrough <- dplyr::if_else(data[, response] > 0, 1, 0)

  event_summary <- 
    data %>%
    dplyr::group_by(!!condition_bool) %>%
    dplyr::summarize(
      population_count = n(),
      event_count = sum(breakthrough),
      event_percentage = event_count / population_count,
      event_low= prop_ci(event_count, population_count)[1],
      event_high= prop_ci(event_count, population_count)[2],
      rate_100k = event_percentage * 100000,
      rate_100k_low = event_low * 100000,
      rate_100k_high = event_high * 100000
    ) %>%
    dplyr::mutate(condition = condition) %>%
    dplyr::relocate(condition, .before = dplyr::everything()) %>%
    dplyr::rename(condition_state = !!condition_bool)

  event_summary
}


make_event_rate_plot <- function(event_rates, title) {

  event_rates$condition_state <- as.factor(event_rates$condition_state)

  event_rates$condition_state <- 
    ifelse(event_rates$condition_state == 0, 'absent', 'present')

  rate_plot <- 
    event_rates %>%
    ggplot2::ggplot(
      ggplot2::aes(x = condition_state, y = rate_100k)
    ) +
    ggplot2::geom_bar(
      stat = 'identity', 
      fill = 'lightgrey', 
      alpha = 0.5
    ) +
    ggplot2::geom_crossbar(
      ggplot2::aes(
        ymin = rate_100k_low, 
        ymax = rate_100k_high, 
        colour = condition_state
      )
    ) +
    ggplot2::facet_wrap(~ condition) +
    ggplot2::theme_bw() +
    ggplot2::theme(legend.position = 'bottom') +
    ggplot2::labs(
      x = 'Comorbidity present or absent',
      y = 'Rate per 100k',
      title = title,
      colour = 'Comorbidity'
    )

  rate_plot
}



calculate_event_rates_weighted <- function(data, condition, response) {

  condition_name <- paste0(condition, '_bool')
  condition_bool <- rlang::sym(condition_name)

  data$breakthrough <- dplyr::if_else(data[, response] > 0, 1, 0)

  data_split <- 
    data %>%
    dplyr::group_split(!!condition_bool) 
  
  states <-
    purrr::map(data_split, ~ .x %>% dplyr::pull(!!condition_bool) %>% unique())

  out <- 
    purrr::map2_dfr(data_split, states, ~ split_event_count(.x, .y)) %>%
    dplyr::mutate(condition = condition) %>%
    dplyr::relocate(condition, .before = dplyr::everything())

  out
}


make_avg_population <- function(data) {
  ttemp <- 
    data %>%
    dplyr::filter(condition_state == 0)
  
  mod1 <- 
    glm(
      cbind(event_count, population_count) ~ 1, 
      data = ttemp, 
      family = 'binomial'
    )
  tid <- broom::tidy(mod1, conf.int = TRUE)
  
  out <- 
    data.frame(
      condition = 'average',
      condition_state = 0,
      event_percentage = plogis(tid$estimate),
      event_low = plogis(tid$conf.low),
      event_high = plogis(tid$conf.high)
    ) %>%
    dplyr::mutate(
      rate_100k = event_percentage * 100000,
      rate_100k_low = event_low * 100000,
      rate_100k_high = event_high * 100000
    )

  out
}
