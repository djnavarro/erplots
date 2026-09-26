# `er_style_tag(fn, label = ...)`'s registration side effect, and the
# `.lookup_style_label()`/`er_style_labels()` helpers that read it back --
# wired up for every `_add_*()` function in the package. Uses a
# throwaway layer/label pair per test to avoid colliding with the real
# built-in registrations.

test_that("er_style_tag() registers a labelled builder, retrievable via .lookup_style_label()", {
  fn <- function(data, config, stratify, time, strata, theme, ...) list()
  tagged <- er_style_tag(fn, layer = "tte_summary", label = "test_registry_basic")

  expect_identical(attr(tagged, "er_style_label"), "test_registry_basic")
  expect_identical(erplots:::.lookup_style_label("tte_summary", "test_registry_basic"), tagged)
})

test_that("er_style_tag() errors when label is supplied without layer", {
  fn <- function(data, config, stratify, time, strata, theme, ...) list()
  expect_error(er_style_tag(fn, label = "no_layer"), "requires `layer`")
})

test_that("re-registering the identical function under the same (layer, label) is a no-op", {
  fn <- function(data, config, stratify, time, strata, theme, ...) list()
  tagged1 <- er_style_tag(fn, layer = "tte_summary", label = "test_registry_idempotent")
  expect_no_error(er_style_tag(tagged1, layer = "tte_summary", label = "test_registry_idempotent"))
})

test_that("registering a different function under an already-used (layer, label) errors", {
  fn1 <- function(data, config, stratify, time, strata, theme, ...) list(1)
  fn2 <- function(data, config, stratify, time, strata, theme, ...) list(2)
  er_style_tag(fn1, layer = "tte_summary", label = "test_registry_collision")

  expect_error(
    er_style_tag(fn2, layer = "tte_summary", label = "test_registry_collision"),
    "already registered"
  )
})

test_that("overwrite = TRUE replaces an existing (layer, label) registration without erroring", {
  fn1 <- function(data, config, stratify, time, strata, theme, ...) list(1)
  fn2 <- function(data, config, stratify, time, strata, theme, ...) list(2)
  er_style_tag(fn1, layer = "tte_summary", label = "test_registry_overwrite")

  tagged2 <- er_style_tag(fn2, layer = "tte_summary", label = "test_registry_overwrite", overwrite = TRUE)

  expect_identical(erplots:::.lookup_style_label("tte_summary", "test_registry_overwrite"), tagged2)
})

test_that("overwrite = FALSE (the default) still errors on a genuine collision", {
  fn1 <- function(data, config, stratify, time, strata, theme, ...) list(1)
  fn2 <- function(data, config, stratify, time, strata, theme, ...) list(2)
  er_style_tag(fn1, layer = "tte_summary", label = "test_registry_no_overwrite")

  expect_error(
    er_style_tag(fn2, layer = "tte_summary", label = "test_registry_no_overwrite", overwrite = FALSE),
    "already registered"
  )
})

test_that("er_style_tag() errors when overwrite is supplied without label", {
  fn <- function(data, config, stratify, time, strata, theme, ...) list()
  expect_error(er_style_tag(fn, layer = "tte_summary", overwrite = TRUE), "requires `label`")
})

test_that("er_style_tag() errors when overwrite isn't a single logical", {
  fn <- function(data, config, stratify, time, strata, theme, ...) list()
  expect_error(er_style_tag(fn, layer = "tte_summary", label = "x", overwrite = "TRUE"), "TRUE.*FALSE")
  expect_error(er_style_tag(fn, layer = "tte_summary", label = "x", overwrite = c(TRUE, FALSE)), "TRUE.*FALSE")
  expect_error(er_style_tag(fn, layer = "tte_summary", label = "x", overwrite = NA), "TRUE.*FALSE")
})

test_that("the same label string is independent across different layers", {
  fn_a <- function(data, config, stratify, time, strata, theme, ...) list("a")
  fn_b <- function(data, config, exposure, response, theme, ...) list("b")
  fn_a <- er_style_tag(fn_a, layer = "tte_summary", label = "test_registry_shared")
  fn_b <- er_style_tag(fn_b, layer = "vpc_observed", label = "test_registry_shared")

  expect_identical(erplots:::.lookup_style_label("tte_summary", "test_registry_shared"), fn_a)
  expect_identical(erplots:::.lookup_style_label("vpc_observed", "test_registry_shared"), fn_b)
})

test_that(".lookup_style_label() errors informatively, listing available labels, for an unknown label", {
  expect_error(
    erplots:::.lookup_style_label("tte_summary", "definitely_not_registered"),
    "logrank"
  )
})

test_that("er_style_labels() lists the four built-in tte_summary registrations", {
  labels <- er_style_labels("tte_summary")
  expect_setequal(
    labels$label[labels$layer == "tte_summary" & labels$label %in% c("logrank", "n", "coefficients", "gof")],
    c("logrank", "n", "coefficients", "gof")
  )
})

test_that("er_style_labels() lists the three built-in model registrations", {
  labels <- er_style_labels("plot_model")
  expect_setequal(labels$label, c("ribbonline", "line", "spaghetti"))
  expect_identical(
    labels$style[[which(labels$label == "line")]],
    er_style_model_line
  )
})

test_that("er_style_labels() with no argument returns every registered layer", {
  labels <- er_style_labels()
  expect_true("tte_summary" %in% labels$layer)
})

test_that("every layer with a built-in style has at least one registered label", {
  labels <- er_style_labels()
  expect_setequal(
    unique(labels$layer),
    c(
      "plot_model", "plot_summary", "plot_quantile", "plot_data", "plot_group",
      "vpc_observed", "vpc_simulated",
      "tte_curve", "tte_censor", "tte_risktable", "tte_model", "tte_summary"
    )
  )
})

test_that("er_style_labels() includes at least the 34 built-in tagged style functions", {
  # >= rather than ==: other tests in this file register their own
  # throwaway (layer, label) pairs into the same session-wide registry,
  # so the exact row count depends on run order across the whole suite.
  labels <- er_style_labels()
  expect_true(nrow(labels) >= 34L)
})
