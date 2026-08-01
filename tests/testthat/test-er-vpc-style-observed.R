test_that("er_style_vpc_observed_pointrange() returns point + errorbar geoms", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |> er_vpc_add_observed()
  geoms <- er_style_vpc_observed_pointrange(
    er_test_data, vpc$layer$observed$config, vpc$exposure, vpc$response, vpc$theme
  )
  expect_length(geoms, 2)
  expect_true(all(purrr::map_lgl(geoms, ~ inherits(.x, "LayerInstance") || inherits(.x, "ggproto"))))
})

test_that("er_style_vpc_observed_quantile_line() returns line + point geoms for a continuous response", {
  vpc <- er_vpc(er_test_data, aucss, biomarker_change) |> er_vpc_add_observed()
  geoms <- er_style_vpc_observed_quantile_line(
    er_test_data, vpc$layer$observed$config, vpc$exposure, vpc$response, vpc$theme
  )
  expect_length(geoms, 2)
})

test_that("er_style_vpc_observed_quantile_line() errors when percentiles aren't available", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |> er_vpc_add_observed()
  expect_error(
    er_style_vpc_observed_quantile_line(er_test_data, vpc$layer$observed$config, vpc$exposure, vpc$response, vpc$theme),
    "percentiles"
  )
})

test_that("built-in observed builders are tagged for the observed layer and correct vpc layout", {
  expect_equal(attr(er_style_vpc_observed_pointrange, "er_style_layer"), "observed")
  expect_equal(attr(er_style_vpc_observed_quantile_line, "er_style_layer"), "observed")
  expect_equal(attr(er_style_vpc_observed_pointrange_continuous, "er_style_layer"), "observed")
  expect_equal(attr(er_style_vpc_observed_pointrange, "er_style_layout"), "categorical")
  expect_equal(attr(er_style_vpc_observed_quantile_line, "er_style_layout"), "continuous")
  expect_equal(attr(er_style_vpc_observed_pointrange_continuous, "er_style_layout"), "continuous")
})

test_that("er_style_vpc_observed_pointrange_continuous() plots at the numeric bin midpoint", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |> er_vpc_add_observed()
  geoms <- er_style_vpc_observed_pointrange_continuous(
    er_test_data, vpc$layer$observed$config, vpc$exposure, vpc$response, vpc$theme
  )
  expect_length(geoms, 2)
  expect_true(rlang::quo_get_expr(geoms[[2]]$mapping$x) == "x_mid")
})

test_that("er_style_vpc_observed_pointrange_continuous() adds dashed percentile pointranges for a continuous response", {
  vpc <- er_vpc(er_test_data, aucss, biomarker_change, probs = c(0.1, 0.5, 0.9)) |> er_vpc_add_observed()
  geoms <- er_style_vpc_observed_pointrange_continuous(
    er_test_data, vpc$layer$observed$config, vpc$exposure, vpc$response, vpc$theme
  )
  # mean errorbar + point, plus percentile errorbar + point
  expect_length(geoms, 4)
  expect_equal(geoms[[3]]$data, vpc$layer$observed$config$percentiles)
  expect_equal(geoms[[3]]$aes_params$linetype, "dashed")
})

test_that("er_style_vpc_observed_pointrange_continuous() stays mean-only for a binary response", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |> er_vpc_add_observed()
  geoms <- er_style_vpc_observed_pointrange_continuous(
    er_test_data, vpc$layer$observed$config, vpc$exposure, vpc$response, vpc$theme
  )
  expect_length(geoms, 2)
})

test_that("er_style_vpc_observed_pointrange_continuous() errors for a categorical plot_by", {
  vpc <- er_vpc(er_test_data, aucss, ae1, plot_by = sex) |> er_vpc_add_observed()
  expect_error(
    er_style_vpc_observed_pointrange_continuous(
      er_test_data, vpc$layer$observed$config, vpc$exposure, vpc$response, vpc$theme
    ),
    "numeric"
  )
})

test_that("er_style_vpc_observed_mean_errorbar() is the default and carries no layout tag", {
  expect_identical(eval(formals(er_vpc_add_observed)$style), er_style_vpc_observed_mean_errorbar)
  expect_null(attr(er_style_vpc_observed_mean_errorbar, "er_style_layout"))
  expect_equal(attr(er_style_vpc_observed_mean_errorbar, "er_style_layer"), "observed")
  expect_equal(
    attr(er_style_vpc_observed_mean_errorbar, "er_style_response_types"),
    c("binary", "continuous", "count")
  )
  expect_equal(
    attr(er_style_vpc_observed_mean_errorbar, "er_style_plot_by_types"),
    c("continuous", "discrete")
  )
})

test_that("er_style_vpc_observed_mean_errorbar() plots at the numeric bin median for a continuous plot_by", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |> er_vpc_add_observed()
  geoms <- er_style_vpc_observed_mean_errorbar(
    er_test_data, vpc$layer$observed$config, vpc$exposure, vpc$response, vpc$theme
  )
  expect_length(geoms, 2)
  expect_true(rlang::quo_get_expr(geoms[[2]]$mapping$x) == "x_median")
  expect_equal(geoms[[2]]$data, vpc$layer$observed$config$summary)
})

test_that("er_style_vpc_observed_mean_errorbar() plots at the equally-spaced bin label for a categorical plot_by", {
  vpc <- er_vpc(er_test_data, aucss, ae1, plot_by = sex) |> er_vpc_add_observed()
  geoms <- er_style_vpc_observed_mean_errorbar(
    er_test_data, vpc$layer$observed$config, vpc$exposure, vpc$response, vpc$theme
  )
  expect_length(geoms, 2)
  expect_true(rlang::quo_get_expr(geoms[[2]]$mapping$x) == ".vpc_bin")
})

test_that("er_style_vpc_observed_mean_errorbar() works for every response type and plot_by type", {
  vpc_binary <- er_vpc(er_test_data, aucss, ae1) |> er_vpc_add_observed()
  vpc_continuous <- er_vpc(er_test_data, aucss, biomarker_change) |> er_vpc_add_observed()
  vpc_count <- er_vpc(er_test_data, aucss, ae_count, response_type = "count") |> er_vpc_add_observed()
  vpc_discrete <- er_vpc(er_test_data, aucss, ae1, plot_by = sex) |> er_vpc_add_observed()

  for (vpc in list(vpc_binary, vpc_continuous, vpc_count, vpc_discrete)) {
    expect_no_error(
      er_style_vpc_observed_mean_errorbar(er_test_data, vpc$layer$observed$config, vpc$exposure, vpc$response, vpc$theme)
    )
  }
})

test_that("er_vpc pipeline builds with the default mean_errorbar pair for a continuous plot_by", {
  vpc <- er_test_data |>
    er_vpc(aucss, ae1) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 711)

  built <- er_vpc_build(vpc)
  expect_true(inherits(built$output, "ggplot"))
})

test_that("er_vpc pipeline builds with the default mean_errorbar pair for a categorical plot_by", {
  vpc <- er_test_data |>
    er_vpc(aucss, ae1, plot_by = sex) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 712)

  built <- er_vpc_build(vpc)
  expect_true(inherits(built$output, "ggplot"))
})

test_that("er_style_vpc_observed_quantile_errorbar() returns point + errorbar geoms, dodged per prob", {
  vpc <- er_vpc(er_test_data, aucss, biomarker_change, probs = c(0.1, 0.5, 0.9)) |>
    er_vpc_add_observed(style = er_style_vpc_observed_quantile_errorbar)
  geoms <- er_style_vpc_observed_quantile_errorbar(
    er_test_data, vpc$layer$observed$config, vpc$exposure, vpc$response, vpc$theme
  )
  expect_length(geoms, 2)
  expect_true(rlang::quo_get_expr(geoms[[2]]$mapping$x) == ".vpc_bin")
  expect_equal(geoms[[2]]$data, vpc$layer$observed$config$percentiles)
})

test_that("er_style_vpc_observed_quantile_errorbar() works for a categorical plot_by", {
  vpc <- er_vpc(er_test_data, aucss, biomarker_change, plot_by = sex, probs = c(0.1, 0.5, 0.9)) |>
    er_vpc_add_observed(style = er_style_vpc_observed_quantile_errorbar)
  geoms <- er_style_vpc_observed_quantile_errorbar(
    er_test_data, vpc$layer$observed$config, vpc$exposure, vpc$response, vpc$theme
  )
  expect_length(geoms, 2)
  expect_false(any(is.na(vpc$layer$observed$config$percentiles$y)))
})

test_that("er_style_vpc_observed_quantile_errorbar() errors when percentiles aren't available", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |> er_vpc_add_observed()
  expect_error(
    er_style_vpc_observed_quantile_errorbar(
      er_test_data, vpc$layer$observed$config, vpc$exposure, vpc$response, vpc$theme
    ),
    "percentiles"
  )
})

test_that("er_vpc_add_observed() rejects er_style_vpc_observed_quantile_errorbar() for a binary response", {
  vpc <- er_vpc(er_test_data, aucss, ae1)
  expect_error(
    er_vpc_add_observed(vpc, style = er_style_vpc_observed_quantile_errorbar),
    "binary"
  )
})

test_that("built-in observed builders are tagged appropriately, including quantile_errorbar", {
  expect_equal(attr(er_style_vpc_observed_quantile_errorbar, "er_style_layer"), "observed")
  expect_equal(attr(er_style_vpc_observed_quantile_errorbar, "er_style_layout"), "categorical")
  expect_equal(
    attr(er_style_vpc_observed_quantile_errorbar, "er_style_response_types"),
    c("continuous", "count")
  )
  expect_equal(
    attr(er_style_vpc_observed_quantile_errorbar, "er_style_plot_by_types"),
    c("continuous", "discrete")
  )
})

test_that("er_vpc pipeline builds with the quantile_errorbar pair for a continuous plot_by", {
  vpc <- er_test_data |>
    er_vpc(aucss, biomarker_change, probs = c(0.1, 0.5, 0.9)) |>
    er_vpc_add_observed(style = er_style_vpc_observed_quantile_errorbar) |>
    er_vpc_add_simulated(
      model = er_test_mod_gaussian, nsim = 5, seed = 713,
      style = er_style_vpc_simulated_quantile_errorbar
    )

  built <- er_vpc_build(vpc)
  expect_true(inherits(built$output, "ggplot"))
})

test_that("er_vpc pipeline builds with the quantile_errorbar pair for a categorical plot_by", {
  vpc <- er_test_data |>
    er_vpc(aucss, biomarker_change, plot_by = sex, probs = c(0.1, 0.5, 0.9)) |>
    er_vpc_add_observed(style = er_style_vpc_observed_quantile_errorbar) |>
    er_vpc_add_simulated(
      model = er_test_mod_gaussian, nsim = 5, seed = 714,
      style = er_style_vpc_simulated_quantile_errorbar
    )

  built <- er_vpc_build(vpc)
  expect_true(inherits(built$output, "ggplot"))
})

test_that("er_vpc pipeline builds with the continuous-x line builder", {
  vpc <- er_test_data |>
    er_vpc(aucss, biomarker_change) |>
    er_vpc_add_observed(style = er_style_vpc_observed_quantile_line) |>
    er_vpc_add_simulated(model = er_test_mod_gaussian, nsim = 5, seed = 701, style = er_style_vpc_simulated_quantile_ribbon)

  built <- er_vpc_build(vpc)
  expect_true(inherits(built$output, "ggplot"))
})
