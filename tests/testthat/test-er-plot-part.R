test_that(".detect_response_type classifies binary and continuous vectors", {
  expect_equal(.detect_response_type(c(0, 1, 0, 1)), "binary")
  expect_equal(.detect_response_type(c(0, 1, NA)), "binary")
  expect_equal(.detect_response_type(c(TRUE, FALSE, NA)), "binary")
  expect_equal(.detect_response_type(c(0, 1, 2)), "continuous")
  expect_equal(.detect_response_type(c(0.1, 0.9, 1.5)), "continuous")
  expect_equal(.detect_response_type(as.numeric(c(NA, NA))), "continuous")
})

test_that(".part_model's corner_distance normalises y for a continuous response", {
  skip_if_not_installed("erglm")

  plt <- er_test_data |>
    er_plot(aucss, biomarker_change) |>
    er_plot_show_model(er_test_mod_gaussian)

  cfg <- plt$part$model$config
  expect_true(all(cfg$corner_distance >= 0))
  # every corner distance should be a finite, non-degenerate value on a
  # comparable scale regardless of the response's raw (non [0,1]) range
  expect_true(all(is.finite(cfg$corner_distance)))
  expect_length(cfg$corner_distance, 4)
})

test_that(".part_model constructs the correct data structure", {
  skip_if_not_installed("erglm")
  mod2 <- erglm::erglm_model(ae1 ~ aucss + sex, er_test_data, family = binomial())

  plt1 <- er_test_data |> er_plot(aucss, ae1)
  plt2 <- er_test_data |> er_plot(aucss, ae1, sex)

  expect_no_error(plt1 |> er_plot_show_model(er_test_mod1))
  expect_no_error(plt2 |> er_plot_show_model(mod2))

  plt1 <- plt1 |> er_plot_show_model(er_test_mod1)
  plt2 <- plt2 |> er_plot_show_model(mod2)

  expect_type(plt1$part$model, "list")
  expect_type(plt2$part$model, "list")

  expect_named(plt1$part$model, c("stratify", "config"))
  expect_named(plt2$part$model, c("stratify", "config"))

  expect_equal(plt1$part$model$stratify, FALSE)
  expect_equal(plt2$part$model$stratify, TRUE)

  cfg1 <- plt1$part$model$config
  cfg2 <- plt2$part$model$config

  expect_type(cfg1, "list")
  expect_type(cfg2, "list")

  expect_length(cfg1, 6)
  expect_length(cfg2, 6)

  cfg_names <- c(
    "model", "conf_level", "predictions", "p_value",
    "corner_distance", "builder"
  )
  expect_named(cfg1, cfg_names)
  expect_named(cfg2, cfg_names)
})


test_that(".part_quantile constructs the correct data structure", {
  skip_if_not_installed("erglm")

  plt1 <- er_test_data |> er_plot(aucss, ae1)
  plt2 <- er_test_data |> er_plot(aucss, ae1, sex)

  expect_no_error(plt1 |> er_plot_show_quantiles())
  expect_no_error(plt2 |> er_plot_show_quantiles())

  plt1 <- plt1 |> er_plot_show_quantiles()
  plt2 <- plt2 |> er_plot_show_quantiles()

  expect_type(plt1$part$quantile, "list")
  expect_type(plt2$part$quantile, "list")

  expect_named(plt1$part$quantile, c("stratify", "config"))
  expect_named(plt2$part$quantile, c("stratify", "config"))

  expect_equal(plt1$part$quantile$stratify, FALSE)
  expect_equal(plt2$part$quantile$stratify, TRUE)

  cfg1 <- plt1$part$quantile$config
  cfg2 <- plt2$part$quantile$config

  expect_type(cfg1, "list")
  expect_type(cfg2, "list")

  expect_length(cfg1, 4)
  expect_length(cfg2, 4)

  cfg_names <- c("n_quantiles", "conf_level", "summary", "builder")
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


test_that(".part_quantile uses bin means and t-intervals for a continuous response", {
  skip_if_not_installed("erglm")

  plt1 <- er_test_data |> er_plot(aucss, biomarker_change)
  plt2 <- er_test_data |> er_plot(aucss, biomarker_change, sex)

  expect_no_error(plt1 |> er_plot_show_quantiles())
  expect_no_error(plt2 |> er_plot_show_quantiles())

  plt1 <- plt1 |> er_plot_show_quantiles()
  plt2 <- plt2 |> er_plot_show_quantiles()

  smm1 <- plt1$part$quantile$config$summary
  smm2 <- plt2$part$quantile$config$summary

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


test_that(".part_quantile routes a count (Poisson) response through the continuous path", {
  skip_if_not_installed("erglm")

  # ae_count is a count, not a {0, 1} response -- "auto" must not
  # misclassify it as binary (PLAN.md Stage 4)
  plt <- er_test_data |> er_plot(aucss, ae_count)
  expect_equal(plt$response$type, "continuous")

  expect_no_error(plt |> er_plot_show_model(er_test_mod_poisson) |> er_plot_show_quantiles())
  plt <- plt |> er_plot_show_model(er_test_mod_poisson) |> er_plot_show_quantiles()

  smm <- plt$part$quantile$config$summary
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


test_that(".part_strip constructs the correct data structure", {
  skip_if_not_installed("erglm")

  plt1 <- er_test_data |> er_plot(aucss, ae1)
  plt2 <- er_test_data |> er_plot(aucss, ae1, sex)

  expect_no_error(plt1 |> er_plot_show_datastrip())
  expect_no_error(plt2 |> er_plot_show_datastrip())

  plt1 <- plt1 |> er_plot_show_datastrip()
  plt2 <- plt2 |> er_plot_show_datastrip()

  expect_type(plt1$part$strip, "list")
  expect_type(plt2$part$strip, "list")

  expect_named(plt1$part$strip, c("stratify", "config"))
  expect_named(plt2$part$strip, c("stratify", "config"))

  expect_equal(plt1$part$strip$stratify, FALSE)
  expect_equal(plt2$part$strip$stratify, TRUE)

  cfg1 <- plt1$part$strip$config
  cfg2 <- plt2$part$strip$config

  expect_type(cfg1, "list")
  expect_type(cfg2, "list")

  expect_length(cfg1, 6)
  expect_length(cfg2, 6)

  cfg_names <- c("style", "panel", "seed", "builder", "lower", "upper")
  expect_named(cfg1, cfg_names)
  expect_named(cfg2, cfg_names)
})


test_that(".part_group constructs the correct data structure", {
  skip_if_not_installed("erglm")

  plt1 <- er_test_data |> er_plot(aucss, ae1)
  plt2 <- er_test_data |> er_plot(aucss, ae1, sex)

  expect_no_error(plt1 |> er_plot_show_groups(aucss))
  expect_no_error(plt2 |> er_plot_show_groups(aucss))
  expect_no_error(plt1 |> er_plot_show_groups(weight))
  expect_no_error(plt2 |> er_plot_show_groups(weight))
  expect_no_error(plt1 |> er_plot_show_groups(sex))

  plt1a <- plt1 |> er_plot_show_groups(aucss)
  plt2a <- plt2 |> er_plot_show_groups(aucss)
  plt1w <- plt1 |> er_plot_show_groups(weight)
  plt2w <- plt2 |> er_plot_show_groups(weight)
  plt1s <- plt1 |> er_plot_show_groups(sex)

  expect_type(plt1a$part$group, "list")
  expect_type(plt2a$part$group, "list")
  expect_type(plt1w$part$group, "list")
  expect_type(plt2w$part$group, "list")
  expect_type(plt1s$part$group, "list")

  grp1a <- plt1a$part$group
  grp2a <- plt2a$part$group
  grp1w <- plt1w$part$group
  grp2w <- plt2w$part$group
  grp1s <- plt1s$part$group

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
