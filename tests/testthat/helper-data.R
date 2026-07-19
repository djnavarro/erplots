if (requireNamespace("erlr", quietly = TRUE)) {
  er_test_data <- erlr::lr_data
  er_test_mod1 <- erlr::lr_model(ae1 ~ aucss, er_test_data)
  er_test_mod2 <- erlr::lr_model(ae1 ~ aucss + sex, er_test_data)
}
