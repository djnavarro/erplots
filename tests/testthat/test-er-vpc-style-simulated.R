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

test_that("built-in simulated builders are tagged for the simulated layer", {
  expect_equal(attr(er_style_vpc_simulated_errorbar, "er_style_layer"), "simulated")
  expect_equal(attr(er_style_vpc_simulated_ribbon, "er_style_layer"), "simulated")
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
