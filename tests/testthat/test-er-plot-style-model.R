test_that("er_style_model_ribbonline returns 2 geoms", {
  mod2 <- er_test_toy_model(ae1 ~ aucss + sex, er_test_data, family = binomial())

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_add_model(er_test_mod1))
  expect_no_error(p2 |> er_plot_add_model(mod2))

  p1 <- p1 |> er_plot_add_model(er_test_mod1)
  p2 <- p2 |> er_plot_add_model(mod2)

  args1 <- list(
    data = p1$data,
    config = p1$layer$model$config,
    stratify = p1$layer$model$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )
  args2 <- list(
    data = p2$data,
    config = p2$layer$model$config,
    stratify = p2$layer$model$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    theme = p2$theme
  )

  expect_no_error(do.call(er_style_model_ribbonline, args1))
  expect_no_error(do.call(er_style_model_ribbonline, args2))

  p1_out <- do.call(er_style_model_ribbonline, args1)
  p2_out <- do.call(er_style_model_ribbonline, args2)

  expect_length(p1_out, 2)
  expect_length(p2_out, 2)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "LayerInstance"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "LayerInstance"))
})


test_that("er_style_model_ribbonline's new style arguments override their previous fixed defaults", {
  mod2 <- er_test_toy_model(ae1 ~ aucss + sex, er_test_data, family = binomial())

  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_model(er_test_mod1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex) |> er_plot_add_model(mod2)

  args1 <- function(...) {
    c(
      list(
        data = p1$data,
        config = p1$layer$model$config,
        stratify = p1$layer$model$stratify,
        exposure = p1$exposure,
        response = p1$response,
        strata = p1$strata,
        theme = p1$theme
      ),
      list(...)
    )
  }
  args2 <- function(...) {
    c(
      list(
        data = p2$data,
        config = p2$layer$model$config,
        stratify = p2$layer$model$stratify,
        exposure = p2$exposure,
        response = p2$response,
        strata = p2$strata,
        theme = p2$theme
      ),
      list(...)
    )
  }

  # defaults reproduce the previous fixed behaviour: 2 geoms, no edges
  out1_default <- do.call(er_style_model_ribbonline, args1())
  out2_default <- do.call(er_style_model_ribbonline, args2())
  expect_length(out1_default, 2)
  expect_length(out2_default, 2)
  expect_equal(out1_default[[1]]$aes_params$fill, "grey40")
  expect_equal(out1_default[[1]]$aes_params$alpha, 0.25)
  expect_equal(out1_default[[2]]$aes_params$linewidth, 1)
  expect_equal(out2_default[[1]]$aes_params$alpha, 0.25) # stratified ribbon has no fixed fill
  expect_equal(out2_default[[2]]$aes_params$linewidth, 1)

  # explicit overrides take effect, including the new ribbon_edges geoms
  out1_custom <- do.call(er_style_model_ribbonline, args1(
    ribbon_fill = "steelblue", ribbon_alpha = 0.15, ribbon_edges = TRUE, linewidth = 2
  ))
  out2_custom <- do.call(er_style_model_ribbonline, args2(
    ribbon_edges = TRUE, linewidth = 2
  ))

  expect_length(out1_custom, 4) # ribbon, edge_lower, edge_upper, line
  expect_length(out2_custom, 4)
  expect_equal(out1_custom[[1]]$aes_params$fill, "steelblue")
  expect_equal(out1_custom[[1]]$aes_params$alpha, 0.15)
  expect_equal(out1_custom[[2]]$aes_params$linetype, "dashed")
  expect_equal(out1_custom[[3]]$aes_params$linetype, "dashed")
  expect_equal(out1_custom[[4]]$aes_params$linewidth, 2)
  expect_null(out1_custom[[2]]$mapping$colour)

  # stratified edges map colour to strata, same as the main line
  expect_false(is.null(out2_custom[[2]]$mapping$colour))
  expect_equal(out2_custom[[4]]$aes_params$linewidth, 2)
})


test_that("er_style_model_line returns 1 geom", {
  mod2 <- er_test_toy_model(ae1 ~ aucss + sex, er_test_data, family = binomial())

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_add_model(er_test_mod1, style = er_style_model_line))
  expect_no_error(p2 |> er_plot_add_model(mod2, style = er_style_model_line))

  p1 <- p1 |> er_plot_add_model(er_test_mod1, style = er_style_model_line)
  p2 <- p2 |> er_plot_add_model(mod2, style = er_style_model_line)

  args1 <- list(
    data = p1$data,
    config = p1$layer$model$config,
    stratify = p1$layer$model$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )
  args2 <- list(
    data = p2$data,
    config = p2$layer$model$config,
    stratify = p2$layer$model$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    theme = p2$theme
  )

  expect_no_error(do.call(er_style_model_line, args1))
  expect_no_error(do.call(er_style_model_line, args2))

  p1_out <- do.call(er_style_model_line, args1)
  p2_out <- do.call(er_style_model_line, args2)

  expect_length(p1_out, 1)
  expect_length(p2_out, 1)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[1]], "LayerInstance"))
})


test_that("er_style_model_line's linewidth argument overrides its previous fixed default", {
  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_model(er_test_mod1, style = er_style_model_line)

  args <- function(...) {
    c(
      list(
        data = p1$data,
        config = p1$layer$model$config,
        stratify = p1$layer$model$stratify,
        exposure = p1$exposure,
        response = p1$response,
        strata = p1$strata,
        theme = p1$theme
      ),
      list(...)
    )
  }

  out_default <- do.call(er_style_model_line, args())
  out_custom <- do.call(er_style_model_line, args(linewidth = 2))

  expect_equal(out_default[[1]]$aes_params$linewidth, 1)
  expect_equal(out_custom[[1]]$aes_params$linewidth, 2)
})


test_that("er_style_model_spaghetti returns 2 geoms", {
  mod2 <- er_test_toy_model(ae1 ~ aucss + sex, er_test_data, family = binomial())

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_add_model(er_test_mod1, style = er_style_model_spaghetti))
  expect_no_error(p2 |> er_plot_add_model(mod2, style = er_style_model_spaghetti))

  p1 <- p1 |> er_plot_add_model(er_test_mod1, style = er_style_model_spaghetti)
  p2 <- p2 |> er_plot_add_model(mod2, style = er_style_model_spaghetti)

  args1 <- list(
    data = p1$data,
    config = p1$layer$model$config,
    stratify = p1$layer$model$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )
  args2 <- list(
    data = p2$data,
    config = p2$layer$model$config,
    stratify = p2$layer$model$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    theme = p2$theme
  )

  expect_no_error(do.call(er_style_model_spaghetti, args1))
  expect_no_error(do.call(er_style_model_spaghetti, args2))

  p1_out <- do.call(er_style_model_spaghetti, args1)
  p2_out <- do.call(er_style_model_spaghetti, args2)

  expect_length(p1_out, 2)
  expect_length(p2_out, 2)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "LayerInstance"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "LayerInstance"))
})

test_that("er_style_model_spaghetti's new style arguments override their previous fixed defaults", {
  mod2 <- er_test_toy_model(ae1 ~ aucss + sex, er_test_data, family = binomial())

  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_model(er_test_mod1, style = er_style_model_spaghetti)
  p2 <- er_plot(er_test_data, aucss, ae1, sex) |> er_plot_add_model(mod2, style = er_style_model_spaghetti)

  args1 <- function(...) {
    c(
      list(
        data = p1$data,
        config = p1$layer$model$config,
        stratify = p1$layer$model$stratify,
        exposure = p1$exposure,
        response = p1$response,
        strata = p1$strata,
        theme = p1$theme
      ),
      list(...)
    )
  }
  args2 <- function(...) {
    c(
      list(
        data = p2$data,
        config = p2$layer$model$config,
        stratify = p2$layer$model$stratify,
        exposure = p2$exposure,
        response = p2$response,
        strata = p2$strata,
        theme = p2$theme
      ),
      list(...)
    )
  }

  # defaults reproduce the previous fixed-per-stratify-status alpha, and
  # the previous fixed linewidth/nsim
  out1_default <- do.call(er_style_model_spaghetti, args1(seed = 123))
  out2_default <- do.call(er_style_model_spaghetti, args2(seed = 123))
  expect_equal(out1_default[[1]]$aes_params$alpha, 0.1)
  expect_equal(out2_default[[1]]$aes_params$alpha, 0.25)
  expect_equal(out1_default[[2]]$aes_params$linewidth, 1)
  expect_equal(length(unique(out1_default[[1]]$data$sim_id)), 100)

  # explicit overrides take effect, including a reduced nsim
  out1_custom <- do.call(er_style_model_spaghetti, args1(
    seed = 123, alpha = 0.05, linewidth = 2, nsim = 10L
  ))
  expect_equal(out1_custom[[1]]$aes_params$alpha, 0.05)
  expect_equal(out1_custom[[2]]$aes_params$linewidth, 2)
  expect_equal(length(unique(out1_custom[[1]]$data$sim_id)), 10)
})


test_that("er_style_model_spaghetti does not warn about unused fill aesthetic", {
  mod2 <- er_test_toy_model(ae1 ~ aucss + sex, er_test_data, family = binomial())

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  p1 <- p1 |> er_plot_add_model(er_test_mod1, style = er_style_model_spaghetti)
  p2 <- p2 |> er_plot_add_model(mod2, style = er_style_model_spaghetti)

  args1 <- list(
    data = p1$data,
    config = p1$layer$model$config,
    stratify = p1$layer$model$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )
  args2 <- list(
    data = p2$data,
    config = p2$layer$model$config,
    stratify = p2$layer$model$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    theme = p2$theme
  )

  expect_no_warning(do.call(er_style_model_spaghetti, args1))
  expect_no_warning(do.call(er_style_model_spaghetti, args2))

  # Also check at render time, since `fill` being unused by `geom_path()`
  # would otherwise surface as a warning during `ggplot_build()`.
  expect_no_warning(plot(p1))
  expect_no_warning(plot(p2))
})

test_that("er_style_model_spaghetti falls back to ribbonline when er_simulate is unavailable", {
  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_model(er_test_mod1)

  config <- p1$layer$model$config
  config$model <- structure(list(), class = "no_simulate_method")

  args1 <- list(
    data = p1$data,
    config = config,
    stratify = p1$layer$model$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )

  expect_message(p1_out <- do.call(er_style_model_spaghetti, args1))
  expect_length(p1_out, 2)
  expect_true(inherits(p1_out[[1]], "LayerInstance"))
})

test_that("er_style_model_spaghetti's fallback to ribbonline forwards linewidth", {
  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_model(er_test_mod1)

  config <- p1$layer$model$config
  config$model <- structure(list(), class = "no_simulate_method")

  args1 <- list(
    data = p1$data,
    config = config,
    stratify = p1$layer$model$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )

  p1_out <- suppressMessages(do.call(er_style_model_spaghetti, c(args1, list(linewidth = 3))))
  expect_length(p1_out, 2)
  expect_equal(p1_out[[2]]$aes_params$linewidth, 3)
})
