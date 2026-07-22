
# `...` passthrough from `er_plot_add_*()` to `er_style_*()` builders -------
#
# See `?er_style`'s "Passing extra arguments to a builder" section. Each
# test below plugs in a small stub builder that records the `...` it
# received (via an environment, since a builder's return value has to be
# geoms/a list of geoms) and checks that the extra named argument reached
# it unchanged.

test_that("er_plot_add_model() forwards `...` identically to style and summary_style", {
  skip_if_not_installed("erglm")

  seen <- new.env()
  stub_style <- function(data, config, stratify, exposure, response, strata, theme, ...) {
    seen$style_dots <- rlang::list2(...)
    list()
  }
  stub_summary <- function(data, config, stratify, exposure, response, strata, theme, ...) {
    seen$summary_dots <- rlang::list2(...)
    list()
  }

  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1, style = stub_style, summary_style = stub_summary, seed = 9626)

  expect_no_error(er_plot_build(plt))
  expect_equal(seen$style_dots, list(seed = 9626))
  expect_equal(seen$summary_dots, list(seed = 9626))
})

test_that("er_plot_add_quantiles() forwards `...` to style", {
  skip_if_not_installed("erglm")

  seen <- new.env()
  stub_style <- er_style_tag(
    function(data, config, stratify, exposure, response, strata, theme, ...) {
      seen$dots <- rlang::list2(...)
      list()
    },
    layer = "quantile"
  )

  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_quantiles(style = stub_style, digits = 2)

  expect_no_error(er_plot_build(plt))
  expect_equal(seen$dots, list(digits = 2))
})

test_that("er_plot_add_data() forwards `...` to style, for both the overlay and panel structural families", {
  skip_if_not_installed("erglm")

  seen <- new.env()
  stub_overlay <- er_style_tag(
    function(data, config, stratify, exposure, response, strata, theme, ...) {
      seen$overlay_dots <- rlang::list2(...)
      list()
    },
    layout = "overlay"
  )
  stub_panel <- er_style_tag(
    function(data, config, stratify, exposure, response, strata, theme, ...) {
      seen$panel_dots <- rlang::list2(...)
      list()
    },
    layout = "panel"
  )

  plt_overlay <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_data(style = stub_overlay, alpha = 0.2)
  expect_no_error(er_plot_build(plt_overlay))
  expect_equal(seen$overlay_dots, list(alpha = 0.2))

  plt_panel <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_data(style = stub_panel, alpha = 0.2)
  expect_no_error(er_plot_build(plt_panel))
  expect_equal(seen$panel_dots, list(alpha = 0.2))
})

test_that("er_plot_add_groups() forwards `...` to style, identically for every grouping variable", {
  skip_if_not_installed("erglm")

  seen <- new.env()
  stub_style <- function(data, config, stratify, exposure, response, strata, theme, ...) {
    seen[[config$y$name]] <- rlang::list2(...)
    list()
  }

  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_groups(c(aucss, treatment), style = stub_style, width = 0.5)

  expect_no_error(er_plot_build(plt))
  expect_equal(seen[[".aucss_quantile"]], list(width = 0.5))
  expect_equal(seen[["treatment"]], list(width = 0.5))
})

test_that("er_plot_add_*() error on an unnamed extra argument", {
  skip_if_not_installed("erglm")

  plt <- er_test_data |> er_plot(aucss, ae1)
  plt_mod <- plt |> er_plot_add_model(er_test_mod1)

  # supply a value (named or positional) for every standard formal so the
  # final, deliberately unnamed value actually lands in `...` rather than
  # being positionally matched to a standard argument
  expect_error(
    er_plot_add_model(plt, er_test_mod1, NULL, NULL, NULL, 0.95, 9626)
  )
  expect_error(
    er_plot_add_quantiles(plt_mod, NULL, NULL, 4, 0.95, 4)
  )
  expect_error(
    er_plot_add_data(plt_mod, NULL, NULL, "both", "overlay")
  )
  expect_error(
    er_plot_add_groups(plt_mod, aucss, NULL, NULL, NULL, 4)
  )
})

test_that("er_style_model_spaghetti() prefers a `seed` passed via `...` over `config$seed`", {
  skip_if_not_installed("erglm")

  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_model(er_test_mod1, style = er_style_model_spaghetti, seed = 9626)

  args <- list(
    data = plt$data,
    config = plt$layer$model$config,
    stratify = plt$layer$model$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata = plt$strata,
    theme = plt$theme,
    seed = 9626
  )

  # `config$seed` is NULL for the model layer -- the `seed` supplied via
  # `...` is what actually reaches `er_simulate()`, so two calls with the
  # same `seed` produce identical simulated draws
  out1 <- do.call(er_style_model_spaghetti, args)
  out2 <- do.call(er_style_model_spaghetti, args)
  expect_identical(out1[[1]]$data, out2[[1]]$data)
})

test_that("a builder that doesn't declare `...` in its signature errors when extra arguments are supplied", {
  skip_if_not_installed("erglm")

  old_style <- function(data, config, stratify, exposure, response, strata, theme) list()

  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1, style = old_style, seed = 9626)

  expect_error(er_plot_build(plt), "unused argument")
})
