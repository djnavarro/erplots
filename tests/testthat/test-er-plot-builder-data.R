test_that("er_builder_data_boxjitter returns box + jitter + coord + yscale", {
  skip_if_not_installed("erglm")

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_add_data(builder = er_builder_data_boxjitter))
  expect_no_error(p2 |> er_plot_add_data(builder = er_builder_data_boxjitter))

  p1 <- p1 |> er_plot_add_data(builder = er_builder_data_boxjitter)
  p2 <- p2 |> er_plot_add_data(builder = er_builder_data_boxjitter)

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

  expect_no_error(do.call(er_builder_data_boxjitter, args1))
  expect_no_error(do.call(er_builder_data_boxjitter, args2))

  p1_out <- do.call(er_builder_data_boxjitter, args1)
  p2_out <- do.call(er_builder_data_boxjitter, args2)

  # boxplot + jitter + coord + yscale
  expect_length(p1_out, 4)
  expect_length(p2_out, 4)

  expect_true(inherits(p1_out[[1]], "LayerInstance")) # geom_boxplot
  expect_true(inherits(p1_out[[2]], "LayerInstance")) # geom_jitter
  expect_true(inherits(p1_out[[3]], "CoordCartesian"))
  expect_true(inherits(p1_out[[4]], "ScaleContinuousPosition"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "LayerInstance"))
  expect_true(inherits(p2_out[[3]], "CoordCartesian"))
  expect_true(inherits(p2_out[[4]], "ScaleDiscretePosition"))

  # unstratified: filtered to just responders, no color/fill mapped
  expect_equal(nrow(p1_out[[1]]$data), sum(er_test_data$ae1 == 1))
  expect_null(p1_out[[1]]$mapping$fill)
  expect_null(p1_out[[2]]$mapping$colour)

  # stratified: still filtered to responders, and fill/color mean strata
  expect_equal(nrow(p2_out[[1]]$data), sum(er_test_data$ae1 == 1))
  expect_false(is.null(p2_out[[1]]$mapping$fill))
  expect_false(is.null(p2_out[[2]]$mapping$colour))
})


test_that("er_builder_data_overlay returns a single geom, jittered only for a binary response", {
  skip_if_not_installed("erglm")

  p_binary  <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_data()
  p_bin_str <- er_plot(er_test_data, aucss, ae1, sex) |> er_plot_add_data()
  p_cont    <- er_plot(er_test_data, aucss, biomarker_change) |> er_plot_add_data()

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

  out_binary  <- do.call(er_builder_data_overlay, args(p_binary))
  out_bin_str <- do.call(er_builder_data_overlay, args(p_bin_str))
  out_cont    <- do.call(er_builder_data_overlay, args(p_cont))

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


test_that("er_builder_data_hex returns a single hex geom for any response type", {
  skip_if_not_installed("erglm")
  skip_if_not_installed("hexbin")

  p_binary <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_data(builder = er_builder_data_hex)
  p_cont <- er_plot(er_test_data, aucss, biomarker_change) |>
    er_plot_add_data(builder = er_builder_data_hex)

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

  out_binary <- do.call(er_builder_data_hex, args(p_binary))
  out_cont <- do.call(er_builder_data_hex, args(p_cont))

  expect_length(out_binary, 1)
  expect_length(out_cont, 1)
  expect_true(inherits(out_binary[[1]], "LayerInstance"))
  expect_true(inherits(out_cont[[1]], "LayerInstance"))
  expect_identical(class(out_cont[[1]]$geom)[1], "GeomHex")
})

test_that("er_builder_data_hex informs (not warns/errors) that strata aren't encoded", {
  skip_if_not_installed("erglm")
  skip_if_not_installed("hexbin")

  p_strat <- er_plot(er_test_data, aucss, biomarker_change, sex) |>
    er_plot_add_data(builder = er_builder_data_hex)

  args <- list(
    data = p_strat$data,
    config = p_strat$part$overlay$config,
    stratify = p_strat$part$overlay$stratify,
    exposure = p_strat$exposure,
    response = p_strat$response,
    strata = p_strat$strata,
    style = p_strat$style
  )

  expect_message(do.call(er_builder_data_hex, args))
  out <- suppressMessages(do.call(er_builder_data_hex, args))
  expect_null(out[[1]]$mapping$colour)
  expect_null(out[[1]]$mapping$fill)
})

test_that("er_plot_add_data() builds and renders with builder = er_builder_data_hex", {
  skip_if_not_installed("erglm")
  skip_if_not_installed("hexbin")

  plt <- er_test_data |>
    er_plot(aucss, biomarker_change) |>
    er_plot_add_model(er_test_mod_gaussian) |>
    er_plot_add_data(builder = er_builder_data_hex)

  expect_no_error(er_plot_build(plt))
})
