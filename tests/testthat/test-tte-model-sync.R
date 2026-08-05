# These tests fit the same formula/data through both `er_test_toy_tte_model()`
# (helper-toy-model.R, a survival::survreg()-based wrapper) and a real
# `ertte::ertte_aft()`, then check that `er_predict_survival()` agrees between
# them and that a real `ertte_model` overlays cleanly on an `er_tte()` plot via
# `er_tte_add_model()`. This is the mechanism that catches ertte's own
# `er_predict_survival.ertte_model()` ever drifting from the CI-construction
# approximation mirrored in the toy wrapper -- see PLAN.md's (now resolved)
# "Real `ertte` integration" entry and AGENTS.md's "Internal toy lm/glm test
# wrapper" section for the general pattern. All tests here are gated on ertte
# being installed, since comparing against a real ertte fit is the whole
# point.

test_that("er_predict_survival() agrees between er_test_toy_tte_model() and ertte for an unstratified fit", {
  skip_if_not_installed("ertte")

  df <- survival::lung
  mod_toy <- er_test_toy_tte_model(survival::Surv(time, status == 2) ~ 1, df)
  mod_ertte <- ertte::ertte_aft(survival::Surv(time, status == 2) ~ 1, df)

  time_grid <- seq(0, 800, length.out = 20)
  p_toy <- er_predict_survival(mod_toy, df[1:5, ], time_grid = time_grid)
  p_ertte <- er_predict_survival(mod_ertte, df[1:5, ], time_grid = time_grid)

  expect_equal(p_toy$fit_survival, p_ertte$fit_survival)
  expect_equal(p_toy$ci_lower, p_ertte$ci_lower)
  expect_equal(p_toy$ci_upper, p_ertte$ci_upper)
})

test_that("er_predict_survival() agrees between er_test_toy_tte_model() and ertte with a covariate", {
  skip_if_not_installed("ertte")

  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  mod_toy <- er_test_toy_tte_model(survival::Surv(time, status == 2) ~ sex, df)
  mod_ertte <- ertte::ertte_aft(survival::Surv(time, status == 2) ~ sex, df)

  time_grid <- seq(0, 800, length.out = 20)
  p_toy <- er_predict_survival(mod_toy, df[1:5, ], time_grid = time_grid)
  p_ertte <- er_predict_survival(mod_ertte, df[1:5, ], time_grid = time_grid)

  expect_equal(p_toy$fit_survival, p_ertte$fit_survival)
  expect_equal(p_toy$ci_lower, p_ertte$ci_lower)
  expect_equal(p_toy$ci_upper, p_ertte$ci_upper)
})

test_that("er_predict_survival() agrees between er_test_toy_tte_model() and ertte across supported distributions", {
  skip_if_not_installed("ertte")

  df <- survival::lung
  time_grid <- seq(0, 800, length.out = 15)

  for (dist in c("exponential", "weibull", "lognormal", "loglogistic")) {
    mod_toy <- er_test_toy_tte_model(survival::Surv(time, status == 2) ~ 1, df, dist = dist)
    mod_ertte <- ertte::ertte_aft(survival::Surv(time, status == 2) ~ 1, df, dist = dist)

    p_toy <- er_predict_survival(mod_toy, df[1:5, ], time_grid = time_grid)
    p_ertte <- er_predict_survival(mod_ertte, df[1:5, ], time_grid = time_grid)

    expect_equal(p_toy$fit_survival, p_ertte$fit_survival, info = dist)
    expect_equal(p_toy$ci_lower, p_ertte$ci_lower, info = dist)
    expect_equal(p_toy$ci_upper, p_ertte$ci_upper, info = dist)
  }
})

test_that("er_tte_add_model() overlays a real ertte_aft() fit end to end", {
  skip_if_not_installed("ertte")

  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  mod <- ertte::ertte_aft(survival::Surv(time, status == 2) ~ sex, df)

  obj <- df |>
    er_tte(time, status == 2, stratify_by = sex) |>
    er_tte_add_curve() |>
    er_tte_add_model(mod)
  built <- er_tte_build(obj)

  layer_geoms <- vapply(built$output$layers, function(l) class(l$geom)[1], character(1))
  expect_true(all(c("GeomRibbon", "GeomLine") %in% layer_geoms))
  expect_setequal(unique(obj$layer$model$config$predictions$sex), c("Male", "Female"))
})

test_that("er_tte_add_model() overlays a real ertte_coxph() fit end to end", {
  skip_if_not_installed("ertte")

  df <- survival::lung
  mod <- ertte::ertte_coxph(survival::Surv(time, status == 2) ~ age, df)

  obj <- df |>
    er_tte(time, status == 2) |>
    er_tte_add_curve() |>
    er_tte_add_model(mod)
  built <- er_tte_build(obj)

  layer_geoms <- vapply(built$output$layers, function(l) class(l$geom)[1], character(1))
  expect_true(all(c("GeomRibbon", "GeomLine") %in% layer_geoms))
})
