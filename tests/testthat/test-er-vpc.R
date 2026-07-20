test_that("er_vpc_plot returns a ggplot", {
  skip_if_not_installed("erglm")
  mod <- erglm::erglm_model(ae1 ~ aucss + sex, er_test_data, family = binomial())
  sim <- erglm::erglm_vpc_sim(mod, nsim = 5)

  expect_no_error(er_vpc_plot(er_test_data, sim, aucss, ae1, group_by = aucss))
  p1 <- er_vpc_plot(er_test_data, sim, aucss, ae1, group_by = aucss)
  p2 <- er_vpc_plot(er_test_data, sim, aucss, ae1, group_by = sex)
  expect_true(inherits(p1, "ggplot"))
  expect_true(inherits(p2, "ggplot"))
})

test_that("er_vpc_plot supports a continuous response with mean/t-interval summaries", {
  skip_if_not_installed("erglm")
  sim <- erglm::erglm_vpc_sim(er_test_mod_gaussian, nsim = 5)

  expect_no_error(
    er_vpc_plot(er_test_data, sim, aucss, biomarker_change, group_by = aucss)
  )
  p1 <- er_vpc_plot(er_test_data, sim, aucss, biomarker_change, group_by = aucss)
  expect_true(inherits(p1, "ggplot"))

  smm <- p1$data
  expect_true(all(smm$ci_lower <= smm$y_mid & smm$y_mid <= smm$ci_upper))
})

test_that("er_vpc_plot routes a count (Poisson) response through the continuous path", {
  skip_if_not_installed("erglm")
  sim <- erglm::erglm_vpc_sim(er_test_mod_poisson, nsim = 5)

  # ae_count is a count, not a {0, 1} response -- "auto" must not
  # misclassify it as binary (PLAN.md Stage 4)
  expect_no_error(er_vpc_plot(er_test_data, sim, aucss, ae_count, group_by = aucss))
  p <- er_vpc_plot(er_test_data, sim, aucss, ae_count, group_by = aucss)
  expect_true(inherits(p, "ggplot"))

  smm <- p$data
  expect_true(all(smm$ci_lower <= smm$y_mid & smm$y_mid <= smm$ci_upper))
})

test_that("er_vpc_plot uses an exact Poisson interval when response_type = \"count\" is declared", {
  skip_if_not_installed("erglm")
  sim <- erglm::erglm_vpc_sim(er_test_mod_poisson, nsim = 5)

  expect_no_error(
    er_vpc_plot(
      er_test_data, sim, aucss, ae_count, group_by = aucss,
      response_type = "count"
    )
  )
  p <- er_vpc_plot(
    er_test_data, sim, aucss, ae_count, group_by = aucss,
    response_type = "count"
  )
  expect_true(inherits(p, "ggplot"))

  smm <- p$data
  expect_true(all(smm$ci_lower <= smm$y_mid & smm$y_mid <= smm$ci_upper))
  # exact Poisson interval should never go negative, unlike the observed
  # side's t-interval approximation under the default "continuous" path
  obs <- smm[smm$Source == "Observed", ]
  expect_true(all(obs$ci_lower >= 0))
})

test_that("er_vpc_plot's response_type argument overrides auto-detection", {
  skip_if_not_installed("erglm")
  mod <- erglm::erglm_model(ae1 ~ aucss + sex, er_test_data, family = binomial())
  sim <- erglm::erglm_vpc_sim(mod, nsim = 5)

  # a 0/1 response explicitly declared continuous should use the
  # mean/t-interval path (no n1/n0 dropped, no percent-style rounding
  # to a small set of values)
  expect_no_error(
    er_vpc_plot(
      er_test_data, sim, aucss, ae1, group_by = aucss,
      response_type = "continuous"
    )
  )

  expect_error(
    er_vpc_plot(
      er_test_data, sim, aucss, ae1, group_by = aucss,
      response_type = "nope"
    )
  )
})
