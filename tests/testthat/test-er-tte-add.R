test_that("er_tte_add_curve adds a curve layer with the default style", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_add_curve()
  expect_false(is.null(obj$layer$curve))
  expect_identical(obj$layer$curve$style, er_style_tte_curve_km)
})

test_that("er_tte_add_curve is a singleton -- a second call replaces the first", {
  obj <- survival::lung |>
    er_tte(time, status == 2) |>
    er_tte_add_curve(show_ci = TRUE) |>
    er_tte_add_curve(show_ci = FALSE)
  expect_identical(obj$layer$curve$dots, list(show_ci = FALSE))
})

test_that("er_tte_add_curve errors on a non-er_tte object", {
  expect_error(er_tte_add_curve(list()), "er_tte object")
})

test_that("er_tte_add_curve errors when style is not a function", {
  expect_error(survival::lung |> er_tte(time, status == 2) |> er_tte_add_curve(style = 1), "must be a function")
})

test_that("er_tte_add_curve errors when a builder tagged for a different layer is passed", {
  expect_error(
    survival::lung |> er_tte(time, status == 2) |> er_tte_add_curve(style = er_style_summary_pvalue),
    "curve"
  )
})

test_that("er_tte_add_curve errors on unnamed extra arguments", {
  expect_error(
    survival::lung |> er_tte(time, status == 2) |> er_tte_add_curve(NULL, 0.3),
    "named"
  )
})

test_that("er_tte_build assembles the curve layer onto the base panel", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_add_curve()
  built <- er_tte_build(obj)
  expect_s3_class(built$output, "ggplot")
  # ribbon + step line, since show_ci defaults to TRUE
  expect_length(built$output$layers, 2)
})

test_that("er_tte_build retitles a stratified legend with the real variable label", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  obj <- df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_add_curve()
  built <- er_tte_build(obj)

  labs <- ggplot2::get_labs(built$output)
  expect_equal(labs$colour, "sex")
  expect_equal(labs$fill, "sex")
})

test_that("er_tte_build leaves an unstratified plot's labels untouched", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_add_curve()
  built <- er_tte_build(obj)
  labs <- ggplot2::get_labs(built$output)
  expect_null(labs$colour)
  expect_null(labs$fill)
})

# censor -----------------------------------------------------------------------

test_that("er_tte_add_censor adds a censor layer with the default style", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_add_censor()
  expect_false(is.null(obj$layer$censor))
  expect_identical(obj$layer$censor$style, er_style_tte_censor_ticks)
})

test_that("er_tte_add_censor is a singleton -- a second call replaces the first", {
  obj <- survival::lung |>
    er_tte(time, status == 2) |>
    er_tte_add_censor(shape = 3) |>
    er_tte_add_censor(shape = 124)
  expect_identical(obj$layer$censor$dots, list(shape = 124))
})

test_that("er_tte_add_censor errors on a non-er_tte object", {
  expect_error(er_tte_add_censor(list()), "er_tte object")
})

test_that("er_tte_add_censor errors when style is not a function", {
  expect_error(survival::lung |> er_tte(time, status == 2) |> er_tte_add_censor(style = 1), "must be a function")
})

test_that("er_tte_add_censor errors when a builder tagged for a different layer is passed", {
  expect_error(
    survival::lung |> er_tte(time, status == 2) |> er_tte_add_censor(style = er_style_tte_curve_km),
    "censor"
  )
})

test_that("er_tte_add_censor errors on unnamed extra arguments", {
  expect_error(
    survival::lung |> er_tte(time, status == 2) |> er_tte_add_censor(NULL, 0.3),
    "named"
  )
})

test_that("er_tte_build assembles the curve and censor layers together", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_add_curve() |> er_tte_add_censor()
  built <- er_tte_build(obj)
  layer_geoms <- vapply(built$output$layers, function(l) class(l$geom)[1], character(1))
  expect_setequal(layer_geoms, c("GeomRect", "GeomStep", "GeomPoint"))
})

test_that("er_tte_add_censor does not require a stratified object", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_add_censor()
  built <- er_tte_build(obj)
  expect_s3_class(built$output, "ggplot")
})

# risktable -----------------------------------------------------------------

test_that("er_tte_add_risktable adds a risktable layer with the default style", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_add_risktable()
  expect_false(is.null(obj$layer$risktable))
  expect_identical(obj$layer$risktable$style, er_style_tte_risktable_text)
})

test_that("er_tte_add_risktable is a singleton -- a second call replaces the first", {
  obj <- survival::lung |>
    er_tte(time, status == 2) |>
    er_tte_add_risktable(times = c(0, 100)) |>
    er_tte_add_risktable(times = c(0, 200))
  expect_equal(obj$layer$risktable$config$breaks, c(0, 200))
})

test_that("er_tte_add_risktable errors on a non-er_tte object", {
  expect_error(er_tte_add_risktable(list()), "er_tte object")
})

test_that("er_tte_add_risktable errors when style is not a function", {
  expect_error(survival::lung |> er_tte(time, status == 2) |> er_tte_add_risktable(style = 1), "must be a function")
})

test_that("er_tte_add_risktable errors when a builder tagged for a different layer is passed", {
  expect_error(
    survival::lung |> er_tte(time, status == 2) |> er_tte_add_risktable(style = er_style_tte_curve_km),
    "risktable"
  )
})

test_that("er_tte_add_risktable errors on unnamed extra arguments", {
  # `times`/`n_times` are named formals (unlike `er_tte_add_curve()`'s
  # bare `style, ...`), so all three leading arguments must be supplied
  # by name here for the trailing `0.3` to actually land in `...`
  expect_error(
    survival::lung |> er_tte(time, status == 2) |> er_tte_add_risktable(style = NULL, times = NULL, n_times = 6, 0.3),
    "named"
  )
})

test_that("er_tte_add_risktable validates times and n_times", {
  expect_error(survival::lung |> er_tte(time, status == 2) |> er_tte_add_risktable(times = -1), "non-negative")
  expect_error(survival::lung |> er_tte(time, status == 2) |> er_tte_add_risktable(n_times = 1), "n_times")
  expect_error(survival::lung |> er_tte(time, status == 2) |> er_tte_add_risktable(n_times = 2.5), "n_times")
})

test_that("er_tte_build composes a patchwork object when risktable is present", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_add_curve() |> er_tte_add_risktable()
  built <- er_tte_build(obj)
  expect_s3_class(built$output, "patchwork")
})

test_that("er_tte_build's curve panel is ticked at the risktable layer's own time breaks", {
  obj <- survival::lung |>
    er_tte(time, status == 2) |>
    er_tte_add_curve() |>
    er_tte_add_risktable(times = c(0, 200, 400))
  built <- er_tte_build(obj)
  curve_panel <- built$output$patches$plots[[1]]
  expect_equal(curve_panel$scales$get_scales("x")$breaks, c(0, 200, 400))
})

# pvalue ---------------------------------------------------------------------

test_that("er_tte_add_pvalue adds a pvalue layer with the default style", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  obj <- df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_add_pvalue()
  expect_false(is.null(obj$layer$pvalue))
  expect_identical(obj$layer$pvalue$style, er_style_tte_pvalue_logrank)
})

test_that("er_tte_add_pvalue is a singleton -- a second call replaces the first", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  obj <- df |>
    er_tte(time, status == 2, stratify_by = sex) |>
    er_tte_add_pvalue(inset = 0.1) |>
    er_tte_add_pvalue(inset = 0.2)
  expect_identical(obj$layer$pvalue$dots, list(inset = 0.2))
})

test_that("er_tte_add_pvalue errors when style is not a function", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  expect_error(
    df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_add_pvalue(style = 1),
    "must be a function"
  )
})

test_that("er_tte_add_pvalue errors on unnamed extra arguments", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  expect_error(
    df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_add_pvalue(NULL, 0.3),
    "named"
  )
})

test_that("er_tte_build assembles both the curve and pvalue layers together", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  obj <- df |>
    er_tte(time, status == 2, stratify_by = sex) |>
    er_tte_add_curve() |>
    er_tte_add_pvalue()
  built <- er_tte_build(obj)
  layer_geoms <- vapply(built$output$layers, function(l) class(l$geom)[1], character(1))
  expect_setequal(layer_geoms, c("GeomRect", "GeomStep", "GeomLabel"))
})
