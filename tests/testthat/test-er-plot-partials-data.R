test_that("build_data_jitter returns geom + coord + yscale", {
  skip_if_not_installed("erglm")
  mod2 <- erglm::erglm_model(ae1 ~ aucss + sex, er_test_data, family = binomial())

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_show_data(builder = build_data_jitter))
  expect_no_error(p2 |> er_plot_show_data(builder = build_data_jitter))

  p1 <- p1 |> er_plot_show_data(builder = build_data_jitter)
  p2 <- p2 |> er_plot_show_data(builder = build_data_jitter)

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


test_that("build_data_color returns geom + coord + yscale for a continuous response", {
  skip_if_not_installed("erglm")

  p1 <- er_plot(er_test_data, aucss, biomarker_change)
  p2 <- er_plot(er_test_data, aucss, biomarker_change, sex)

  p1 <- p1 |> er_plot_show_data(builder = build_data_color)
  p2 <- p2 |> er_plot_show_data(builder = build_data_color)

  config1 <- p1$part$data$config
  config2 <- p2$part$data$config
  config1$panel <- "data"
  config2$panel <- as.character(unique(er_test_data$sex))[1]

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

  expect_no_error(do.call(build_data_color, args1))
  expect_no_error(do.call(build_data_color, args2))

  p1_out <- do.call(build_data_color, args1)
  p2_out <- do.call(build_data_color, args2)

  expect_length(p1_out, 3)
  expect_length(p2_out, 3)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "CoordCartesian"))
  expect_true(inherits(p1_out[[3]], "ScaleContinuousPosition"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "CoordCartesian"))
  expect_true(inherits(p2_out[[3]], "ScaleContinuousPosition"))

  # the stratified builder filters to just the requested stratum's rows
  filtered_n <- p2_out[[1]]$data |> nrow()
  expect_equal(filtered_n, sum(er_test_data$sex == config2$panel))
})


test_that("build_data_overlay returns a single geom, jittered only for a binary response", {
  skip_if_not_installed("erglm")

  p_binary  <- er_plot(er_test_data, aucss, ae1) |> er_plot_show_data()
  p_bin_str <- er_plot(er_test_data, aucss, ae1, sex) |> er_plot_show_data()
  p_cont    <- er_plot(er_test_data, aucss, biomarker_change) |> er_plot_show_data()

  args <- function(p) {
    list(
      data = p$data,
      config = p$part$overlay$config,
      stratify = p$part$overlay$stratify,
      exposure = p$exposure,
      response = p$response,
      strata = p$strata,
      style = p$style
    )
  }

  out_binary  <- do.call(build_data_overlay, args(p_binary))
  out_bin_str <- do.call(build_data_overlay, args(p_bin_str))
  out_cont    <- do.call(build_data_overlay, args(p_cont))

  expect_length(out_binary, 1)
  expect_length(out_bin_str, 1)
  expect_length(out_cont, 1)

  expect_true(inherits(out_binary[[1]], "LayerInstance"))
  expect_true(inherits(out_bin_str[[1]], "LayerInstance"))
  expect_true(inherits(out_cont[[1]], "LayerInstance"))

  # binary response: nonzero vertical jitter
  expect_gt(out_binary[[1]]$position$height, 0)
  expect_gt(out_bin_str[[1]]$position$height, 0)
  # continuous response: no jitter
  expect_equal(out_cont[[1]]$position$height, 0)

  # color aesthetic only present when stratified
  expect_null(out_binary[[1]]$mapping$colour)
  expect_false(is.null(out_bin_str[[1]]$mapping$colour))
  expect_null(out_cont[[1]]$mapping$colour)
})
