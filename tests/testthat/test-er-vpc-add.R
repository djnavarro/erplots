test_that("er_vpc_add_observed() defaults group_by to the exposure variable", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |> er_vpc_add_observed()
  expect_equal(vpc$layer$observed$config$group_var, "aucss")
  expect_true(vpc$layer$observed$config$is_numeric_group)
  expect_length(vpc$layer$observed$config$breaks, vpc$layer$observed$config$n_bins + 1)
})

test_that("er_vpc_add_observed() stores probs on the layer's config", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |> er_vpc_add_observed(probs = c(0.2, 0.5, 0.8))
  expect_equal(vpc$layer$observed$config$probs, c(0.2, 0.5, 0.8))
})

test_that("er_vpc_add_observed() supports a categorical group_by with no binning", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |> er_vpc_add_observed(group_by = sex)
  expect_equal(vpc$layer$observed$config$group_var, "sex")
  expect_false(vpc$layer$observed$config$is_numeric_group)
  expect_null(vpc$layer$observed$config$breaks)
  expect_null(vpc$layer$observed$config$percentiles)
})

test_that("er_vpc_add_observed() validates n_bins and group_by", {
  vpc <- er_vpc(er_test_data, aucss, ae1)
  expect_error(er_vpc_add_observed(vpc, n_bins = 0), "positive whole number")
  expect_error(er_vpc_add_observed(vpc, n_bins = 2.5), "positive whole number")
  expect_error(er_vpc_add_observed(vpc, group_by = not_a_column), "not found")
})

test_that("er_vpc_add_observed() rejects a style tagged for the wrong layer", {
  vpc <- er_vpc(er_test_data, aucss, ae1)
  expect_error(
    er_vpc_add_observed(vpc, style = er_style_vpc_simulated_errorbar),
    "simulated"
  )
})

test_that("er_vpc_add_observed() requires named ... arguments", {
  vpc <- er_vpc(er_test_data, aucss, ae1)
  expect_error(
    er_vpc_add_observed(vpc, aucss, 4, 0.95, c(0.1, 0.5, 0.9), er_style_vpc_observed_pointrange, "oops"),
    "named"
  )
})

test_that("er_vpc_add_simulated() requires an observed layer first", {
  vpc <- er_vpc(er_test_data, aucss, ae1)
  expect_error(
    er_vpc_add_simulated(vpc, model = er_test_mod1, seed = 1),
    "er_vpc_add_observed"
  )
})

test_that("er_vpc_add_simulated() rejects a style tagged for the wrong layer", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |> er_vpc_add_observed()
  expect_error(
    er_vpc_add_simulated(vpc, model = er_test_mod1, seed = 1, style = er_style_vpc_observed_pointrange),
    "observed"
  )
})

test_that("er_vpc_add_simulated() requires exactly one of sim/model", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |> er_vpc_add_observed()
  expect_error(er_vpc_add_simulated(vpc), "exactly one")

  sim <- er_simulate(er_test_mod1, newdata = er_test_data, nsim = 3, seed = 11)
  sim$ae1 <- sim$sim_resp
  expect_error(
    er_vpc_add_simulated(vpc, model = er_test_mod1, sim = sim),
    "exactly one"
  )
})

test_that("er_vpc_add_simulated() validates nsim only when model is supplied", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |> er_vpc_add_observed()
  expect_error(er_vpc_add_simulated(vpc, model = er_test_mod1, nsim = 0), "positive whole number")
  expect_error(er_vpc_add_simulated(vpc, model = er_test_mod1, nsim = -5), "positive whole number")

  sim <- er_simulate(er_test_mod1, newdata = er_test_data, nsim = 3, seed = 12)
  sim$ae1 <- sim$sim_resp
  expect_no_error(er_vpc_add_simulated(vpc, sim = sim, nsim = -1))
})

test_that("er_vpc_add_simulated() errors informatively when sim_resp is unavailable", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |> er_vpc_add_observed()
  spaghetti_only_mod <- structure(list(prob = 0.4), class = "er_test_fake_spaghetti_only_model")
  no_method_mod <- structure(list(), class = "er_test_no_simulate_method_model")

  expect_error(er_vpc_add_simulated(vpc, model = spaghetti_only_mod), "sim_resp")
  expect_error(er_vpc_add_simulated(vpc, model = no_method_mod), "sim_resp")
})

test_that("er_vpc_add_simulated() errors on a categorical/continuous layout mismatch", {
  vpc <- er_vpc(er_test_data, aucss, biomarker_change) |>
    er_vpc_add_observed(style = er_style_vpc_observed_pointrange)
  expect_error(
    er_vpc_add_simulated(vpc, model = er_test_mod_gaussian, nsim = 5, seed = 901, style = er_style_vpc_simulated_ribbon),
    "categorical.*continuous|continuous.*categorical"
  )

  vpc2 <- er_vpc(er_test_data, aucss, biomarker_change) |>
    er_vpc_add_observed(style = er_style_vpc_observed_line)
  expect_error(
    er_vpc_add_simulated(vpc2, model = er_test_mod_gaussian, nsim = 5, seed = 902, style = er_style_vpc_simulated_errorbar),
    "categorical.*continuous|continuous.*categorical"
  )
})

test_that("er_vpc_add_simulated() errors when probs disagree between continuous-layout builders", {
  vpc <- er_vpc(er_test_data, aucss, biomarker_change) |>
    er_vpc_add_observed(style = er_style_vpc_observed_line, probs = c(0.1, 0.5, 0.9))
  expect_error(
    er_vpc_add_simulated(
      vpc, model = er_test_mod_gaussian, nsim = 5, seed = 911,
      style = er_style_vpc_simulated_ribbon, probs = c(0.2, 0.5, 0.8)
    ),
    "probs"
  )

  vpc2 <- er_vpc(er_test_data, aucss, biomarker_change) |>
    er_vpc_add_observed(style = er_style_vpc_observed_pointrange_continuous, probs = c(0.1, 0.5, 0.9))
  expect_error(
    er_vpc_add_simulated(
      vpc2, model = er_test_mod_gaussian, nsim = 5, seed = 912,
      style = er_style_vpc_simulated_errorbar_continuous, probs = c(0.25, 0.75)
    ),
    "probs"
  )
})

test_that("er_vpc_add_simulated() allows matching probs (order-independent) and identical default probs", {
  vpc <- er_vpc(er_test_data, aucss, biomarker_change) |>
    er_vpc_add_observed(style = er_style_vpc_observed_line, probs = c(0.9, 0.1, 0.5))
  expect_no_error(
    er_vpc_add_simulated(
      vpc, model = er_test_mod_gaussian, nsim = 5, seed = 913,
      style = er_style_vpc_simulated_ribbon, probs = c(0.1, 0.5, 0.9)
    )
  )
})

test_that("er_vpc_add_simulated() ignores probs mismatches for categorical-layout builders", {
  vpc <- er_vpc(er_test_data, aucss, biomarker_change) |>
    er_vpc_add_observed(style = er_style_vpc_observed_pointrange, probs = c(0.1, 0.5, 0.9))
  expect_no_error(
    er_vpc_add_simulated(
      vpc, model = er_test_mod_gaussian, nsim = 5, seed = 914,
      style = er_style_vpc_simulated_errorbar, probs = c(0.2, 0.8)
    )
  )
})

test_that("er_vpc_add_simulated() allows layout-matched pairs, including the continuous pointrange/errorbar builders", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |>
    er_vpc_add_observed(style = er_style_vpc_observed_pointrange_continuous)
  expect_no_error(
    er_vpc_add_simulated(vpc, model = er_test_mod1, nsim = 5, seed = 903, style = er_style_vpc_simulated_errorbar_continuous)
  )
})

test_that("er_vpc_add_simulated() ungroups a grouped sim argument", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |> er_vpc_add_observed()
  sim <- er_simulate(er_test_mod1, newdata = er_test_data, nsim = 3, seed = 13)
  sim$ae1 <- sim$sim_resp
  sim <- sim |> dplyr::group_by(sex)

  expect_no_error(er_vpc_add_simulated(vpc, sim = sim))
})
