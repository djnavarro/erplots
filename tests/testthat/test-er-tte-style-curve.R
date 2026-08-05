test_that("er_style_tte_curve_km draws a ribbon + step line by default", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_add_curve()
  built <- er_tte_build(obj)
  layer_geoms <- vapply(built$output$layers, function(l) class(l$geom)[1], character(1))
  expect_setequal(layer_geoms, c("GeomRect", "GeomStep"))
})

test_that("er_style_tte_curve_km's show_ci = FALSE omits the ribbon", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_add_curve(show_ci = FALSE)
  built <- er_tte_build(obj)
  expect_length(built$output$layers, 1)
  expect_s3_class(built$output$layers[[1]]$geom, "GeomStep")
})

test_that("er_style_tte_curve_km's curve starts at (0, 1)", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_add_curve()
  expect_equal(obj$layer$curve$config$table$time[1], 0)
  expect_equal(obj$layer$curve$config$table$surv[1], 1)
})

test_that("er_style_tte_curve_km's KM curve matches survival::survfit()'s own survival values", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_add_curve()
  fit_direct <- survival::survfit(survival::Surv(time, status == 2) ~ 1, data = survival::lung)

  # drop the (0, 1) origin row erplots prepends before comparing
  curve_tbl <- obj$layer$curve$config$table[-1, ]
  expect_equal(curve_tbl$time, unname(fit_direct$time))
  expect_equal(curve_tbl$surv, unname(fit_direct$surv))
})

test_that("er_style_tte_curve_km stratifies color/fill by config$table's strata column", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  obj <- df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_add_curve()
  built <- er_tte_build(obj)

  step_layer <- Filter(function(l) inherits(l$geom, "GeomStep"), built$output$layers)[[1]]
  expect_true("colour" %in% names(step_layer$mapping) || "colour" %in% names(step_layer$computed_mapping))
})

test_that("er_style_tte_curve_km's ribbon extends the last interval to the time axis limit", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_add_curve()
  step_table <- obj$layer$curve$config$table |>
    dplyr::mutate(xmax = dplyr::lead(time, default = obj$layer$curve$config$time_upper))
  expect_equal(tail(step_table$xmax, 1), obj$time$limits[2])
})

test_that("er_style_tte_curve_km errors informatively without config$table (fallback guard)", {
  expect_error(
    er_style_tte_curve_km(
      data = NULL, config = list(time_upper = 100), stratify = FALSE,
      time = list(), strata = NULL, theme = list(draw_key = NULL)
    )
  )
})

test_that("er_style_tte_curve_km is tagged for the curve layer", {
  expect_equal(attr(er_style_tte_curve_km, "er_style_layer"), "curve")
})
