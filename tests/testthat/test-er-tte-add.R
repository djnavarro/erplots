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
