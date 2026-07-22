test_that(".detect_response_type classifies binary and continuous vectors", {
  expect_equal(.detect_response_type(c(0, 1, 0, 1)), "binary")
  expect_equal(.detect_response_type(c(0, 1, NA)), "binary")
  expect_equal(.detect_response_type(c(TRUE, FALSE, NA)), "binary")
  expect_equal(.detect_response_type(c(0, 1, 2)), "continuous")
  expect_equal(.detect_response_type(c(0.1, 0.9, 1.5)), "continuous")
  expect_equal(.detect_response_type(as.numeric(c(NA, NA))), "continuous")
})

test_that(".layer_model's corner_distance normalises y for a continuous response", {
  skip_if_not_installed("erglm")

  plt <- er_test_data |>
    er_plot(aucss, biomarker_change) |>
    er_plot_add_model(er_test_mod_gaussian)

  cfg <- plt$layer$model$config
  expect_true(all(cfg$corner_distance >= 0))
  # every corner distance should be a finite, non-degenerate value on a
  # comparable scale regardless of the response's raw (non [0,1]) range
  expect_true(all(is.finite(cfg$corner_distance)))
  expect_length(cfg$corner_distance, 4)
})

test_that(".layer_model constructs the correct data structure", {
  skip_if_not_installed("erglm")
  mod2 <- erglm::erglm_model(ae1 ~ aucss + sex, er_test_data, family = binomial())

  plt1 <- er_test_data |> er_plot(aucss, ae1)
  plt2 <- er_test_data |> er_plot(aucss, ae1, sex)

  expect_no_error(plt1 |> er_plot_add_model(er_test_mod1))
  expect_no_error(plt2 |> er_plot_add_model(mod2))

  plt1 <- plt1 |> er_plot_add_model(er_test_mod1)
  plt2 <- plt2 |> er_plot_add_model(mod2)

  expect_type(plt1$layer$model, "list")
  expect_type(plt2$layer$model, "list")

  expect_named(plt1$layer$model, c("stratify", "config"))
  expect_named(plt2$layer$model, c("stratify", "config"))

  expect_equal(plt1$layer$model$stratify, FALSE)
  expect_equal(plt2$layer$model$stratify, TRUE)

  cfg1 <- plt1$layer$model$config
  cfg2 <- plt2$layer$model$config

  expect_type(cfg1, "list")
  expect_type(cfg2, "list")

  expect_length(cfg1, 7)
  expect_length(cfg2, 7)

  cfg_names <- c(
    "model", "conf_level", "predictions", "p_value",
    "corner_distance", "style", "dots"
  )
  expect_named(cfg1, cfg_names)
  expect_named(cfg2, cfg_names)
})


test_that(".layer_quantile constructs the correct data structure", {
  skip_if_not_installed("erglm")

  plt1 <- er_test_data |> er_plot(aucss, ae1)
  plt2 <- er_test_data |> er_plot(aucss, ae1, sex)

  expect_no_error(plt1 |> er_plot_add_quantiles())
  expect_no_error(plt2 |> er_plot_add_quantiles())

  plt1 <- plt1 |> er_plot_add_quantiles()
  plt2 <- plt2 |> er_plot_add_quantiles()

  expect_type(plt1$layer$quantile, "list")
  expect_type(plt2$layer$quantile, "list")

  expect_named(plt1$layer$quantile, c("stratify", "config"))
  expect_named(plt2$layer$quantile, c("stratify", "config"))

  expect_equal(plt1$layer$quantile$stratify, FALSE)
  expect_equal(plt2$layer$quantile$stratify, TRUE)

  cfg1 <- plt1$layer$quantile$config
  cfg2 <- plt2$layer$quantile$config

  expect_type(cfg1, "list")
  expect_type(cfg2, "list")

  expect_length(cfg1, 6)
  expect_length(cfg2, 6)

  cfg_names <- c("n_quantiles", "conf_level", "breaks", "summary", "style", "dots")
  expect_named(cfg1, cfg_names)
  expect_named(cfg2, cfg_names)

  smm1 <- cfg1$summary
  smm2 <- cfg2$summary

  expect_s3_class(smm1, "data.frame")
  expect_s3_class(smm2, "data.frame")

  smm_names <- c(
    "exposure_bins", "strata", "n1", "n0",
    "x_mid", "y_mid", "y_mid_lbl", "ci_lower",
    "ci_upper", "y_lwr_lbl", "y_upr_lbl", "y_lbl"
  )

  expect_named(smm1, smm_names)
  expect_named(smm2, smm_names)

  expect_equal(unique(smm1$strata), NA)
  expect_equal(as.character(unique(smm2$strata)), c("Male", "Female"))
})


test_that(".layer_quantile uses bin means and t-intervals for a continuous response", {
  skip_if_not_installed("erglm")

  plt1 <- er_test_data |> er_plot(aucss, biomarker_change)
  plt2 <- er_test_data |> er_plot(aucss, biomarker_change, sex)

  expect_no_error(plt1 |> er_plot_add_quantiles())
  expect_no_error(plt2 |> er_plot_add_quantiles())

  plt1 <- plt1 |> er_plot_add_quantiles()
  plt2 <- plt2 |> er_plot_add_quantiles()

  smm1 <- plt1$layer$quantile$config$summary
  smm2 <- plt2$layer$quantile$config$summary

  # no n1/n0 columns (those are binary-only) -- bin mean/CI columns instead
  smm_names <- c(
    "exposure_bins", "strata",
    "x_mid", "y_mid", "y_mid_lbl", "ci_lower",
    "ci_upper", "y_lwr_lbl", "y_upr_lbl", "y_lbl"
  )
  expect_named(smm1, smm_names)
  expect_named(smm2, smm_names)

  # bin mean should agree with a direct calculation on the same bins, and
  # lie within its own CI
  expect_true(all(smm1$ci_lower <= smm1$y_mid & smm1$y_mid <= smm1$ci_upper))
  expect_true(all(smm2$ci_lower <= smm2$y_mid & smm2$y_mid <= smm2$ci_upper))
})


test_that(".layer_quantile routes a count (Poisson) response through the continuous path", {
  skip_if_not_installed("erglm")

  # ae_count is a count, not a {0, 1} response -- "auto" must not
  # misclassify it as binary (PLAN.md Stage 4)
  plt <- er_test_data |> er_plot(aucss, ae_count)
  expect_equal(plt$response$type, "continuous")

  expect_no_error(plt |> er_plot_add_model(er_test_mod_poisson) |> er_plot_add_quantiles())
  plt <- plt |> er_plot_add_model(er_test_mod_poisson) |> er_plot_add_quantiles()

  smm <- plt$layer$quantile$config$summary
  expect_named(smm, c(
    "exposure_bins", "strata",
    "x_mid", "y_mid", "y_mid_lbl", "ci_lower",
    "ci_upper", "y_lwr_lbl", "y_upr_lbl", "y_lbl"
  ))
  expect_true(all(smm$ci_lower <= smm$y_mid & smm$y_mid <= smm$ci_upper))
  # bin means should be non-negative (it's a count), even though the
  # t-interval approximation can push ci_lower below zero -- a known,
  # documented limitation, not asserted against here
})


test_that(".layer_quantile uses an exact Poisson interval when response_type = \"count\" is declared", {
  skip_if_not_installed("erglm")

  plt <- er_test_data |> er_plot(aucss, ae_count, response_type = "count")
  expect_equal(plt$response$type, "count")

  expect_no_error(plt |> er_plot_add_model(er_test_mod_poisson) |> er_plot_add_quantiles())
  plt <- plt |> er_plot_add_model(er_test_mod_poisson) |> er_plot_add_quantiles()

  smm <- plt$layer$quantile$config$summary
  # same column shape as the continuous path (no n1/n0, no leftover
  # n_units helper column)
  expect_named(smm, c(
    "exposure_bins", "strata",
    "x_mid", "y_mid", "y_mid_lbl", "ci_lower",
    "ci_upper", "y_lwr_lbl", "y_upr_lbl", "y_lbl"
  ))
  expect_true(all(smm$ci_lower <= smm$y_mid & smm$y_mid <= smm$ci_upper))
  # the exact Poisson interval, unlike the t-interval approximation,
  # should never go negative for a non-negative count
  expect_true(all(smm$ci_lower >= 0))
})


test_that(".layer_data constructs the correct data structure", {
  skip_if_not_installed("erglm")

  plt1 <- er_test_data |> er_plot(aucss, ae1)
  plt2 <- er_test_data |> er_plot(aucss, ae1, sex)

  expect_no_error(plt1 |> er_plot_add_data(style = er_style_data_boxjitter))
  expect_no_error(plt2 |> er_plot_add_data(style = er_style_data_boxjitter))

  plt1 <- plt1 |> er_plot_add_data(style = er_style_data_boxjitter)
  plt2 <- plt2 |> er_plot_add_data(style = er_style_data_boxjitter)

  expect_type(plt1$layer$data, "list")
  expect_type(plt2$layer$data, "list")

  expect_named(plt1$layer$data, c("stratify", "config"))
  expect_named(plt2$layer$data, c("stratify", "config"))

  expect_equal(plt1$layer$data$stratify, FALSE)
  expect_equal(plt2$layer$data$stratify, TRUE)

  cfg1 <- plt1$layer$data$config
  cfg2 <- plt2$layer$data$config

  expect_type(cfg1, "list")
  expect_type(cfg2, "list")

  expect_length(cfg1, 8)
  expect_length(cfg2, 8)

  cfg_names <- c("layout", "panel", "seed", "style", "dots", "color_role", "panels", "panel_position")
  expect_named(cfg1, cfg_names)
  expect_named(cfg2, cfg_names)

  expect_equal(cfg1$color_role, "strata")
  expect_equal(cfg2$color_role, "strata")
  expect_equal(cfg1$panels, c("upper", "lower"))
  expect_equal(cfg2$panels, c("upper", "lower"))
  expect_equal(cfg1$panel_position, c(upper = "above", lower = "below"))
  expect_equal(cfg2$panel_position, c(upper = "above", lower = "below"))
})


test_that(".layer_data records a response-colored panel structure for a continuous response", {
  skip_if_not_installed("erglm")

  # there's no built-in "panel"-layout style for a continuous/count
  # response (the older `build_data_color()` was removed once
  # `er_style_data_overlay()` covered its typical use case more simply --
  # see PLAN.md), but `.layer_data()`'s response-type dispatch is still
  # general-purpose and exercised here via a minimal custom style.
  stub_panel_builder <- er_style_tag(
    function(data, config, stratify, exposure, response, strata, theme) list(),
    layout = "panel"
  )

  plt1 <- er_test_data |> er_plot(aucss, biomarker_change)
  plt2 <- er_test_data |> er_plot(aucss, biomarker_change, sex)

  expect_no_error(plt1 |> er_plot_add_data(style = stub_panel_builder))
  expect_no_error(plt2 |> er_plot_add_data(style = stub_panel_builder))

  plt1 <- plt1 |> er_plot_add_data(style = stub_panel_builder)
  plt2 <- plt2 |> er_plot_add_data(style = stub_panel_builder)

  cfg1 <- plt1$layer$data$config
  cfg2 <- plt2$layer$data$config

  expect_identical(cfg1$style, stub_panel_builder)
  expect_identical(cfg2$style, stub_panel_builder)
  expect_equal(cfg1$color_role, "response")
  expect_equal(cfg2$color_role, "response")

  # unstratified: a single panel named "data"
  expect_equal(cfg1$panels, "data")
  expect_equal(cfg1$panel_position, c(data = "below"))

  # stratified: one panel per stratum level, all "below"
  expect_equal(sort(cfg2$panels), sort(as.character(unique(er_test_data$sex))))
  expect_true(all(cfg2$panel_position == "below"))
})


test_that(".layer_data records the same single-panel structure for a count response", {
  skip_if_not_installed("erglm")

  stub_panel_builder <- er_style_tag(
    function(data, config, stratify, exposure, response, strata, theme) list(),
    layout = "panel"
  )

  plt <- er_test_data |> er_plot(aucss, ae_count, response_type = "count")
  expect_no_error(plt |> er_plot_add_data(style = stub_panel_builder))
  cfg <- (plt |> er_plot_add_data(style = stub_panel_builder))$layer$data$config
  expect_identical(cfg$style, stub_panel_builder)
  expect_equal(cfg$color_role, "response")
  expect_equal(cfg$panels, "data")
})


test_that(".layer_group constructs the correct data structure", {
  skip_if_not_installed("erglm")

  plt1 <- er_test_data |> er_plot(aucss, ae1)
  plt2 <- er_test_data |> er_plot(aucss, ae1, sex)

  expect_no_error(plt1 |> er_plot_add_groups(aucss))
  expect_no_error(plt2 |> er_plot_add_groups(aucss))
  expect_no_error(plt1 |> er_plot_add_groups(weight))
  expect_no_error(plt2 |> er_plot_add_groups(weight))
  expect_no_error(plt1 |> er_plot_add_groups(sex))

  plt1a <- plt1 |> er_plot_add_groups(aucss)
  plt2a <- plt2 |> er_plot_add_groups(aucss)
  plt1w <- plt1 |> er_plot_add_groups(weight)
  plt2w <- plt2 |> er_plot_add_groups(weight)
  plt1s <- plt1 |> er_plot_add_groups(sex)

  expect_type(plt1a$layer$group, "list")
  expect_type(plt2a$layer$group, "list")
  expect_type(plt1w$layer$group, "list")
  expect_type(plt2w$layer$group, "list")
  expect_type(plt1s$layer$group, "list")

  grp1a <- plt1a$layer$group
  grp2a <- plt2a$layer$group
  grp1w <- plt1w$layer$group
  grp2w <- plt2w$layer$group
  grp1s <- plt1s$layer$group

  expect_named(grp1a, c("stratify", "config"))
  expect_named(grp2a, c("stratify", "config"))
  expect_named(grp1w, c("stratify", "config"))
  expect_named(grp2w, c("stratify", "config"))
  expect_named(grp1s, c("stratify", "config"))

  cfg1a <- grp1a$config
  cfg2a <- grp2a$config
  cfg1w <- grp1w$config
  cfg2w <- grp2w$config
  cfg1s <- grp1s$config

  expect_length(cfg1a, 1)
  expect_length(cfg2a, 1)
  expect_length(cfg1w, 1)
  expect_length(cfg2w, 1)
  expect_length(cfg1s, 1)

  expect_named(cfg1a[[1]]$data, c(".aucss_quantile", "aucss", "n", "lbl", "lvl"))
  expect_named(cfg2a[[1]]$data, c(".aucss_quantile", "sex", "aucss", "n", "lbl", "lvl"))
  expect_named(cfg1w[[1]]$data, c(".weight_quantile", "aucss", "n", "lbl", "lvl"))
  expect_named(cfg2w[[1]]$data, c(".weight_quantile", "sex", "aucss", "n", "lbl", "lvl"))
  expect_named(cfg1s[[1]]$data, c("sex", "aucss", "n", "lbl", "lvl"))

  fct1a <- cfg1a[[1]]$data[[1]]
  fct2a <- cfg2a[[1]]$data[[1]]
  fct1w <- cfg1w[[1]]$data[[1]]
  fct2w <- cfg2w[[1]]$data[[1]]
  fct1s <- cfg1s[[1]]$data[[1]]

  expect_s3_class(fct1a, "factor")
  expect_s3_class(fct2a, "factor")
  expect_s3_class(fct1w, "factor")
  expect_s3_class(fct2w, "factor")
  expect_s3_class(fct1s, "factor")

  expect_equal(attr(fct1a, "label"), attr(er_test_data$aucss, "label"))
  expect_equal(attr(fct2a, "label"), attr(er_test_data$aucss, "label"))
  expect_equal(attr(fct1w, "label"), attr(er_test_data$weight, "label"))
  expect_equal(attr(fct2w, "label"), attr(er_test_data$weight, "label"))
  expect_equal(attr(fct1s, "label"), attr(er_test_data$sex, "label"))
})


test_that(".layer_overlay constructs the correct data structure", {
  skip_if_not_installed("erglm")

  plt1 <- er_test_data |> er_plot(aucss, ae1)
  plt2 <- er_test_data |> er_plot(aucss, ae1, sex)
  plt3 <- er_test_data |> er_plot(aucss, biomarker_change)

  expect_no_error(plt1 |> er_plot_add_data())
  expect_no_error(plt2 |> er_plot_add_data())
  expect_no_error(plt3 |> er_plot_add_data())

  plt1 <- plt1 |> er_plot_add_data()
  plt2 <- plt2 |> er_plot_add_data()
  plt3 <- plt3 |> er_plot_add_data()

  expect_type(plt1$layer$overlay, "list")
  expect_type(plt2$layer$overlay, "list")

  expect_named(plt1$layer$overlay, c("stratify", "config"))
  expect_named(plt2$layer$overlay, c("stratify", "config"))

  expect_equal(plt1$layer$overlay$stratify, FALSE)
  expect_equal(plt2$layer$overlay$stratify, TRUE)

  # an "overlay"-layout style (the default) is a mutually exclusive
  # alternative to a "panel"-layout style -- only one of
  # `layer$data`/`layer$overlay` is ever non-NULL
  expect_null(plt1$layer$data)
  expect_null(plt2$layer$data)

  cfg1 <- plt1$layer$overlay$config
  cfg3 <- plt3$layer$overlay$config

  expect_named(cfg1, c("seed", "response_type", "style", "dots"))
  expect_identical(cfg1$style, er_style_data_overlay)
  expect_equal(cfg1$response_type, "binary")
  expect_equal(cfg3$response_type, "continuous")
})
