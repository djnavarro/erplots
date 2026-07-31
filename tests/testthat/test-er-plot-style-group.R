test_that("er_style_group_boxplot returns geom + coord", {
  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_add_groups(treatment))
  expect_no_error(p2 |> er_plot_add_groups(treatment))

  p1 <- p1 |> er_plot_add_groups(treatment)
  p2 <- p2 |> er_plot_add_groups(treatment)

  args1 <- list(
    data = p1$data,
    config = p1$layer$group$config[[1]],
    stratify = p1$layer$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )
  args2 <- list(
    data = p2$data,
    config = p2$layer$group$config[[1]],
    stratify = p2$layer$group$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    theme = p2$theme
  )

  expect_no_error(do.call(er_style_group_boxplot, args1))
  expect_no_error(do.call(er_style_group_boxplot, args2))

  p1_out <- do.call(er_style_group_boxplot, args1)
  p2_out <- do.call(er_style_group_boxplot, args2)

  expect_length(p1_out, 2)
  expect_length(p2_out, 2)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "CoordCartesian"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "CoordCartesian"))
})


test_that("er_style_group_histogram returns geom + facet + coord", {
  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_add_groups(treatment, style = er_style_group_histogram))
  expect_no_error(p2 |> er_plot_add_groups(treatment, style = er_style_group_histogram))

  p1 <- p1 |> er_plot_add_groups(treatment, style = er_style_group_histogram)
  p2 <- p2 |> er_plot_add_groups(treatment, style = er_style_group_histogram)

  args1 <- list(
    data = p1$data,
    config = p1$layer$group$config[[1]],
    stratify = p1$layer$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )
  args2 <- list(
    data = p2$data,
    config = p2$layer$group$config[[1]],
    stratify = p2$layer$group$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    theme = p2$theme
  )

  expect_no_error(do.call(er_style_group_histogram, args1))
  expect_no_error(do.call(er_style_group_histogram, args2))

  p1_out <- do.call(er_style_group_histogram, args1)
  p2_out <- do.call(er_style_group_histogram, args2)

  expect_length(p1_out, 4)
  expect_length(p2_out, 4)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "Facet"))
  expect_true(inherits(p1_out[[3]], "CoordCartesian"))
  expect_true(inherits(p1_out[[4]], "theme"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "Facet"))
  expect_true(inherits(p2_out[[3]], "CoordCartesian"))
  expect_true(inherits(p2_out[[4]], "theme"))
})

test_that("er_style_group_histogram rotates strip text to avoid clipping long level labels", {
  p1 <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_groups(treatment, style = er_style_group_histogram)

  args1 <- list(
    data = p1$data,
    config = p1$layer$group$config[[1]],
    stratify = p1$layer$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )

  p1_out <- do.call(er_style_group_histogram, args1)
  strip_theme <- p1_out[[4]]
  expect_equal(strip_theme$strip.text.y.left$angle, 0)
})

test_that("er_plot_add_groups() builds and renders with style = er_style_group_histogram", {
  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_groups(treatment, style = er_style_group_histogram)

  expect_no_error(er_plot_build(plt))
})


test_that("er_style_group_violin returns geom + coord", {
  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_add_groups(treatment, style = er_style_group_violin))
  expect_no_error(p2 |> er_plot_add_groups(treatment, style = er_style_group_violin))

  p1 <- p1 |> er_plot_add_groups(treatment, style = er_style_group_violin)
  p2 <- p2 |> er_plot_add_groups(treatment, style = er_style_group_violin)

  args1 <- list(
    data = p1$data,
    config = p1$layer$group$config[[1]],
    stratify = p1$layer$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )
  args2 <- list(
    data = p2$data,
    config = p2$layer$group$config[[1]],
    stratify = p2$layer$group$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    theme = p2$theme
  )

  expect_no_error(do.call(er_style_group_violin, args1))
  expect_no_error(do.call(er_style_group_violin, args2))

  p1_out <- do.call(er_style_group_violin, args1)
  p2_out <- do.call(er_style_group_violin, args2)

  expect_length(p1_out, 2)
  expect_length(p2_out, 2)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "CoordCartesian"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "CoordCartesian"))
})

# ---- new arguments: alpha, bins, quantiles/quantile_linetype ----

test_that("er_style_group_boxplot() alpha argument overrides the default 0.5", {
  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_groups(treatment)
  args <- list(
    data     = p1$data,
    config   = p1$layer$group$config[[1]],
    stratify = p1$layer$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata   = p1$strata,
    theme    = p1$theme
  )

  out_default <- do.call(er_style_group_boxplot, args)
  out_custom  <- do.call(er_style_group_boxplot, c(args, list(alpha = 0.1)))

  expect_equal(out_default[[1]]$aes_params$alpha, 0.5)
  expect_equal(out_custom[[1]]$aes_params$alpha, 0.1)
})

test_that("er_style_group_violin() alpha argument overrides the default 0.5", {
  p1 <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_groups(treatment, style = er_style_group_violin)
  args <- list(
    data     = p1$data,
    config   = p1$layer$group$config[[1]],
    stratify = p1$layer$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata   = p1$strata,
    theme    = p1$theme
  )

  out_default <- do.call(er_style_group_violin, args)
  out_custom  <- do.call(er_style_group_violin, c(args, list(alpha = 0.2)))

  expect_equal(out_default[[1]]$aes_params$alpha, 0.5)
  expect_equal(out_custom[[1]]$aes_params$alpha, 0.2)
})

test_that("er_style_group_violin() quantiles argument maps to draw_quantiles", {
  p1 <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_groups(treatment, style = er_style_group_violin)
  args <- list(
    data     = p1$data,
    config   = p1$layer$group$config[[1]],
    stratify = p1$layer$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata   = p1$strata,
    theme    = p1$theme
  )

  out_default <- do.call(er_style_group_violin, args)
  out_custom  <- do.call(er_style_group_violin,
                         c(args, list(quantiles = c(0.25, 0.5, 0.75),
                                      quantile_linetype = "dashed")))

  # default: no quantile lines
  expect_true(is.null(out_default[[1]]$stat_params$quantiles))

  # custom: quantile lines at the specified probabilities, with the given linetype
  expect_equal(out_custom[[1]]$stat_params$quantiles, c(0.25, 0.5, 0.75))
  expect_equal(out_custom[[1]]$geom_params$quantile_gp$linetype, "dashed")
})

test_that("er_style_group_histogram() bins argument overrides the default 30", {
  p1 <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_groups(treatment, style = er_style_group_histogram)
  args <- list(
    data     = p1$data,
    config   = p1$layer$group$config[[1]],
    stratify = p1$layer$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata   = p1$strata,
    theme    = p1$theme
  )

  out_default <- do.call(er_style_group_histogram, args)
  out_custom  <- do.call(er_style_group_histogram, c(args, list(bins = 15)))

  expect_equal(out_default[[1]]$stat_params$bins, 30)
  expect_equal(out_custom[[1]]$stat_params$bins, 15)
})

test_that("er_style_group_histogram() alpha = NULL gives conditional default; explicit alpha overrides", {
  p1 <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_groups(treatment, style = er_style_group_histogram)
  p2 <- er_plot(er_test_data, aucss, ae1, sex) |>
    er_plot_add_groups(treatment, style = er_style_group_histogram)

  args <- function(p) list(
    data     = p$data,
    config   = p$layer$group$config[[1]],
    stratify = p$layer$group$stratify,
    exposure = p$exposure,
    response = p$response,
    strata   = p$strata,
    theme    = p$theme
  )

  # alpha = NULL (default): 0.8 unstratified, 0.5 stratified
  out_unstrat <- do.call(er_style_group_histogram, args(p1))
  out_strat   <- do.call(er_style_group_histogram, args(p2))
  expect_equal(out_unstrat[[1]]$aes_params$alpha, 0.8)
  expect_equal(out_strat[[1]]$aes_params$alpha, 0.5)

  # explicit alpha overrides regardless of stratification
  out_custom <- do.call(er_style_group_histogram, c(args(p1), list(alpha = 0.3)))
  expect_equal(out_custom[[1]]$aes_params$alpha, 0.3)
})

# ---- er_style_group_linerange ----

test_that("er_style_group_linerange returns three geoms + coord", {
  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_add_groups(treatment, style = er_style_group_linerange))
  expect_no_error(p2 |> er_plot_add_groups(treatment, style = er_style_group_linerange))

  p1 <- p1 |> er_plot_add_groups(treatment, style = er_style_group_linerange)
  p2 <- p2 |> er_plot_add_groups(treatment, style = er_style_group_linerange)

  args1 <- list(
    data = p1$data,
    config = p1$layer$group$config[[1]],
    stratify = p1$layer$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )
  args2 <- list(
    data = p2$data,
    config = p2$layer$group$config[[1]],
    stratify = p2$layer$group$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    theme = p2$theme
  )

  p1_out <- do.call(er_style_group_linerange, args1)
  p2_out <- do.call(er_style_group_linerange, args2)

  expect_length(p1_out, 4)
  expect_length(p2_out, 4)

  expect_true(all(vapply(p1_out[1:3], inherits, logical(1), "LayerInstance")))
  expect_true(inherits(p1_out[[4]], "CoordCartesian"))

  expect_true(all(vapply(p2_out[1:3], inherits, logical(1), "LayerInstance")))
  expect_true(inherits(p2_out[[4]], "CoordCartesian"))
})

test_that("er_style_group_linerange() computes correct median/quantile values", {
  p1 <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_groups(treatment, style = er_style_group_linerange)
  args1 <- list(
    data = p1$data,
    config = p1$layer$group$config[[1]],
    stratify = p1$layer$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )

  p1_out <- do.call(er_style_group_linerange, args1)
  dot_data <- p1_out[[3]]$data
  drug_row <- dot_data[dot_data$lvl == "Drug (N=200)", ]

  drug_aucss <- er_test_data$aucss[er_test_data$treatment == "Drug"]
  expect_equal(drug_row$med, stats::median(drug_aucss))
  expect_equal(drug_row$inner_lo, unname(stats::quantile(drug_aucss, 0.25)))
  expect_equal(drug_row$inner_hi, unname(stats::quantile(drug_aucss, 0.75)))
  expect_equal(drug_row$outer_lo, unname(stats::quantile(drug_aucss, 0.05)))
  expect_equal(drug_row$outer_hi, unname(stats::quantile(drug_aucss, 0.95)))
})

test_that("er_style_group_linerange() size argument scales dot/line sizes together", {
  p1 <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_groups(treatment, style = er_style_group_linerange)
  args <- list(
    data     = p1$data,
    config   = p1$layer$group$config[[1]],
    stratify = p1$layer$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata   = p1$strata,
    theme    = p1$theme
  )

  out_default <- do.call(er_style_group_linerange, args)
  out_double  <- do.call(er_style_group_linerange, c(args, list(size = 2)))

  expect_equal(out_double[[1]]$aes_params$linewidth, out_default[[1]]$aes_params$linewidth * 2)
  expect_equal(out_double[[2]]$aes_params$linewidth, out_default[[2]]$aes_params$linewidth * 2)
  expect_equal(out_double[[3]]$aes_params$size, out_default[[3]]$aes_params$size * 2)
})

test_that("er_style_group_linerange() alpha_dot/alpha_inner/alpha_outer override defaults", {
  p1 <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_groups(treatment, style = er_style_group_linerange)
  args <- list(
    data     = p1$data,
    config   = p1$layer$group$config[[1]],
    stratify = p1$layer$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata   = p1$strata,
    theme    = p1$theme
  )

  out_default <- do.call(er_style_group_linerange, args)
  expect_equal(out_default[[1]]$aes_params$alpha, 0.4)
  expect_equal(out_default[[2]]$aes_params$alpha, 0.8)
  expect_equal(out_default[[3]]$aes_params$alpha, 1)

  out_custom <- do.call(er_style_group_linerange, c(args, list(
    alpha_dot = 0.9, alpha_inner = 0.6, alpha_outer = 0.2
  )))
  expect_equal(out_custom[[1]]$aes_params$alpha, 0.2)
  expect_equal(out_custom[[2]]$aes_params$alpha, 0.6)
  expect_equal(out_custom[[3]]$aes_params$alpha, 0.9)
})

test_that("er_style_group_linerange() validates inner_range/outer_range", {
  p1 <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_groups(treatment, style = er_style_group_linerange, inner_range = c(0.75, 0.25))
  expect_error(er_plot_build(p1), "inner_range")

  p2 <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_groups(treatment, style = er_style_group_linerange, outer_range = c(-0.1, 0.9))
  expect_error(er_plot_build(p2), "outer_range")
})

test_that("er_plot_add_groups() builds and renders with style = er_style_group_linerange", {
  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_groups(treatment, style = er_style_group_linerange)

  expect_no_error(er_plot_build(plt))

  plt_strat <- er_test_data |>
    er_plot(aucss, ae1, sex) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_groups(treatment, style = er_style_group_linerange)

  expect_no_error(er_plot_build(plt_strat))
})

# ---- er_style_group_boxjitter / er_style_group_violinjitter ----

test_that("er_style_group_boxjitter returns boxplot geoms + jitter geom + coord", {
  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_add_groups(treatment, style = er_style_group_boxjitter))
  expect_no_error(p2 |> er_plot_add_groups(treatment, style = er_style_group_boxjitter))

  p1 <- p1 |> er_plot_add_groups(treatment, style = er_style_group_boxjitter)
  p2 <- p2 |> er_plot_add_groups(treatment, style = er_style_group_boxjitter)

  args1 <- list(
    data = p1$data,
    config = p1$layer$group$config[[1]],
    stratify = p1$layer$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )
  args2 <- list(
    data = p2$data,
    config = p2$layer$group$config[[1]],
    stratify = p2$layer$group$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    theme = p2$theme
  )

  p1_out <- do.call(er_style_group_boxjitter, args1)
  p2_out <- do.call(er_style_group_boxjitter, args2)

  # boxplot geom + coord (from er_style_group_boxplot()) + jitter geom
  expect_length(p1_out, 3)
  expect_length(p2_out, 3)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "CoordCartesian"))
  expect_true(inherits(p1_out[[3]], "LayerInstance"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "CoordCartesian"))
  expect_true(inherits(p2_out[[3]], "LayerInstance"))
})

test_that("er_style_group_violinjitter returns violin geoms + jitter geom + coord", {
  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_add_groups(treatment, style = er_style_group_violinjitter))
  expect_no_error(p2 |> er_plot_add_groups(treatment, style = er_style_group_violinjitter))

  p1 <- p1 |> er_plot_add_groups(treatment, style = er_style_group_violinjitter)
  p2 <- p2 |> er_plot_add_groups(treatment, style = er_style_group_violinjitter)

  args1 <- list(
    data = p1$data,
    config = p1$layer$group$config[[1]],
    stratify = p1$layer$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )
  args2 <- list(
    data = p2$data,
    config = p2$layer$group$config[[1]],
    stratify = p2$layer$group$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    theme = p2$theme
  )

  p1_out <- do.call(er_style_group_violinjitter, args1)
  p2_out <- do.call(er_style_group_violinjitter, args2)

  expect_length(p1_out, 3)
  expect_length(p2_out, 3)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "CoordCartesian"))
  expect_true(inherits(p1_out[[3]], "LayerInstance"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "CoordCartesian"))
  expect_true(inherits(p2_out[[3]], "LayerInstance"))
})

test_that("er_style_group_boxjitter()/er_style_group_violinjitter() forward alpha to the wrapped base builder", {
  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_groups(treatment, style = er_style_group_boxjitter)
  args <- list(
    data     = p1$data,
    config   = p1$layer$group$config[[1]],
    stratify = p1$layer$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata   = p1$strata,
    theme    = p1$theme
  )

  out_default <- do.call(er_style_group_boxjitter, args)
  out_custom  <- do.call(er_style_group_boxjitter, c(args, list(alpha = 0.1)))
  expect_equal(out_default[[1]]$aes_params$alpha, 0.5)
  expect_equal(out_custom[[1]]$aes_params$alpha, 0.1)

  p2 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_groups(treatment, style = er_style_group_violinjitter)
  args2 <- list(
    data     = p2$data,
    config   = p2$layer$group$config[[1]],
    stratify = p2$layer$group$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata   = p2$strata,
    theme    = p2$theme
  )

  out_default2 <- do.call(er_style_group_violinjitter, args2)
  out_custom2  <- do.call(er_style_group_violinjitter, c(args2, list(alpha = 0.2, quantiles = c(0.5))))
  expect_equal(out_default2[[1]]$aes_params$alpha, 0.5)
  expect_equal(out_custom2[[1]]$aes_params$alpha, 0.2)
  expect_equal(out_custom2[[1]]$stat_params$quantiles, c(0.5))
})

test_that("er_style_group_boxjitter()/er_style_group_violinjitter() jitter_size/jitter_alpha override defaults", {
  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_groups(treatment, style = er_style_group_boxjitter)
  args <- list(
    data     = p1$data,
    config   = p1$layer$group$config[[1]],
    stratify = p1$layer$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata   = p1$strata,
    theme    = p1$theme
  )

  out_default <- do.call(er_style_group_boxjitter, args)
  out_custom  <- do.call(er_style_group_boxjitter, c(args, list(jitter_size = 3, jitter_alpha = 0.9)))

  jitter_layer_default <- out_default[[3]]
  jitter_layer_custom  <- out_custom[[3]]

  expect_equal(jitter_layer_default$aes_params$size, 1)
  expect_equal(jitter_layer_default$aes_params$alpha, 0.6)
  expect_equal(jitter_layer_custom$aes_params$size, 3)
  expect_equal(jitter_layer_custom$aes_params$alpha, 0.9)
})

test_that("er_style_group_boxjitter()/er_style_group_violinjitter() jitter stays within jitter_height of the lvl position", {
  p1 <- er_plot(er_test_data, aucss, ae1, sex) |>
    er_plot_add_groups(treatment, style = er_style_group_boxjitter)
  args <- list(
    data     = p1$data,
    config   = p1$layer$group$config[[1]],
    stratify = p1$layer$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata   = p1$strata,
    theme    = p1$theme
  )

  out <- do.call(er_style_group_boxjitter, c(args, list(jitter_height = 0.1)))
  jitter_data <- out[[3]]$data

  lvl_num <- as.numeric(factor(jitter_data$lvl))
  # dodge (max half-width 0.75/2 = 0.375) + jitter_height (0.1)
  expect_true(all(abs(jitter_data$y_jitter - lvl_num) <= 0.375 + 0.1 + 1e-8))
})

test_that("er_plot_add_groups() builds and renders with style = er_style_group_boxjitter/violinjitter", {
  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_groups(treatment, style = er_style_group_boxjitter)
  expect_no_error(er_plot_build(plt))

  plt_strat <- er_test_data |>
    er_plot(aucss, ae1, sex) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_groups(treatment, style = er_style_group_violinjitter)
  expect_no_error(er_plot_build(plt_strat))
})
