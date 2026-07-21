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

test_that("er_plot_add_quantiles supports both binary and continuous responses", {
  skip_if_not_installed("erglm")

  # continuous response: bin means with t-interval CIs (PLAN.md Stage 1)
  plt <- er_test_data |> er_plot(aucss, biomarker_change)
  expect_no_error(er_plot_add_quantiles(plt))

  smm <- (plt |> er_plot_add_quantiles())$part$quantile$config$summary
  expect_named(smm, c(
    "exposure_bins", "strata", "x_mid", "y_mid", "y_mid_lbl",
    "ci_lower", "ci_upper", "y_lwr_lbl", "y_upr_lbl", "y_lbl"
  ))
  expect_true(all(smm$ci_lower <= smm$y_mid & smm$y_mid <= smm$ci_upper))

  # binary response still works, unchanged
  plt_binary <- er_test_data |> er_plot(aucss, ae1)
  expect_no_error(er_plot_add_quantiles(plt_binary))
})

test_that("er_plot_add_data's panel layout supports a continuous response (single color-encoded panel)", {
  skip_if_not_installed("erglm")

  # there's no built-in "panel"-layout builder for a continuous/count
  # response (see PLAN.md's note on removing `build_data_color()`), but
  # `.part_data()`'s response-type dispatch is still general-purpose and
  # exercised here via a minimal custom builder.
  stub_panel_builder <- er_builder_tag(
    function(data, config, stratify, exposure, response, strata, style) list(),
    layout = "panel"
  )

  plt <- er_test_data |> er_plot(aucss, biomarker_change)
  expect_no_error(er_plot_add_data(plt, builder = stub_panel_builder))

  plt <- er_plot_add_data(plt, builder = stub_panel_builder)
  expect_equal(plt$part$data$config$color_role, "response")
  expect_equal(plt$part$data$config$panels, "data")

  # binary response still works, with er_builder_data_boxjitter
  plt_binary <- er_test_data |> er_plot(aucss, ae1)
  expect_no_error(er_plot_add_data(plt_binary, builder = er_builder_data_boxjitter))
  expect_equal((plt_binary |> er_plot_add_data(builder = er_builder_data_boxjitter))$part$data$config$color_role, "strata")
})

test_that("er_plot_add_data supports a declared count response", {
  skip_if_not_installed("erglm")

  stub_panel_builder <- er_builder_tag(
    function(data, config, stratify, exposure, response, strata, style) list(),
    layout = "panel"
  )

  plt <- er_test_data |> er_plot(aucss, ae_count, response_type = "count")
  expect_no_error(er_plot_add_data(plt, builder = stub_panel_builder))
  expect_equal((plt |> er_plot_add_data(builder = stub_panel_builder))$part$data$config$color_role, "response")
})

test_that("er_plot_add_data's default builder is er_builder_data_overlay, replacing data/overlay on re-call", {
  skip_if_not_installed("erglm")

  plt <- er_test_data |> er_plot(aucss, ae1)

  plt_overlay <- plt |> er_plot_add_data()
  expect_false(is.null(plt_overlay$part$overlay))
  expect_null(plt_overlay$part$data)

  plt_jitter <- plt_overlay |> er_plot_add_data(builder = er_builder_data_boxjitter)
  expect_false(is.null(plt_jitter$part$data))
  expect_null(plt_jitter$part$overlay)

  plt_back <- plt_jitter |> er_plot_add_data()
  expect_false(is.null(plt_back$part$overlay))
  expect_null(plt_back$part$data)

  expect_error(er_plot_add_data(plt, builder = "not a function"))
})

test_that("er_plot_add_data errors when panel != 'both'", {
  skip_if_not_installed("erglm")

  stub_panel_builder <- er_builder_tag(
    function(data, config, stratify, exposure, response, strata, style) list(),
    layout = "panel"
  )

  plt_continuous <- er_test_data |> er_plot(aucss, biomarker_change)
  expect_error(
    er_plot_add_data(plt_continuous, builder = stub_panel_builder, panel = "upper"),
    regexp = "must be \"both\""
  )

  plt_count <- er_test_data |> er_plot(aucss, ae_count, response_type = "count")
  expect_error(
    er_plot_add_data(plt_count, builder = stub_panel_builder, panel = "lower"),
    regexp = "must be \"both\""
  )

  # `er_builder_data_overlay` (the default) has no upper/lower partition for
  # any response type, unlike `er_builder_data_boxjitter` on a binary response
  plt_binary <- er_test_data |> er_plot(aucss, ae1)
  expect_error(
    er_plot_add_data(plt_binary, panel = "upper"),
    regexp = "must be \"both\""
  )

  # default ("both") and binary + er_builder_data_boxjitter are unaffected
  expect_no_error(er_plot_add_data(plt_continuous))
  expect_no_error(er_plot_add_data(plt_binary, builder = er_builder_data_boxjitter, panel = "upper"))
})

test_that("er_plot_add_data produces N stratum panels, each with a response colorbar", {
  skip_if_not_installed("erglm")

  # there's no built-in "panel"-layout builder for a continuous response
  # (see PLAN.md's note on removing `build_data_color()`); this custom
  # builder recreates its color-encoded-panel behaviour to check that
  # `.part_data()`/`.polish_labels()`'s per-stratum-panel machinery still
  # works for a response type with no shipped built-in.
  custom_color_panel_builder <- er_builder_tag(
    function(data, config, stratify, exposure, response, strata, style) {
      dat <- if (stratify) data |> dplyr::filter(.data[[strata$name]] == config$panel) else data
      list(
        ggplot2::geom_jitter(
          data = dat,
          mapping = ggplot2::aes(x = .data[[exposure$name]], y = 0, color = .data[[response$name]]),
          height = 0.1
        )
      )
    },
    layout = "panel"
  )

  mod3 <- erglm::erglm_model(biomarker_change ~ aucss + sex, er_test_data, family = gaussian())
  plt <- er_test_data |>
    er_plot(aucss, biomarker_change, sex) |>
    er_plot_add_model(mod3) |>
    er_plot_add_data(builder = custom_color_panel_builder)

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
      er_plot_add_model(er_test_mod1) |>
      er_plot_add_quantiles()  |>
      er_plot_add_data()  |>
      er_plot_add_groups(c(treatment, dose))
  )
  plt <- er_test_data |>
    dplyr::mutate(dose = factor(dose)) |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_quantiles()  |>
    er_plot_add_data()  |>
    er_plot_add_groups(c(treatment, dose))
  expect_s3_class(plt, "er_plot")
})

test_that("er_plot creates an er_plot (all parts, all strata)", {
  skip_if_not_installed("erglm")
  mod <- erglm::erglm_model(ae1 ~ aucss + sex, er_test_data, family = binomial())
  expect_no_error(
    er_test_data |>
      dplyr::mutate(dose = factor(dose)) |>
      er_plot(aucss, ae1, sex) |>
      er_plot_add_model(mod) |>
      er_plot_add_quantiles()  |>
      er_plot_add_data()  |>
      er_plot_add_groups(c(treatment, dose))
  )
  plt <- er_test_data |>
    dplyr::mutate(dose = factor(dose)) |>
    er_plot(aucss, ae1, sex) |>
    er_plot_add_model(mod) |>
    er_plot_add_quantiles()  |>
    er_plot_add_data()  |>
    er_plot_add_groups(c(treatment, dose))
  expect_s3_class(plt, "er_plot")
})

test_that("er_plot_add_groups errors when grouping by the stratification variable with keep_strata = TRUE", {
  skip_if_not_installed("erglm")

  # regression test: grouping by the same variable used for
  # stratification while keeping strata bakes that column name into
  # `config$groupings` twice, which used to surface as an opaque
  # "Join columns in `x` must be unique" error from dplyr::left_join()
  plt <- er_test_data |>
    er_plot(aucss, ae1, treatment) |>
    er_plot_add_model(er_test_mod1)

  expect_error(
    er_plot_add_groups(plt, treatment, keep_strata = TRUE),
    "stratification variable"
  )

  # keep_strata = FALSE for that same variable is fine
  expect_no_error(er_plot_add_groups(plt, treatment, keep_strata = FALSE))

  # grouping by a *different* variable with keep_strata = TRUE is unaffected
  expect_no_error(er_plot_add_groups(plt, aucss, keep_strata = TRUE))
})

test_that("er_plot_add_groups is additive across repeated calls", {
  skip_if_not_installed("erglm")

  # regression test: er_plot_add_groups() used to overwrite
  # object$part$group on each call instead of merging into it, so a
  # second call silently dropped the first group panel
  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_groups(aucss) |>
    er_plot_add_groups(treatment)

  expect_named(plt$part$group$config, c(".aucss_quantile", "treatment"))

  built <- er_plot_build(plt)
  expect_named(built$plot$group, c(".aucss_quantile", "treatment"))
  expect_no_error(plot(plt))

  # re-adding the same grouping variable replaces just that one panel,
  # in place, rather than duplicating it
  plt2 <- plt |> er_plot_add_groups(aucss, builder = er_builder_group_violin)
  expect_named(plt2$part$group$config, c(".aucss_quantile", "treatment"))
  expect_identical(plt2$part$group$config[[".aucss_quantile"]]$builder, er_builder_group_violin)
})

test_that("er_plot_add_groups honors per-call keep_strata when mixed", {
  skip_if_not_installed("erglm")

  # regression test: `stratify` used to be stored once for the whole
  # `part$group` and shared by every panel at build time, so mixing
  # `keep_strata = TRUE`/`FALSE` across calls applied the wrong flag to
  # at least one panel (and could error if a panel built without a
  # strata column was then asked to map `fill`/`colour` to it)
  plt <- er_test_data |>
    dplyr::mutate(dose = factor(dose)) |>
    er_plot(aucss, ae1, sex) |>
    er_plot_add_model(er_test_mod2) |>
    er_plot_add_groups(aucss, keep_strata = FALSE) |>
    er_plot_add_groups(dose, keep_strata = TRUE)

  expect_false(plt$part$group$config[[".aucss_quantile"]]$stratify)
  expect_true(plt$part$group$config[["dose"]]$stratify)

  # the unstratified panel's data/groupings should have no strata column
  expect_identical(plt$part$group$config[[".aucss_quantile"]]$groupings, ".aucss_quantile")
  expect_false("sex" %in% names(plt$part$group$config[[".aucss_quantile"]]$data))

  # the stratified panel's data/groupings should include the strata column
  expect_identical(plt$part$group$config[["dose"]]$groupings, c("dose", "sex"))
  expect_true("sex" %in% names(plt$part$group$config[["dose"]]$data))

  # top-level flag (used only for cross-panel strata-legend dedup) is
  # TRUE because at least one panel is stratified
  expect_true(plt$part$group$stratify)

  expect_no_error(er_plot_build(plt))
  built <- er_plot_build(plt)

  # the unstratified panel has no fill/colour legend; the stratified one does
  unstratified_labs <- ggplot2::get_labs(built$plot$group[[".aucss_quantile"]])
  stratified_labs   <- ggplot2::get_labs(built$plot$group[["dose"]])
  expect_null(unstratified_labs$fill)
  expect_equal(stratified_labs$fill, plt$strata$label)

  expect_no_error(plot(plt))
})

test_that("er_plot_build does not error", {
  skip_if_not_installed("erglm")

  plt1 <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1)

  plt2 <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_quantiles()  |>
    er_plot_add_data()

  plt3 <- er_test_data |>
    dplyr::mutate(dose = factor(dose)) |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_quantiles()  |>
    er_plot_add_data()  |>
    er_plot_add_groups(c(treatment, dose))

  expect_no_error(er_plot_build(plt1))
  expect_no_error(er_plot_build(plt2))
  expect_no_error(er_plot_build(plt3))
})

test_that("er_plot_build constructs ggplot2 objects", {
  skip_if_not_installed("erglm")

  plt1 <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1)

  plt2 <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_quantiles()  |>
    er_plot_add_data(builder = er_builder_data_boxjitter)

  plt3 <- er_test_data |>
    dplyr::mutate(dose = factor(dose)) |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_quantiles()  |>
    er_plot_add_data(builder = er_builder_data_boxjitter)  |>
    er_plot_add_groups(c(treatment, dose))

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
    er_plot_add_model(er_test_mod1)

  plt2 <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_quantiles()  |>
    er_plot_add_data(builder = er_builder_data_boxjitter)

  plt3 <- er_test_data |>
    dplyr::mutate(dose = factor(dose)) |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_quantiles()  |>
    er_plot_add_data(builder = er_builder_data_boxjitter)  |>
    er_plot_add_groups(c(treatment, dose))

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

test_that("er_plot_add_data() with the default er_builder_data_overlay merges into the base plot", {
  skip_if_not_installed("erglm")

  # overlay as the *only* layer: the base plot must still get built (for
  # its coord/scale), with no separate object$plot$data panels
  plt <- er_test_data |> er_plot(aucss, ae1) |> er_plot_add_data()
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
    er_plot_add_model(mod2) |>
    er_plot_add_data()

  expect_no_error(er_plot_build(plt_strat))
  built_strat <- er_plot_build(plt_strat)

  expect_true(ggplot2::is_ggplot(built_strat$output))
  expect_equal(ggplot2::get_labs(built_strat$output)$colour, plt_strat$strata$label)
})


# builder escape hatch ---------------------------------------------------------

test_that("er_plot_add_model() accepts a custom builder/summary_builder", {
  skip_if_not_installed("erglm")

  custom_model_builder <- function(data, config, stratify, exposure, response, strata, style) {
    ggplot2::geom_line(
      data = config$predictions,
      mapping = ggplot2::aes(x = .data[[exposure$name]], y = fit_resp),
      linetype = "dashed"
    )
  }
  custom_summary_builder <- function(data, config, stratify, exposure, response, strata, style) {
    list()
  }

  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1, builder = custom_model_builder, summary_builder = custom_summary_builder)

  expect_identical(plt$part$model$config$builder$model, custom_model_builder)
  expect_identical(plt$part$model$config$builder$summary, custom_summary_builder)
  expect_no_error(er_plot_build(plt))
})

test_that("er_plot_add_model() rejects a non-function builder", {
  skip_if_not_installed("erglm")

  plt <- er_test_data |> er_plot(aucss, ae1)
  expect_error(er_plot_add_model(plt, er_test_mod1, builder = "not a function"))
})

test_that("er_plot_add_quantiles() accepts a custom builder", {
  skip_if_not_installed("erglm")

  custom_quantile_builder <- function(data, config, stratify, exposure, response, strata, style) {
    ggplot2::geom_pointrange(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, y = y_mid, ymin = ci_lower, ymax = ci_upper),
      inherit.aes = FALSE
    )
  }

  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_quantiles(builder = custom_quantile_builder)

  expect_identical(plt$part$quantile$config$builder, custom_quantile_builder)
  expect_no_error(er_plot_build(plt))
})

test_that("er_plot_add_quantiles() rejects a non-function builder", {
  skip_if_not_installed("erglm")

  plt <- er_test_data |> er_plot(aucss, ae1) |> er_plot_add_model(er_test_mod1)
  expect_error(er_plot_add_quantiles(plt, builder = "not a function"))
})

test_that("er_plot_add_data() accepts a custom builder for both the overlay and panel structural families", {
  skip_if_not_installed("erglm")

  custom_overlay_builder <- er_builder_tag(function(data, config, stratify, exposure, response, strata, style) {
    ggplot2::geom_point(
      data = data,
      mapping = ggplot2::aes(x = .data[[exposure$name]], y = .data[[response$name]]),
      shape = 4
    )
  }, layout = "overlay")
  custom_panel_builder <- er_builder_tag(function(data, config, stratify, exposure, response, strata, style) {
    ggplot2::geom_histogram(
      data = data,
      mapping = ggplot2::aes(x = .data[[exposure$name]])
    )
  }, layout = "panel")

  plt_overlay <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_data(builder = custom_overlay_builder)

  expect_identical(plt_overlay$part$overlay$config$builder, custom_overlay_builder)
  expect_null(plt_overlay$part$data)
  expect_no_error(er_plot_build(plt_overlay))

  plt_jitter <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_data(builder = custom_panel_builder)

  expect_identical(plt_jitter$part$data$config$builder, custom_panel_builder)
  expect_null(plt_jitter$part$overlay)
  expect_no_error(er_plot_build(plt_jitter))
})

test_that("er_plot_add_data() rejects a builder with no declared layout", {
  skip_if_not_installed("erglm")

  untagged_builder <- function(data, config, stratify, exposure, response, strata, style) list()
  plt <- er_test_data |> er_plot(aucss, ae1) |> er_plot_add_model(er_test_mod1)
  expect_error(er_plot_add_data(plt, builder = untagged_builder))
})

test_that("er_plot_add_groups() accepts a custom builder, applied to every grouping variable", {
  skip_if_not_installed("erglm")

  custom_group_builder <- function(data, config, stratify, exposure, response, strata, style) {
    ggplot2::geom_violin(
      data = config$data,
      mapping = ggplot2::aes(x = .data[[exposure$name]], y = .data[[config$groupings[1]]])
    )
  }

  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_groups(c(aucss, sex), builder = custom_group_builder)

  expect_true(all(purrr::map_lgl(plt$part$group$config, \(cfg) identical(cfg$builder, custom_group_builder))))
  expect_no_error(er_plot_build(plt))
})

test_that("er_plot_add_groups() rejects a non-function builder", {
  skip_if_not_installed("erglm")

  plt <- er_test_data |> er_plot(aucss, ae1) |> er_plot_add_model(er_test_mod1)
  expect_error(er_plot_add_groups(plt, aucss, builder = "not a function"))
})

test_that("er_builder_tag() attaches a layer attribute, validated against a fixed set", {
  fn <- function(data, config, stratify, exposure, response, strata, style) list()

  tagged <- er_builder_tag(fn, layer = "quantile")
  expect_identical(attr(tagged, "er_builder_layer"), "quantile")

  expect_error(er_builder_tag(fn, layer = "not_a_layer"))
})

test_that("built-in builders are tagged with their layer", {
  expect_identical(attr(er_builder_model_ribbonline, "er_builder_layer"), "model")
  expect_identical(attr(er_builder_model_line, "er_builder_layer"), "model")
  expect_identical(attr(er_builder_model_spaghetti, "er_builder_layer"), "model")
  expect_identical(attr(er_builder_summary_pvalue, "er_builder_layer"), "summary")
  expect_identical(attr(er_builder_quantile_errorbar, "er_builder_layer"), "quantile")
  expect_identical(attr(er_builder_quantile_errorbar_vlines, "er_builder_layer"), "quantile")
  expect_identical(attr(er_builder_quantile_pointrange, "er_builder_layer"), "quantile")
  expect_identical(attr(er_builder_quantile_pointrange_vlines, "er_builder_layer"), "quantile")
  expect_identical(attr(er_builder_data_overlay, "er_builder_layer"), "data")
  expect_identical(attr(er_builder_data_boxjitter, "er_builder_layer"), "data")
  expect_identical(attr(er_builder_data_hex, "er_builder_layer"), "data")
  expect_identical(attr(er_builder_group_boxplot, "er_builder_layer"), "group")
  expect_identical(attr(er_builder_group_violin, "er_builder_layer"), "group")
  expect_identical(attr(er_builder_group_histogram, "er_builder_layer"), "group")
})

test_that("er_plot_add_model() errors informatively for a wrong-layer builder/summary_builder", {
  skip_if_not_installed("erglm")

  plt <- er_test_data |> er_plot(aucss, ae1)

  expect_error(
    er_plot_add_model(plt, er_test_mod1, builder = er_builder_quantile_errorbar),
    "quantile"
  )
  expect_error(
    er_plot_add_model(plt, er_test_mod1, summary_builder = er_builder_group_boxplot),
    "group"
  )
  # a builder tagged for the right layer (or no layer at all) is unaffected
  expect_no_error(er_plot_add_model(plt, er_test_mod1, builder = er_builder_model_line))
})

test_that("er_plot_add_quantiles() errors informatively for a wrong-layer builder", {
  skip_if_not_installed("erglm")

  plt <- er_test_data |> er_plot(aucss, ae1) |> er_plot_add_model(er_test_mod1)

  expect_error(
    er_plot_add_quantiles(plt, builder = er_builder_data_overlay),
    "data"
  )
  expect_no_error(er_plot_add_quantiles(plt, builder = er_builder_quantile_pointrange))
})

test_that("er_plot_add_data() errors informatively for a wrong-layer builder", {
  skip_if_not_installed("erglm")

  plt <- er_test_data |> er_plot(aucss, ae1) |> er_plot_add_model(er_test_mod1)

  expect_error(
    er_plot_add_data(plt, builder = er_builder_group_boxplot),
    "group"
  )
  expect_no_error(er_plot_add_data(plt, builder = er_builder_data_boxjitter))
})

test_that("er_plot_add_groups() errors informatively for a wrong-layer builder", {
  skip_if_not_installed("erglm")

  plt <- er_test_data |> er_plot(aucss, ae1) |> er_plot_add_model(er_test_mod1)

  expect_error(
    er_plot_add_groups(plt, aucss, builder = er_builder_quantile_errorbar),
    "quantile"
  )
  expect_no_error(er_plot_add_groups(plt, aucss, builder = er_builder_group_violin))
})

test_that("a builder with no `layer` tag is never checked, in any layer", {
  skip_if_not_installed("erglm")

  untagged <- function(data, config, stratify, exposure, response, strata, style) list()
  plt <- er_test_data |> er_plot(aucss, ae1)

  expect_no_error(er_plot_add_model(plt, er_test_mod1, builder = untagged, summary_builder = untagged))
  expect_no_error(er_plot_add_quantiles(er_plot_add_model(plt, er_test_mod1), builder = untagged))
})
