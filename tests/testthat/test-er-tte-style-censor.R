test_that("er_style_tte_censor_ticks draws a point geom at each censoring time", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_add_curve() |> er_tte_add_censor()
  built <- er_tte_build(obj)
  layer_geoms <- vapply(built$output$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomPoint" %in% layer_geoms)
})

test_that("er_style_tte_censor_ticks's config only keeps rows with n_censor > 0", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_add_censor()
  expect_true(all(obj$layer$censor$config$table$n_censor > 0))
  expect_true(nrow(obj$layer$censor$config$table) > 0)
})

test_that("er_style_tte_censor_ticks's marks land on the survival curve", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_add_censor()
  fit_direct <- survival::survfit(survival::Surv(time, status == 2) ~ 1, data = survival::lung)
  censor_tbl <- obj$layer$censor$config$table
  expect_true(all(censor_tbl$time %in% fit_direct$time))
  expect_true(all(censor_tbl$surv %in% fit_direct$surv))
})

test_that("er_style_tte_censor_ticks stratifies colour by config$table's strata column", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  obj <- df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_add_curve() |> er_tte_add_censor()
  built <- er_tte_build(obj)

  point_layer <- Filter(function(l) inherits(l$geom, "GeomPoint"), built$output$layers)[[1]]
  expect_true("colour" %in% names(point_layer$mapping) || "colour" %in% names(point_layer$computed_mapping))
})

test_that("er_style_tte_censor_ticks's marks never add their own legend entry", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  obj <- df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_add_curve() |> er_tte_add_censor()
  built <- er_tte_build(obj)

  point_layer <- Filter(function(l) inherits(l$geom, "GeomPoint"), built$output$layers)[[1]]
  expect_false(point_layer$show.legend)
})

test_that("er_style_tte_censor_ticks returns no geoms when config$table is empty (fallback guard)", {
  geoms <- er_style_tte_censor_ticks(
    data = NULL, config = list(table = survival::lung[0, ]), stratify = FALSE,
    time = list(), strata = NULL, theme = list()
  )
  expect_length(geoms, 0)
})

test_that("er_style_tte_censor_ticks is tagged for the censor layer", {
  expect_equal(attr(er_style_tte_censor_ticks, "er_style_layer"), "censor")
})
