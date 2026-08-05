test_that("er_style_tte_risktable_text draws a geom_text with one row per stratum", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_add_risktable()
  geoms <- er_style_tte_risktable_text(
    data = NULL, config = obj$layer$risktable$config, stratify = FALSE,
    time = obj$time, strata = NULL, theme = obj$theme
  )
  expect_length(geoms, 1)
  expect_s3_class(geoms[[1]], "LayerInstance")
  expect_equal(unique(as.character(geoms[[1]]$data$strata)), "All")
})

test_that("er_style_tte_risktable_text's config$table has a row per stratum per break", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  obj <- df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_add_risktable(n_times = 5)

  tbl <- obj$layer$risktable$config$table
  expect_setequal(unique(tbl$strata), c("Male", "Female"))
  expect_equal(nrow(tbl), length(unique(tbl$time)) * 2)
})

test_that("er_style_tte_risktable_text's n_risk values match summary.survfit() directly", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_add_risktable(times = c(0, 100, 300))
  fit_summary <- summary(survival::survfit(survival::Surv(time, status == 2) ~ 1, data = survival::lung),
                          times = c(0, 100, 300), extend = TRUE)
  expect_equal(obj$layer$risktable$config$table$n_risk, unname(fit_summary$n.risk))
})

test_that("er_style_tte_risktable_text is tagged for the risktable layer", {
  expect_equal(attr(er_style_tte_risktable_text, "er_style_layer"), "risktable")
})
