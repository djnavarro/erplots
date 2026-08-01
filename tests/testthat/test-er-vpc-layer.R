test_that(".layer_vpc_observed() computes rate + Clopper-Pearson CI for a binary response", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |> er_vpc_add_observed()
  smm <- vpc$layer$observed$config$summary
  expect_true(all(c(".vpc_bin", "x_mid", "y_mid", "y_mid_lbl", "ci_lower", "ci_upper") %in% names(smm)))
  expect_true(all(smm$ci_lower <= smm$y_mid & smm$y_mid <= smm$ci_upper))
  expect_null(vpc$layer$observed$config$percentiles)
})

test_that(".layer_vpc_observed() computes mean + t-interval and percentiles for a continuous response", {
  vpc <- er_vpc(er_test_data, aucss, biomarker_change, probs = c(0.1, 0.5, 0.9)) |> er_vpc_add_observed()
  smm <- vpc$layer$observed$config$summary
  expect_true(all(smm$ci_lower <= smm$y_mid & smm$y_mid <= smm$ci_upper))

  pct <- vpc$layer$observed$config$percentiles
  expect_true(all(c(".vpc_bin", "x_mid", "x_median", "prob", "y", "ci_lower", "ci_upper") %in% names(pct)))
  expect_setequal(unique(pct$prob), c(0.1, 0.5, 0.9))
  expect_equal(nrow(pct), 3 * length(unique(pct$.vpc_bin)))
  expect_true(all(pct$ci_lower <= pct$y & pct$y <= pct$ci_upper))
  expect_false(any(is.na(pct$x_median)))
})

test_that(".layer_vpc_observed() uses an exact Poisson interval for response_type = 'count'", {
  df_count <- er_test_data
  df_count$n_events <- pmax(round(df_count$aucss / 20), 0)
  vpc <- er_vpc(df_count, aucss, n_events, response_type = "count") |> er_vpc_add_observed()
  smm <- vpc$layer$observed$config$summary
  expect_true(all(smm$ci_lower >= 0))
})

test_that(".layer_vpc_simulated() bins simulated rows against the observed layer's own breaks", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 601)

  obs_bins <- as.character(vpc$layer$observed$config$summary$.vpc_bin)
  sim_bins <- as.character(vpc$layer$simulated$config$summary$.vpc_bin)
  # simulated rows are binned against the observed layer's own stored
  # cutpoints (not re-derived independently), so both sides share
  # identical bin labels
  expect_setequal(sim_bins, obs_bins)
})

test_that(".layer_vpc_simulated() computes percentile bands matching config$percentiles' shape", {
  vpc <- er_vpc(er_test_data, aucss, biomarker_change, probs = c(0.1, 0.5, 0.9)) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod_gaussian, nsim = 5, seed = 602)

  pct <- vpc$layer$simulated$config$percentiles
  expect_true(all(c(".vpc_bin", "x_mid", "x_median", "prob", "y_mid", "ci_lower", "ci_upper") %in% names(pct)))
  expect_true(all(pct$ci_lower <= pct$y_mid & pct$y_mid <= pct$ci_upper))
  expect_false(any(is.na(pct$x_median)))
})

test_that(".layer_vpc_observed()/.layer_vpc_simulated() still compute percentiles for a categorical plot_by", {
  # needed by the categorical-bin quantile idiom
  # (er_style_vpc_observed_quantile_errorbar()/er_style_vpc_simulated_quantile_errorbar()),
  # which supports a categorical plot_by unlike the continuous-x idioms
  vpc <- er_vpc(er_test_data, aucss, biomarker_change, plot_by = sex, probs = c(0.1, 0.5, 0.9)) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod_gaussian, nsim = 5, seed = 603)

  obs_pct <- vpc$layer$observed$config$percentiles
  sim_pct <- vpc$layer$simulated$config$percentiles
  expect_true(all(is.na(obs_pct$x_mid)))
  expect_true(all(is.na(sim_pct$x_mid)))
  expect_true(all(is.na(obs_pct$x_median)))
  expect_true(all(is.na(sim_pct$x_median)))
  expect_false(any(is.na(obs_pct$y)))
  expect_false(any(is.na(sim_pct$y_mid)))
})

test_that(".layer_vpc_observed()/.layer_vpc_simulated() bin by a numeric plot_by different from exposure, not by exposure itself", {
  # regression test: `group_var` (`weight`) must drive both the binning
  # and the continuous-x positions/limits, never `exp_var` (`aucss`)
  vpc <- er_vpc(er_test_data, aucss, biomarker_change, plot_by = weight, probs = c(0.1, 0.5, 0.9)) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod_gaussian, nsim = 5, seed = 605)

  obs_config <- vpc$layer$observed$config
  sim_config <- vpc$layer$simulated$config

  # `x_mid`/`x_median` are computed from `weight`, so they must fall
  # within `weight`'s range, not `aucss`'s
  weight_range <- range(er_test_data$weight)
  expect_true(all(obs_config$summary$x_mid >= weight_range[1] & obs_config$summary$x_mid <= weight_range[2]))
  expect_true(all(obs_config$percentiles$x_median >= weight_range[1] & obs_config$percentiles$x_median <= weight_range[2]))
  expect_true(all(sim_config$summary$x_mid >= weight_range[1] & sim_config$summary$x_mid <= weight_range[2]))

  # `group_limits` (used to size continuous-x error bars) reflects
  # `weight`'s own range, distinct from `object$exposure$limits`
  expect_equal(obs_config$group_limits, weight_range)
  expect_equal(sim_config$group_limits, weight_range)
  expect_false(isTRUE(all.equal(obs_config$group_limits, vpc$exposure$limits)))
})

test_that(".layer_vpc_observed()/.layer_vpc_simulated() still skip percentiles for a binary response with a categorical plot_by", {
  vpc <- er_vpc(er_test_data, aucss, ae1, plot_by = sex) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 604)

  expect_null(vpc$layer$observed$config$percentiles)
  expect_null(vpc$layer$simulated$config$percentiles)
})
