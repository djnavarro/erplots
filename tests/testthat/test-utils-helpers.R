test_that("ci_t matches stats::t.test for a plain numeric vector", {
  set.seed(2837)
  x <- rnorm(15, mean = 5, sd = 2)

  ci <- ci_t(x)
  ref <- stats::t.test(x, conf.level = 0.95)$conf.int

  expect_equal(unname(ci["lower"]), ref[1])
  expect_equal(unname(ci["upper"]), ref[2])
})

test_that("ci_t respects conf_level and stores it as an attribute", {
  x <- c(1, 2, 3, 4, 5)

  ci_95 <- ci_t(x, conf_level = 0.95)
  ci_80 <- ci_t(x, conf_level = 0.80)

  expect_equal(attr(ci_95, "conf_level"), 0.95)
  expect_equal(attr(ci_80, "conf_level"), 0.80)

  # A narrower confidence level should give a narrower interval
  width_95 <- ci_95["upper"] - ci_95["lower"]
  width_80 <- ci_80["upper"] - ci_80["lower"]
  expect_true(width_80 < width_95)
})

test_that("ci_t is centred on the sample mean", {
  x <- c(2, 4, 6, 8, 10)
  ci <- ci_t(x)

  midpoint <- unname((ci["lower"] + ci["upper"]) / 2)
  expect_equal(midpoint, mean(x))
})

test_that("ci_t drops NAs before computing the interval", {
  x <- c(1, 2, 3, NA, 4, 5, NA)
  ci_with_na <- ci_t(x)
  ci_without_na <- ci_t(x[!is.na(x)])

  expect_equal(ci_with_na, ci_without_na)
})

test_that("ci_t returns NA bounds for fewer than 2 non-missing values", {
  ci_zero <- ci_t(numeric(0))
  ci_one <- ci_t(5)
  ci_one_after_na <- ci_t(c(5, NA, NA))

  expect_true(all(is.na(ci_zero)))
  expect_true(all(is.na(ci_one)))
  expect_true(all(is.na(ci_one_after_na)))

  # conf_level should still be recorded even in the degenerate case
  expect_equal(attr(ci_zero, "conf_level"), 0.95)
})

test_that("ci_t returns a named lower/upper vector", {
  ci <- ci_t(c(1, 2, 3))
  expect_named(ci, c("lower", "upper"))
  expect_true(ci["lower"] < ci["upper"])
})


test_that("ci_poisson matches stats::poisson.test for a single count", {
  ci <- ci_poisson(7, 10)
  ref <- stats::poisson.test(7, 10, conf.level = 0.95)$conf.int

  expect_equal(unname(ci["lower"]), ref[1])
  expect_equal(unname(ci["upper"]), ref[2])
})

test_that("ci_poisson brackets the rate and respects conf_level", {
  ci_95 <- ci_poisson(20, 50, conf_level = 0.95)
  ci_80 <- ci_poisson(20, 50, conf_level = 0.80)

  rate <- 20 / 50
  expect_true(ci_95["lower"] <= rate && rate <= ci_95["upper"])
  expect_equal(attr(ci_95, "conf_level"), 0.95)
  expect_equal(attr(ci_80, "conf_level"), 0.80)

  width_95 <- ci_95["upper"] - ci_95["lower"]
  width_80 <- ci_80["upper"] - ci_80["lower"]
  expect_true(width_80 < width_95)
})

test_that("ci_poisson sums a vector of counts and never returns a negative lower bound", {
  ci_vec <- ci_poisson(c(0, 1, 2, 0, 1), n = 5)
  ci_sum <- ci_poisson(4, n = 5)
  expect_equal(ci_vec, ci_sum)

  ci_zero <- ci_poisson(0, n = 10)
  expect_equal(unname(ci_zero["lower"]), 0)
  expect_true(ci_zero["upper"] >= 0)
})

test_that("ci_poisson returns a named lower/upper vector", {
  ci <- ci_poisson(5, 20)
  expect_named(ci, c("lower", "upper"))
  expect_true(ci["lower"] < ci["upper"])
})

test_that(".dodge_quantile_strata adds a symmetric, scale-appropriate offset per stratum", {
  summary <- data.frame(
    x_mid = c(10, 10, 50, 50),
    strata = factor(c("Female", "Male", "Female", "Male"), levels = c("Female", "Male"))
  )

  dodged <- .dodge_quantile_strata(summary, exposure_limits = c(0, 100))

  expect_true("x_dodge" %in% names(dodged))
  # offsets are symmetric around x_mid within each bin
  expect_equal(mean(dodged$x_dodge[1:2]) , 10)
  expect_equal(mean(dodged$x_dodge[3:4]), 50)
  # the two strata get distinct positions at the same x_mid
  expect_false(dodged$x_dodge[1] == dodged$x_dodge[2])
  # offset magnitude scales with the exposure range
  dodged_wide <- .dodge_quantile_strata(summary, exposure_limits = c(0, 1000))
  offset_narrow <- dodged$x_dodge[1] - dodged$x_mid[1]
  offset_wide <- dodged_wide$x_dodge[1] - dodged_wide$x_mid[1]
  expect_equal(offset_wide, offset_narrow * 10)
})

test_that(".dodge_quantile_strata handles non-factor strata and a single stratum", {
  summary_char <- data.frame(x_mid = c(5, 5), strata = c("b", "a"))
  dodged_char <- .dodge_quantile_strata(summary_char, exposure_limits = c(0, 10))
  expect_false(dodged_char$x_dodge[1] == dodged_char$x_dodge[2])

  summary_one <- data.frame(x_mid = 5, strata = factor("a"))
  dodged_one <- .dodge_quantile_strata(summary_one, exposure_limits = c(0, 10))
  expect_equal(dodged_one$x_dodge, dodged_one$x_mid)
})
