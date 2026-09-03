test_that("er_style_tte_model_line draws a ribbon + line by default", {
  obj <- survival::lung |>
    er_tte(time, status == 2) |>
    er_tte_add_model(er_test_toy_tte_model(survival::Surv(time, status == 2) ~ 1, survival::lung))
  built <- er_tte_build(obj)
  layer_geoms <- vapply(built$output$layers, function(l) class(l$geom)[1], character(1))
  expect_setequal(layer_geoms, c("GeomRibbon", "GeomLine"))
})

test_that("er_style_tte_model_line's show_ci = FALSE omits the ribbon", {
  obj <- survival::lung |>
    er_tte(time, status == 2) |>
    er_tte_add_model(er_test_toy_tte_model(survival::Surv(time, status == 2) ~ 1, survival::lung), show_ci = FALSE)
  built <- er_tte_build(obj)
  expect_length(built$output$layers, 1)
  expect_s3_class(built$output$layers[[1]]$geom, "GeomLine")
})

test_that("er_style_tte_model_line's predictions span [0, 1]", {
  obj <- survival::lung |>
    er_tte(time, status == 2) |>
    er_tte_add_model(er_test_toy_tte_model(survival::Surv(time, status == 2) ~ 1, survival::lung))
  predictions <- obj$layer$model$config$predictions
  expect_true(all(predictions$fit_survival >= 0 & predictions$fit_survival <= 1))
  expect_true(all(predictions$ci_lower <= predictions$fit_survival))
  expect_true(all(predictions$ci_upper >= predictions$fit_survival))
})

test_that("er_style_tte_model_line stratifies color/fill by the strata variable's own column", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  mod <- er_test_toy_tte_model(survival::Surv(time, status == 2) ~ sex, df)
  obj <- df |>
    er_tte(time, status == 2, stratify_by = sex) |>
    er_tte_add_model(mod)
  built <- er_tte_build(obj)

  line_layer <- Filter(function(l) inherits(l$geom, "GeomLine"), built$output$layers)[[1]]
  expect_true("colour" %in% names(line_layer$mapping) || "colour" %in% names(line_layer$computed_mapping))
  expect_setequal(unique(obj$layer$model$config$predictions$sex), c("Male", "Female"))
})

test_that("er_tte_build retitles a stratified model layer's legend with the real variable label", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  mod <- er_test_toy_tte_model(survival::Surv(time, status == 2) ~ sex, df)
  obj <- df |>
    er_tte(time, status == 2, stratify_by = sex) |>
    er_tte_add_model(mod)
  built <- er_tte_build(obj)

  labs <- ggplot2::get_labs(built$output)
  expect_equal(labs$colour, "sex")
  expect_equal(labs$fill, "sex")
})

test_that("er_style_tte_model_line is tagged for the model layer", {
  expect_equal(attr(er_style_tte_model_line, "er_style_layer"), "model")
})
