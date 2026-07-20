# AGENTS.md

## What this package is

erplots provides a fluent mini-language for building exposure-response
plots: model curves/ribbons, quantile-binned response-rate summaries,
data strips, and grouped distribution panels. It is model-agnostic:
erplots never fits a model itself. Any model implementing `er_predict()`
can be visualised; implementing `er_simulate()` and `er_summary()`
additionally enables uncertainty spaghetti plots/VPCs and summary
annotations (e.g. p-values). See `?er_model_interface`.

`er_plot()` takes a `response_type = c("auto", "binary", "continuous")`
argument (auto-detected from the response column if not given: logical
or values entirely in `{0, 1}` → `"binary"`, else `"continuous"`),
stored on `object$response$type`/`object$response$limits`. The model
curve/ribbon (`er_plot_show_model()`) and group panel
(`er_plot_show_groups()`) layers work for either response type. The
quantile summary layer (`er_plot_show_quantiles()`), the data strip
(`er_plot_show_datastrip()`), and `er_vpc_plot()` still assume a binary
response internally and currently *error* (rather than silently
mis-plot) if given a continuous response -- see "Planned work" below.

The companion package [erglm](https://github.com/djnavarro/erglm)
(formerly `erlr`) fits GLM-based exposure-response models and implements
this package's generics for its model objects. erplots has no hard
dependency on erglm -- it's listed only under `Suggests`, for
examples/tests/vignettes. Since erglm is GitHub-only (not on CRAN),
`DESCRIPTION` also declares `Remotes: djnavarro/erglm` so CI can resolve
it. Key API points to remember: the example dataset is
`erglm::erglm_data` (not `erlr::lr_data`), and models are fit with
`erglm::erglm_model(formula, data, family = ...)` (family is explicit).
erglm now genuinely supports `binomial`/`poisson`/`gaussian`/`Gamma`
families, with matching binary (`ae1`/`ae2`), count (`ae_count`), and
continuous (`biomarker_change`, `ae_duration`) response columns in
`erglm_data` -- not just binomial. Models are simulated with
`erglm::erglm_vpc_sim()`; the `er_predict()`/`er_simulate()`/
`er_summary()` methods erglm registers for its model objects are correct
for all four families, so no erplots-side changes are needed there.

## Planned work

See [PLAN.md](PLAN.md) for scoped-out future development. The main item
is extending several data-summary layers (quantile bins, data strips, VPC
plots), which currently assume a binary (0/1) response, to also support
continuous-response exposure-response models -- now a live need, since
erglm can produce those models directly (see above). Progress so far:
response-type detection/declaration (`er_plot(response_type = ...)`) and
guard rails (continuous responses now error clearly rather than silently
mis-plotting in `er_plot_show_quantiles()`/`er_plot_show_datastrip()`/
`er_vpc_plot()`) are done (PLAN.md Stages 0 and 5). The substantive
generalisation of those three layers (t-interval-based quantile/VPC
summaries, a continuous-response data strip design or documented
omission, count-response handling) is still open (Stages 1-4, 6).

## Structure

- `R/er-generics.R` -- the model interface: `er_predict()`,
  `er_simulate()`, `er_summary()` generics and their default methods.
- `R/er-plot-api.R` -- the public plot-building API: `er_plot()`,
  `er_plot_show_model()`, `er_plot_show_quantiles()`,
  `er_plot_show_datastrip()`, `er_plot_show_groups()`, `er_plot_build()`,
  plus `print`/`plot` methods for the `er_plot` S3 class.
- `R/er-plot-part.R` -- internal `.part_*()` functions that assemble the
  configuration for each plot component (this is where `er_predict()` /
  `er_simulate()` / `er_summary()` get called on the user-supplied model).
- `R/er-plot-build.R`, `R/er-plot-compose.R` -- internal plotting/layout
  machinery that turns parts into ggplot2 objects and composes them with
  patchwork.
- `R/er-plot-partials-*.R` -- the pluggable `build_*()` partial builders
  (one file per component: model, summary, quantile, datastrip, group).
  See `?er_partial` for the interface these builders share.
- `R/er-vpc.R` -- `er_vpc_plot()`, a model-agnostic VPC-style plot
  operating on plain observed/simulated data frames.
- `R/utils-helpers.R`, `R/utils-global.R` -- small internal helpers
  (including the binary-response-only `clopper_pearson()`,
  `cut_quantile()`, `cut_exposure_quantile()`, the response-type
  detector `.detect_response_type()`, and the shared guard-rail helper
  `.abort_continuous_unsupported()`) and `globalVariables()` declarations
  for NSE.

## Development workflow

- Document with roxygen2 (`devtools::document()`); Markdown roxygen is
  enabled (`Roxygen: list(markdown = TRUE)`).
- Run tests with `devtools::test()`; full checks with `devtools::check()`.
  The package should check cleanly (0 errors/warnings/notes).
- Tests live in `tests/testthat/`. Most test files need `erglm` (a
  `Suggests` dependency, used only to fit example models) and are guarded
  with `skip_if_not_installed("erglm")`; shared test fixtures (including
  `er_test_mod_gaussian`, a continuous-response fixture) live in
  `tests/testthat/helper-data.R`.
- Vignettes/articles live in `vignettes/articles/` and are built for the
  pkgdown site, not shipped with the package (see `.Rbuildignore`).

## Conventions

- Use the base R pipe (`|>`), not the magrittr pipe.
- Follow the existing tidyverse-style conventions (dplyr/tibble/rlang/
  ggplot2/patchwork) already used throughout.
- Public API functions are prefixed `er_`; partial builders are prefixed
  `build_`; internal helpers are prefixed with `.`.
- Never call a model-fitting function from this package. If a plot
  component needs something from the model, add or extend a generic in
  `R/er-generics.R` instead of reaching into model internals.
