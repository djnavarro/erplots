skip_if_not_installed("erglm")

test_that("er_plot_theme() writes labels to the expected fields", {
  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_theme(xlab = "Exposure (AUCss)", ylab = "Adverse event")

  expect_equal(plt$exposure$label, "Exposure (AUCss)")
  expect_equal(plt$response$label, "Adverse event")
})

test_that("er_plot_theme() writes strata_lab, and errors with no stratification set", {
  plt <- er_test_data |>
    er_plot(aucss, ae1, stratify_by = sex) |>
    er_plot_theme(strata_lab = "Sex")
  expect_equal(plt$strata$label, "Sex")

  plt_unstrat <- er_test_data |> er_plot(aucss, ae1)
  expect_error(er_plot_theme(plt_unstrat, strata_lab = "Sex"), "stratify_by")
})

test_that("er_plot_theme() writes title/subtitle/caption, applied via plot_annotation()", {
  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_theme(title = "My title", subtitle = "My subtitle", caption = "My caption")

  expect_equal(plt$theme$title, "My title")
  expect_equal(plt$theme$subtitle, "My subtitle")
  expect_equal(plt$theme$caption, "My caption")

  built <- er_plot_build(plt)
  expect_true(ggplot2::is_ggplot(built$output))
})

test_that("er_plot_theme() writes xlim/ylim, consumed lazily at build time", {
  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_theme(xlim = c(0, 100), ylim = c(-0.1, 1.1))

  expect_equal(plt$exposure$limits, c(0, 100))
  expect_equal(plt$response$limits, c(-0.1, 1.1))
  expect_no_error(er_plot_build(plt))
})

test_that("er_plot_theme() validates xlab/ylab/strata_lab/title/subtitle/caption", {
  plt <- er_test_data |> er_plot(aucss, ae1)
  expect_error(er_plot_theme(plt, xlab = c("a", "b")), "single string")
  expect_error(er_plot_theme(plt, title = 1), "single string")
})

test_that("er_plot_theme() validates xlim/ylim", {
  plt <- er_test_data |> er_plot(aucss, ae1)
  expect_error(er_plot_theme(plt, xlim = 1), "length-2")
  expect_error(er_plot_theme(plt, xlim = c(5, 1)), "increasing")
})

test_that("er_plot_theme() writes and validates theme_base/theme_extra", {
  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_theme(theme_base = ggplot2::theme_minimal(), theme_extra = ggplot2::theme())

  expect_identical(plt$theme$theme_base, ggplot2::theme_minimal())
  expect_identical(plt$theme$theme_extra, ggplot2::theme())
  expect_no_error(er_plot_build(plt))

  expect_error(er_plot_theme(plt, theme_base = "not a theme"), "theme")
})

test_that("er_plot_theme() writes and validates format_p/format_percent/format_number", {
  plt <- er_test_data |> er_plot(aucss, ae1)
  new_fmt <- scales::label_pvalue(accuracy = .0001)
  plt <- er_plot_theme(plt, format_p = new_fmt)
  expect_identical(plt$theme$format_p, new_fmt)

  expect_error(er_plot_theme(plt, format_number = "not a function"), "function")
})

test_that("er_plot_theme() writes and validates draw_key", {
  plt <- er_test_data |> er_plot(aucss, ae1)
  plt <- er_plot_theme(plt, draw_key = ggplot2::draw_key_point)
  expect_identical(plt$theme$draw_key, ggplot2::draw_key_point)

  expect_error(er_plot_theme(plt, draw_key = 1), "function")
})

test_that("er_plot_theme() merges height overrides without disturbing other fields", {
  plt <- er_test_data |> er_plot(aucss, ae1)
  default_height <- plt$theme$height

  plt <- er_plot_theme(plt, height_group = 10)
  expect_equal(plt$theme$height$group, 10)
  expect_equal(plt$theme$height$base, default_height$base)
  expect_equal(plt$theme$height$data, default_height$data)

  expect_error(er_plot_theme(plt, height_base = -1), "positive")
  expect_error(er_plot_theme(plt, height_base = c(1, 2)), "positive")
})

test_that("er_plot_theme() calls accumulate rather than replace previous settings", {
  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_theme(xlab = "Exposure") |>
    er_plot_theme(ylab = "Response")

  expect_equal(plt$exposure$label, "Exposure")
  expect_equal(plt$response$label, "Response")
})

test_that("er_plot_theme() writes and validates discrete color/fill scales", {
  plt <- er_test_data |> er_plot(aucss, ae1, stratify_by = sex)
  color_scale <- ggplot2::scale_color_brewer(palette = "Set2")
  fill_scale <- ggplot2::scale_fill_brewer(palette = "Set2")
  plt <- er_plot_theme(plt, color_discrete = color_scale, fill_discrete = fill_scale)

  expect_identical(plt$theme$color_discrete, color_scale)
  expect_identical(plt$theme$fill_discrete, fill_scale)

  expect_error(er_plot_theme(plt, color_discrete = "not a scale"), "Scale")
})

test_that("integration: several er_plot_theme() overrides applied at once build successfully", {
  plt <- er_test_data |>
    er_plot(aucss, ae1, stratify_by = sex) |>
    er_plot_add_model(er_test_mod2) |>
    er_plot_add_quantiles() |>
    er_plot_add_data() |>
    er_plot_add_groups(aucss) |>
    er_plot_theme(
      xlab = "Custom exposure label",
      theme_base = ggplot2::theme_minimal(),
      color_discrete = ggplot2::scale_color_brewer(palette = "Set2"),
      fill_discrete = ggplot2::scale_fill_brewer(palette = "Set2"),
      title = "Integration test plot"
    )

  built <- er_plot_build(plt)
  expect_true(ggplot2::is_ggplot(built$output))
  expect_equal(ggplot2::get_labs(built$plot$base)$x, "Custom exposure label")
})

test_that("fill_discrete doesn't affect an er_style_data_hex() density fill", {
  skip_if_not_installed("hexbin")
  mod <- erglm::erglm_model(biomarker_change ~ aucss, er_test_data, family = gaussian())
  plt <- er_test_data |>
    er_plot(aucss, biomarker_change) |>
    er_plot_add_model(mod, style = er_style_model_line) |>
    er_plot_add_data(style = er_style_data_hex) |>
    er_plot_theme(fill_discrete = ggplot2::scale_fill_brewer(palette = "Set2"))

  expect_no_error(built <- er_plot_build(plt))
  # the density fill scale should be untouched -- not coerced into a
  # discrete brewer palette
  fill_scale <- built$plot$base$scales$get_scales("fill")
  expect_false(inherits(fill_scale, "ScaleDiscrete"))
})

test_that("er_plot_theme() writes and validates continuous color/fill scales", {
  plt <- er_test_data |> er_plot(aucss, ae1)
  color_scale <- ggplot2::scale_color_viridis_c()
  fill_scale <- ggplot2::scale_fill_viridis_c()
  plt <- er_plot_theme(plt, color_continuous = color_scale, fill_continuous = fill_scale)

  expect_identical(plt$theme$color_continuous, color_scale)
  expect_identical(plt$theme$fill_continuous, fill_scale)

  expect_error(er_plot_theme(plt, color_continuous = "not a scale"), "ScaleContinuous")
  # a *discrete* scale is rejected too -- `color_continuous` isn't just an
  # alias for `color_discrete`
  expect_error(
    er_plot_theme(plt, color_continuous = ggplot2::scale_color_brewer()),
    "ScaleContinuous"
  )
})

test_that("fill_continuous replaces an er_style_data_hex() density fill", {
  skip_if_not_installed("hexbin")
  mod <- erglm::erglm_model(biomarker_change ~ aucss, er_test_data, family = gaussian())
  plt <- er_test_data |>
    er_plot(aucss, biomarker_change) |>
    er_plot_add_model(mod, style = er_style_model_line) |>
    er_plot_add_data(style = er_style_data_hex) |>
    er_plot_theme(fill_continuous = ggplot2::scale_fill_viridis_c())

  expect_no_error(built <- er_plot_build(plt))
  fill_scale <- built$plot$base$scales$get_scales("fill")
  expect_true(inherits(fill_scale, "ScaleContinuous"))
  expect_match(deparse(fill_scale$call), "scale_fill_viridis_c\\(\\)$")

  # color_discrete/color_continuous have nothing to touch here (`colour`
  # isn't mapped at all), and fill_discrete must not clobber the density
  # fill even when fill_continuous is also supplied
  plt2 <- plt |> er_plot_theme(fill_discrete = ggplot2::scale_fill_brewer())
  expect_no_error(built2 <- er_plot_build(plt2))
  fill_scale2 <- built2$plot$base$scales$get_scales("fill")
  expect_true(inherits(fill_scale2, "ScaleContinuous"))
})

test_that("color_continuous applies to a custom builder's response-colored data panel", {
  # there's no built-in "panel"-layout builder for a continuous/count
  # response's `color_role == "response"` case (see PLAN.md's "Data
  # layer color scale / continuous-response panel design") -- exercise
  # the `.polish_scales()` branch with a small custom one instead
  custom_response_color_builder <- er_style_tag(
    function(data, config, stratify, exposure, response, strata, theme, ...) {
      list(
        ggplot2::geom_point(
          data = data,
          mapping = ggplot2::aes(x = .data[[exposure$name]], y = 0, color = .data[[response$name]])
        )
      )
    },
    layout = "panel"
  )

  mod <- erglm::erglm_model(biomarker_change ~ aucss, er_test_data, family = gaussian())
  plt <- er_test_data |>
    er_plot(aucss, biomarker_change) |>
    er_plot_add_model(mod, style = er_style_model_line) |>
    er_plot_add_data(style = custom_response_color_builder) |>
    er_plot_theme(color_continuous = ggplot2::scale_color_viridis_c())

  expect_no_error(built <- er_plot_build(plt))
  color_scale <- built$plot$data[["data"]]$scales$get_scales("colour")
  expect_true(inherits(color_scale, "ScaleContinuous"))
  expect_match(deparse(color_scale$call), "scale_color_viridis_c\\(\\)$")
})
