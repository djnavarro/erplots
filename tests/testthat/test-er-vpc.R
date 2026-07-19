test_that("er_vpc_plot returns a ggplot", {
  skip_if_not_installed("erlr")
  mod <- erlr::lr_model(ae1 ~ aucss + sex, er_test_data)
  sim <- erlr::lr_vpc_sim(mod, nsim = 5)

  expect_no_error(er_vpc_plot(er_test_data, sim, aucss, ae1, group_by = aucss))
  p1 <- er_vpc_plot(er_test_data, sim, aucss, ae1, group_by = aucss)
  p2 <- er_vpc_plot(er_test_data, sim, aucss, ae1, group_by = sex)
  expect_true(inherits(p1, "ggplot"))
  expect_true(inherits(p2, "ggplot"))
})
