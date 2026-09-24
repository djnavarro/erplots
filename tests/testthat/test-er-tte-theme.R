test_that("er_tte_theme() requires an er_tte object", {
  expect_error(er_tte_theme(list(), xlab = "x"), "er_tte")
})

test_that("er_tte_theme() writes xlab/ylab", {
  obj <- survival::lung |>
    er_tte(time, status == 2) |>
    er_tte_theme(xlab = "Days", ylab = "P(survival)")
  expect_equal(obj$theme$xlab, "Days")
  expect_equal(obj$theme$ylab, "P(survival)")
})

test_that("er_tte_theme() writes strata_lab, and errors with no stratify_by set", {
  df <- survival::lung
  df$sex <- factor(df$sex, labels = c("Male", "Female"))
  obj <- df |> er_tte(time, status == 2, stratify_by = sex) |> er_tte_theme(strata_lab = "Sex")
  expect_equal(obj$strata$label, "Sex")

  obj_unstrat <- survival::lung |> er_tte(time, status == 2)
  expect_error(er_tte_theme(obj_unstrat, strata_lab = "Sex"), "stratify_by")
})

test_that("er_tte_theme() writes title/subtitle/caption, applied via labs() on the curve panel", {
  obj <- survival::lung |>
    er_tte(time, status == 2) |>
    er_tte_add_curve() |>
    er_tte_theme(title = "My title", subtitle = "My subtitle", caption = "My caption")

  expect_equal(obj$theme$title, "My title")
  expect_equal(obj$theme$subtitle, "My subtitle")
  expect_equal(obj$theme$caption, "My caption")

  built <- er_tte_build(obj)
  labs <- ggplot2::get_labs(built$output)
  expect_equal(labs$title, "My title")
  expect_equal(labs$subtitle, "My subtitle")
  expect_equal(labs$caption, "My caption")
})

test_that("er_tte_theme() applies title to the top-most panel when risktable is present", {
  obj <- survival::lung |>
    er_tte(time, status == 2) |>
    er_tte_add_curve() |>
    er_tte_add_risktable() |>
    er_tte_theme(title = "With risktable")
  built <- er_tte_build(obj)
  expect_s3_class(built$output, "patchwork")
  curve_panel <- built$output$patches$plots[[1]]
  expect_equal(ggplot2::get_labs(curve_panel)$title, "With risktable")
})

test_that("er_tte_theme()'s xlim overwrites object$time$limits structurally", {
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_theme(xlim = c(0, 200))
  expect_equal(obj$time$limits, c(0, 200))
})

test_that("er_tte_theme()'s xlim affects er_tte_add_model()'s default time_grid when set first", {
  mod <- er_test_toy_tte_model(survival::Surv(time, status == 2) ~ 1, survival::lung)
  obj <- survival::lung |>
    er_tte(time, status == 2) |>
    er_tte_theme(xlim = c(0, 200)) |>
    er_tte_add_model(mod)
  expect_equal(range(obj$layer$model$config$time_grid), c(0, 200))
})

test_that("er_tte_theme()'s ylim is cosmetic, defaulting to c(0, 1)", {
  obj <- survival::lung |> er_tte(time, status == 2)
  expect_equal(obj$theme$ylim, c(0, 1))

  obj <- obj |> er_tte_add_curve() |> er_tte_theme(ylim = c(0.2, 1))
  expect_equal(obj$theme$ylim, c(0.2, 1))
  built <- er_tte_build(obj)
  expect_equal(built$output$scales$get_scales("y")$limits, c(0.2, 1))
})

test_that("er_tte_theme() validates xlab/ylab/strata_lab/title/subtitle/caption", {
  obj <- survival::lung |> er_tte(time, status == 2)
  expect_error(er_tte_theme(obj, xlab = c("a", "b")), "single string")
  expect_error(er_tte_theme(obj, title = 1), "single string")
})

test_that("er_tte_theme() validates xlim/ylim", {
  obj <- survival::lung |> er_tte(time, status == 2)
  expect_error(er_tte_theme(obj, xlim = 1), "length-2")
  expect_error(er_tte_theme(obj, xlim = c(5, 1)), "increasing")
  expect_error(er_tte_theme(obj, ylim = c(NA, 1)), "NA")
})

test_that("er_tte_theme() writes and validates theme_base/theme_extra", {
  obj <- survival::lung |>
    er_tte(time, status == 2) |>
    er_tte_add_curve() |>
    er_tte_theme(theme_base = ggplot2::theme_minimal())

  expect_true(inherits(obj$theme$theme_base, "theme"))
  expect_no_error(er_tte_build(obj))
  expect_error(er_tte_theme(obj, theme_base = "not a theme"), "theme")
})

test_that("er_tte_theme() writes and validates format_p/format_percent", {
  fmt <- scales::label_pvalue(accuracy = 0.01)
  obj <- survival::lung |> er_tte(time, status == 2) |> er_tte_theme(format_p = fmt)
  expect_identical(obj$theme$format_p, fmt)
  expect_error(er_tte_theme(obj, format_p = "not a function"), "function")
})

test_that("er_tte_theme() writes and validates draw_key", {
  obj <- survival::lung |>
    er_tte(time, status == 2) |>
    er_tte_add_curve() |>
    er_tte_theme(draw_key = ggplot2::draw_key_point)
  expect_identical(obj$theme$draw_key, ggplot2::draw_key_point)
  expect_no_error(er_tte_build(obj))
  expect_error(er_tte_theme(obj, draw_key = "not a function"), "function")
})

test_that("er_tte_theme() writes and validates height_curve/height_risktable", {
  obj <- survival::lung |>
    er_tte(time, status == 2) |>
    er_tte_add_curve() |>
    er_tte_add_risktable() |>
    er_tte_theme(height_curve = 5, height_risktable = 1.5)
  expect_equal(obj$theme$height, list(curve = 5, risktable = 1.5))
  expect_error(er_tte_theme(obj, height_curve = -1), "positive")
})

test_that("er_tte_theme() calls accumulate, leaving unsupplied fields unchanged", {
  obj <- survival::lung |>
    er_tte(time, status == 2) |>
    er_tte_theme(xlab = "X") |>
    er_tte_theme(ylab = "Y")

  expect_equal(obj$theme$xlab, "X")
  expect_equal(obj$theme$ylab, "Y")
})

test_that("er_tte_theme(xlim = ...) after er_tte_add_model()/er_tte_add_risktable() still widens their defaults (#18)", {
  # regression test for issue #18: the model layer's default `time_grid`
  # and the risktable layer's default `breaks` used to be snapshotted
  # once, at add-layer time, over whatever `object$time$limits` happened
  # to be *then* -- a later `er_tte_theme(xlim = ...)` never revisited
  # either. Narrowing turned out to be self-correcting (`er_tte_build()`
  # uses hard `scale_x_continuous(limits = ...)`, which ggplot2 itself
  # crops/warns about), but *widening* left the model curve/ribbon and
  # the risktable's reported time points stuck at the old, narrower
  # range, with no warning at all. Contrast with "er_tte_theme()'s xlim
  # affects er_tte_add_model()'s default time_grid when set first" above
  # -- this is the previously-broken *other* call order.
  lung_early <- subset(survival::lung, time <= 300)
  mod <- er_test_toy_tte_model(survival::Surv(time, status == 2) ~ 1, lung_early)

  tte_after <- lung_early |>
    er_tte(time, status == 2) |>
    er_tte_add_curve() |>
    er_tte_add_model(mod) |>
    er_tte_add_risktable() |>
    er_tte_theme(xlim = c(0, 1022))

  built_after <- er_tte_build(tte_after)
  expect_equal(range(built_after$layer$model$config$time_grid), c(0, 1022))
  expect_equal(built_after$layer$curve$config$time_upper, 1022)
  # `.default_risktable_times()` snaps to `pretty()` breaks within the
  # limit, so this won't hit 1022 exactly -- just confirm it's no longer
  # stuck at (or near) the old, narrower 0-300 range
  expect_true(max(built_after$layer$risktable$config$breaks) > 300)
  expect_true(max(built_after$layer$risktable$config$table$time) > 300)

  # same result regardless of call order
  tte_before <- lung_early |>
    er_tte(time, status == 2) |>
    er_tte_theme(xlim = c(0, 1022)) |>
    er_tte_add_curve() |>
    er_tte_add_model(mod) |>
    er_tte_add_risktable()

  built_before <- er_tte_build(tte_before)
  expect_equal(built_after$layer$model$config$time_grid, built_before$layer$model$config$time_grid)
  expect_equal(built_after$layer$curve$config$time_upper, built_before$layer$curve$config$time_upper)
  expect_equal(built_after$layer$risktable$config$breaks, built_before$layer$risktable$config$breaks)
})

test_that("er_tte_theme(xlim = ...) after er_tte_add_model()/er_tte_add_risktable() still narrows their defaults", {
  mod <- er_test_toy_tte_model(survival::Surv(time, status == 2) ~ 1, survival::lung)

  tte_narrowed <- survival::lung |>
    er_tte(time, status == 2) |>
    er_tte_add_curve() |>
    er_tte_add_model(mod) |>
    er_tte_add_risktable() |>
    er_tte_theme(xlim = c(0, 200))

  built <- er_tte_build(tte_narrowed)
  expect_equal(range(built$layer$model$config$time_grid), c(0, 200))
  expect_equal(built$layer$curve$config$time_upper, 200)
  expect_true(max(built$layer$risktable$config$breaks) <= 200)
})

test_that("er_tte_add_model(time_grid = ...)/er_tte_add_risktable(times = ...) explicit overrides are never regenerated from time$limits", {
  lung_early <- subset(survival::lung, time <= 300)
  mod <- er_test_toy_tte_model(survival::Surv(time, status == 2) ~ 1, lung_early)

  tte <- lung_early |>
    er_tte(time, status == 2) |>
    er_tte_add_curve() |>
    er_tte_add_model(mod, time_grid = seq(0, 250, length.out = 10)) |>
    er_tte_add_risktable(times = c(0, 100, 200)) |>
    er_tte_theme(xlim = c(0, 1022))

  built <- er_tte_build(tte)
  expect_equal(built$layer$model$config$time_grid, seq(0, 250, length.out = 10))
  expect_equal(built$layer$risktable$config$breaks, c(0, 100, 200))
})

test_that("er_tte_build() refreshes are no-ops when the model/risktable layers aren't present", {
  tte <- survival::lung |>
    er_tte(time, status == 2) |>
    er_tte_add_curve() |>
    er_tte_theme(xlim = c(0, 200))

  expect_no_error(er_tte_build(tte))
})
