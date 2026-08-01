test_that("er_style_vpc_simulated_errorbar() returns point + errorbar geoms", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 801)

  geoms <- er_style_vpc_simulated_errorbar(
    er_test_data, vpc$layer$simulated$config, vpc$exposure, vpc$response, vpc$theme
  )
  expect_length(geoms, 2)
})

test_that("er_style_vpc_simulated_ribbon() returns ribbon + line geoms for a continuous response", {
  vpc <- er_vpc(er_test_data, aucss, biomarker_change) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod_gaussian, nsim = 5, seed = 802)

  geoms <- er_style_vpc_simulated_ribbon(
    er_test_data, vpc$layer$simulated$config, vpc$exposure, vpc$response, vpc$theme
  )
  expect_length(geoms, 3)
})

test_that("er_style_vpc_simulated_ribbon() errors when percentiles aren't available", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 803)

  expect_error(
    er_style_vpc_simulated_ribbon(er_test_data, vpc$layer$simulated$config, vpc$exposure, vpc$response, vpc$theme),
    "percentiles"
  )
})

test_that("built-in simulated builders are tagged for the simulated layer and correct vpc layout", {
  expect_equal(attr(er_style_vpc_simulated_errorbar, "er_style_layer"), "simulated")
  expect_equal(attr(er_style_vpc_simulated_ribbon, "er_style_layer"), "simulated")
  expect_equal(attr(er_style_vpc_simulated_errorbar_continuous, "er_style_layer"), "simulated")
  expect_equal(attr(er_style_vpc_simulated_errorbar, "er_style_layout"), "categorical")
  expect_equal(attr(er_style_vpc_simulated_ribbon, "er_style_layout"), "continuous")
  expect_equal(attr(er_style_vpc_simulated_errorbar_continuous, "er_style_layout"), "continuous")
})

test_that("er_style_vpc_simulated_errorbar_continuous() plots at the numeric bin midpoint", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 805)

  geoms <- er_style_vpc_simulated_errorbar_continuous(
    er_test_data, vpc$layer$simulated$config, vpc$exposure, vpc$response, vpc$theme
  )
  expect_length(geoms, 2)
  expect_true(rlang::quo_get_expr(geoms[[2]]$mapping$x) == "x_mid")
})

test_that("er_style_vpc_simulated_errorbar_continuous() adds dashed percentile pointranges for a continuous response", {
  vpc <- er_vpc(er_test_data, aucss, biomarker_change, probs = c(0.1, 0.5, 0.9)) |>
    er_vpc_add_observed(style = er_style_vpc_observed_pointrange_continuous) |>
    er_vpc_add_simulated(
      model = er_test_mod_gaussian, nsim = 5, seed = 808,
      style = er_style_vpc_simulated_errorbar_continuous
    )

  geoms <- er_style_vpc_simulated_errorbar_continuous(
    er_test_data, vpc$layer$simulated$config, vpc$exposure, vpc$response, vpc$theme
  )
  expect_length(geoms, 4)
  expect_equal(geoms[[3]]$data, vpc$layer$simulated$config$percentiles)
  expect_equal(geoms[[3]]$aes_params$linetype, "dashed")
})

test_that("er_style_vpc_simulated_errorbar_continuous() stays mean-only for a binary response", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |>
    er_vpc_add_observed(style = er_style_vpc_observed_pointrange_continuous) |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 809, style = er_style_vpc_simulated_errorbar_continuous)

  geoms <- er_style_vpc_simulated_errorbar_continuous(
    er_test_data, vpc$layer$simulated$config, vpc$exposure, vpc$response, vpc$theme
  )
  expect_length(geoms, 2)
})

test_that("er_style_vpc_simulated_errorbar_continuous() errors for a categorical plot_by", {
  vpc <- er_vpc(er_test_data, aucss, ae1, plot_by = sex) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 806, style = er_style_vpc_simulated_errorbar)

  expect_error(
    er_style_vpc_simulated_errorbar_continuous(
      er_test_data, vpc$layer$simulated$config, vpc$exposure, vpc$response, vpc$theme
    ),
    "numeric"
  )
})

test_that("er_vpc pipeline builds with the continuous-x pointrange/errorbar builders", {
  vpc <- er_test_data |>
    er_vpc(aucss, ae1) |>
    er_vpc_add_observed(style = er_style_vpc_observed_pointrange_continuous) |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 807, style = er_style_vpc_simulated_errorbar_continuous)

  built <- er_vpc_build(vpc)
  expect_true(inherits(built$output, "ggplot"))
})

test_that("er_style_vpc_simulated_mean_errorbar() is the default and carries no layout tag", {
  expect_identical(eval(formals(er_vpc_add_simulated)$style), er_style_vpc_simulated_mean_errorbar)
  expect_null(attr(er_style_vpc_simulated_mean_errorbar, "er_style_layout"))
  expect_equal(attr(er_style_vpc_simulated_mean_errorbar, "er_style_layer"), "simulated")
  expect_equal(
    attr(er_style_vpc_simulated_mean_errorbar, "er_style_response_types"),
    c("binary", "continuous", "count")
  )
  expect_equal(
    attr(er_style_vpc_simulated_mean_errorbar, "er_style_plot_by_types"),
    c("continuous", "discrete")
  )
})

test_that("er_style_vpc_simulated_mean_errorbar() plots at the numeric bin median for a continuous plot_by", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 810)

  geoms <- er_style_vpc_simulated_mean_errorbar(
    er_test_data, vpc$layer$simulated$config, vpc$exposure, vpc$response, vpc$theme
  )
  expect_length(geoms, 2)
  expect_true(rlang::quo_get_expr(geoms[[2]]$mapping$x) == "x_median")
})

test_that("er_style_vpc_simulated_mean_errorbar() plots at the equally-spaced bin label for a categorical plot_by", {
  vpc <- er_vpc(er_test_data, aucss, ae1, plot_by = sex) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 811)

  geoms <- er_style_vpc_simulated_mean_errorbar(
    er_test_data, vpc$layer$simulated$config, vpc$exposure, vpc$response, vpc$theme
  )
  expect_length(geoms, 2)
  expect_true(rlang::quo_get_expr(geoms[[2]]$mapping$x) == ".vpc_bin")
})

test_that("the default mean_errorbar pair shares consistent x-positions for a continuous plot_by", {
  vpc <- er_test_data |>
    er_vpc(aucss, ae1) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 812)

  expect_equal(
    sort(vpc$layer$observed$config$summary$x_median),
    sort(vpc$layer$simulated$config$summary$x_median)
  )
})

test_that("the simulated layer's geoms are drawn before the observed layer's in the base plot", {
  vpc <- er_test_data |>
    er_vpc(aucss, ae1) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 804)

  built <- er_vpc_build(vpc)
  layer_colors <- purrr::map_chr(built$output$layers, function(l) {
    val <- rlang::eval_tidy(l$mapping$colour %||% l$aes_params$colour %||% NA)
    if (length(val) == 0) NA_character_ else as.character(val)
  })
  # first occurrence of "Simulated" should come before the first
  # occurrence of "Observed"
  expect_lt(min(which(layer_colors == "Simulated")), min(which(layer_colors == "Observed")))
})
