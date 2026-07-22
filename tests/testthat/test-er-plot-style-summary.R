test_that("er_style_summary_coefficients renders when coefficients are present", {
  skip_if_not_installed("erglm")
  fake_model <- structure(list(), class = "er_test_fake_summary_model")

  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_summary(model = fake_model, style = er_style_summary_coefficients)

  args <- list(
    data = plt$data,
    config = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata = plt$strata,
    theme = plt$theme
  )

  expect_no_error(out <- do.call(er_style_summary_coefficients, args))
  expect_true(inherits(out, "LayerInstance"))
})

test_that("er_style_summary_gof renders all four fields when present", {
  skip_if_not_installed("erglm")
  fake_model <- structure(list(), class = "er_test_fake_summary_model")

  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_summary(model = fake_model, style = er_style_summary_gof)

  args <- list(
    data = plt$data,
    config = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata = plt$strata,
    theme = plt$theme
  )

  expect_no_error(out <- do.call(er_style_summary_gof, args))
  expect_true(inherits(out, "LayerInstance"))
  lbl <- out$data$lbl
  expect_match(lbl, "N = 100")
  expect_match(lbl, "AIC = 123.4")
  expect_match(lbl, "BIC = 130.1")
  expect_match(lbl, "R\u00b2 = 0.42")
})

test_that("er_style_summary_gof shows only present, non-NA fields", {
  skip_if_not_installed("erglm")
  partial_model <- structure(list(), class = "er_test_partial_gof_model")

  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_summary(model = partial_model, style = er_style_summary_gof)

  args <- list(
    data = plt$data,
    config = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata = plt$strata,
    theme = plt$theme
  )

  out <- do.call(er_style_summary_gof, args)
  lbl <- out$data$lbl
  expect_equal(lbl, "AIC = 88.80")
})

test_that("er_style_summary_gof draws nothing when glance is absent", {
  skip_if_not_installed("erglm")

  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_summary(model = er_test_mod1, style = er_style_summary_gof)

  args <- list(
    data = plt$data,
    config = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata = plt$strata,
    theme = plt$theme
  )

  out <- do.call(er_style_summary_gof, args)
  expect_length(out, 0)
})

test_that("er_style_summary_gof draws nothing when stratified", {
  skip_if_not_installed("erglm")
  fake_model <- structure(list(), class = "er_test_fake_summary_model")

  plt <- er_plot(er_test_data, aucss, ae1, sex) |>
    er_plot_add_summary(model = fake_model, style = er_style_summary_gof)

  args <- list(
    data = plt$data,
    config = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata = plt$strata,
    theme = plt$theme
  )

  out <- do.call(er_style_summary_gof, args)
  expect_length(out, 0)
})

test_that("er_style_summary_coefficients draws nothing when coefficients are absent", {
  skip_if_not_installed("erglm")

  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_summary(model = er_test_mod1, style = er_style_summary_coefficients)

  args <- list(
    data = plt$data,
    config = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata = plt$strata,
    theme = plt$theme
  )

  out <- do.call(er_style_summary_coefficients, args)
  expect_length(out, 0)
})

test_that("er_style_summary_coefficients draws nothing when stratified", {
  skip_if_not_installed("erglm")
  fake_model <- structure(list(), class = "er_test_fake_summary_model")

  plt <- er_plot(er_test_data, aucss, ae1, sex) |>
    er_plot_add_summary(model = fake_model, style = er_style_summary_coefficients)

  args <- list(
    data = plt$data,
    config = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata = plt$strata,
    theme = plt$theme
  )

  out <- do.call(er_style_summary_coefficients, args)
  expect_length(out, 0)
})

test_that("er_style_summary_coefficients tolerates a coefficients table with no p_value column", {
  skip_if_not_installed("erglm")

  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_summary()

  plt$layer$summary$config$summary <- list(
    coefficients = tibble::tibble(term = c("a", "b"), estimate = c(1, 2))
  )

  args <- list(
    data = plt$data,
    config = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata = plt$strata,
    theme = plt$theme
  )

  expect_no_error(out <- do.call(er_style_summary_coefficients, args))
  expect_true(inherits(out, "LayerInstance"))
})

