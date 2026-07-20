test_that("t_interval matches stats::t.test for a plain numeric vector", {
  set.seed(2837)
  x <- rnorm(15, mean = 5, sd = 2)

  ci <- t_interval(x)
  ref <- stats::t.test(x, conf.level = 0.95)$conf.int

  expect_equal(unname(ci["lower"]), ref[1])
  expect_equal(unname(ci["upper"]), ref[2])
})

test_that("t_interval respects conf_level and stores it as an attribute", {
  x <- c(1, 2, 3, 4, 5)

  ci_95 <- t_interval(x, conf_level = 0.95)
  ci_80 <- t_interval(x, conf_level = 0.80)

  expect_equal(attr(ci_95, "conf_level"), 0.95)
  expect_equal(attr(ci_80, "conf_level"), 0.80)

  # A narrower confidence level should give a narrower interval
  width_95 <- ci_95["upper"] - ci_95["lower"]
  width_80 <- ci_80["upper"] - ci_80["lower"]
  expect_true(width_80 < width_95)
})

test_that("t_interval is centred on the sample mean", {
  x <- c(2, 4, 6, 8, 10)
  ci <- t_interval(x)

  midpoint <- unname((ci["lower"] + ci["upper"]) / 2)
  expect_equal(midpoint, mean(x))
})

test_that("t_interval drops NAs before computing the interval", {
  x <- c(1, 2, 3, NA, 4, 5, NA)
  ci_with_na <- t_interval(x)
  ci_without_na <- t_interval(x[!is.na(x)])

  expect_equal(ci_with_na, ci_without_na)
})

test_that("t_interval returns NA bounds for fewer than 2 non-missing values", {
  ci_zero <- t_interval(numeric(0))
  ci_one <- t_interval(5)
  ci_one_after_na <- t_interval(c(5, NA, NA))

  expect_true(all(is.na(ci_zero)))
  expect_true(all(is.na(ci_one)))
  expect_true(all(is.na(ci_one_after_na)))

  # conf_level should still be recorded even in the degenerate case
  expect_equal(attr(ci_zero, "conf_level"), 0.95)
})

test_that("t_interval returns a named lower/upper vector", {
  ci <- t_interval(c(1, 2, 3))
  expect_named(ci, c("lower", "upper"))
  expect_true(ci["lower"] < ci["upper"])
})
