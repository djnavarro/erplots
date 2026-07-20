test_that("build_group_boxplot returns geom + coord", {
  skip_if_not_installed("erglm")

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_show_groups(treatment))
  expect_no_error(p2 |> er_plot_show_groups(treatment))

  p1 <- p1 |> er_plot_show_groups(treatment)
  p2 <- p2 |> er_plot_show_groups(treatment)

  args1 <- list(
    data = p1$data,
    config = p1$part$group$config[[1]],
    stratify = p1$part$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    style = p1$style
  )
  args2 <- list(
    data = p2$data,
    config = p2$part$group$config[[1]],
    stratify = p2$part$group$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    style = p2$style
  )

  expect_no_error(do.call(build_group_boxplot, args1))
  expect_no_error(do.call(build_group_boxplot, args2))

  p1_out <- do.call(build_group_boxplot, args1)
  p2_out <- do.call(build_group_boxplot, args2)

  expect_length(p1_out, 2)
  expect_length(p2_out, 2)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "CoordCartesian"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "CoordCartesian"))
})


test_that("build_group_violin returns geom + coord", {
  skip_if_not_installed("erglm")

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_show_groups(treatment, builder = build_group_violin))
  expect_no_error(p2 |> er_plot_show_groups(treatment, builder = build_group_violin))

  p1 <- p1 |> er_plot_show_groups(treatment, builder = build_group_violin)
  p2 <- p2 |> er_plot_show_groups(treatment, builder = build_group_violin)

  args1 <- list(
    data = p1$data,
    config = p1$part$group$config[[1]],
    stratify = p1$part$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    style = p1$style
  )
  args2 <- list(
    data = p2$data,
    config = p2$part$group$config[[1]],
    stratify = p2$part$group$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    style = p2$style
  )

  expect_no_error(do.call(build_group_violin, args1))
  expect_no_error(do.call(build_group_violin, args2))

  p1_out <- do.call(build_group_violin, args1)
  p2_out <- do.call(build_group_violin, args2)

  expect_length(p1_out, 2)
  expect_length(p2_out, 2)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "CoordCartesian"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "CoordCartesian"))
})
