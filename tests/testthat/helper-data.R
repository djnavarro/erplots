if (requireNamespace("erglm", quietly = TRUE)) {
  er_test_data <- erglm::erglm_data
  er_test_mod1 <- erglm::erglm_model(ae1 ~ aucss, er_test_data, family = binomial())
  er_test_mod2 <- erglm::erglm_model(ae1 ~ aucss + sex, er_test_data, family = binomial())
  # continuous-response fixture, used by the Stage 0 (and later) tests for
  # response-type detection/handling -- see PLAN.md
  er_test_mod_gaussian <- erglm::erglm_model(biomarker_change ~ aucss, er_test_data, family = gaussian())
  # count-response fixture, used by the Stage 4 tests -- see PLAN.md. Count
  # responses auto-detect as "continuous" and are routed through the same
  # mean + t-interval path (a documented approximation, not an exact
  # Poisson interval).
  er_test_mod_poisson <- erglm::erglm_model(ae_count ~ aucss, er_test_data, family = poisson())
}

# test-only fixture with no `er_predict()` method, used to exercise the
# `er_summary()` contract's `coefficients`/`glance` fields (see
# `?er_model_interface`) without depending on erglm implementing them --
# `.layer_summary()` never calls `er_predict()`, so this is enough for
# `er_plot_add_summary(model = ...)`, but not for `er_plot_add_model()`.
er_summary.er_test_fake_summary_model <- function(model, ...) {
  list(
    p_value = NULL, # e.g. a multi-parameter model with no single privileged term
    coefficients = tibble::tibble(
      term = c("(Intercept)", "aucss"),
      estimate = c(0.1, 0.02),
      p_value = c(0.5, 0.02)
    ),
    glance = tibble::tibble(n = 100L, aic = 123.4, bic = 130.1, r_squared = 0.42)
  )
}
# a second fixture with a partially-populated `glance` (only `aic`; `bic`/
# `r_squared` absent, `n` present but `NA`) -- exercises
# `er_style_summary_gof()`'s "show only what's present and non-NA" branch
er_summary.er_test_partial_gof_model <- function(model, ...) {
  list(glance = tibble::tibble(n = NA_integer_, aic = 88.8))
}
# `er_summary()` is called from inside erplots' own internals
# (`.layer_summary()`), several frames away from this test file, so plain
# lexical scoping won't find an informally-defined method here -- register
# it explicitly, the same runtime pattern erglm itself uses (see AGENTS.md).
registerS3method("er_summary", "er_test_fake_summary_model", er_summary.er_test_fake_summary_model)
registerS3method("er_summary", "er_test_partial_gof_model", er_summary.er_test_partial_gof_model)
