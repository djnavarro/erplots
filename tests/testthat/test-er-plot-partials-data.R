test_that("build_data_jitter returns geom + coord + yscale", {
  skip_if_not_installed("erglm")
  mod2 <- erglm::erglm_model(ae1 ~ aucss + sex, er_test_data, family = binomial())

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_show_data(style = "jitter"))
  expect_no_error(p2 |> er_plot_show_data(style = "jitter"))

  p1 <- p1 |> er_plot_show_data(style = "jitter")
  p2 <- p2 |> er_plot_show_data(style = "jitter")

  config1 <- p1$part$data$config
  config2 <- p2$part$data$config

  config1$panel <- "upper"
  config2$panel <- "upper"

  args1 <- list(
    data = p1$data,
    config = config1,
    stratify = p1$part$data$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    style = p1$style
  )
  args2 <- list(
    data = p2$data,
    config = config2,
    stratify = p2$part$data$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    style = p2$style
  )

  expect_no_error(do.call(build_data_jitter, args1))
  expect_no_error(do.call(build_data_jitter, args2))

  p1_out <- do.call(build_data_jitter, args1)
  p2_out <- do.call(build_data_jitter, args2)

  expect_length(p1_out, 3)
  expect_length(p2_out, 3)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "CoordCartesian"))
  expect_true(inherits(p1_out[[3]], "ScaleContinuousPosition"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "CoordCartesian"))
  expect_true(inherits(p2_out[[3]], "ScaleContinuousPosition"))
})
