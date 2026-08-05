# `survival` is an `Imports` dependency (see `.agents/PLAN.md`'s TTE
# grammar entry), so `survival::lung` is always available here -- no
# `skip_if_not_installed()` needed, unlike the erglm/emaxnls fixtures.

test_that("er_tte creates an er_tte (minimal, single-arm)", {
  expect_no_error(survival::lung |> er_tte(time, status == 2))
  obj <- survival::lung |> er_tte(time, status == 2)
  expect_s3_class(obj, "er_tte")
})

test_that("er_tte accepts a bare 0/1 or logical event column, not just an expression", {
  df <- survival::lung
  df$event_lgl <- df$status == 2
  df$event_num <- as.numeric(df$event_lgl)

  expect_no_error(df |> er_tte(time, event_lgl))
  expect_no_error(df |> er_tte(time, event_num))
})

test_that("er_tte's single-arm KM fit matches a direct survival::survfit() call", {
  obj <- survival::lung |> er_tte(time, status == 2)
  fit_direct <- survival::survfit(survival::Surv(time, status == 2) ~ 1, data = survival::lung)

  expect_equal(unname(obj$km$table$time),  unname(fit_direct$time))
  expect_equal(unname(obj$km$table$surv),  unname(fit_direct$surv))
  expect_equal(unname(obj$km$table$lower), unname(fit_direct$lower))
  expect_equal(unname(obj$km$table$upper), unname(fit_direct$upper))
  expect_equal(obj$km$fit$n, fit_direct$n)
})

test_that("er_tte respects conf_level when computing the KM confidence band", {
  obj_95 <- survival::lung |> er_tte(time, status == 2, conf_level = 0.95)
  obj_90 <- survival::lung |> er_tte(time, status == 2, conf_level = 0.90)

  # a narrower confidence level produces a narrower band at every time point
  expect_true(all(obj_90$km$table$upper - obj_90$km$table$lower <=
    obj_95$km$table$upper - obj_95$km$table$lower))
})

test_that("er_tte stores time/event labels derived from the supplied expressions", {
  obj <- survival::lung |> er_tte(time, status == 2)
  expect_equal(obj$time$label, "time")
  expect_equal(obj$event$label, "status == 2")
})

test_that("er_tte errors clearly when time is non-numeric or negative", {
  df_char <- survival::lung
  df_char$time <- as.character(df_char$time)
  expect_error(df_char |> er_tte(time, status == 2), "must be numeric")

  expect_error(survival::lung |> er_tte(-time, status == 2), "negative")
})

test_that("er_tte errors clearly when event is not a valid binary encoding", {
  expect_error(survival::lung |> er_tte(time, status), "must be logical")
})

test_that("er_tte errors clearly when conf_level is out of range", {
  expect_error(survival::lung |> er_tte(time, status == 2, conf_level = 0), "conf_level")
  expect_error(survival::lung |> er_tte(time, status == 2, conf_level = 1), "conf_level")
  expect_error(survival::lung |> er_tte(time, status == 2, conf_level = c(0.9, 0.95)), "conf_level")
})

test_that("er_tte warns and drops rows with missing time/event values", {
  df_na <- survival::lung
  df_na$time[1:2] <- NA
  expect_warning(df_na |> er_tte(time, status == 2), "2 rows dropped")
})

test_that("er_tte_build/print/plot don't error with no layers (blank canvas fallback)", {
  obj <- survival::lung |> er_tte(time, status == 2)

  expect_no_error(print(obj))
  expect_output(print(obj), "plot layers: <none>")
  expect_output(print(obj), "output built: no")

  built <- er_tte_build(obj)
  expect_s3_class(built$output, "ggplot")
  expect_no_error(plot(obj))
})

test_that("er_tte_build errors on a non-er_tte object", {
  expect_error(er_tte_build(list()), "er_tte object")
})

# stratification -----------------------------------------------------------

test_that("er_tte stratifies by a categorical variable, matching a direct survfit() call", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))

  obj <- df |> er_tte(time, status == 2, stratify_by = sex)
  fit_direct <- survival::survfit(survival::Surv(time, status == 2) ~ sex, data = df)

  expect_s3_class(obj, "er_tte")
  expect_equal(obj$strata$var, "sex")
  expect_equal(obj$strata$type, "discrete")
  expect_setequal(unique(obj$km$table$strata), c("Male", "Female"))
  expect_equal(sort(unname(obj$km$fit$surv)), sort(unname(fit_direct$surv)))
  expect_equal(sort(unname(obj$km$fit$n)), sort(unname(fit_direct$n)))
})

test_that("er_tte stratifies by a numeric variable via quantile bins, matching a direct survfit() call", {
  obj <- survival::lung |> er_tte(time, status == 2, stratify_by = age, n_strata = 3)

  expect_equal(obj$strata$type, "continuous")
  expect_equal(obj$strata$n_strata, 3)
  expect_setequal(unique(obj$km$table$strata), c("Q1", "Q2", "Q3"))

  fit_direct <- survival::survfit(
    survival::Surv(time, status == 2) ~ obj$data$.er_tte_strata,
    data = survival::lung
  )
  expect_equal(sort(unname(obj$km$fit$surv)), sort(unname(fit_direct$surv)))
})

test_that("er_tte's numeric stratify_by never carves out a placebo bin", {
  # unlike `er_vpc()`'s `stratify_by`, `er_tte()` has no exposure argument
  # to compare against, so a numeric `stratify_by` is always split into
  # plain quantile bins with no separate placebo/zero bin
  obj <- survival::lung |> er_tte(time, status == 2, stratify_by = age, n_strata = 3)
  expect_false("Placebo" %in% unique(obj$km$table$strata))
})

test_that("er_tte informs when stratify_by is numeric", {
  expect_message(
    survival::lung |> er_tte(time, status == 2, stratify_by = age),
    "quantile bins"
  )
})

test_that("er_tte errors clearly on a bad stratify_by/n_strata", {
  expect_error(survival::lung |> er_tte(time, status == 2, stratify_by = not_a_col), "not_a_col")
  expect_error(survival::lung |> er_tte(time, status == 2, stratify_by = age, n_strata = 0), "n_strata")
  expect_error(survival::lung |> er_tte(time, status == 2, stratify_by = age, n_strata = 1.5), "n_strata")
})

test_that("print/plot/build work when stratified", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  obj <- df |> er_tte(time, status == 2, stratify_by = sex)

  expect_output(print(obj), "stratify_by:\\s+sex")
  expect_output(print(obj), "Male")
  expect_output(print(obj), "Female")
  expect_no_error(plot(obj))
})
