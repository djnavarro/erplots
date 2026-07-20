# AGENTS.md

## What this package is

erplots provides a fluent mini-language for building exposure-response
plots: model curves/ribbons, quantile-binned response-rate/mean
summaries, a raw-data layer, and grouped distribution panels. It is
model-agnostic: erplots never fits a model itself. Any model
implementing `er_predict()` can be visualised; implementing
`er_simulate()` and `er_summary()` additionally enables uncertainty
spaghetti plots/VPCs and summary annotations (e.g. p-values). See
`?er_model_interface`.

`er_plot()` takes a `response_type = c("auto", "binary", "continuous",
"count")` argument (auto-detected from the response column if not
given: logical or values entirely in `{0, 1}` → `"binary"`, else
`"continuous"`; `"auto"` never resolves to `"count"` -- that must be
declared explicitly), stored on `object$response$type`/
`object$response$limits`. The model curve/ribbon
(`er_plot_show_model()`) and group panel (`er_plot_show_groups()`)
layers work for any response type with no dispatch needed. The
quantile summary layer (`er_plot_show_quantiles()`) and `er_vpc_plot()`
are now fully generalised across all three response types (rate +
Clopper-Pearson for `"binary"`; mean + t-interval for `"continuous"`;
mean + exact Poisson interval for `"count"`). The data layer
(`er_plot_show_data()`, renamed from `er_plot_show_datastrip()`) also
works for any response type, with no `"continuous"`/`"count"` error path
left -- see "Planned work" below.

`er_plot_show_data()` offers two mutually exclusive styles: `"overlay"`
(the default) plots raw observations at their true `(exposure, response)`
coordinates directly on the model panel -- a single, response-type-agnostic
builder (`build_data_overlay()`) with a small vertical jitter applied only
for binary responses, and a `color` aesthetic that's always strata (sharing
the base plot's own legend) rather than the response value. `"jitter"` is
the older panel-based design (`build_data_jitter()` for a binary response,
`build_data_color()` for continuous/count, `object$part$data`) -- for a
continuous/count response it produces one color-coded panel (or one per
stratum level) below the base plot instead of an overlay in the main
panel. The two styles live in separate `object$part` slots (`overlay` vs.
`data`); setting one via `er_plot_show_data()` clears the other.

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

See [PLAN.md](PLAN.md) for scoped-out future development. The original
continuous/count-response generalisation (PLAN.md Stages 0-6, plus the
exact-Poisson-interval fast-follow) is done: response-type detection/
declaration, guard rails, and the substantive generalisation of the
quantile summary layer and `er_vpc_plot()` have all landed. The **data
layer's continuous-response variant** (PLAN.md's "Continuous-response
data strip" section) is also done, in two forms: Stage 7a/7b's
panel-based design (`style = "jitter"`, dispatching to
`build_data_color()` for a continuous/count response) and Stage 7d's
`build_data_overlay()` (`style = "overlay"`, now the default -- see
above). Still open: Stage 7c (docs/vignette content for the panel-based
variant). Also see PLAN.md's "Mini-language architecture review"
section for documented-but-unimplemented design notes (singleton/
additive layer semantics, stratification/color precedence) that
motivated both variants' design.

## Structure

- `R/er-generics.R` -- the model interface: `er_predict()`,
  `er_simulate()`, `er_summary()` generics and their default methods.
- `R/er-plot-api.R` -- the public plot-building API: `er_plot()`,
  `er_plot_show_model()`, `er_plot_show_quantiles()`,
  `er_plot_show_data()`, `er_plot_show_groups()`, `er_plot_build()`,
  plus `print`/`plot` methods for the `er_plot` S3 class. Each layer
  function (except `er_plot()` itself) has its own dedicated Rd topic
  (no shared `@rdname`).
- `R/er-plot-part.R` -- internal `.part_*()` functions that assemble the
  configuration for each plot component (this is where `er_predict()` /
  `er_simulate()` / `er_summary()` get called on the user-supplied model).
- `R/er-plot-build.R`, `R/er-plot-compose.R` -- internal plotting/layout
  machinery that turns parts into ggplot2 objects and composes them with
  patchwork.
- `R/er-plot-partials-*.R` -- the pluggable `build_*()` partial builders
  (one file per component: model, summary, quantile, data, group).
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
