test_that("er_plot creates an er_plot (minimal)", {
  skip_if_not_installed("erglm")
  expect_no_error(er_plot(er_test_data, aucss, ae1))
  plt <- er_plot(er_test_data, aucss, ae1)
  expect_s3_class(plt, "er_plot")
})

test_that("er_plot resolves response_type = 'auto' correctly", {
  skip_if_not_installed("erglm")

  plt_binary <- er_plot(er_test_data, aucss, ae1)
  expect_equal(plt_binary$response$type, "binary")
  expect_equal(plt_binary$response$limits, c(0, 1))

  plt_continuous <- er_plot(er_test_data, aucss, biomarker_change)
  expect_equal(plt_continuous$response$type, "continuous")
  expect_equal(
    plt_continuous$response$limits,
    range(er_test_data$biomarker_change, na.rm = TRUE)
  )
})

test_that("er_plot's response_type argument overrides auto-detection", {
  skip_if_not_installed("erglm")

  # a 0/1 response explicitly declared continuous
  plt <- er_plot(er_test_data, aucss, ae1, response_type = "continuous")
  expect_equal(plt$response$type, "continuous")
  expect_equal(plt$response$limits, range(er_test_data$ae1, na.rm = TRUE))

  expect_error(er_plot(er_test_data, aucss, ae1, response_type = "nope"))
})

test_that("er_plot_show_quantiles supports both binary and continuous responses", {
  skip_if_not_installed("erglm")

  # continuous response: bin means with t-interval CIs (PLAN.md Stage 1)
  plt <- er_test_data |> er_plot(aucss, biomarker_change)
  expect_no_error(er_plot_show_quantiles(plt))

  smm <- (plt |> er_plot_show_quantiles())$part$quantile$config$summary
  expect_named(smm, c(
    "exposure_bins", "strata", "x_mid", "y_mid", "y_mid_lbl",
    "ci_lower", "ci_upper", "y_lwr_lbl", "y_upr_lbl", "y_lbl"
  ))
  expect_true(all(smm$ci_lower <= smm$y_mid & smm$y_mid <= smm$ci_upper))

  # binary response still works, unchanged
  plt_binary <- er_test_data |> er_plot(aucss, ae1)
  expect_no_error(er_plot_show_quantiles(plt_binary))
})

test_that("er_plot_show_data supports a continuous response (single color-encoded panel)", {
  skip_if_not_installed("erglm")

  plt <- er_test_data |> er_plot(aucss, biomarker_change)
  expect_no_error(er_plot_show_data(plt, style = "jitter"))

  plt <- er_plot_show_data(plt, style = "jitter")
  expect_equal(plt$part$data$config$color_role, "response")
  expect_equal(plt$part$data$config$panels, "data")

  # binary response still works, dispatched to build_data_jitter
  plt_binary <- er_test_data |> er_plot(aucss, ae1)
  expect_no_error(er_plot_show_data(plt_binary, style = "jitter"))
  expect_equal((plt_binary |> er_plot_show_data(style = "jitter"))$part$data$config$color_role, "strata")
})

test_that("er_plot_show_data supports a declared count response", {
  skip_if_not_installed("erglm")

  plt <- er_test_data |> er_plot(aucss, ae_count, response_type = "count")
  expect_no_error(er_plot_show_data(plt, style = "jitter"))
  expect_equal((plt |> er_plot_show_data(style = "jitter"))$part$data$config$color_role, "response")
})

test_that("er_plot_show_data's default style is overlay, replacing data/overlay on re-call", {
  skip_if_not_installed("erglm")

  plt <- er_test_data |> er_plot(aucss, ae1)

  plt_overlay <- plt |> er_plot_show_data()
  expect_false(is.null(plt_overlay$part$overlay))
  expect_null(plt_overlay$part$data)

  plt_jitter <- plt_overlay |> er_plot_show_data(style = "jitter")
  expect_false(is.null(plt_jitter$part$data))
  expect_null(plt_jitter$part$overlay)

  plt_back <- plt_jitter |> er_plot_show_data(style = "overlay")
  expect_false(is.null(plt_back$part$overlay))
  expect_null(plt_back$part$data)

  expect_error(er_plot_show_data(plt, style = "nope"))
})

test_that("er_plot_show_data errors when panel != 'both'", {
  skip_if_not_installed("erglm")

  plt_continuous <- er_test_data |> er_plot(aucss, biomarker_change)
  expect_error(
    er_plot_show_data(plt_continuous, style = "jitter", panel = "upper"),
    regexp = "must be \"both\""
  )

  plt_count <- er_test_data |> er_plot(aucss, ae_count, response_type = "count")
  expect_error(
    er_plot_show_data(plt_count, style = "jitter", panel = "lower"),
    regexp = "must be \"both\""
  )

  # `style = "overlay"` (the default) has no upper/lower partition for
  # any response type, unlike `style = "jitter"` on a binary response
  plt_binary <- er_test_data |> er_plot(aucss, ae1)
  expect_error(
    er_plot_show_data(plt_binary, panel = "upper"),
    regexp = "must be \"both\""
  )

  # default ("both") and binary + style = "jitter" are unaffected
  expect_no_error(er_plot_show_data(plt_continuous))
  expect_no_error(er_plot_show_data(plt_binary, style = "jitter", panel = "upper"))
})

test_that("er_plot_show_data produces N stratum panels, each with a response colorbar", {
  skip_if_not_installed("erglm")

  mod3 <- erglm::erglm_model(biomarker_change ~ aucss + sex, er_test_data, family = gaussian())
  plt <- er_test_data |>
    er_plot(aucss, biomarker_change, sex) |>
    er_plot_show_model(mod3) |>
    er_plot_show_data(style = "jitter")

  expect_no_error(er_plot_build(plt))
  built <- er_plot_build(plt)

  strata_levels <- sort(as.character(unique(er_test_data$sex)))
  expect_equal(sort(names(built$plot$data)), strata_levels)

  # the response label -- not the strata label -- should be on the color legend
  labs_by_panel <- purrr::map(built$plot$data, ggplot2::get_labs)
  purrr::walk(labs_by_panel, function(l) {
    expect_equal(l$colour, plt$response$label)
  })
})

test_that("er_plot creates an er_plot (all parts)", {
  skip_if_not_installed("erglm")
  expect_no_error(
    er_test_data |>
      dplyr::mutate(dose = factor(dose)) |>
      er_plot(aucss, ae1) |>
      er_plot_show_model(er_test_mod1) |>
      er_plot_show_quantiles()  |>
      er_plot_show_data()  |>
      er_plot_show_groups(c(treatment, dose))
  )
  plt <- er_test_data |>
    dplyr::mutate(dose = factor(dose)) |>
    er_plot(aucss, ae1) |>
    er_plot_show_model(er_test_mod1) |>
    er_plot_show_quantiles()  |>
    er_plot_show_data()  |>
    er_plot_show_groups(c(treatment, dose))
  expect_s3_class(plt, "er_plot")
})

test_that("er_plot creates an er_plot (all parts, all strata)", {
  skip_if_not_installed("erglm")
  mod <- erglm::erglm_model(ae1 ~ aucss + sex, er_test_data, family = binomial())
  expect_no_error(
    er_test_data |>
      dplyr::mutate(dose = factor(dose)) |>
      er_plot(aucss, ae1, sex) |>
      er_plot_show_model(mod) |>
      er_plot_show_quantiles()  |>
      er_plot_show_data()  |>
      er_plot_show_groups(c(treatment, dose))
  )
  plt <- er_test_data |>
    dplyr::mutate(dose = factor(dose)) |>
    er_plot(aucss, ae1, sex) |>
    er_plot_show_model(mod) |>
    er_plot_show_quantiles()  |>
    er_plot_show_data()  |>
    er_plot_show_groups(c(treatment, dose))
  expect_s3_class(plt, "er_plot")
})

test_that("er_plot_build does not error", {
  skip_if_not_installed("erglm")

  plt1 <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_show_model(er_test_mod1)

  plt2 <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_show_model(er_test_mod1) |>
    er_plot_show_quantiles()  |>
    er_plot_show_data()

  plt3 <- er_test_data |>
    dplyr::mutate(dose = factor(dose)) |>
    er_plot(aucss, ae1) |>
    er_plot_show_model(er_test_mod1) |>
    er_plot_show_quantiles()  |>
    er_plot_show_data()  |>
    er_plot_show_groups(c(treatment, dose))

  expect_no_error(er_plot_build(plt1))
  expect_no_error(er_plot_build(plt2))
  expect_no_error(er_plot_build(plt3))
})

test_that("er_plot_build constructs ggplot2 objects", {
  skip_if_not_installed("erglm")

  plt1 <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_show_model(er_test_mod1)

  plt2 <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_show_model(er_test_mod1) |>
    er_plot_show_quantiles()  |>
    er_plot_show_data(style = "jitter")

  plt3 <- er_test_data |>
    dplyr::mutate(dose = factor(dose)) |>
    er_plot(aucss, ae1) |>
    er_plot_show_model(er_test_mod1) |>
    er_plot_show_quantiles()  |>
    er_plot_show_data(style = "jitter")  |>
    er_plot_show_groups(c(treatment, dose))

  plt1_built <- er_plot_build(plt1)
  plt2_built <- er_plot_build(plt2)
  plt3_built <- er_plot_build(plt3)

  plt1_built_gg <- plt1_built$plot |> purrr::list_flatten() |> purrr::map_lgl(ggplot2::is_ggplot)
  plt2_built_gg <- plt2_built$plot |> purrr::list_flatten() |> purrr::map_lgl(ggplot2::is_ggplot)
  plt3_built_gg <- plt3_built$plot |> purrr::list_flatten() |> purrr::map_lgl(ggplot2::is_ggplot)

  expect_equal(
    plt1_built_gg,
    c(base = TRUE, data = FALSE, group = FALSE)
  )
  expect_equal(
    plt2_built_gg,
    c(base = TRUE, data_upper = TRUE, data_lower = TRUE, group = FALSE)
  )
  expect_equal(
    plt3_built_gg,
    c(base = TRUE, data_upper = TRUE, data_lower = TRUE, group_treatment = TRUE, group_dose = TRUE)
  )
})

test_that("print method works as expected", {
  skip_if_not_installed("erglm")

  plt1 <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_show_model(er_test_mod1)

  plt2 <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_show_model(er_test_mod1) |>
    er_plot_show_quantiles()  |>
    er_plot_show_data(style = "jitter")

  plt3 <- er_test_data |>
    dplyr::mutate(dose = factor(dose)) |>
    er_plot(aucss, ae1) |>
    er_plot_show_model(er_test_mod1) |>
    er_plot_show_quantiles()  |>
    er_plot_show_data(style = "jitter")  |>
    er_plot_show_groups(c(treatment, dose))

  print_quiet <- purrr::quietly(print.er_plot)

  expect_no_error(print_quiet(plt1))
  expect_no_error(print_quiet(plt2))
  expect_no_error(print_quiet(plt3))

  printout1 <- print_quiet(plt1)
  printout2 <- print_quiet(plt2)
  printout3 <- print_quiet(plt3)

  expect_equal(printout1$result, plt1)
  expect_equal(printout2$result, plt2)
  expect_equal(printout3$result, plt3)

  expect_equal(printout1$warnings, character())
  expect_equal(printout2$warnings, character())
  expect_equal(printout3$warnings, character())

  expect_equal(printout1$messages, character())
  expect_equal(printout2$messages, character())
  expect_equal(printout3$messages, character())

  outlines1 <- strsplit(printout1$output, split = "\n")[[1]]
  outlines2 <- strsplit(printout2$output, split = "\n")[[1]]
  outlines3 <- strsplit(printout3$output, split = "\n")[[1]]

  expect_length(outlines1, 9)
  expect_length(outlines2, 11)
  expect_length(outlines3, 12)
})

test_that("er_plot_show_data(style = 'overlay') merges into the base plot", {
  skip_if_not_installed("erglm")

  # overlay as the *only* layer: the base plot must still get built (for
  # its coord/scale), with no separate object$plot$data panels
  plt <- er_test_data |> er_plot(aucss, ae1) |> er_plot_show_data()
  expect_no_error(er_plot_build(plt))
  built <- er_plot_build(plt)

  expect_true(ggplot2::is_ggplot(built$plot$base))
  expect_null(built$plot$data)
  expect_equal(length(built$output$layers), 1)

  # stratified overlay shares one legend with a stratified model curve,
  # both living on the same base plot
  mod2 <- erglm::erglm_model(ae1 ~ aucss + sex, er_test_data, family = binomial())
  plt_strat <- er_test_data |>
    er_plot(aucss, ae1, sex) |>
    er_plot_show_model(mod2) |>
    er_plot_show_data()

  expect_no_error(er_plot_build(plt_strat))
  built_strat <- er_plot_build(plt_strat)

  expect_true(ggplot2::is_ggplot(built_strat$output))
  expect_equal(ggplot2::get_labs(built_strat$output)$colour, plt_strat$strata$label)
})
