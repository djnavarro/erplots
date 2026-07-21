test_that("er_builder_group_boxplot returns geom + coord", {
  skip_if_not_installed("erglm")

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_add_groups(treatment))
  expect_no_error(p2 |> er_plot_add_groups(treatment))

  p1 <- p1 |> er_plot_add_groups(treatment)
  p2 <- p2 |> er_plot_add_groups(treatment)

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

  expect_no_error(do.call(er_builder_group_boxplot, args1))
  expect_no_error(do.call(er_builder_group_boxplot, args2))

  p1_out <- do.call(er_builder_group_boxplot, args1)
  p2_out <- do.call(er_builder_group_boxplot, args2)

  expect_length(p1_out, 2)
  expect_length(p2_out, 2)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "CoordCartesian"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "CoordCartesian"))
})


test_that("er_builder_group_histogram returns geom + facet + coord", {
  skip_if_not_installed("erglm")

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_add_groups(treatment, builder = er_builder_group_histogram))
  expect_no_error(p2 |> er_plot_add_groups(treatment, builder = er_builder_group_histogram))

  p1 <- p1 |> er_plot_add_groups(treatment, builder = er_builder_group_histogram)
  p2 <- p2 |> er_plot_add_groups(treatment, builder = er_builder_group_histogram)

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

  expect_no_error(do.call(er_builder_group_histogram, args1))
  expect_no_error(do.call(er_builder_group_histogram, args2))

  p1_out <- do.call(er_builder_group_histogram, args1)
  p2_out <- do.call(er_builder_group_histogram, args2)

  expect_length(p1_out, 4)
  expect_length(p2_out, 4)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "Facet"))
  expect_true(inherits(p1_out[[3]], "CoordCartesian"))
  expect_true(inherits(p1_out[[4]], "theme"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "Facet"))
  expect_true(inherits(p2_out[[3]], "CoordCartesian"))
  expect_true(inherits(p2_out[[4]], "theme"))
})

test_that("er_builder_group_histogram rotates strip text to avoid clipping long level labels", {
  skip_if_not_installed("erglm")

  p1 <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_groups(treatment, builder = er_builder_group_histogram)

  args1 <- list(
    data = p1$data,
    config = p1$part$group$config[[1]],
    stratify = p1$part$group$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    style = p1$style
  )

  p1_out <- do.call(er_builder_group_histogram, args1)
  strip_theme <- p1_out[[4]]
  expect_equal(strip_theme$strip.text.y.left$angle, 0)
})

test_that("er_plot_add_groups() builds and renders with builder = er_builder_group_histogram", {
  skip_if_not_installed("erglm")

  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_groups(treatment, builder = er_builder_group_histogram)

  expect_no_error(er_plot_build(plt))
})


test_that("er_builder_group_violin returns geom + coord", {
  skip_if_not_installed("erglm")

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_add_groups(treatment, builder = er_builder_group_violin))
  expect_no_error(p2 |> er_plot_add_groups(treatment, builder = er_builder_group_violin))

  p1 <- p1 |> er_plot_add_groups(treatment, builder = er_builder_group_violin)
  p2 <- p2 |> er_plot_add_groups(treatment, builder = er_builder_group_violin)

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

  expect_no_error(do.call(er_builder_group_violin, args1))
  expect_no_error(do.call(er_builder_group_violin, args2))

  p1_out <- do.call(er_builder_group_violin, args1)
  p2_out <- do.call(er_builder_group_violin, args2)

  expect_length(p1_out, 2)
  expect_length(p2_out, 2)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "CoordCartesian"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "CoordCartesian"))
})
