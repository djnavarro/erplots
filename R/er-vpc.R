
#' Visual predictive check plot for an exposure-response model
#'
#' Compares observed response rates against simulated response rates from a
#' model, stratified by a grouping variable. This function is model-agnostic:
#' it operates purely on data frames, and can obtain those data frames in
#' either of two ways -- see the `sim`/`model` arguments below.
#'
#' @param data Observed data
#' @param sim Simulated data, with the same `exposure`/`response`/`group_by`
#'   columns as `data`, plus a `sim_id` column identifying each replicate.
#'   Mutually exclusive with `model`; supply exactly one of the two. Useful
#'   for a hand-built simulation, or a model-specific helper that doesn't
#'   go through the `er_simulate()` interface. Passing `model` instead is
#'   preferred whenever the model implements [er_simulate()]'s `sim_resp`
#'   extension (see [er_model_interface]).
#' @param exposure Exposure variable (one variable, unquoted)
#' @param response Response variable (one variable, unquoted). May be
#'   binary (0/1, or logical) or continuous; see `response_type`
#' @param group_by Variable (unquoted) to stratify predictions
#' @param model A fitted exposure-response model implementing
#'   [er_simulate()] with a `sim_resp` column (see [er_model_interface]).
#'   Mutually exclusive with `sim`; supply exactly one of the two. When
#'   supplied, `sim` is built internally via `er_simulate(model, newdata =
#'   data, nsim = nsim, seed = seed)`; an error is raised if the model's
#'   `er_simulate()` method doesn't provide `sim_resp` (either because it
#'   returns `NULL`, i.e. no simulation support at all, or because it only
#'   supports the parameter-uncertainty-only `fit_resp` used by
#'   [er_style_model_spaghetti()] -- a VPC needs the fuller, response-level
#'   simulation `sim_resp` represents; see [er_model_interface] for the
#'   distinction).
#' @param nsim Number of simulation replicates, only used when `model` is
#'   supplied. Must be a single positive whole number.
#' @param seed Optional RNG seed, only used when `model` is supplied
#' @param conf_level Confidence level
#' @param response_type One of `"auto"` (default), `"binary"`,
#'   `"continuous"`, or `"count"`. Governs how the observed-side summary
#'   is computed: response *rate* with a Clopper-Pearson CI for
#'   `"binary"`, bin *mean* with a t-interval for `"continuous"` (see
#'   [ci_t()]), or bin *mean* with an exact Poisson interval for
#'   `"count"` (see [ci_poisson()]). `"auto"` detects from the
#'   observed `response` column (entirely in `{0, 1}`, or logical, is
#'   treated as binary; see [er_plot()]'s `response_type` for the same
#'   heuristic) and never resolves to `"count"`: a count (Poisson-style)
#'   response auto-detects as `"continuous"` (counts aren't confined to
#'   `{0, 1}`) and is summarised with the bin-mean-plus-t-interval
#'   approximation unless `response_type = "count"` is declared
#'   explicitly, in which case the exact Poisson interval is used instead.
#'
#' @returns A ggplot2 object
#'
#' @examples
#' if (requireNamespace("erglm", quietly = TRUE)) {
#' library(erglm)
#' mod <- erglm_model(ae2 ~ aucss + sex, erglm_data, family = binomial())
#'
#' er_vpc_plot(erglm_data, exposure = aucss, response = ae2, group_by = aucss, model = mod)
#' er_vpc_plot(erglm_data, exposure = aucss, response = ae2, group_by = sex, model = mod)
#'
#' mod_gaussian <- erglm_model(biomarker_change ~ aucss, erglm_data, family = gaussian())
#' er_vpc_plot(
#'   erglm_data, exposure = aucss, response = biomarker_change,
#'   group_by = aucss, model = mod_gaussian
#' )
#'
#' mod_poisson <- erglm_model(ae_count ~ aucss, erglm_data, family = poisson())
#' er_vpc_plot(
#'   erglm_data, exposure = aucss, response = ae_count, group_by = aucss,
#'   model = mod_poisson, response_type = "count"
#' )
#' }
#'
#' @export
#' 
er_vpc_plot <- function(data, sim = NULL, exposure, response, group_by, model = NULL,
                         nsim = 100, seed = NULL, conf_level = 0.95,
                         response_type = c("auto", "binary", "continuous", "count")) {

  response_type <- match.arg(response_type)

  exp_var <- rlang::as_name(rlang::enquo(exposure))
  rsp_var <- rlang::as_name(rlang::enquo(response))
  grp_var <- rlang::as_name(rlang::enquo(group_by))

  if (is.null(sim) && is.null(model)) {
    rlang::abort("Supply exactly one of `sim` or `model` to `er_vpc_plot()`.")
  }
  if (!is.null(sim) && !is.null(model)) {
    rlang::abort("Supply exactly one of `sim` or `model` to `er_vpc_plot()`, not both.")
  }

  if (!is.null(model)) {
    # validate `nsim` up front -- without this, `nsim = 0`/negative/
    # fractional values ran to completion but failed deep inside whatever
    # matrix/vector machinery a model's `er_simulate()` method happens to
    # use (e.g. "non-conformable arguments", "invalid arguments"), with
    # no indication that `nsim` itself was the problem; see PLAN.md's
    # "stress-test findings" section
    if (!is.numeric(nsim) || length(nsim) != 1L) {
      rlang::abort("`nsim` must be a single number.")
    }
    if (!is.finite(nsim) || nsim < 1 || nsim != round(nsim)) {
      rlang::abort(c(
        sprintf("`nsim` must be a positive whole number, not %s.", format(nsim)),
        "i" = "`nsim` is the number of simulation replicates drawn via `er_simulate()`, only used when `model` is supplied."
      ))
    }
    raw_sim <- er_simulate(model, newdata = data, nsim = nsim, seed = seed)
    if (is.null(raw_sim) || !("sim_resp" %in% names(raw_sim))) {
      rlang::abort(c(
        paste0(
          "`er_simulate()` does not provide predictive simulation (a `sim_resp` column) for objects of class <",
          paste(class(model), collapse = "/"), ">."
        ),
        "i" = paste0(
          "`er_vpc_plot()`'s `model` argument needs an `er_simulate()` method returning `sim_resp` ",
          "(see `?er_model_interface`) -- this is a stricter requirement than the `fit_resp`-only ",
          "simulation that suffices for `er_style_model_spaghetti()`."
        ),
        "i" = "Alternatively, pass a pre-built `sim` data frame directly."
      ))
    }
    sim <- raw_sim
    sim[[rsp_var]] <- sim[["sim_resp"]]
  }

  if (response_type == "auto") {
    response_type <- .detect_response_type(data[[rsp_var]])
  }

  ll <- list()
  ll[[rsp_var]] <- .get_label(data[[rsp_var]]) %||% rsp_var
  ll[[grp_var]] <- .get_label(data[[grp_var]]) %||% grp_var

  obs <- data |> 
    dplyr::select(dplyr::all_of(c(exp_var, rsp_var, grp_var))) |> 
    dplyr::mutate(
      row_id = dplyr::row_number(),
      sim_id = 0L
    )
  sim <- sim |> 
    dplyr::select(dplyr::all_of(c(exp_var, rsp_var, grp_var, "sim_id")))

  dat <- dplyr::bind_rows(
    Observed = obs,
    Simulated = sim,
    .id = "Source"
  )

  if (is.numeric(dat[[grp_var]])) {
    if (grp_var == exp_var) dat[[".is_placebo"]] <- dat[[exp_var]] == 0
    if (grp_var != exp_var) dat[[".is_placebo"]] <- rep(FALSE, nrow(dat))
    dat <- dat |> dplyr::mutate(
      .quantile = cut_exposure_quantile(
        x = .data[[grp_var]], n = 4, 
        is_placebo = .data[[".is_placebo"]]
      ),
      .by = "Source"
    )
    ll[[".quantile"]] <- ll[[grp_var]]
    grp_var <- ".quantile"
  }

  # response-type-dispatched label formatter and observed-side summary --
  # mirrors .layer_quantile()'s binary/continuous/count dispatch (PLAN.md
  # Stage 1, and the design decision (4) fast-follow for "count")
  if (response_type == "binary") {
    format_y_mid <- scales::label_percent(accuracy = 1)
    smm_obs <- dat |>
      dplyr::filter(Source == "Observed") |> 
      dplyr::summarise(
        n1 = sum(.data[[rsp_var]] == 1, na.rm = TRUE),
        n0 = sum(.data[[rsp_var]] == 0, na.rm = TRUE),
        y_mid = n1 / (n0 + n1),
        ci_lower = ci_clopper_pearson(n1, n0 + n1, conf_level)["lower"], 
        ci_upper = ci_clopper_pearson(n1, n0 + n1, conf_level)["upper"], 
        .by = c("Source", dplyr::all_of(grp_var))
      ) |> 
      dplyr::select(-n1, -n0)
  } else if (response_type == "count") {
    format_y_mid <- scales::label_number(accuracy = 0.01)
    smm_obs <- dat |>
      dplyr::filter(Source == "Observed") |> 
      dplyr::summarise(
        n_units = sum(!is.na(.data[[rsp_var]])),
        y_mid = mean(.data[[rsp_var]], na.rm = TRUE),
        ci_lower = ci_poisson(sum(.data[[rsp_var]], na.rm = TRUE), n_units, conf_level)["lower"], 
        ci_upper = ci_poisson(sum(.data[[rsp_var]], na.rm = TRUE), n_units, conf_level)["upper"], 
        .by = c("Source", dplyr::all_of(grp_var))
      ) |> 
      dplyr::select(-n_units)
  } else {
    format_y_mid <- scales::label_number(accuracy = 0.01)
    smm_obs <- dat |>
      dplyr::filter(Source == "Observed") |> 
      dplyr::summarise(
        y_mid = mean(.data[[rsp_var]], na.rm = TRUE),
        ci_lower = ci_t(.data[[rsp_var]], conf_level)["lower"], 
        ci_upper = ci_t(.data[[rsp_var]], conf_level)["upper"], 
        .by = c("Source", dplyr::all_of(grp_var))
      )
  }
  smm_obs$y_mid_lbl <- format_y_mid(smm_obs$y_mid)

  alpha <- (1 - conf_level)/2
  smm_sim <- dat |> 
    dplyr::filter(Source == "Simulated") |> 
    dplyr::summarise(
      y = mean(.data[[rsp_var]], na.rm = TRUE),
      .by = c("Source", dplyr::all_of(grp_var), "sim_id")
    ) |> 
    dplyr::summarise(
      y_mid = mean(y, na.rm = TRUE),
      ci_lower = stats::quantile(y, probs = alpha, na.rm = TRUE), 
      ci_upper = stats::quantile(y, probs = 1 - alpha, na.rm = TRUE), 
      .by = c("Source", dplyr::all_of(grp_var))
    )
  smm_sim$y_mid_lbl <- format_y_mid(smm_sim$y_mid)

  smm <- dplyr::bind_rows(smm_obs, smm_sim)
  attr(smm[["y_mid"]], "label") <- ll[[rsp_var]]
  attr(smm[[grp_var]], "label") <- ll[[grp_var]]

  plt <- smm |> 
    ggplot2::ggplot(ggplot2::aes(
      x = .data[[grp_var]], 
      y = y_mid,
      color = Source
    )) +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        ymin = ci_lower,
        ymax = ci_upper
      ),
      position = ggplot2::position_dodge2(width = .2),
      width = .2
    ) + 
    ggplot2::geom_point(
      position = ggplot2::position_dodge2(width = .2),
      size = 2
    ) +
    ggplot2::theme_bw() + 
    NULL

  return(plt)
}
