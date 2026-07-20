
#' Visual predictive check plot for an exposure-response model
#'
#' Compares observed response rates against simulated response rates from a
#' model, stratified by a grouping variable. This function is model-agnostic:
#' it operates purely on data frames. The `sim` data frame is expected to
#' contain one row per simulated observation per replicate, with a `sim_id`
#' column identifying each replicate (see e.g. `erglm::erglm_vpc_sim()` for one
#' way to generate such simulations from a fitted model).
#'
#' @param data Observed data
#' @param sim Simulated data, with the same `exposure`/`response`/`group_by`
#'   columns as `data`, plus a `sim_id` column identifying each replicate
#' @param exposure Exposure variable (one variable, unquoted)
#' @param response Response variable (one variable, unquoted). Must
#'   currently be binary (0/1, or logical); continuous responses are not
#'   yet supported and raise an error (see `PLAN.md`)
#' @param group_by Variable (unquoted) to stratify predictions
#' @param conf_level Confidence level
#'
#' @returns A ggplot2 object
#'
#' @examples
#' \dontrun{
#' library(erglm)
#' mod <- erglm_model(ae2 ~ aucss + sex, erglm_data, family = binomial())
#' sim <- erglm_vpc_sim(mod)
#' er_vpc_plot(erglm_data, sim, aucss, ae2, group_by = aucss)
#' er_vpc_plot(erglm_data, sim, aucss, ae2, group_by = sex)
#' }
#'
#' @export
#' 
er_vpc_plot <- function(data, sim, exposure, response, group_by, conf_level = 0.95) {

  exp_var <- rlang::as_name(rlang::enquo(exposure))
  rsp_var <- rlang::as_name(rlang::enquo(response))
  grp_var <- rlang::as_name(rlang::enquo(group_by))

  if (identical(.detect_response_type(data[[rsp_var]]), "continuous")) {
    .abort_continuous_unsupported("er_vpc_plot")
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

  percent <- scales::label_percent(accuracy = 1)
  smm_obs <- dat |>
    dplyr::filter(Source == "Observed") |> 
    dplyr::summarise(
      n1 = sum(.data[[rsp_var]] == 1, na.rm = TRUE),
      n0 = sum(.data[[rsp_var]] == 0, na.rm = TRUE),
      y_mid = mean(.data[[rsp_var]], na.rm = TRUE),
      y_mid_lbl = percent(n1 / (n0 + n1)),
      ci_lower = clopper_pearson(n1, n0 + n1, conf_level)["lower"], 
      ci_upper = clopper_pearson(n1, n0 + n1, conf_level)["upper"], 
      .by = c("Source", grp_var)
    ) |> 
    dplyr::select(-n1, -n0)

  alpha <- (1 - conf_level)/2
  smm_sim <- dat |> 
    dplyr::filter(Source == "Simulated") |> 
    dplyr::summarise(
      y = mean(.data[[rsp_var]], na.rm = TRUE),
      .by = c("Source", grp_var, "sim_id")
    ) |> 
    dplyr::summarise(
      y_mid = mean(y, na.rm = TRUE),
      y_mid_lbl = percent(y_mid),
      ci_lower = stats::quantile(y, probs = alpha, na.rm = TRUE), 
      ci_upper = stats::quantile(y, probs = 1 - alpha, na.rm = TRUE), 
      .by = c("Source", grp_var)
    )

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
