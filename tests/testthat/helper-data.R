if (requireNamespace("erglm", quietly = TRUE)) {
  er_test_data <- erglm::erglm_data
  er_test_mod1 <- erglm::erglm_model(ae1 ~ aucss, er_test_data, family = binomial())
  er_test_mod2 <- erglm::erglm_model(ae1 ~ aucss + sex, er_test_data, family = binomial())
}
