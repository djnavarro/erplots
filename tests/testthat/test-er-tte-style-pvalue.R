test_that("er_tte_add_pvalue requires a stratified er_tte object", {
  expect_error(
    survival::lung |> er_tte(time, status == 2) |> er_tte_add_pvalue(),
    "requires a stratified"
  )
})

test_that("er_tte_add_pvalue errors when stratify_by has only 1 level present", {
  df <- survival::lung
  df$sex <- factor(1)
  expect_error(
    df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_add_pvalue(),
    "only 1 level"
  )
})

test_that("er_tte_add_pvalue errors on a non-er_tte object", {
  expect_error(er_tte_add_pvalue(list()), "er_tte object")
})

test_that("er_tte_add_pvalue errors when a builder tagged for a different layer is passed", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  expect_error(
    df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_add_pvalue(style = er_style_tte_curve_km),
    "pvalue"
  )
})

test_that("er_tte_add_pvalue's log-rank p-value matches a direct survival::survdiff() call", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  obj <- df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_add_pvalue()

  lr_direct <- survival::survdiff(survival::Surv(time, status == 2) ~ sex, data = df)
  p_direct <- stats::pchisq(lr_direct$chisq, length(lr_direct$n) - 1, lower.tail = FALSE)

  expect_equal(obj$layer$pvalue$config$p_value, unname(p_direct))
})

test_that("er_tte_add_pvalue matches survdiff() with more than 2 strata", {
  obj <- survival::lung |> er_tte(time, status == 2, stratify_by = age, n_strata = 3) |> er_tte_add_pvalue()

  lr_direct <- survival::survdiff(
    survival::Surv(time, status == 2) ~ obj$data$.er_tte_strata,
    data = survival::lung
  )
  p_direct <- stats::pchisq(lr_direct$chisq, length(lr_direct$n) - 1, lower.tail = FALSE)

  expect_equal(obj$layer$pvalue$config$p_value, unname(p_direct))
})

test_that("print.er_tte shows the log-rank p-value once the pvalue layer is added", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  obj <- df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_add_pvalue()
  expect_output(print(obj), "log-rank")
})

test_that("er_style_tte_pvalue_logrank draws a label geom placed away from the curve", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  obj <- df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_add_curve() |> er_tte_add_pvalue()
  built <- er_tte_build(obj)

  label_layer <- Filter(function(l) inherits(l$geom, "GeomLabel"), built$output$layers)
  expect_length(label_layer, 1)
})

test_that("er_style_tte_pvalue_logrank is tagged for the pvalue layer", {
  expect_equal(attr(er_style_tte_pvalue_logrank, "er_style_layer"), "pvalue")
})

test_that("er_style_tte_pvalue_logrank returns no geoms without a p-value (fallback guard)", {
  geoms <- er_style_tte_pvalue_logrank(
    data = NULL, config = list(p_value = NULL), stratify = TRUE,
    time = list(), strata = list(), theme = list(format_p = identity)
  )
  expect_length(geoms, 0)
})
