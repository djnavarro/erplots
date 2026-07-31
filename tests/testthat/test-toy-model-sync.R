# These tests fit the same formula/data through both `er_test_toy_model()`
# (helper-toy-model.R) and a real `erglm::erglm_model()`, then check that
# their er_predict()/er_summary()/er_simulate() outputs agree. This is the
# mechanism that catches erglm ever drifting from the algorithm mirrored in
# the toy wrapper -- see AGENTS.md's "Internal toy lm/glm test wrapper"
# section. All tests here are gated on erglm being installed, since
# comparing against a real erglm fit is the whole point.

test_that("er_predict() agrees between er_test_toy_model() and erglm for a binomial/logit fit", {
  skip_if_not_installed("erglm")

  mod_glm <- erglm::erglm_model(ae1 ~ aucss + sex, er_test_data, family = binomial())
  mod_toy <- er_test_toy_model(ae1 ~ aucss + sex, er_test_data, family = binomial())

  p_glm <- er_predict(mod_glm, er_test_data)
  p_toy <- er_predict(mod_toy, er_test_data)

  expect_equal(p_toy$fit_resp, p_glm$fit_resp)
  expect_equal(p_toy$ci_lower, p_glm$ci_lower)
  expect_equal(p_toy$ci_upper, p_glm$ci_upper)
})

test_that("er_predict() agrees between er_test_toy_model() and erglm for a gaussian/identity fit", {
  skip_if_not_installed("erglm")

  mod_glm <- erglm::erglm_model(biomarker_change ~ aucss, er_test_data, family = gaussian())
  mod_toy <- er_test_toy_model(biomarker_change ~ aucss, er_test_data, family = gaussian())

  p_glm <- er_predict(mod_glm, er_test_data)
  p_toy <- er_predict(mod_toy, er_test_data)

  expect_equal(p_toy$fit_resp, p_glm$fit_resp)
  expect_equal(p_toy$ci_lower, p_glm$ci_lower)
  expect_equal(p_toy$ci_upper, p_glm$ci_upper)
})

test_that("er_summary() agrees between er_test_toy_model() and erglm for a binomial/logit fit", {
  skip_if_not_installed("erglm")

  mod_glm <- erglm::erglm_model(ae1 ~ aucss + sex, er_test_data, family = binomial())
  mod_toy <- er_test_toy_model(ae1 ~ aucss + sex, er_test_data, family = binomial())

  s_glm <- er_summary(mod_glm)
  s_toy <- er_summary(mod_toy)

  expect_equal(s_toy$p_value, s_glm$p_value)
  expect_equal(
    s_toy$coefficients[c("estimate", "std_error", "statistic", "p_value", "conf_low", "conf_high")],
    s_glm$coefficients[c("estimate", "std_error", "statistic", "p_value", "conf_low", "conf_high")]
  )
  expect_equal(
    s_toy$glance[c("n", "df_residual", "logLik", "aic", "bic", "deviance", "r_squared")],
    s_glm$glance[c("n", "df_residual", "logLik", "aic", "bic", "deviance", "r_squared")]
  )
})

test_that("er_summary() agrees between er_test_toy_model() and erglm for a gaussian/identity fit", {
  skip_if_not_installed("erglm")

  mod_glm <- erglm::erglm_model(biomarker_change ~ aucss, er_test_data, family = gaussian())
  mod_toy <- er_test_toy_model(biomarker_change ~ aucss, er_test_data, family = gaussian())

  s_glm <- er_summary(mod_glm)
  s_toy <- er_summary(mod_toy)

  expect_equal(s_toy$p_value, s_glm$p_value)
  expect_equal(
    s_toy$coefficients[c("estimate", "std_error", "statistic", "p_value", "conf_low", "conf_high")],
    s_glm$coefficients[c("estimate", "std_error", "statistic", "p_value", "conf_low", "conf_high")]
  )
  expect_equal(
    s_toy$glance[c("n", "df_residual", "logLik", "aic", "bic", "deviance", "r_squared")],
    s_glm$glance[c("n", "df_residual", "logLik", "aic", "bic", "deviance", "r_squared")]
  )
})

test_that("er_simulate() agrees structurally/distributionally between er_test_toy_model() and erglm", {
  skip_if_not_installed("erglm")

  # Not compared value-for-value: erglm's and the toy wrapper's RNG calls
  # aren't shaped identically (e.g. erglm's replicate loop also advances
  # `row_id`), so matching seeds don't produce identical draws even though
  # the underlying algorithm (rmvnorm() parameter draws, then
  # family-appropriate response noise) is the same. Compared instead on
  # structure (columns, replicate count) and Monte Carlo agreement (the
  # mean of `sim_resp` across replicates should track `fit_resp` similarly
  # for both).
  newdata <- er_test_data[1:20, ]

  for (family_spec in list(
    list(formula = ae1 ~ aucss + sex, family = binomial(), response = "ae1"),
    list(formula = biomarker_change ~ aucss, family = gaussian(), response = "biomarker_change")
  )) {
    mod_glm <- erglm::erglm_model(family_spec$formula, er_test_data, family = family_spec$family)
    mod_toy <- er_test_toy_model(family_spec$formula, er_test_data, family = family_spec$family)

    sim_glm <- er_simulate(mod_glm, newdata = newdata, nsim = 300, seed = 5148)
    sim_toy <- er_simulate(mod_toy, newdata = newdata, nsim = 300, seed = 5148)

    expect_true(all(c("sim_id", "fit_resp", "sim_resp") %in% names(sim_glm)))
    expect_true(all(c("sim_id", "fit_resp", "sim_resp") %in% names(sim_toy)))
    expect_equal(length(unique(sim_glm$sim_id)), 300)
    expect_equal(length(unique(sim_toy$sim_id)), 300)

    expect_equal(mean(sim_toy$fit_resp), mean(sim_glm$fit_resp), tolerance = 1e-6)
    expect_equal(mean(sim_toy$sim_resp), mean(sim_glm$sim_resp), tolerance = 0.1)
  }
})
