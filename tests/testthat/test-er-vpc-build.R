# .clip_vpc_config_to_limits() ------------------------------------------
#
# The VPC analogue of `.clip_to_limits()`/`.clip_quantile_summary_to_limits()`
# (see test-er-plot-build.R and issue #17): `er_vpc_theme(xlim = )`/
# `ylim = )` is purely cosmetic (it never touches the bin/percentile
# computations), but `.build_vpc_plot()`'s `coord_cartesian(clip = "off")`
# meant a narrowed window used to let an out-of-range summary/percentile
# marker bleed silently past the panel border. These tests cover the
# helper directly, plus every built-in VPC idiom at build time.

test_that(".clip_vpc_config_to_limits() is a no-op when neither xlim nor ylim is set", {
  config <- list(
    style = er_style_vpc_observed_mean_errorbar,
    is_numeric_group = TRUE,
    summary = data.frame(
      .vpc_bin = factor(c("Q1", "Q2")), .vpc_stratum = c(1, 1),
      x_mid = c(10, 20), x_median = c(10, 20), y_mid = c(0.1, 5)
    )
  )
  out <- .clip_vpc_config_to_limits(config, NULL, NULL, "observed")
  expect_identical(out, config)
})

test_that(".clip_vpc_config_to_limits() drops out-of-range summary markers for a marker_source = 'summary' style", {
  config <- list(
    style = er_style_vpc_observed_mean_errorbar,
    is_numeric_group = TRUE,
    summary = data.frame(
      .vpc_bin = factor(c("Q1", "Q2", "Q3")), .vpc_stratum = c(1, 1, 1),
      x_mid = c(10, 20, 30), x_median = c(10, 20, 30), y_mid = c(0.1, 5, 0.2)
    )
  )
  expect_warning(
    out <- .clip_vpc_config_to_limits(config, NULL, c(0, 1), "observed"),
    "1 of 3 observed VPC marker falls outside the plotted axis limits and is not shown: Q2"
  )
  expect_equal(as.character(out$summary$.vpc_bin), c("Q1", "Q3"))
})

test_that(".clip_vpc_config_to_limits() never touches config$percentiles for a marker_source = 'summary' style", {
  config <- list(
    style = er_style_vpc_observed_mean_errorbar,
    is_numeric_group = TRUE,
    summary = data.frame(
      .vpc_bin = factor("Q1"), .vpc_stratum = 1, x_mid = 10, x_median = 10, y_mid = 0.1
    ),
    percentiles = data.frame(
      .vpc_bin = factor("Q1"), .vpc_stratum = 1, x_mid = 10, x_median = 10,
      prob = 0.5, y = 999, ci_lower = 990, ci_upper = 1000
    )
  )
  out <- .clip_vpc_config_to_limits(config, NULL, c(0, 1), "observed")
  expect_equal(nrow(out$percentiles), 1) # left untouched, despite y = 999 being far outside ylim
})

test_that(".clip_vpc_config_to_limits() drops out-of-range percentile markers for a marker_source = 'percentiles' style, naming bin and prob", {
  config <- list(
    style = er_style_vpc_observed_quantile_line,
    is_numeric_group = TRUE,
    summary = data.frame(.vpc_bin = factor("Q1"), .vpc_stratum = 1, x_mid = 10, x_median = 10, y_mid = 999),
    percentiles = data.frame(
      .vpc_bin = factor(c("Q1", "Q1")), .vpc_stratum = c(1, 1),
      x_mid = c(10, 10), x_median = c(10, 10),
      prob = c(0.1, 0.9), y = c(0.2, 5), ci_lower = c(0.1, 4), ci_upper = c(0.3, 6)
    )
  )
  expect_warning(
    out <- .clip_vpc_config_to_limits(config, NULL, c(0, 1), "observed"),
    "Q1 \\(p0\\.9\\)"
  )
  expect_equal(nrow(out$percentiles), 1)
  expect_equal(out$percentiles$prob, 0.1)
  expect_equal(nrow(out$summary), 1) # untouched despite y_mid = 999 being out of range
})

test_that(".clip_vpc_config_to_limits() checks both tables for an untagged custom style", {
  untagged_style <- function(...) NULL # no er_style_tag() at all
  config <- list(
    style = untagged_style,
    is_numeric_group = TRUE,
    summary = data.frame(.vpc_bin = factor("Q1"), .vpc_stratum = 1, x_mid = 10, x_median = 10, y_mid = 999),
    percentiles = data.frame(
      .vpc_bin = factor("Q1"), .vpc_stratum = 1, x_mid = 10, x_median = 10,
      prob = 0.5, y = 999, ci_lower = 990, ci_upper = 1000
    )
  )
  warnings <- testthat::capture_warnings(out <- .clip_vpc_config_to_limits(config, NULL, c(0, 1), "observed"))
  expect_length(warnings, 2)
  expect_equal(nrow(out$summary), 0)
  expect_equal(nrow(out$percentiles), 0)
})

test_that(".clip_vpc_config_to_limits() never filters a categorical plot_by's discrete bin position on xlim", {
  config <- list(
    style = er_style_vpc_observed_mean_errorbar,
    is_numeric_group = FALSE,
    summary = data.frame(
      .vpc_bin = factor(c("A", "B")), .vpc_stratum = c(1, 1),
      x_mid = c(NA, NA), x_median = c(NA, NA), y_mid = c(0.1, 0.2)
    )
  )
  out <- .clip_vpc_config_to_limits(config, c(0, 1), NULL, "observed")
  expect_equal(nrow(out$summary), 2) # xlim is meaningless for a discrete `.vpc_bin`, so nothing is dropped
})

# integration: built-in idioms at build time -------------------------------

test_that("er_vpc_build() crops and warns about out-of-range mean/errorbar markers, keyed to current ylim", {
  vpc <- er_test_data |>
    er_vpc(aucss, ae1, response_type = "binary") |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 9411) |>
    er_vpc_theme(ylim = c(0.4, 0.6))

  expect_warning(built <- er_vpc_build(vpc), "VPC marker")
  gb <- ggplot2::ggplot_build(built$output)
  point_layers <- which(vapply(gb$plot$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1)))
  for (ii in point_layers) {
    expect_true(all(gb$data[[ii]]$y >= 0.4 & gb$data[[ii]]$y <= 0.6))
  }
})

test_that("er_vpc_build() crops and warns about out-of-range quantile-errorbar markers only, not summary", {
  vpc <- er_test_data |>
    er_vpc(aucss, biomarker_change, response_type = "continuous") |>
    er_vpc_add_observed(style = er_style_vpc_observed_quantile_errorbar) |>
    er_vpc_add_simulated(model = er_test_mod_gaussian, nsim = 5, seed = 9412, style = er_style_vpc_simulated_quantile_errorbar) |>
    er_vpc_theme(ylim = c(-1, 1))

  expect_warning(built <- er_vpc_build(vpc), "\\(p0\\.")
  gb <- ggplot2::ggplot_build(built$output)
  point_layers <- which(vapply(gb$plot$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1)))
  for (ii in point_layers) {
    expect_true(all(gb$data[[ii]]$y >= -1 & gb$data[[ii]]$y <= 1))
  }
})

test_that("er_vpc_build() crops and warns about out-of-range quantile-line/ribbon markers", {
  vpc <- er_test_data |>
    er_vpc(aucss, biomarker_change, response_type = "continuous") |>
    er_vpc_add_observed(style = er_style_vpc_observed_quantile_line) |>
    er_vpc_add_simulated(model = er_test_mod_gaussian, nsim = 5, seed = 9413, style = er_style_vpc_simulated_quantile_ribbon) |>
    er_vpc_theme(ylim = c(-1, 1))

  expect_warning(built <- er_vpc_build(vpc), "VPC marker")
  gb <- ggplot2::ggplot_build(built$output)
  point_layers <- which(vapply(gb$plot$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1)))
  for (ii in point_layers) {
    expect_true(all(gb$data[[ii]]$y >= -1 & gb$data[[ii]]$y <= 1))
  }
})

test_that("er_vpc_build() does not warn when xlim/ylim aren't narrowed past the data", {
  vpc <- er_test_data |>
    er_vpc(aucss, ae1, response_type = "binary") |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 9414)

  expect_no_warning(er_vpc_build(vpc))
})

test_that("er_vpc_build() with a categorical plot_by only filters on ylim, never xlim", {
  vpc <- er_test_data |>
    er_vpc(aucss, biomarker_change, response_type = "continuous", plot_by = treatment) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod_gaussian, nsim = 5, seed = 9415) |>
    er_vpc_theme(ylim = c(-1, 1))

  expect_warning(built <- er_vpc_build(vpc), "VPC marker")
  expect_true(ggplot2::is_ggplot(built$output))
})
