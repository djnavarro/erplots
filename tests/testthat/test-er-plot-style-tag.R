# `er_style_tag()`'s `response_types`/`plot_by_types` attributes -----------
#
# See `?er_style_tag`'s "Details" -- these two tags are checked against
# an `er_vpc` object's `response$type`/`group$type` at
# `er_vpc_add_observed()`/`er_vpc_add_simulated()` time, not against
# another builder the way `layer`/`layout` are.

test_that("er_style_tag() round-trips response_types/plot_by_types as attributes", {
  fn <- function(data, config, exposure, response, theme, ...) list()
  tagged <- er_style_tag(fn, response_types = c("continuous", "count"), plot_by_types = "continuous")

  expect_equal(attr(tagged, "er_style_response_types"), c("continuous", "count"))
  expect_equal(attr(tagged, "er_style_plot_by_types"), "continuous")
})

test_that("er_style_tag() validates response_types/plot_by_types against their vocabularies", {
  fn <- function(data, config, exposure, response, theme, ...) list()

  expect_error(er_style_tag(fn, response_types = "ordinal"))
  expect_error(er_style_tag(fn, plot_by_types = "categorical"))
})

test_that("er_style_tag() leaves response_types/plot_by_types unset by default", {
  fn <- function(data, config, exposure, response, theme, ...) list()
  tagged <- er_style_tag(fn, layer = "observed")

  expect_null(attr(tagged, "er_style_response_types"))
  expect_null(attr(tagged, "er_style_plot_by_types"))
})

test_that(".check_style_response_type()/.check_style_plot_by_type() pass an untagged builder through unchanged", {
  fn <- function(data, config, exposure, response, theme, ...) list()

  expect_no_error(erplots:::.check_style_response_type(fn, "binary"))
  expect_no_error(erplots:::.check_style_plot_by_type(fn, "discrete"))
})

test_that(".check_style_response_type() errors informatively for an unsupported response type", {
  fn <- er_style_tag(
    function(data, config, exposure, response, theme, ...) list(),
    response_types = c("continuous", "count")
  )
  expect_error(erplots:::.check_style_response_type(fn, "binary", arg = "style"), "binary")
})

test_that(".check_style_plot_by_type() errors informatively for an unsupported plot_by type", {
  fn <- er_style_tag(
    function(data, config, exposure, response, theme, ...) list(),
    plot_by_types = "continuous"
  )
  expect_error(erplots:::.check_style_plot_by_type(fn, "discrete", arg = "style"), "discrete")
})
