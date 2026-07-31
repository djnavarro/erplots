test_that("er_style_summary_coefficients renders when coefficients are present", {
  fake_model <- structure(list(), class = "er_test_fake_summary_model")

  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_summary(model = fake_model, style = er_style_summary_coefficients)

  args <- list(
    data = plt$data,
    config = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata = plt$strata,
    theme = plt$theme
  )

  expect_no_error(out <- do.call(er_style_summary_coefficients, args))
  expect_true(inherits(out, "LayerInstance"))
})

test_that("er_style_summary_gof renders all four fields when present", {
  fake_model <- structure(list(), class = "er_test_fake_summary_model")

  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_summary(model = fake_model, style = er_style_summary_gof)

  args <- list(
    data = plt$data,
    config = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata = plt$strata,
    theme = plt$theme
  )

  expect_no_error(out <- do.call(er_style_summary_gof, args))
  expect_true(inherits(out, "LayerInstance"))
  lbl <- out$data$lbl
  expect_match(lbl, "N = 100")
  expect_match(lbl, "AIC = 123.4")
  expect_match(lbl, "BIC = 130.1")
  expect_match(lbl, "R\u00b2 = 0.42")
})

test_that("er_style_summary_gof shows only present, non-NA fields", {
  partial_model <- structure(list(), class = "er_test_partial_gof_model")

  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_summary(model = partial_model, style = er_style_summary_gof)

  args <- list(
    data = plt$data,
    config = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata = plt$strata,
    theme = plt$theme
  )

  out <- do.call(er_style_summary_gof, args)
  lbl <- out$data$lbl
  expect_equal(lbl, "AIC = 88.80")
})

test_that("er_style_summary_gof draws nothing when glance is absent", {
  # constructed directly, rather than via a real fitted model, since every
  # model implementing the full `er_summary()` contract (e.g. erglm's own
  # `er_summary.erglm_model()`) now populates `glance` -- this exercises
  # the "no glance at all" branch a model author omitting it would hit
  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_summary()
  plt$layer$summary$config$summary <- list(p_value = 0.01)

  args <- list(
    data = plt$data,
    config = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata = plt$strata,
    theme = plt$theme
  )

  out <- do.call(er_style_summary_gof, args)
  expect_length(out, 0)
})

test_that("er_style_summary_gof draws nothing when stratified", {
  fake_model <- structure(list(), class = "er_test_fake_summary_model")

  plt <- er_plot(er_test_data, aucss, ae1, sex) |>
    er_plot_add_summary(model = fake_model, style = er_style_summary_gof)

  args <- list(
    data = plt$data,
    config = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata = plt$strata,
    theme = plt$theme
  )

  out <- do.call(er_style_summary_gof, args)
  expect_length(out, 0)
})

test_that("er_style_summary_coefficients draws nothing when coefficients are absent", {
  # constructed directly, rather than via a real fitted model, since every
  # model implementing the full `er_summary()` contract (e.g. erglm's own
  # `er_summary.erglm_model()`) now populates `coefficients` -- this
  # exercises the "no coefficients at all" branch a model author omitting
  # it would hit
  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_summary()
  plt$layer$summary$config$summary <- list(p_value = 0.01)

  args <- list(
    data = plt$data,
    config = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata = plt$strata,
    theme = plt$theme
  )

  out <- do.call(er_style_summary_coefficients, args)
  expect_length(out, 0)
})

test_that("er_style_summary_coefficients draws nothing when stratified", {
  fake_model <- structure(list(), class = "er_test_fake_summary_model")

  plt <- er_plot(er_test_data, aucss, ae1, sex) |>
    er_plot_add_summary(model = fake_model, style = er_style_summary_coefficients)

  args <- list(
    data = plt$data,
    config = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata = plt$strata,
    theme = plt$theme
  )

  out <- do.call(er_style_summary_coefficients, args)
  expect_length(out, 0)
})

test_that("er_style_summary_coefficients tolerates a coefficients table with no p_value column", {
  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_summary()

  plt$layer$summary$config$summary <- list(
    coefficients = tibble::tibble(term = c("a", "b"), estimate = c(1, 2))
  )

  args <- list(
    data = plt$data,
    config = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata = plt$strata,
    theme = plt$theme
  )

  expect_no_error(out <- do.call(er_style_summary_coefficients, args))
  expect_true(inherits(out, "LayerInstance"))
})


# ---- new argument: inset ----

test_that("er_style_summary_pvalue() inset argument changes label position", {
  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_summary(model = er_test_mod1)
  args <- list(
    data     = plt$data,
    config   = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata   = plt$strata,
    theme    = plt$theme
  )

  out_default <- do.call(er_style_summary_pvalue, args)
  out_custom  <- do.call(er_style_summary_pvalue, c(args, list(inset = 0.1)))

  # default positions should be 0.05 or 0.95 (i.e. inset or 1 - inset)
  x_default <- as.numeric(rlang::eval_tidy(out_default$mapping$x))
  y_default <- as.numeric(rlang::eval_tidy(out_default$mapping$y))
  expect_true(x_default %in% c(0.05, 0.95))
  expect_true(y_default %in% c(0.05, 0.95))

  # custom positions should be 0.1 or 0.9
  x_custom <- as.numeric(rlang::eval_tidy(out_custom$mapping$x))
  y_custom <- as.numeric(rlang::eval_tidy(out_custom$mapping$y))
  expect_true(x_custom %in% c(0.1, 0.9))
  expect_true(y_custom %in% c(0.1, 0.9))

  # the two should differ
  expect_false(isTRUE(x_default == x_custom))
})

test_that("er_style_summary_n() inset argument changes label position", {
  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_summary(style = er_style_summary_n)
  args <- list(
    data     = plt$data,
    config   = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata   = plt$strata,
    theme    = plt$theme
  )

  out_default <- do.call(er_style_summary_n, args)
  out_custom  <- do.call(er_style_summary_n, c(args, list(inset = 0.15)))

  x_default <- as.numeric(rlang::eval_tidy(out_default$mapping$x))
  x_custom  <- as.numeric(rlang::eval_tidy(out_custom$mapping$x))
  expect_true(x_default %in% c(0.05, 0.95))
  expect_true(x_custom %in% c(0.15, 0.85))
})

test_that("er_style_summary_gof() fields argument controls which fields appear in the label", {
  fake_model <- structure(list(), class = "er_test_fake_summary_model")

  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_summary(model = fake_model, style = er_style_summary_gof)
  args <- list(
    data     = plt$data,
    config   = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata   = plt$strata,
    theme    = plt$theme
  )

  # default: all four fields
  out_all <- do.call(er_style_summary_gof, args)
  lbl_all <- out_all$data$lbl
  expect_match(lbl_all, "N = ")
  expect_match(lbl_all, "AIC = ")
  expect_match(lbl_all, "BIC = ")

  # subset: only n and aic
  out_sub <- do.call(er_style_summary_gof, c(args, list(fields = c("n", "aic"))))
  lbl_sub <- out_sub$data$lbl
  expect_match(lbl_sub, "N = ")
  expect_match(lbl_sub, "AIC = ")
  expect_false(grepl("BIC", lbl_sub))
  expect_false(grepl("R\u00b2", lbl_sub))
})

test_that("er_style_summary_gof() fields argument also controls display order", {
  fake_model <- structure(list(), class = "er_test_fake_summary_model")

  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_summary(model = fake_model, style = er_style_summary_gof)
  args <- list(
    data     = plt$data,
    config   = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata   = plt$strata,
    theme    = plt$theme
  )

  out_fwd <- do.call(er_style_summary_gof, c(args, list(fields = c("aic", "n"))))
  out_rev <- do.call(er_style_summary_gof, c(args, list(fields = c("n", "aic"))))

  # AIC before N vs N before AIC
  lbl_fwd <- out_fwd$data$lbl
  lbl_rev <- out_rev$data$lbl
  expect_lt(regexpr("AIC", lbl_fwd), regexpr("N =", lbl_fwd))
  expect_lt(regexpr("N =", lbl_rev), regexpr("AIC", lbl_rev))
})

# ---- new arguments: label styling ----

test_that("er_style_summary_pvalue() accepts label styling args and stores them as aesthetics", {
  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_summary(model = er_test_mod1)
  args <- list(
    data     = plt$data,
    config   = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata   = plt$strata,
    theme    = plt$theme
  )

  out_custom <- do.call(er_style_summary_pvalue, c(args, list(label_size = 6, label_colour = "red", label_fill = "yellow")))
  expect_true(inherits(out_custom, "LayerInstance"))
  expect_equal(out_custom$aes_params$size, 6)
  expect_equal(out_custom$aes_params$colour, "red")
  expect_equal(out_custom$aes_params$fill, "yellow")
})

test_that("er_style_summary_gof() accepts label styling args and stores them as aesthetics", {
  fake_model <- structure(list(), class = "er_test_fake_summary_model")
  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_summary(model = fake_model, style = er_style_summary_gof)

  args <- list(
    data     = plt$data,
    config   = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata = plt$strata,
    theme = plt$theme
  )

  out_custom <- do.call(er_style_summary_gof, c(args, list(label_size = 5, label_colour = "blue")))
  expect_true(inherits(out_custom, "LayerInstance"))
  expect_equal(out_custom$aes_params$size, 5)
  expect_equal(out_custom$aes_params$colour, "blue")
})

test_that("er_style_summary_n() accepts label styling args and stores them as aesthetics", {
  plt <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_summary(style = er_style_summary_n)

  args <- list(
    data     = plt$data,
    config   = plt$layer$summary$config,
    stratify = plt$layer$summary$stratify,
    exposure = plt$exposure,
    response = plt$response,
    strata = plt$strata,
    theme = plt$theme
  )

  out_custom <- do.call(er_style_summary_n, c(args, list(label_size = 5, label_colour = "green", label_fill = "grey")))
  expect_true(inherits(out_custom, "LayerInstance"))
  expect_equal(out_custom$aes_params$size, 5)
  expect_equal(out_custom$aes_params$colour, "green")
  expect_equal(out_custom$aes_params$fill, "grey")
})
