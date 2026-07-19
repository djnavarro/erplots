test_that("er_predict() errors informatively for unsupported classes", {
  expect_error(er_predict(structure(list(), class = "not_a_model"), data.frame(x = 1)))
})

test_that("er_simulate() and er_summary() default to NULL for unsupported classes", {
  expect_null(er_simulate(structure(list(), class = "not_a_model"), data.frame(x = 1)))
  expect_null(er_summary(structure(list(), class = "not_a_model")))
})
