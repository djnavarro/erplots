test_that("er_style_vpc_observed_pointrange() returns point + errorbar geoms", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |> er_vpc_add_observed()
  geoms <- er_style_vpc_observed_pointrange(
    er_test_data, vpc$layer$observed$config, vpc$exposure, vpc$response, vpc$theme
  )
  expect_length(geoms, 2)
  expect_true(all(purrr::map_lgl(geoms, ~ inherits(.x, "LayerInstance") || inherits(.x, "ggproto"))))
})

test_that("er_style_vpc_observed_line() returns line + point geoms for a continuous response", {
  vpc <- er_vpc(er_test_data, aucss, biomarker_change) |> er_vpc_add_observed()
  geoms <- er_style_vpc_observed_line(
    er_test_data, vpc$layer$observed$config, vpc$exposure, vpc$response, vpc$theme
  )
  expect_length(geoms, 2)
})

test_that("er_style_vpc_observed_line() errors when percentiles aren't available", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |> er_vpc_add_observed()
  expect_error(
    er_style_vpc_observed_line(er_test_data, vpc$layer$observed$config, vpc$exposure, vpc$response, vpc$theme),
    "percentiles"
  )
})

test_that("built-in observed builders are tagged for the observed layer and correct vpc layout", {
  expect_equal(attr(er_style_vpc_observed_pointrange, "er_style_layer"), "observed")
  expect_equal(attr(er_style_vpc_observed_line, "er_style_layer"), "observed")
  expect_equal(attr(er_style_vpc_observed_pointrange_continuous, "er_style_layer"), "observed")
  expect_equal(attr(er_style_vpc_observed_pointrange, "er_style_layout"), "categorical")
  expect_equal(attr(er_style_vpc_observed_line, "er_style_layout"), "continuous")
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

test_that("er_vpc pipeline builds with the continuous-x line builder", {
  vpc <- er_test_data |>
    er_vpc(aucss, biomarker_change) |>
    er_vpc_add_observed(style = er_style_vpc_observed_line) |>
    er_vpc_add_simulated(model = er_test_mod_gaussian, nsim = 5, seed = 701, style = er_style_vpc_simulated_ribbon)

  built <- er_vpc_build(vpc)
  expect_true(inherits(built$output, "ggplot"))
})
