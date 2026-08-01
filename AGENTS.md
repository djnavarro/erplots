# AGENTS.md

## What this package is

erplots provides a fluent mini-language for building exposure-response
plots: model curves/ribbons, a summary annotation, quantile-binned
response-rate/mean summaries, a raw-data layer, and grouped distribution
panels. It is model-agnostic: erplots never fits a model itself. Any
model implementing `er_predict()` can be visualised; implementing
`er_simulate()` and `er_summary()` additionally enables uncertainty
spaghetti plots/VPCs and model-derived summary annotations. See
`?er_model_interface`.

**Never call a model-fitting function from this package.** If a plot
component needs something from the model, add or extend a generic in
`R/er-generics.R` instead of reaching into model internals.

Companion packages implementing the model interface: `erglm` (GLM-based
exposure-response models; `Suggests`-only, `Remotes: djnavarro/erglm`
since it's GitHub-only) and `emaxnls` (Emax/sigmoidal dose-response
models via nonlinear least squares; `Suggests: emaxnls (>= 0.1.1.9000)`
-- this version floor is load-bearing, see "Gotchas" below -- plus
`Remotes: djnavarro/emaxnls`).

## Architecture reference (current state)

This section documents how the package works *today*. For the design
rationale behind these choices, rejected alternatives, and a record of
how the API got here, see [.agents/HISTORY.md](.agents/HISTORY.md).

### The `er_plot` mini-language

`er_plot(data, exposure, response, response_type = c("auto", "binary",
"continuous", "count"), stratify_by = NULL)` constructs an object that
six `er_plot_add_*()` verbs attach layers to; nothing is drawn until
`er_plot_build()`/`print()`/`plot()`. `response_type` is auto-detected
when not given (logical or values entirely in `{0, 1}` -> `"binary"`,
else `"continuous"`; `"auto"` never resolves to `"count"`, that must be
declared explicitly), stored on `object$response$type`/`object$response$limits`.

Layers, each stored in its own `object$layer$*` slot so **pipe order
never affects the built plot**:

- **`er_plot_add_model()`** -- model curve/ribbon. Singleton (a second
  call replaces the first). Works for any response type.
- **`er_plot_add_summary()`** -- a corner-placed text/label annotation.
  Singleton. `model` is optional (`NULL` means no model-derived
  statistic, e.g. a plain observation-count annotation). Independent of
  the model layer -- doesn't require `er_plot_add_model()` to have been
  called.
- **`er_plot_add_quantiles()`** -- quantile-binned response-rate/mean
  summary with CI. Singleton. Generalised across all three response
  types (rate + Clopper-Pearson for `"binary"`; mean + t-interval for
  `"continuous"`; mean + exact Poisson interval for `"count"`).
- **`er_plot_add_data()`** -- raw-data layer. Singleton. Two mutually
  exclusive structural families selected by which builder is passed as
  `style` (see "Builder system" below): `"overlay"` (raw points/hexbins
  drawn directly on the model panel, stored in `object$layer$overlay`)
  or `"panel"` (one or more panels stacked below the base plot, stored
  in `object$layer$data`). Passing a builder from one family clears the
  other slot.
- **`er_plot_add_groups()`** -- one or more stacked panels showing the
  exposure distribution per group variable. The one layer that's
  additive rather than singleton (each call adds another panel).

`er_plot_build()` triggers a base panel when at least one of
model/summary/quantile/overlay is present, *or* when no layer at all has
been added (renders a blank axes-only panel rather than erroring).

**Stratification.** `stratify_by` (set in `er_plot()`) drives a
color/facet precedence rule documented in `vignettes/articles/design.Rmd`:
color/fill encodes strata wherever there's room for it (model
line/ribbon, data overlay's `color`), and facets are used only where
color is already spoken for by something else.

### The model interface (`er_predict()`/`er_simulate()`/`er_summary()`)

Three generics, defined in `R/er-generics.R`. Full contract in
`?er_model_interface`.

- **`er_predict(model, newdata, ...)`** -- point predictions + CI on the
  response scale, for the model curve/ribbon.
- **`er_simulate(model, newdata, nsim, seed, ...)`** -- optional. Returns
  a data frame with `fit_resp` (parameter-uncertainty-only draws, used by
  `er_style_model_spaghetti()`) and, optionally, `sim_resp` (a full
  response-scale draw including observation-level noise -- a 0/1 draw
  for binary, integer for count, includes residual variance for
  continuous). `sim_resp` powers `er_vpc_add_simulated(model = ...)`; if
  a method never populates it, that call errors informatively rather
  than treating `fit_resp` as if it were a noisy draw.
- **`er_summary(model, ...)`** -- optional. Returns `NULL` or a named
  list with any of three independently-optional, reserved keys
  (unrecognized keys are permitted and ignored by built-ins):
  - `p_value` (scalar or `NULL`): a single headline p-value, only when
    the model has one unambiguous candidate coefficient.
  - `coefficients` (tibble/data frame or `NULL`): one row per model
    parameter, snake_case columns (`term`, optional `label`, `estimate`,
    optional `std_error`/`statistic`/`p_value`/`conf_low`/`conf_high`).
  - `glance` (single-row tibble/data frame or `NULL`): model-level
    goodness-of-fit, `broom::glance()`-style (`n`, `df_residual`,
    `logLik`, `aic`, `bic`, `deviance`, `r_squared`, `converged`).

### Builder system (`er_style_*()`)

Every `er_plot_add_*()` function takes a `style` argument (a function
matching `function(data, config, stratify, exposure, response, strata,
theme, ...)`) that defaults to a built-in `er_style_*()` builder and can
be swapped for another built-in or a fully custom one. `...` passed to
an `er_plot_add_*()` call is forwarded to the builder (arguments must be
named). See `?er_style` and `vignettes/articles/extending.Rmd` for the
full custom-builder walkthrough, including what `config` contains per
layer.

A builder self-declares metadata via `er_style_tag(fn, layout = NULL,
fill_role = NULL, y_role = NULL, layer = NULL, zorder = NULL,
response_types = NULL, plot_by_types = NULL)` -- seven independent,
optional attributes (only `layout` is mandatory, and only for a
data-layer builder):

- **`layout`** (`"overlay"`/`"panel"`) -- which structural family a data
  builder belongs to (see above). Mandatory for data-layer builders;
  `er_plot_add_data()` errors if missing.
- **`fill_role`** (e.g. `"density"`) -- tells `.polish_labels()`/
  `.polish_scales()` that a builder's `fill` means something other than
  strata (e.g. `er_style_data_hex()`'s bin density), so the legend is
  titled correctly and `er_plot_theme(fill_continuous = ...)` targets it
  instead of `fill_discrete`.
- **`y_role`** (e.g. `"count"`) -- tells `.polish_labels()` a group
  builder's y-axis is something other than the categorical group
  variable (e.g. `er_style_group_histogram()`'s facet-based layout puts
  counts on y).
- **`layer`** (one of `"model"`, `"summary"`, `"quantile"`, `"data"`,
  `"group"`, `"observed"`, `"simulated"`) -- checked, not just stored:
  each `er_plot_add_*()`/`er_vpc_add_*()` function errors immediately if
  a builder tagged for a different layer is passed to it. Optional --
  an untagged builder is simply never checked.
- **`zorder`** (`"foreground"` default, or `"background"`) -- only
  matters for an `"overlay"`-layout data builder. `"background"` draws
  the overlay's geoms *before* model/summary/quantile (so a
  full-panel-coverage builder like `er_style_data_hex()` doesn't bury
  them); `"foreground"` (the default) draws them after.
- **`response_types`** (subset of `"binary"`/`"continuous"`/`"count"`)
  and **`plot_by_types`** (subset of `"continuous"`/`"discrete"`) --
  VPC-specific; declare which `object$response$type`/`object$group$type`
  values a builder supports. Checked, not just stored:
  `er_vpc_add_observed()`/`er_vpc_add_simulated()` each error
  immediately (`.check_style_response_type()`/`.check_style_plot_by_type()`
  in `R/er-plot-style.R`) if `style` is tagged for a type the `er_vpc`
  object doesn't have -- e.g. `er_style_vpc_observed_line()` declares
  `response_types = c("continuous", "count")` (needs
  `config$percentiles`, never computed for a binary response) and
  `plot_by_types = "continuous"` (its `geom_line()` connects bins along
  a numeric midpoint, meaningless for an unordered categorical
  `plot_by`). Both optional -- an untagged builder is never checked
  against either, the same opt-in treatment `layer` gets; a custom
  builder that skips these tags is responsible for guarding against
  incompatible inputs itself, the way every built-in VPC builder still
  does internally as a fallback.

Built-in builders, by layer:

| Layer | Builders |
|---|---|
| model | `er_style_model_ribbonline()` (default), `er_style_model_line()`, `er_style_model_spaghetti()` |
| summary | `er_style_summary_pvalue()` (default), `er_style_summary_n()`, `er_style_summary_coefficients()`, `er_style_summary_gof()` |
| quantile | `er_style_quantile_errorbar()` (default), `er_style_quantile_pointrange()`, and each's `_vlines` variant (adds a labelled `geom_vline()` at every quantile-bin boundary, including the two outer edges) |
| data | `er_style_data_overlay()` (default, `"overlay"`), `er_style_data_hex()` (`"overlay"`, 2D density via `geom_hex()`, requires `hexbin`), `er_style_data_boxjitter()` (`"panel"`, binary-response only) |
| group | `er_style_group_boxplot()` (default), `er_style_group_violin()`, `er_style_group_histogram()`, `er_style_group_boxjitter()`, `er_style_group_violinjitter()` |

### The VPC mini-grammar

`er_vpc(data, exposure, response, response_type, plot_by = NULL, n_bins
= 4, conf_level = 0.95, probs = c(0.1, 0.5, 0.9))` |>
`er_vpc_add_observed()` |> `er_vpc_add_simulated()` |> `plot()` mirrors
`er_plot()`'s object/layer/builder architecture, scoped deliberately
narrower: no stratification, always a single panel. `plot_by`/`n_bins`/
`conf_level`/`probs` all live on `er_vpc()` itself (stored on
`object$group`), not on either add-verb, since the observed and
simulated layers must always agree on them -- `plot_by` defaults to the
plot's exposure variable; numeric `plot_by` is quantile-binned
(`cut_exposure_quantile()`, placebo separated when `plot_by` is the
exposure variable itself), categorical is used as-is. Whether `plot_by`
is numeric or categorical is auto-detected once in `er_vpc()` and
stored as `object$group$type` (`"continuous"`/`"discrete"`), mirroring
`object$response$type`; both `.layer_vpc_*()` functions copy it onto
their `config$group_type` (with `config$is_numeric_group` kept as a
convenience boolean derived from it) for builders to read. When
`plot_by` is numeric, both `.layer_vpc_*()` functions also compute
`x_median` alongside `x_mid` on `config$summary` (the per-bin median,
vs. mean, of `plot_by`'s values) -- `x_mid` remains what the
mean-anchored builders (`_pointrange_continuous()`/`_errorbar_continuous()`/
the percentile-band idiom) plot at, while `x_median` is what the
default `_mean_errorbar()` pair plots at instead.

- **`er_vpc_add_observed(object, style = ...)`** -- bins the observed
  data (using `object$group`) and computes its response summary.
- **`er_vpc_add_simulated(object, model = NULL, sim = NULL, nsim = 100,
  seed = NULL, style = ...)`** -- must be called after
  `er_vpc_add_observed()`; bins simulated rows against the *observed*
  layer's own stored cutpoints (`obs_config$breaks`, via
  `.apply_exposure_breaks()`), guaranteeing both sides share identical
  bin boundaries. `model`/`sim` are mutually exclusive; exactly one is
  required. When `model` is supplied, calls `er_simulate()` internally
  and requires a `sim_resp` column.

Five visual idioms, chosen by `style`:

- **Adaptive mean/errorbar idiom** (default): `er_style_vpc_observed_mean_errorbar()`
  / `er_style_vpc_simulated_mean_errorbar()` -- point/errorbar of the
  mean/rate + CI, with an x-position that adapts to `object$group$type`
  at build time rather than declaring one `layout` statically:
  equally-spaced at each bin's discrete `.vpc_bin` location when
  `plot_by` is categorical (like the categorical-bin idiom below), or at
  each bin's numeric *median* (`x_median`, computed alongside `x_mid` in
  both `.layer_vpc_*()` functions) on the continuous exposure scale when
  `plot_by` is numeric (like the continuous-x pointrange/errorbar idiom
  below, which uses the mean instead of the median). Both support every
  response type and both `plot_by` types (`response_types = c("binary",
  "continuous", "count")`, `plot_by_types = c("continuous",
  "discrete")`), and neither carries a `layout` tag -- since the
  x-position family is chosen dynamically from the data rather than
  fixed per builder, `.check_vpc_layout_match()` can't meaningfully
  check it statically, so it's skipped (the same opt-in treatment an
  untagged custom builder gets). Pair the two together; pairing either
  with a builder from one of the three idioms below risks an x-position
  mismatch that `.check_vpc_layout_match()` won't catch.
- **Categorical-bin idiom** (`layout = "categorical"`):
  `er_style_vpc_observed_pointrange()` / `er_style_vpc_simulated_errorbar()`
  -- point/errorbar of the mean plotted at each bin's discrete `.vpc_bin`
  location, always (even for a numeric `plot_by`).
- **Continuous-x percentile-band idiom** (`layout = "continuous"`):
  `er_style_vpc_observed_line()` / `er_style_vpc_simulated_ribbon()` --
  one line/ribbon per requested percentile against a continuous exposure
  x-axis (bin midpoint, `x_mid`). Continuous/count responses only (a
  binary response's distribution is fully described by its rate
  already) and a numeric `plot_by` only -- tagged
  `response_types = c("continuous", "count")`, `plot_by_types =
  "continuous"`, so `er_vpc_add_observed()`/`er_vpc_add_simulated()`
  reject an incompatible object up front; each also keeps its own
  internal `config$percentiles`-unavailable guard as a fallback for an
  untagged custom builder.
- **Continuous-x pointrange/errorbar idiom** (`layout = "continuous"`):
  `er_style_vpc_observed_pointrange_continuous()` /
  `er_style_vpc_simulated_errorbar_continuous()` -- the same mean/CI as
  the categorical-bin idiom, but plotted at `x_mid` instead of
  `.vpc_bin`, for pairing with the percentile-band idiom (or with each
  other, on a continuous x-axis) without a layout mismatch. Unlike the
  percentile-band idiom, these only need `config$summary` (already
  carries `x_mid` for a numeric `plot_by`), so they work for a binary
  response too; they error if `plot_by` is categorical (no numeric
  midpoint to plot at).
- **Categorical-bin quantile idiom** (`layout = "categorical"`):
  `er_style_vpc_observed_quantile_errorbar()` /
  `er_style_vpc_simulated_quantile_errorbar()` -- a point/errorbar per
  requested percentile (see [er_vpc()]'s `probs` argument), dodged at
  each bin's discrete `.vpc_bin` location. Unlike the two idioms above,
  `config$percentiles` (and so this idiom) supports a categorical
  `plot_by` as well as a numeric one -- tagged `response_types =
  c("continuous", "count")`, `plot_by_types = c("continuous",
  "discrete")` -- since it never needs a numeric midpoint, only the
  discrete bin label; each builder still errors informatively without
  `config$percentiles` (continuous/count response only) as a fallback.

`er_vpc_add_simulated()` checks the observed and simulated builders'
`layout` tags against each other (`.check_vpc_layout_match()` in
`R/er-plot-style.R`) and errors if they disagree -- e.g. pairing
`er_style_vpc_observed_pointrange()`'s discrete locations with
`er_style_vpc_simulated_ribbon()`'s numeric midpoints would otherwise
silently plot the two layers at inconsistent x-positions for the same
bin. An untagged custom builder on either side skips this check, the
same opt-in treatment the `layer` tag gets. `probs` can't diverge
between the two layers the way `layout` still can, since it's set once
on `er_vpc()` and read from `object$group` by both `.layer_vpc_*()`
functions.

The simulated layer's geoms are always added before the observed layer's,
so a simulated ribbon never buries the observed points/line.

### `er_plot_theme()`

Styles the plot without remapping which variable drives which aesthetic
(that's the builder's job). All arguments default to `NULL` ("leave
unchanged"), so repeated calls accumulate, each only touching the
arguments it supplies:

- `xlab`/`ylab`/`strata_lab` -- axis/legend labels (`strata_lab` errors
  if `stratify_by` wasn't set).
- `title`/`subtitle`/`caption` -- plot-level annotation.
- `xlim`/`ylim` -- exposure/response axis limits.
- `theme_base`/`theme_extra` -- plain ggplot2 theme objects (not
  functions); `theme_extra` fully replaces the default (panel border +
  bottom legend) rather than merging.
- `color_discrete`/`fill_discrete` -- discrete ggplot2 scale objects,
  applied wherever `colour`/`fill` means strata.
- `color_continuous`/`fill_continuous` -- continuous ggplot2 scale
  objects (validated against `"ScaleContinuous"`), applied wherever
  `colour`/`fill` means density (`fill_role = "density"`) or response
  value (`config$color_role == "response"`, a hook only a custom
  builder currently uses).
- `format_p`/`format_percent`/`format_number` -- label formatters.
- `draw_key` -- legend key glyph.
- `height_base`/`height_data`/`height_group` -- relative panel heights,
  merged via `utils::modifyList()`.
- `dodge_width` -- fraction of the exposure range used to separate
  strata within a dodged quantile layer (default `0.05`).

### Bundled example dataset: `erplots_data`

4,000 simulated subjects, one row each, generated by
`data-raw/erplots_data.R` (excluded from the build via `.Rbuildignore`),
documented in `R/data.R`. Columns:

- **Arms**: `dose_mg`/`dose_group` -- placebo + 4 active doses, ~800/arm.
- **Covariates**: `bodyweight_kg`, `age_years`, `sex`, `renal_function`.
- **Exposure** (three columns, from a simplified PK-flavored
  simulation): `auc_ss`, `cmax_ss`, `cmin_ss`.
- **Response** (five columns, each paired with the exposure column and
  modelling scenario it was built to exercise):
  - `biomarker_change` -- continuous, Emax on `auc_ss`.
  - `responder` -- binary, Emax on the logit scale on `cmax_ss`.
  - `adverse_event` -- binary, log-linear logistic regression on `auc_ss`.
  - `symptom_score` -- continuous, linear on `cmin_ss`.
  - `n_events` -- count, log-linear Poisson on `auc_ss`.
- **`study_id`** (`"Study 1"`-`"Study 4"`, 400/800/1200/1600 subjects) --
  administrative label, independent of dose/exposure/response, useful
  for subsetting to a smaller N that still spans the full dose range.

## Gotchas worth remembering

A handful of non-obvious implementation details that would bite a future
edit if forgotten:

- **Rotated-label `vjust`/`hjust` are swapped.** For `geom_label(angle =
  90)` text, `vjust` controls the *horizontal* offset relative to the
  anchor (0 = left, 1 = right) and `hjust` controls the offset *along*
  the now-vertical text. Used in the quantile `_vlines` builders'
  boundary labels (`R/er-plot-style-quantile.R`).
- **`position_jitterdodge()` has no `orientation` argument.** The group
  layer puts the discrete grouping variable on y and exposure on x (the
  opposite of what `position_jitterdodge()` assumes), so
  `er_style_group_boxjitter()`/`er_style_group_violinjitter()` compute
  their own dodge+jitter offsets via `.dodge_group_jitter()`
  (`R/er-plot-style-group.R`) rather than using it. Converting a `lvl`
  column to a factor before `as.numeric()` matters here -- calling
  `as.numeric()` on a plain character column coerces label text to `NA`.
- **A new `R/er-plot-style-*.R` file that calls `er_style_tag()` at its
  own top level needs `#' @include er-plot-style.R`.** `er_style_tag()`
  lives in `R/er-plot-style.R`; without the `@include` tag,
  `devtools::document()` won't guarantee it loads before a style file
  that calls it at load time (R sources `R/*.R` alphabetically by
  default, and `-` sorts before `.`).
- **`er_plot()`/`er_vpc()` call `dplyr::ungroup()` on `data` (and, for
  `er_vpc()`, `sim`) internally.** A grouped or rowwise input tibble
  would otherwise break `.by = `-based `summarise()` calls and silently
  corrupt `.compute_corner_distance()`'s output. Don't remove this.
- **`Suggests: emaxnls (>= 0.1.1.9000)` is load-bearing on r-universe.**
  CRAN's `emaxnls` release doesn't register the `er_predict`/
  `er_simulate`/`er_summary` S3 methods; the version floor forces
  r-universe's resolver to fall through to `Remotes: djnavarro/emaxnls`
  instead of the CRAN release. Revisit this floor once a CRAN release of
  emaxnls actually registers those methods.
- **No deprecation shims.** erplots is GitHub-only/pre-CRAN, so renames
  are done as straight renames across `R/`, `tests/`, and vignettes, not
  soft-deprecated.

## Structure

- `R/er-generics.R` -- the model interface: `er_predict()`,
  `er_simulate()`, `er_summary()` generics and their default methods.
- `R/er-plot-api.R` -- the `er_plot` object's core lifecycle only:
  `er_plot()`, `er_plot_build()`, and `print`/`plot` methods for the
  `er_plot` S3 class.
- `R/er-plot-add.R` -- the five pipeline verbs, `er_plot_add_model()`,
  `er_plot_add_summary()`, `er_plot_add_quantiles()`,
  `er_plot_add_data()`, `er_plot_add_groups()`.
- `R/er-plot-theme.R` -- `er_plot_theme()` and its `.check_theme_*()`
  validation helpers.
- `R/er-plot-layer.R` -- internal `.layer_*()` functions that assemble
  the configuration for each plot layer (this is where
  `er_predict()`/`er_simulate()`/`er_summary()` get called on the
  user-supplied model).
- `R/er-plot-build.R`, `R/er-plot-compose.R` -- internal
  plotting/layout machinery that turns layers into ggplot2 objects and
  composes them with patchwork.
- `R/er-plot-style-*.R` -- the pluggable `er_style_*()` partial builders
  (one file per component), plus `R/er-plot-style.R` (the
  shared-interface doc page, `?er_style`, which also holds
  `er_style_tag()` and its internal attribute readers/checker). See
  `?er_style` for the interface these builders share.
- `R/er-vpc-api.R`, `R/er-vpc-add.R`, `R/er-vpc-layer.R`,
  `R/er-vpc-build.R`, `R/er-vpc-style-observed.R`,
  `R/er-vpc-style-simulated.R` -- the VPC mini-grammar, mirroring
  `er_plot()`'s own file split.
- `R/utils-helpers.R` -- small internal helpers (including the
  binary-response-only `ci_clopper_pearson()`, `ci_t()`, `ci_poisson()`,
  `cut_quantile()`, `cut_exposure_quantile()`, the response-type
  detector `.detect_response_type()`) and the `globalVariables()`
  declarations for NSE.
- `R/data.R` -- roxygen documentation for the bundled `erplots_data`
  dataset (object lives in `data/erplots_data.rda`, generated by
  `data-raw/erplots_data.R`).

## Vignette structure

`vignettes/articles/` (pkgdown-only, not shipped -- see `.Rbuildignore`)
holds seven articles:

- `plot-binary.Rmd`, `plot-continuous.Rmd`, `plot-count.Rmd` -- worked
  examples of each layer, one per response type. Binary is the most
  detailed; the other two link back to it for response-type-agnostic
  content (model/summary/group layers).
- `design.Rmd` -- "The plotting grammar": singleton/additive layer
  distinction, the stratification color/facet precedence rule, the
  response-type dispatch table. Short pointer sections into `theming.Rmd`
  and `extending.Rmd`.
- `theming.Rmd` -- "Theming erplots": one section per `er_plot_theme()`
  argument group.
- `extending.Rmd` -- "Extending erplots: writing your own builder": what
  each `.layer_*()` function's `config` contains, a worked custom
  quantile builder, and a walkthrough of all five `er_style_tag()`
  arguments.
- `model-interface.Rmd` -- "Implementing the model interface", aimed at
  maintainers of *other* modelling packages (distinct audience from
  `extending.Rmd`): two self-contained toy model classes built from
  scratch (`toy_model`: single-coefficient GLM; `toy_emax`: multi-
  parameter `nls()` fit) demonstrating each generic.

Keep `design.Rmd` and `extending.Rmd` in sync when the grammar changes
in a way that affects builders (e.g. a new `er_style_tag()` argument, or
a change to what a `.layer_*()` function puts in `config`) -- that kind
of detail belongs in `extending.Rmd`, `design.Rmd` should only point to
it.

## Conventions

- Use the base R pipe (`|>`), not the magrittr pipe.
- Follow the existing tidyverse-style conventions (dplyr/tibble/rlang/
  ggplot2/patchwork) already used throughout.
- Naming families: pipeline layer-adders are `er_plot_add_*()` (verbs);
  partial builders are `er_style_*()` (noun phrases naming the visual
  idiom, with the layer name as the second token), selected via each
  layer-adder's `style` argument; confidence-interval helpers are
  `ci_*()` (noun phrases naming the statistical method); internal
  helpers are prefixed with `.`. "Builder" remains fine as ordinary
  English prose for "a function you write to build geoms" -- only the
  actual API symbols use the `style` vocabulary.
- Never call a model-fitting function from this package. If a plot
  component needs something from the model, add or extend a generic in
  `R/er-generics.R` instead of reaching into model internals.

## Development workflow

- Document with roxygen2 (`devtools::document()`); Markdown roxygen is
  enabled (`Roxygen: list(markdown = TRUE)`).
- Run tests with `devtools::test()`; full checks with `devtools::check()`.
  The package should check cleanly (0 errors/warnings/notes).
- Tests live in `tests/testthat/`. Shared test fixtures (including a
  test-only `er_test_toy_model()` `lm`/`glm` wrapper, used so most tests
  don't depend on `erglm` being installed) live in
  `tests/testthat/helper-data.R`/`helper-toy-model.R`. A handful of
  genuinely erglm-specific tests (the Poisson fixture, and a dedicated
  sync-check file comparing `er_test_toy_model()`'s output against a
  real `erglm` fit) remain gated with `skip_if_not_installed("erglm")`.
  Builder-specific tests live in
  `tests/testthat/test-er-plot-style-{model,summary,quantile,data,group}.R`.
- Vignettes/articles live in `vignettes/articles/` and are built for the
  pkgdown site, not shipped with the package (see `.Rbuildignore`).

## Keeping this documentation current

This file (`AGENTS.md`) should stay a lean, current-state reference --
if a change makes something above inaccurate, update it in place rather
than appending a note about the change.

Two companion files in `.agents/` (also excluded from the built package
via `.Rbuildignore`) carry the parts that don't belong here:

- **[.agents/HISTORY.md](.agents/HISTORY.md)** -- a condensed record of
  completed design decisions and their rationale (what was tried,
  rejected, and why), for context in future sessions. When you finish a
  piece of nontrivial design work, add an entry here rather than
  growing this file with "used to be X, now Y" narrative.
- **[.agents/PLAN.md](.agents/PLAN.md)** -- scoped-out future work and
  deferred/open items. When you finish something listed there, move its
  write-up into `HISTORY.md` and remove it from `PLAN.md` rather than
  marking it "done" in place.
