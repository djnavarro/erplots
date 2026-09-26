# logrank ---------------------------------------------------------------

test_that("er_tte_add_summary's default builder draws nothing on an unstratified object", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_add_summary()
  expect_null(obj$layer$summary$config$logrank_p_value)
  built <- er_tte_build(obj)
  label_layer <- Filter(function(l) inherits(l$geom, "GeomLabel"), built$output$layers)
  expect_length(label_layer, 0)
})

test_that("er_tte_add_summary's default builder draws nothing when stratify_by has only 1 level present", {
  df <- survival::lung
  df$sex <- factor(1)
  obj <- df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_add_summary()
  expect_null(obj$layer$summary$config$logrank_p_value)
  built <- er_tte_build(obj)
  label_layer <- Filter(function(l) inherits(l$geom, "GeomLabel"), built$output$layers)
  expect_length(label_layer, 0)
})

test_that("er_tte_add_summary errors on a non-er_tte object", {
  expect_error(er_tte_add_summary(list()), "er_tte object")
})

test_that("er_tte_add_summary errors when a builder tagged for a different layer is passed", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  expect_error(
    df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_add_summary(style = er_style_tte_curve_km),
    "summary"
  )
})

test_that("er_tte_add_summary's log-rank p-value matches a direct survival::survdiff() call", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  obj <- df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_add_summary()

  lr_direct <- survival::survdiff(survival::Surv(time, status == 2) ~ sex, data = df)
  p_direct <- stats::pchisq(lr_direct$chisq, length(lr_direct$n) - 1, lower.tail = FALSE)

  expect_equal(obj$layer$summary$config$logrank_p_value, unname(p_direct))
})

test_that("er_tte_add_summary matches survdiff() with more than 2 strata", {
  # stratify_by must be discrete -- bin age into 3 quantile groups first
  df <- survival::lung
  df$age_grp <- cut_quantile(df$age, n = 3)
  obj <- df |> er_tte(time, status == 2, stratify_by = age_grp) |> er_tte_add_summary()

  lr_direct <- survival::survdiff(
    survival::Surv(time, status == 2) ~ obj$data$.er_tte_strata,
    data = df
  )
  p_direct <- stats::pchisq(lr_direct$chisq, length(lr_direct$n) - 1, lower.tail = FALSE)

  expect_equal(obj$layer$summary$config$logrank_p_value, unname(p_direct))
})

test_that("print.er_tte shows the log-rank p-value once the summary layer is added", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  obj <- df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_add_summary()
  expect_output(print(obj), "log-rank")
})

test_that("er_style_tte_summary_logrank draws a label geom placed away from the curve", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  obj <- df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_add_curve() |> er_tte_add_summary()
  built <- er_tte_build(obj)

  label_layer <- Filter(function(l) inherits(l$geom, "GeomLabel"), built$output$layers)
  expect_length(label_layer, 1)
})

test_that("er_style_tte_summary_logrank is tagged for the summary layer", {
  expect_equal(attr(er_style_tte_summary_logrank, "er_style_layer"), "tte_summary")
})

test_that("er_tte_add_summary rejects an er_plot() summary builder rather than silently no-oping", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  expect_error(
    df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_add_summary(style = er_style_summary_pvalue),
    "tte_summary"
  )
})

test_that("er_style_tte_summary_logrank returns no geoms without a p-value (fallback guard)", {
  geoms <- er_style_tte_summary_logrank(
    data = NULL, config = list(logrank_p_value = NULL), stratify = TRUE,
    time = list(), strata = list(), theme = list(format_p = identity)
  )
  expect_length(geoms, 0)
})

# n -----------------------------------------------------------------------

test_that("er_style_tte_summary_n works on an unstratified object", {
  obj <- survival::lung |>
    er_tte(time, status == 2) |>
    er_tte_add_curve() |>
    er_tte_add_summary(style = er_style_tte_summary_n)
  built <- er_tte_build(obj)
  label_layer <- Filter(function(l) inherits(l$geom, "GeomLabel"), built$output$layers)
  expect_length(label_layer, 1)
})

test_that("er_style_tte_summary_n reports one line per stratum when stratified", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  geoms <- er_style_tte_summary_n(
    data = df |> transform(.er_tte_strata = sex, .er_tte_event = status == 2),
    config = list(corner_distance = c(top_left = 1, top_right = 2, bottom_left = 3, bottom_right = 4)),
    stratify = TRUE, time = list(), strata = list(var = "sex"), theme = list()
  )
  lbl <- geoms$data$lbl
  expect_true(grepl("Male", lbl) && grepl("Female", lbl))
})

test_that("er_style_tte_summary_n is tagged for the summary layer", {
  expect_equal(attr(er_style_tte_summary_n, "er_style_layer"), "tte_summary")
})

# coefficients/gof ----------------------------------------------------------

test_that("er_style_tte_summary_coefficients draws nothing without a coefficients table", {
  geoms <- er_style_tte_summary_coefficients(
    data = NULL, config = list(summary = NULL), stratify = FALSE,
    time = list(), strata = list(), theme = list()
  )
  expect_length(geoms, 0)
})

test_that("er_style_tte_summary_coefficients draws nothing when the layer is stratified", {
  coefs <- tibble::tibble(term = "sex", estimate = 1.2, p_value = 0.03)
  geoms <- er_style_tte_summary_coefficients(
    data = NULL, config = list(summary = list(coefficients = coefs)), stratify = TRUE,
    time = list(), strata = list(), theme = list()
  )
  expect_length(geoms, 0)
})

test_that("er_style_tte_summary_coefficients draws a label from the coefficients table", {
  coefs <- tibble::tibble(term = "age", estimate = 0.04, p_value = 0.01)
  geoms <- er_style_tte_summary_coefficients(
    data = NULL,
    config = list(
      summary = list(coefficients = coefs),
      corner_distance = c(top_left = 1, top_right = 2, bottom_left = 3, bottom_right = 4)
    ),
    stratify = FALSE, time = list(), strata = list(),
    theme = list(format_number = function(x) format(round(x, 2)), format_p = function(x) paste0("p=", x))
  )
  expect_true(grepl("age", geoms$data$lbl))
})

test_that("er_style_tte_summary_coefficients is tagged for the summary layer", {
  expect_equal(attr(er_style_tte_summary_coefficients, "er_style_layer"), "tte_summary")
})

test_that("er_style_tte_summary_gof draws nothing without a glance table", {
  geoms <- er_style_tte_summary_gof(
    data = NULL, config = list(summary = NULL), stratify = FALSE,
    time = list(), strata = list(), theme = list()
  )
  expect_length(geoms, 0)
})

test_that("er_style_tte_summary_gof draws nothing when the layer is stratified", {
  glance <- tibble::tibble(n = 10, aic = 100)
  geoms <- er_style_tte_summary_gof(
    data = NULL, config = list(summary = list(glance = glance)), stratify = TRUE,
    time = list(), strata = list(), theme = list()
  )
  expect_length(geoms, 0)
})

test_that("er_style_tte_summary_gof draws only the fields that are present and non-NA", {
  glance <- tibble::tibble(n = 228, aic = NA_real_, bic = 950.2, r_squared = NA_real_)
  geoms <- er_style_tte_summary_gof(
    data = NULL,
    config = list(
      summary = list(glance = glance),
      corner_distance = c(top_left = 1, top_right = 2, bottom_left = 3, bottom_right = 4)
    ),
    stratify = FALSE, time = list(), strata = list(),
    theme = list(format_number = function(x) format(round(x, 1)))
  )
  expect_true(grepl("N", geoms$data$lbl))
  expect_true(grepl("BIC", geoms$data$lbl))
  expect_false(grepl("AIC", geoms$data$lbl))
})

test_that("er_style_tte_summary_gof is tagged for the summary layer", {
  expect_equal(attr(er_style_tte_summary_gof, "er_style_layer"), "tte_summary")
})
