# .clip_to_limits() / .clip_quantile_summary_to_limits() -----------------
#
# Unit tests for the shared filtering/warning helpers, plus integration
# tests confirming every affected layer (data overlay/panel, group,
# quantile) actually wires them in at build time. See PR discussion for
# #14's follow-on: unlike the model layer (a synthetic grid, regenerated
# exactly within limits), these layers plot/summarise genuine
# observations that can extend beyond a narrowed `xlim`/`ylim`.

test_that(".clip_to_limits() drops out-of-range rows and warns with a correct count", {
  df <- data.frame(x = c(-5, 0, 50, 100, 150), y = c(1, 2, 3, 4, 5))

  expect_warning(
    out <- .clip_to_limits(df, "x", c(0, 100), layer_label = "widgets"),
    "2 of 5 widgets \\(40%\\) fall outside the plotted axis limits and are not shown"
  )
  expect_equal(out$x, c(0, 50, 100))
})

test_that(".clip_to_limits() keeps boundary values and doesn't warn when nothing is dropped", {
  df <- data.frame(x = c(0, 50, 100))
  expect_no_warning(out <- .clip_to_limits(df, "x", c(0, 100), layer_label = "widgets"))
  expect_equal(nrow(out), 3)
})

test_that(".clip_to_limits() leaves existing NAs alone (not counted as out of range)", {
  df <- data.frame(x = c(NA, 50, 200))
  expect_warning(out <- .clip_to_limits(df, "x", c(0, 100), layer_label = "widgets"), "1 of 3")
  expect_equal(nrow(out), 2)
  expect_true(is.na(out$x[1]))
})

test_that(".clip_to_limits() also filters on response_name/response_limits when supplied", {
  df <- data.frame(x = c(10, 10, 10), y = c(-5, 0, 5))
  expect_warning(
    out <- .clip_to_limits(df, "x", c(0, 100), "y", c(0, 10), layer_label = "widgets"),
    "1 of 3"
  )
  expect_equal(out$y, c(0, 5))
})

test_that(".clip_quantile_summary_to_limits() drops out-of-range bin markers, names them, and warns", {
  summary <- data.frame(
    exposure_bins = factor(c("Placebo", "Q1", "Q2", "Q3"), levels = c("Placebo", "Q1", "Q2", "Q3")),
    x_mid = c(0, 50, 600, 1200),
    y_mid = c(0.1, 0.3, 0.5, 0.7)
  )
  expect_warning(
    out <- .clip_quantile_summary_to_limits(summary, c(0, 100), c(0, 1)),
    "2 of 4 quantile bin markers fall outside the plotted axis limits and are not shown: Q2, Q3"
  )
  expect_equal(as.character(out$exposure_bins), c("Placebo", "Q1"))
})

test_that(".clip_quantile_summary_to_limits() doesn't warn when every marker is in range", {
  summary <- data.frame(exposure_bins = factor(c("Q1", "Q2")), x_mid = c(10, 20), y_mid = c(0.1, 0.2))
  expect_no_warning(out <- .clip_quantile_summary_to_limits(summary, c(0, 100), c(0, 1)))
  expect_equal(nrow(out), 2)
})

test_that(".clip_quantile_breaks_to_limits() drops out-of-range breaks, names them, and warns", {
  expect_warning(
    out <- .clip_quantile_breaks_to_limits(c(0, 50, 600, 1200), c(0, 100)),
    "2 of 4 quantile-bin boundary lines fall outside the plotted axis limits and are not shown: 600, 1,200"
  )
  expect_equal(out, c(0, 50))
})

test_that(".clip_quantile_breaks_to_limits() doesn't warn when every break is in range", {
  expect_no_warning(out <- .clip_quantile_breaks_to_limits(c(0, 50, 100), c(0, 100)))
  expect_equal(out, c(0, 50, 100))
})

test_that(".clip_quantile_breaks_to_limits() is a no-op on NULL breaks", {
  expect_null(.clip_quantile_breaks_to_limits(NULL, c(0, 100)))
})

# integration: data overlay layer -----------------------------------------

test_that("er_plot_build() drops out-of-window data-overlay points and warns, keyed to current xlim", {
  plt <- er_test_data |>
    er_plot(aucss, biomarker_change) |>
    er_plot_add_data() |>
    er_plot_theme(xlim = c(0, 100))

  expect_warning(built <- er_plot_build(plt), "data-overlay observations")

  n_out_of_range <- sum(er_test_data$aucss < 0 | er_test_data$aucss > 100)
  gb <- ggplot2::ggplot_build(built$output)
  point_layer <- which(vapply(gb$plot$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1)))[1]
  expect_equal(nrow(gb$data[[point_layer]]), nrow(er_test_data) - n_out_of_range)
})

test_that("er_plot_build() does not warn about the data-overlay layer when xlim covers the full data range", {
  plt <- er_test_data |>
    er_plot(aucss, biomarker_change) |>
    er_plot_add_data()

  expect_no_warning(er_plot_build(plt))
})

# integration: data panel layer (boxjitter) --------------------------------

test_that("er_plot_build() drops out-of-window rows for a panel-layout data builder and warns", {
  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_data(style = er_style_data_boxjitter) |>
    er_plot_theme(xlim = c(0, 100))

  expect_warning(er_plot_build(plt), "data-panel observations")
})

# integration: group layer -------------------------------------------------

test_that("er_plot_build() drops out-of-window rows for a group panel and warns", {
  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_groups(aucss) |>
    er_plot_theme(xlim = c(0, 100))

  expect_warning(built <- er_plot_build(plt), "group panel.*observations")

  n_out_of_range <- sum(er_test_data$aucss < 0 | er_test_data$aucss > 100)
  # the boxplot geom's own *pre-stat* data (before ggplot aggregates it
  # into one summary row per group) reflects the row-level filtering
  raw_layer_data <- built$plot$group[[1]]$layers[[1]]$data
  expect_equal(nrow(raw_layer_data), nrow(er_test_data) - n_out_of_range)
})

test_that("er_plot_build() does not warn about the group layer when xlim covers the full data range", {
  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_groups(aucss)

  expect_no_warning(er_plot_build(plt))
})

# integration: quantile layer -----------------------------------------------

test_that("er_plot_build() hides out-of-window quantile bin markers, warns, but leaves their statistics unchanged", {
  # `.build_quantile_geoms()` filters a local copy of `config$summary`
  # before handing it to the style builder -- the object returned by
  # `er_plot_build()` still carries the unfiltered `config$summary`
  # (mirroring every other layer's config, which also isn't mutated in
  # place), so what's actually asserted on here is the *rendered* geom
  # data, not `built$layer$quantile$config`.
  plt_wide <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_quantiles(bins = 4)
  built_wide <- er_plot_build(plt_wide)
  gb_wide <- ggplot2::ggplot_build(built_wide$output)
  point_layer_wide <- which(vapply(gb_wide$plot$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1)))
  full_points <- gb_wide$data[[point_layer_wide]]
  expect_equal(nrow(full_points), 5) # Placebo + 4 quantile bins

  plt_narrow <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_quantiles(bins = 4) |>
    er_plot_theme(xlim = c(0, 100))

  expect_warning(built_narrow <- er_plot_build(plt_narrow), "quantile bin marker")

  gb_narrow <- ggplot2::ggplot_build(built_narrow$output)
  point_layer_narrow <- which(vapply(gb_narrow$plot$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1)))
  narrow_points <- gb_narrow$data[[point_layer_narrow]]

  # only the Placebo bin (x_mid = 0) sits inside xlim = c(0, 100)
  expect_equal(nrow(narrow_points), 1)
  expect_equal(narrow_points$y, full_points$y[full_points$x == 0])
})

test_that("er_plot_build() hides out-of-window quantile-bin boundary vlines and warns", {
  plt_wide <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_quantiles(bins = 4, style = er_style_quantile_errorbar_vlines)
  built_wide <- er_plot_build(plt_wide)
  gb_wide <- ggplot2::ggplot_build(built_wide$output)
  vline_layer_wide <- which(vapply(gb_wide$plot$layers, function(l) inherits(l$geom, "GeomVline"), logical(1)))
  full_vlines <- gb_wide$data[[vline_layer_wide]]
  expect_equal(nrow(full_vlines), 5) # Placebo + 4 quantile-bin boundaries

  # `config$breaks` for `aucss` (4 bins, excluding placebo) sit near
  # 163/478/881/1638/3723; narrowing to `xlim = c(0, 300)` keeps only the
  # first.
  plt_narrow <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_quantiles(bins = 4, style = er_style_quantile_errorbar_vlines) |>
    er_plot_theme(xlim = c(0, 300))

  expect_warning(built_narrow <- er_plot_build(plt_narrow), "quantile-bin boundary line")

  gb_narrow <- ggplot2::ggplot_build(built_narrow$output)
  vline_layer_narrow <- which(vapply(gb_narrow$plot$layers, function(l) inherits(l$geom, "GeomVline"), logical(1)))
  narrow_vlines <- gb_narrow$data[[vline_layer_narrow]]

  expect_equal(nrow(narrow_vlines), 1)
  expect_equal(narrow_vlines$xintercept, full_vlines$xintercept[1])
})

test_that("er_plot_build() does not warn about the quantile layer when every bin marker is in range", {
  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_quantiles(bins = 4)

  expect_no_warning(er_plot_build(plt))
})
