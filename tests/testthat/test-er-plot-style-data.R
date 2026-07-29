test_that("er_style_data_boxjitter returns box + jitter + coord + yscale", {
  skip_if_not_installed("erglm")

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_add_data(style = er_style_data_boxjitter))
  expect_no_error(p2 |> er_plot_add_data(style = er_style_data_boxjitter))

  p1 <- p1 |> er_plot_add_data(style = er_style_data_boxjitter)
  p2 <- p2 |> er_plot_add_data(style = er_style_data_boxjitter)

  config1 <- p1$layer$data$config
  config2 <- p2$layer$data$config

  config1$panel <- "upper"
  config2$panel <- "upper"

  args1 <- list(
    data = p1$data,
    config = config1,
    stratify = p1$layer$data$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )
  args2 <- list(
    data = p2$data,
    config = config2,
    stratify = p2$layer$data$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    theme = p2$theme
  )

  expect_no_error(do.call(er_style_data_boxjitter, args1))
  expect_no_error(do.call(er_style_data_boxjitter, args2))

  p1_out <- do.call(er_style_data_boxjitter, args1)
  p2_out <- do.call(er_style_data_boxjitter, args2)

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


test_that("er_style_data_boxjitter's new style arguments override their previous fixed defaults", {
  skip_if_not_installed("erglm")

  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_data(style = er_style_data_boxjitter)
  config1 <- p1$layer$data$config
  config1$panel <- "upper"

  args <- function(...) {
    c(
      list(
        data = p1$data,
        config = config1,
        stratify = p1$layer$data$stratify,
        exposure = p1$exposure,
        response = p1$response,
        strata = p1$strata,
        theme = p1$theme
      ),
      list(...)
    )
  }

  # defaults reproduce the previous fixed behaviour
  out_default <- do.call(er_style_data_boxjitter, args())
  expect_equal(out_default[[1]]$aes_params$width, 0.6)
  expect_equal(out_default[[1]]$aes_params$alpha, 0.4)
  expect_equal(out_default[[1]]$geom_params$outlier_gp$shape, NA)
  expect_equal(out_default[[2]]$aes_params$size, 1)
  expect_equal(out_default[[2]]$aes_params$alpha, 0.6)
  expect_equal(out_default[[2]]$position$height, 0.15) # unstratified

  # explicit overrides take effect
  out_custom <- do.call(er_style_data_boxjitter, args(
    box_width = 0.9,
    box_alpha = 0.9,
    show_outliers = TRUE,
    jitter_height = 0.5,
    jitter_size = 4,
    jitter_alpha = 0.9
  ))
  expect_equal(out_custom[[1]]$aes_params$width, 0.9)
  expect_equal(out_custom[[1]]$aes_params$alpha, 0.9)
  expect_equal(out_custom[[1]]$geom_params$outlier_gp$shape, 19)
  expect_equal(out_custom[[2]]$aes_params$size, 4)
  expect_equal(out_custom[[2]]$aes_params$alpha, 0.9)
  expect_equal(out_custom[[2]]$position$height, 0.5)
})


test_that("er_style_data_overlay returns a single geom, jittered only for a binary response", {
  skip_if_not_installed("erglm")

  p_binary  <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_data()
  p_bin_str <- er_plot(er_test_data, aucss, ae1, sex) |> er_plot_add_data()
  p_cont    <- er_plot(er_test_data, aucss, biomarker_change) |> er_plot_add_data()

  args <- function(p) {
    list(
      data = p$data,
      config = p$layer$overlay$config,
      stratify = p$layer$overlay$stratify,
      exposure = p$exposure,
      response = p$response,
      strata = p$strata,
      theme = p$theme
    )
  }

  out_binary  <- do.call(er_style_data_overlay, args(p_binary))
  out_bin_str <- do.call(er_style_data_overlay, args(p_bin_str))
  out_cont    <- do.call(er_style_data_overlay, args(p_cont))

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


test_that("er_style_data_overlay's new style arguments override their previous fixed defaults", {
  skip_if_not_installed("erglm")

  p_binary <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_data()
  p_cont   <- er_plot(er_test_data, aucss, biomarker_change) |> er_plot_add_data()

  args <- function(p, ...) {
    c(
      list(
        data = p$data,
        config = p$layer$overlay$config,
        stratify = p$layer$overlay$stratify,
        exposure = p$exposure,
        response = p$response,
        strata = p$strata,
        theme = p$theme
      ),
      list(...)
    )
  }

  # defaults reproduce the previous response-type-dependent behaviour
  out_binary_default <- do.call(er_style_data_overlay, args(p_binary))
  out_cont_default    <- do.call(er_style_data_overlay, args(p_cont))
  expect_equal(out_binary_default[[1]]$position$height, 0.05)
  expect_equal(out_cont_default[[1]]$position$height, 0)
  expect_equal(out_binary_default[[1]]$aes_params$alpha, 0.4)
  expect_equal(out_binary_default[[1]]$aes_params$size, 1)

  # an explicit jitter_height overrides the response-type default uniformly
  out_binary_custom <- do.call(er_style_data_overlay, args(p_binary, jitter_height = 0.2, alpha = 0.9, size = 3))
  out_cont_custom    <- do.call(er_style_data_overlay, args(p_cont, jitter_height = 0.2, alpha = 0.9, size = 3))
  expect_equal(out_binary_custom[[1]]$position$height, 0.2)
  expect_equal(out_cont_custom[[1]]$position$height, 0.2)
  expect_equal(out_binary_custom[[1]]$aes_params$alpha, 0.9)
  expect_equal(out_binary_custom[[1]]$aes_params$size, 3)
})


test_that("er_style_data_hex returns a single hex geom for any response type", {
  skip_if_not_installed("erglm")
  skip_if_not_installed("hexbin")

  p_binary <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_data(style = er_style_data_hex)
  p_cont <- er_plot(er_test_data, aucss, biomarker_change) |>
    er_plot_add_data(style = er_style_data_hex)

  args <- function(p) {
    list(
      data = p$data,
      config = p$layer$overlay$config,
      stratify = p$layer$overlay$stratify,
      exposure = p$exposure,
      response = p$response,
      strata = p$strata,
      theme = p$theme
    )
  }

  out_binary <- do.call(er_style_data_hex, args(p_binary))
  out_cont <- do.call(er_style_data_hex, args(p_cont))

  expect_length(out_binary, 1)
  expect_length(out_cont, 1)
  expect_true(inherits(out_binary[[1]], "LayerInstance"))
  expect_true(inherits(out_cont[[1]], "LayerInstance"))
  expect_identical(class(out_cont[[1]]$geom)[1], "GeomHex")
})

test_that("er_style_data_hex informs (not warns/errors) that strata aren't encoded", {
  skip_if_not_installed("erglm")
  skip_if_not_installed("hexbin")

  p_strat <- er_plot(er_test_data, aucss, biomarker_change, sex) |>
    er_plot_add_data(style = er_style_data_hex)

  args <- list(
    data = p_strat$data,
    config = p_strat$layer$overlay$config,
    stratify = p_strat$layer$overlay$stratify,
    exposure = p_strat$exposure,
    response = p_strat$response,
    strata = p_strat$strata,
    theme = p_strat$theme
  )

  expect_message(do.call(er_style_data_hex, args))
  out <- suppressMessages(do.call(er_style_data_hex, args))
  expect_null(out[[1]]$mapping$colour)
  expect_null(out[[1]]$mapping$fill)
})

test_that("er_style_data_hex's bins argument overrides the previous fixed default", {
  skip_if_not_installed("erglm")
  skip_if_not_installed("hexbin")

  p_cont <- er_plot(er_test_data, aucss, biomarker_change) |>
    er_plot_add_data(style = er_style_data_hex)

  args <- function(...) {
    c(
      list(
        data = p_cont$data,
        config = p_cont$layer$overlay$config,
        stratify = p_cont$layer$overlay$stratify,
        exposure = p_cont$exposure,
        response = p_cont$response,
        strata = p_cont$strata,
        theme = p_cont$theme
      ),
      list(...)
    )
  }

  out_default <- do.call(er_style_data_hex, args())
  out_custom  <- do.call(er_style_data_hex, args(bins = 10))

  expect_equal(out_default[[1]]$stat_params$bins, 30)
  expect_equal(out_custom[[1]]$stat_params$bins, 10)
})


test_that("er_plot_add_data() forwards new style arguments through `...` to the builder", {
  skip_if_not_installed("erglm")

  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_data(style = er_style_data_overlay, jitter_height = 0.2, alpha = 0.9, size = 3)

  expect_no_error(er_plot_build(plt))

  built <- er_plot_build(plt)
  jitter_layer <- built$plot$base$layers[[length(built$plot$base$layers)]]
  expect_equal(jitter_layer$position$height, 0.2)
  expect_equal(jitter_layer$aes_params$alpha, 0.9)
  expect_equal(jitter_layer$aes_params$size, 3)
})


test_that("er_plot_add_data() builds and renders with style = er_style_data_hex", {
  skip_if_not_installed("erglm")
  skip_if_not_installed("hexbin")

  plt <- er_test_data |>
    er_plot(aucss, biomarker_change) |>
    er_plot_add_model(er_test_mod_gaussian) |>
    er_plot_add_data(style = er_style_data_hex)

  expect_no_error(er_plot_build(plt))
})
