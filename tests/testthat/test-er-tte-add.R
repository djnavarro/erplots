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
