test_that("er_vpc() constructs an er_vpc object with the right variable metadata", {
  vpc <- er_vpc(er_test_data, aucss, ae1)
  expect_s3_class(vpc, "er_vpc")
  expect_equal(vpc$exposure$name, "aucss")
  expect_equal(vpc$response$name, "ae1")
  expect_equal(vpc$response$type, "binary")
  expect_equal(vpc$response$limits, c(0, 1))
  expect_null(vpc$layer$observed)
  expect_null(vpc$layer$simulated)
})

test_that("er_vpc() defaults plot_by to the exposure variable and stores n_bins/conf_level/probs", {
  vpc <- er_vpc(er_test_data, aucss, ae1)
  expect_equal(vpc$group$var, "aucss")
  expect_equal(vpc$group$n_bins, 4)
  expect_equal(vpc$group$conf_level, 0.95)
  expect_equal(vpc$group$probs, c(0.1, 0.5, 0.9))

  vpc2 <- er_vpc(er_test_data, aucss, ae1, plot_by = sex, n_bins = 6, conf_level = 0.9, probs = c(0.2, 0.8))
  expect_equal(vpc2$group$var, "sex")
  expect_equal(vpc2$group$n_bins, 6)
  expect_equal(vpc2$group$conf_level, 0.9)
  expect_equal(vpc2$group$probs, c(0.2, 0.8))
})

test_that("er_vpc() auto-detects plot_by's type as continuous or discrete", {
  vpc_numeric <- er_vpc(er_test_data, aucss, ae1)
  expect_equal(vpc_numeric$group$type, "continuous")

  vpc_categorical <- er_vpc(er_test_data, aucss, ae1, plot_by = sex)
  expect_equal(vpc_categorical$group$type, "discrete")
})

test_that("er_vpc() resolves response_type = 'auto' and honours explicit overrides", {
  vpc_auto <- er_vpc(er_test_data, aucss, biomarker_change)
  expect_equal(vpc_auto$response$type, "continuous")

  vpc_explicit <- er_vpc(er_test_data, aucss, ae1, response_type = "continuous")
  expect_equal(vpc_explicit$response$type, "continuous")

  expect_error(er_vpc(er_test_data, aucss, ae1, response_type = "nope"))
})

test_that("er_vpc() validates columns and exposure type", {
  expect_error(er_vpc(er_test_data, not_a_column, ae1), "not found")
  expect_error(er_vpc(er_test_data, sex, ae1), "numeric")
})

test_that("er_vpc() shares the same response-value validation as er_plot()", {
  df_bad <- er_test_data
  df_bad$ae1[1:5] <- 2
  expect_warning(er_vpc(df_bad, aucss, ae1, response_type = "binary"), "outside \\{0, 1\\}")

  df_neg <- er_test_data
  df_neg$ae_count <- -1
  expect_error(er_vpc(df_neg, aucss, ae_count, response_type = "count"), "non-negative")
})

test_that("er_vpc() ungroups a grouped/rowwise data argument", {
  grouped_data <- er_test_data |> dplyr::group_by(sex)
  rowwise_data <- er_test_data |> dplyr::rowwise()

  expect_no_error(er_vpc(grouped_data, aucss, ae1))
  expect_no_error(er_vpc(rowwise_data, aucss, ae1))
})

test_that("print.er_vpc() runs without error at every stage of the pipeline", {
  vpc0 <- er_vpc(er_test_data, aucss, ae1)
  expect_no_error(print(vpc0))

  vpc1 <- vpc0 |> er_vpc_add_observed()
  expect_no_error(print(vpc1))

  vpc2 <- vpc1 |> er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 501)
  expect_no_error(print(vpc2))

  built <- er_vpc_build(vpc2)
  expect_no_error(print(built))
})

test_that("er_vpc_build()/plot() produce a ggplot object", {
  vpc <- er_test_data |>
    er_vpc(aucss, ae1) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 502)

  built <- er_vpc_build(vpc)
  expect_true(inherits(built$output, "ggplot"))
  expect_no_error(plot(vpc))
})

test_that("er_vpc_build() requires an er_vpc object", {
  expect_error(er_vpc_build(list()), "er_vpc")
})

test_that("er_vpc_build() labels the x-axis with plot_by's label, not exposure's, when they differ", {
  # regression test: the x-axis is `plot_by`, which only coincides with
  # `exposure` when the caller didn't override it
  vpc <- er_test_data |>
    er_vpc(aucss, ae1, plot_by = weight) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 606)

  built <- er_vpc_build(vpc)
  expect_equal(ggplot2::get_labs(built$output)$x, vpc$group$label)
  expect_false(identical(ggplot2::get_labs(built$output)$x, vpc$exposure$label))
})
