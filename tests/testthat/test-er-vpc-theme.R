test_that("er_vpc_theme() requires an er_vpc object", {
  expect_error(er_vpc_theme(list(), xlab = "x"), "er_vpc")
})

test_that("er_vpc_theme() writes xlab to plot_by's label, not exposure's", {
  vpc <- er_vpc(er_test_data, aucss, ae1, plot_by = weight) |>
    er_vpc_theme(xlab = "Body weight (kg)", ylab = "Adverse event")

  expect_equal(vpc$group$label, "Body weight (kg)")
  expect_equal(vpc$response$label, "Adverse event")
  expect_false(identical(vpc$exposure$label, "Body weight (kg)"))
})

test_that("er_vpc_theme() writes strata_lab, and errors with no stratify_by set", {
  vpc <- er_vpc(er_test_data, aucss, ae1, stratify_by = sex) |>
    er_vpc_theme(strata_lab = "Sex")
  expect_equal(vpc$strata$label, "Sex")

  vpc_unstrat <- er_vpc(er_test_data, aucss, ae1)
  expect_error(er_vpc_theme(vpc_unstrat, strata_lab = "Sex"), "stratify_by")
})

test_that("er_vpc_theme() writes title/subtitle/caption, applied via labs()", {
  vpc <- er_test_data |>
    er_vpc(aucss, ae1) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 9401) |>
    er_vpc_theme(title = "My title", subtitle = "My subtitle", caption = "My caption")

  expect_equal(vpc$theme$title, "My title")
  expect_equal(vpc$theme$subtitle, "My subtitle")
  expect_equal(vpc$theme$caption, "My caption")

  built <- er_vpc_build(vpc)
  expect_true(ggplot2::is_ggplot(built$output))
  labs <- ggplot2::get_labs(built$output)
  expect_equal(labs$title, "My title")
  expect_equal(labs$subtitle, "My subtitle")
  expect_equal(labs$caption, "My caption")
})

test_that("er_vpc_theme() writes xlim/ylim, consumed lazily at build time", {
  vpc <- er_test_data |>
    er_vpc(aucss, ae1) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 9402) |>
    er_vpc_theme(xlim = c(0, 100), ylim = c(-0.1, 1.1))

  expect_equal(vpc$theme$xlim, c(0, 100))
  expect_equal(vpc$theme$ylim, c(-0.1, 1.1))
  expect_no_error(er_vpc_build(vpc))
})

test_that("er_vpc_theme() validates xlab/ylab/strata_lab/title/subtitle/caption", {
  vpc <- er_vpc(er_test_data, aucss, ae1)
  expect_error(er_vpc_theme(vpc, xlab = c("a", "b")), "single string")
  expect_error(er_vpc_theme(vpc, title = 1), "single string")
})

test_that("er_vpc_theme() validates xlim/ylim", {
  vpc <- er_vpc(er_test_data, aucss, ae1)
  expect_error(er_vpc_theme(vpc, xlim = 1), "length-2")
  expect_error(er_vpc_theme(vpc, xlim = c(5, 1)), "increasing")
})

test_that("er_vpc_theme() writes and validates theme_base/theme_extra", {
  vpc <- er_test_data |>
    er_vpc(aucss, ae1) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = er_test_mod1, nsim = 5, seed = 9403) |>
    er_vpc_theme(theme_base = ggplot2::theme_minimal())

  expect_true(inherits(vpc$theme$theme_base, "theme"))
  expect_no_error(er_vpc_build(vpc))

  expect_error(er_vpc_theme(vpc, theme_base = "not a theme"), "theme")
})

test_that("er_vpc_theme() writes and validates format_percent/format_number", {
  fmt <- scales::label_percent(accuracy = 0.1)
  vpc <- er_vpc(er_test_data, aucss, ae1) |> er_vpc_theme(format_percent = fmt)
  expect_identical(vpc$theme$format_percent, fmt)

  expect_error(er_vpc_theme(vpc, format_percent = "not a function"), "function")
})

test_that("er_vpc_theme() calls accumulate, leaving unsupplied fields unchanged", {
  vpc <- er_vpc(er_test_data, aucss, ae1) |>
    er_vpc_theme(xlab = "X") |>
    er_vpc_theme(ylab = "Y")

  expect_equal(vpc$group$label, "X")
  expect_equal(vpc$response$label, "Y")
})
