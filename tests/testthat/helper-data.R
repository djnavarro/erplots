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
