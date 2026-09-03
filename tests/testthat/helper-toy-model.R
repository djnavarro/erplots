# ---------------------------------------------------------------------------
# er_test_toy_model(): an internal, test-only model wrapper covering exactly
# two cases -- Gaussian/identity ("linear regression") and binomial/logit
# ("logistic regression") -- implemented via stats::glm(), mirroring
# erglm::erglm_model()'s own algorithms (erglm_model() is itself just a
# tagged glm() call). This exists purely to let most of the test suite run
# without erglm installed; it has no bearing on erplots' own "erplots never
# fits a model" design principle, since nothing in R/ calls this -- see
# AGENTS.md's "Internal toy lm/glm test wrapper" section for the full
# rationale.
#
# Deliberately narrow: only gaussian(link = "identity") and
# binomial(link = "logit") are supported. Poisson/Gamma/non-canonical links
# stay erglm/emaxnls-only (see er_test_mod_poisson in helper-data.R, which
# remains erglm-backed for exactly this reason).
#
# `tests/testthat/test-toy-model-sync.R` fits the same formula/data through
# both this wrapper and erglm::erglm_model() and asserts their
# er_predict()/er_summary() outputs agree, so a future erglm change that
# silently drifts from the algorithm mirrored here is caught rather than
# passing unnoticed.
# ---------------------------------------------------------------------------

er_test_toy_model <- function(formula, data, family = stats::gaussian()) {
  if (is.character(family)) family <- get(family, mode = "function")()
  if (!family$family %in% c("gaussian", "binomial")) {
    rlang::abort("er_test_toy_model() only supports family = gaussian() or binomial().")
  }

  fit <- stats::glm(formula, data = data, family = family)

  expected_link <- if (family$family == "gaussian") "identity" else "logit"
  if (!identical(stats::family(fit)$link, expected_link)) {
    rlang::abort("er_test_toy_model() only supports the canonical link for each family.")
  }

  structure(list(fit = fit, data = data), class = "er_test_toy_model")
}

er_predict.er_test_toy_model <- function(model, newdata, conf_level = 0.95, ...) {
  fit <- model$fit
  inverse_link <- stats::family(fit)$linkinv
  z_scale <- -stats::qnorm((1 - conf_level) / 2)

  link_pred <- stats::predict(fit, newdata, se.fit = TRUE, type = "link")

  newdata$fit_resp <- inverse_link(link_pred$fit)
  newdata$ci_lower <- inverse_link(link_pred$fit - z_scale * link_pred$se.fit)
  newdata$ci_upper <- inverse_link(link_pred$fit + z_scale * link_pred$se.fit)
  newdata
}

er_simulate.er_test_toy_model <- function(model, newdata, nsim = 100, seed = NULL, ...) {
  # mvtnorm is Suggests-only; skip cleanly (rather than erroring) for any
  # test that transitively reaches this method when it isn't installed,
  # e.g. under R-hub's `nosuggests` container.
  testthat::skip_if_not_installed("mvtnorm")

  fit <- model$fit
  family_name <- stats::family(fit)$family
  dispersion <- summary(fit)$dispersion
  inverse_link <- stats::family(fit)$linkinv

  # mirrors erglm:::erglm_fun()'s own model-matrix-based linear predictor,
  # so a simulated draw's mean matches the same computation erglm uses
  mm <- stats::model.matrix(stats::delete.response(stats::terms(fit$formula)), newdata)

  reps <- vector("list", nsim)
  withr::with_seed(seed %||% 1, {
    par <- mvtnorm::rmvnorm(n = nsim, mean = stats::coef(fit), sigma = stats::vcov(fit))
    for (ii in seq_len(nsim)) {
      row <- newdata
      row$sim_id <- ii
      row$fit_resp <- inverse_link(as.vector(mm %*% par[ii, ]))
      row$sim_resp <- switch(
        family_name,
        binomial = stats::rbinom(nrow(row), size = 1, prob = row$fit_resp),
        gaussian = stats::rnorm(nrow(row), mean = row$fit_resp, sd = sqrt(dispersion))
      )
      reps[[ii]] <- row
    }
  })
  dplyr::bind_rows(reps)
}

er_summary.er_test_toy_model <- function(model, conf_level = 0.95, ...) {
  fit <- model$fit
  coefs <- summary(fit)$coefficients
  if (nrow(coefs) < 2) return(NULL)

  # "Pr(>|z|)" for binomial (known dispersion), "Pr(>|t|)" for gaussian
  # (estimated dispersion) -- match by pattern, same as erglm
  p_col <- grep("^Pr\\(", colnames(coefs))[1]

  z_scale <- -stats::qnorm((1 - conf_level) / 2)
  estimate <- unname(coefs[, 1])
  std_error <- unname(coefs[, 2])

  coefficients <- tibble::tibble(
    term = rownames(coefs),
    estimate = estimate,
    std_error = std_error,
    statistic = unname(coefs[, 3]),
    p_value = unname(coefs[, p_col]),
    conf_low = estimate - z_scale * std_error,
    conf_high = estimate + z_scale * std_error,
  )

  fam <- stats::family(fit)
  r_squared <- if (fam$family == "gaussian" && fam$link == "identity") {
    1 - fit$deviance / fit$null.deviance
  } else {
    NA_real_
  }

  glance <- tibble::tibble(
    n = stats::nobs(fit),
    df_residual = fit$df.residual,
    logLik = as.numeric(stats::logLik(fit)),
    aic = stats::AIC(fit),
    bic = stats::BIC(fit),
    deviance = fit$deviance,
    r_squared = r_squared,
    converged = fit$converged,
  )

  list(
    p_value = unname(coefs[2, p_col]),
    coefficients = coefficients,
    glance = glance
  )
}

registerS3method("er_predict", "er_test_toy_model", er_predict.er_test_toy_model)
registerS3method("er_simulate", "er_test_toy_model", er_simulate.er_test_toy_model)
registerS3method("er_summary", "er_test_toy_model", er_summary.er_test_toy_model)

# ---------------------------------------------------------------------------
# er_test_toy_tte_model(): an internal, test-only AFT time-to-event model
# wrapper, implemented via survival::survreg(). Exists to exercise
# er_tte_add_model()/er_predict_survival() without depending on the (not
# yet CRAN-released) ertte package -- see PLAN.md's "er_tte_add_model()"
# entry. CI construction deliberately mirrors ertte's own documented
# approximation for its AFT engine (Wald interval on the linear
# predictor `mu`, back-transformed through the base distribution's CDF;
# `scale` uncertainty is ignored) -- not a claim of optimality, just
# enough for this package's own tests to exercise the generic contract.
# ---------------------------------------------------------------------------

er_test_toy_tte_model <- function(formula, data, dist = "weibull") {
  fit <- survival::survreg(formula, data = data, dist = dist)
  structure(list(fit = fit, data = data), class = "er_test_toy_tte_model")
}

er_predict_survival.er_test_toy_tte_model <- function(model, newdata, time_grid, conf_level = 0.95, ...) {
  fit <- model$fit
  scale <- fit$scale
  dist <- fit$dist

  pbase <- switch(dist,
    weibull = ,
    exponential = function(z) 1 - exp(-exp(z)),
    lognormal = stats::pnorm,
    loglogistic = stats::plogis,
    rlang::abort(paste0("er_test_toy_tte_model() doesn't support dist = \"", dist, "\"."))
  )

  z_scale <- -stats::qnorm((1 - conf_level) / 2)
  lp <- stats::predict(fit, newdata = newdata, type = "linear", se.fit = TRUE)

  n_profile <- nrow(newdata)
  n_time <- length(time_grid)
  out <- newdata[rep(seq_len(n_profile), each = n_time), , drop = FALSE]
  out$time <- rep(time_grid, times = n_profile)
  rownames(out) <- NULL

  mu    <- rep(lp$fit, each = n_time)
  se_mu <- rep(lp$se.fit, each = n_time)
  log_t <- log(out$time)

  out$fit_survival <- 1 - pbase((log_t - mu) / scale)
  out$ci_lower <- 1 - pbase((log_t - (mu - z_scale * se_mu)) / scale)
  out$ci_upper <- 1 - pbase((log_t - (mu + z_scale * se_mu)) / scale)

  out
}
registerS3method("er_predict_survival", "er_test_toy_tte_model", er_predict_survival.er_test_toy_tte_model)
