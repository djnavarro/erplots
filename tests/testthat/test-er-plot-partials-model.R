test_that("build_model_ribbonline returns 2 geoms", {
  skip_if_not_installed("erglm")
  mod2 <- erglm::erglm_model(ae1 ~ aucss + sex, er_test_data, family = binomial())

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_show_model(er_test_mod1))
  expect_no_error(p2 |> er_plot_show_model(mod2))

  p1 <- p1 |> er_plot_show_model(er_test_mod1)
  p2 <- p2 |> er_plot_show_model(mod2)

  args1 <- list(
    data = p1$data,
    config = p1$part$model$config,
    stratify = p1$part$model$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    style = p1$style
  )
  args2 <- list(
    data = p2$data,
    config = p2$part$model$config,
    stratify = p2$part$model$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    style = p2$style
  )

  expect_no_error(do.call(build_model_ribbonline, args1))
  expect_no_error(do.call(build_model_ribbonline, args2))

  p1_out <- do.call(build_model_ribbonline, args1)
  p2_out <- do.call(build_model_ribbonline, args2)

  expect_length(p1_out, 2)
  expect_length(p2_out, 2)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "LayerInstance"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "LayerInstance"))
})


test_that("build_model_line returns 1 geom", {
  skip_if_not_installed("erglm")
  mod2 <- erglm::erglm_model(ae1 ~ aucss + sex, er_test_data, family = binomial())

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_show_model(er_test_mod1, builder = build_model_line))
  expect_no_error(p2 |> er_plot_show_model(mod2, builder = build_model_line))

  p1 <- p1 |> er_plot_show_model(er_test_mod1, builder = build_model_line)
  p2 <- p2 |> er_plot_show_model(mod2, builder = build_model_line)

  args1 <- list(
    data = p1$data,
    config = p1$part$model$config,
    stratify = p1$part$model$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    style = p1$style
  )
  args2 <- list(
    data = p2$data,
    config = p2$part$model$config,
    stratify = p2$part$model$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    style = p2$style
  )

  expect_no_error(do.call(build_model_line, args1))
  expect_no_error(do.call(build_model_line, args2))

  p1_out <- do.call(build_model_line, args1)
  p2_out <- do.call(build_model_line, args2)

  expect_length(p1_out, 1)
  expect_length(p2_out, 1)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[1]], "LayerInstance"))
})


test_that("build_model_spaghetti returns 2 geoms", {
  skip_if_not_installed("erglm")
  mod2 <- erglm::erglm_model(ae1 ~ aucss + sex, er_test_data, family = binomial())

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_show_model(er_test_mod1, builder = build_model_spaghetti))
  expect_no_error(p2 |> er_plot_show_model(mod2, builder = build_model_spaghetti))

  p1 <- p1 |> er_plot_show_model(er_test_mod1, builder = build_model_spaghetti)
  p2 <- p2 |> er_plot_show_model(mod2, builder = build_model_spaghetti)

  args1 <- list(
    data = p1$data,
    config = p1$part$model$config,
    stratify = p1$part$model$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    style = p1$style
  )
  args2 <- list(
    data = p2$data,
    config = p2$part$model$config,
    stratify = p2$part$model$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    style = p2$style
  )

  expect_no_error(do.call(build_model_spaghetti, args1))
  expect_no_error(do.call(build_model_spaghetti, args2))

  p1_out <- do.call(build_model_spaghetti, args1)
  p2_out <- do.call(build_model_spaghetti, args2)

  expect_length(p1_out, 2)
  expect_length(p2_out, 2)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "LayerInstance"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "LayerInstance"))
})

test_that("build_model_spaghetti does not warn about unused fill aesthetic", {
  skip_if_not_installed("erglm")
  mod2 <- erglm::erglm_model(ae1 ~ aucss + sex, er_test_data, family = binomial())

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  p1 <- p1 |> er_plot_show_model(er_test_mod1, builder = build_model_spaghetti)
  p2 <- p2 |> er_plot_show_model(mod2, builder = build_model_spaghetti)

  args1 <- list(
    data = p1$data,
    config = p1$part$model$config,
    stratify = p1$part$model$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    style = p1$style
  )
  args2 <- list(
    data = p2$data,
    config = p2$part$model$config,
    stratify = p2$part$model$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    style = p2$style
  )

  expect_no_warning(do.call(build_model_spaghetti, args1))
  expect_no_warning(do.call(build_model_spaghetti, args2))

  # Also check at render time, since `fill` being unused by `geom_path()`
  # would otherwise surface as a warning during `ggplot_build()`.
  expect_no_warning(plot(p1))
  expect_no_warning(plot(p2))
})

test_that("build_model_spaghetti falls back to ribbonline when er_simulate is unavailable", {
  skip_if_not_installed("erglm")

  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_show_model(er_test_mod1)

  config <- p1$part$model$config
  config$model <- structure(list(), class = "no_simulate_method")

  args1 <- list(
    data = p1$data,
    config = config,
    stratify = p1$part$model$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    style = p1$style
  )

  expect_message(p1_out <- do.call(build_model_spaghetti, args1))
  expect_length(p1_out, 2)
  expect_true(inherits(p1_out[[1]], "LayerInstance"))
})
