# erplots development plan

This document tracks scoped-out future development for erplots. It is
not a changelog. Items here are proposals to be reviewed before
implementation, not committed designs.

## Extend beyond binary responses to continuous (and count) responses

### Motivation

erplots is designed to be model-agnostic on the *fitted model* side (any
model implementing `er_predict()`/`er_simulate()`/`er_summary()` can be
plotted), but several of its data layers still hardcode an assumption
that the observed response is binary (0/1). Generalising these layers
would let erplots visualise, e.g., continuous-response exposure-response
models (dose-response/emax-style models) as well as logistic-regression
style binary-response models, without changing the model-side contract.

**This is no longer hypothetical.** `erglm` (the reference model package)
has generalised from binomial-only (`erlr`) to `erglm_model(formula, data,
family = ...)` supporting `binomial`/`poisson`/`gaussian`/`Gamma`, and its
example data (`erglm::erglm_data`) now ships genuine continuous
(`biomarker_change`) and count (`ae_count`, `ae_duration`) response
columns alongside the original binary ones (`ae1`/`ae2`). The
`er_predict()`/`er_simulate()`/`er_summary()` contract itself is honoured
correctly for all of these families -- that part of the integration needs
no work. But fitting `erglm_model(biomarker_change ~ aucss, erglm_data,
family = gaussian())` and passing it to `er_plot_show_quantiles()`
confirms the failure mode predicted below: it does not error, it silently
renders nonsense (error bars pinned to y = 0/1, computed as
`sum(response == 1)` / `sum(response == 0)` against a response that is
never exactly 0 or 1). `er_vpc_plot()` has the identical bug. Since users
can now trivially construct exactly this kind of model, generalising these
layers has moved from "nice to have" to the main blocker for saying
erplots supports "any erglm model".

### What already generalises for free

- The model curve/ribbon and spaghetti layers (`er_plot_show_model()`,
  `build_model_ribbonline()`, `build_model_spaghetti()`) only ever consume
  `er_predict()`/`er_simulate()` output (`fit_resp`/`ci_lower`/`ci_upper`,
  or simulated draws) -- there's no assumption about response type
  anywhere in that code path. No changes needed.
- The group panel (`er_plot_show_groups()`, boxplot/violin of exposure by
  group) only ever looks at the exposure variable, not the response. No
  changes needed.

### What needs to change

- **Quantile summary layer** (`er_plot_show_quantiles()`,
  `.part_quantile()`, `build_quantile_errorbar()`): computes, per
  exposure bin, `n1`/`n0` counts and a Clopper-Pearson CI for the
  response *rate*. For a continuous response this should instead compute
  a mean and a CI for the mean (e.g. t-based, or SE-based). Needs a
  response-type-dispatched summary step -- most likely a small internal
  generic (analogous to the existing `build_*` partial pattern) with
  `summarise_quantile.binary()` / `summarise_quantile.continuous()`
  implementations, selected either by explicit argument or by
  auto-detecting whether the response column is binary (all values in
  `{0, 1}`, or logical).
- **Data strip layer** (`er_plot_show_datastrip()`,
  `build_datastrip_jitter()`): the "responders above the line,
  non-responders below" two-panel jitter strip is inherently a
  binary-response visualisation. It doesn't have an obvious continuous
  analogue (a plain exposure-vs-response scatter would be the closest
  equivalent, but that's a different plot, not a variant of the same
  one). This is the layer most likely to need a genuinely different
  design for continuous responses, or to simply not be offered for
  continuous-response plots.
- **`er_vpc_plot()`**: currently compares observed vs. simulated response
  *rates* (with Clopper-Pearson CIs for the observed side, simulation
  quantiles for the simulated side). Generalises fairly directly to
  comparing means (with an appropriate CI for the observed mean) -- this
  is the easiest of the three to generalise.
- **Response-type detection/declaration**: needs a decision on whether
  response type is auto-detected (e.g., "binary" if the response column
  only takes values in `{0, 1}`/is logical, "continuous" otherwise) or
  explicitly declared (e.g. a `response_type` argument on `er_plot()`).
  Auto-detection is more convenient but has failure modes (e.g. a 0/1
  count variable that isn't actually a binary response); an explicit
  argument with a sensible auto-detected default is probably the safer
  choice.
- **Count (Poisson-like) responses**: not clearly binary or continuous.
  Treating them as "continuous" (mean + CI) is probably an adequate
  approximation for a first pass, but worth flagging as a known
  simplification rather than deciding definitively now.
- **`er_plot()`'s hardcoded response scale**: `er_plot()` sets
  `object$response$limits <- c(0, 1)` unconditionally (`R/er-plot-part.R`),
  and `.part_model()`'s p-value-label placement (`config$corner_distance`)
  computes distance to the four plot corners assuming `y`/`fit_resp`
  already lives on `[0, 1]` (it never rescales by `object$response$limits`
  or the data's own range). For a continuous response this silently
  places (or fails to place) the p-value label using the wrong scale. Not
  mentioned in the original version of this plan -- found while
  confirming the quantile-layer bug above. Needs to be part of the
  response-type work even though it sits in the "already generalises for
  free" model/ribbon code path, not the quantile/strip/VPC layers.

### Design decisions (reviewed)

The questions below were originally left open; each now has a working
recommendation so implementation isn't blocked, but all are still up for
debate if new information changes the calculus.

1. **Response-type detection.** Add an explicit `response_type` argument
   (probably on `er_plot()`, since it governs which builders are valid
   for the whole plot, not just one component), defaulting to `"auto"`.
   The auto-detection heuristic: values entirely in `{0, 1}` or a logical
   column → `"binary"`, otherwise → `"continuous"`. This mirrors the
   "automatic with an escape hatch" pattern already adopted on the erlr
   side (e.g. its SCM test-selection decision) -- convenient by default,
   overridable when the heuristic gets it wrong (e.g. a genuine 0/1
   count variable).

2. **Data strip for continuous responses.** [Superseded -- see "Continuous-
   response data strip" section below.] Originally: omit it for v1, as a
   documented limitation, rather than design a continuous-specific
   replacement now. The two-panel "responders above the line,
   non-responders below" design is structurally about a binary flag --
   there's no variant of *that* geometry for a continuous response, only
   a different plot entirely (e.g. a rug or raw scatter), and building
   that speculatively before anyone needs it isn't worth the design
   effort yet. Revisit if/when a concrete use case shows up. That revisit
   has now happened -- see below for the scoped design.

3. **Quantile-bin CI method for continuous responses.** Use a t-interval,
   not a bootstrap. This mirrors the convention erlr/erglm's own
   generalisation plan settled on for the analogous problem (families
   with estimated dispersion -- gaussian, Gamma -- use `Pr(>|t|)`-based
   inference, not a chi-squared/asymptotic-normal approximation), so the
   two packages stay consistent, and it's simpler to implement and
   explain than a bootstrap.

4. **Count responses.** [Fast-follow implemented.] v1 (Stage 4) treated
   them as "continuous" (mean ± CI via the same t-interval as (3)),
   documented as a known approximation, which remains the *default*
   behaviour under `response_type = "auto"` (a count response still
   auto-detects as `"continuous"`, since `.detect_response_type()` was
   deliberately left unchanged -- see below). The planned fast-follow --
   an exact Poisson CI path, analogous to how the binary path uses an
   exact Clopper-Pearson interval rather than a normal approximation --
   has now been added as a fourth, explicitly opt-in `response_type =
   "count"` value on `er_plot()`/`er_vpc_plot()`. It swaps the
   t-interval approximation for [poisson_interval()] (bin mean ± an
   exact Poisson/Garwood interval via `qgamma()`), which -- unlike the
   t-interval -- never produces a negative lower bound for a low-count
   bin. `"auto"` intentionally never resolves to `"count"` (only
   `"binary"`/`"continuous"`), so this is purely additive: existing
   auto-detected or explicitly-`"continuous"` count-response code is
   unaffected, and callers opt in to the exact interval only by naming
   `response_type = "count"` themselves.
   - Files: `R/utils-helpers.R` (`poisson_interval()`,
     `.abort_continuous_unsupported()` gaining a `response_type`
     parameter so its message names the actual offending type),
     `R/er-plot-part.R` (`.part_quantile()`'s new `"count"` branch),
     `R/er-vpc.R` (`er_vpc_plot()`'s new `"count"` branch in `smm_obs`;
     `smm_sim` needed no changes, as expected), `R/er-plot-api.R`
     (`er_plot()`'s `match.arg()` choices and
     `er_plot_show_datastrip()`'s guard, which now also fires -- with an
     accurate "does not support count responses" message -- for a
     declared `"count"` response, not just `"continuous"`),
     `R/utils-global.R` (`n_units` global). Docs: `?er_plot`,
     `?er_vpc_plot`, `vignettes/articles/plot.Rmd` all updated to
     describe and demonstrate the new value.
   - Tests: `poisson_interval()` unit tests in
     `test-utils-helpers.R` (matches `stats::poisson.test()`, brackets
     the rate, respects `conf_level`, sums a vector of counts, never
     negative at zero counts); `response_type = "count"` round-trips
     added to `test-er-plot-part.R` and `test-er-vpc.R` (asserting
     `ci_lower >= 0`, unlike the t-interval path); a new
     `er_plot_show_datastrip()` error-message test for a declared count
     response in `test-er-plot-api.R`.
   - Done when: `erglm_model(ae_count ~ aucss, erglm_data, family =
     poisson())` round-trips through `er_plot_show_quantiles()` and
     `er_vpc_plot()` with `response_type = "count"` producing a
     non-negative exact Poisson interval, without disturbing the
     existing `"auto"`/`"continuous"` count-response behaviour or any
     other response type. Met -- `devtools::check()` clean (0/0/0),
     270 tests passing (up from 248).

5. **Coordination with `erglm`.** Superseded -- erglm's continuous/count
   response support has landed (`gaussian`/`Gamma`/`poisson` families,
   `biomarker_change`/`ae_count`/`ae_duration` columns in `erglm_data`).
   The implementation roadmap below uses `erglm` test models directly
   rather than stubbing a local `glm()`/`lm()` fixture, since the real
   dependency is now available and exercising it directly (rather than a
   hand-rolled stand-in) is the better test of the actual integration.

### Implementation roadmap (staged)

Each stage below is intended to be a self-contained, mergeable unit of
work with its own tests; later stages depend on earlier ones. "Done"
criteria are meant to be concrete enough to check off, not aspirational.

**Stage 0 -- response-type plumbing (foundation for everything else) [done]**
- Add `response_type = c("auto", "binary", "continuous")` to `er_plot()`.
  Auto-detection: response entirely in `{0, 1}` or logical → `"binary"`,
  else `"continuous"`. Store the resolved type on `object$response$type`.
- Replace the hardcoded `object$response$limits <- c(0, 1)` in `er_plot()`
  with type-dependent logic: `c(0, 1)` for `"binary"`, `range(data[[response]],
  na.rm = TRUE)` for `"continuous"`.
- Fix `.part_model()`'s `corner_distance` computation to normalise `y`
  using `object$response$limits` instead of assuming `[0, 1]`.
- Files: `R/er-plot-part.R` (`er_plot()`, `.part_model()`). Tests:
  extend `test-er-plot-part.R` with a continuous-response `er_plot()`
  fixture (e.g. `erglm_model(biomarker_change ~ aucss, erglm_data, family
  = gaussian())`) and assert `response$type`/`response$limits` resolve
  correctly, and that corner-distance placement doesn't degenerate.
- Done when: `er_plot()` correctly classifies both response types (with
  override), and no other stage needs to touch response-limits logic
  again.

**Stage 1 -- quantile summary layer [done]**
- `.part_quantile()` now dispatches on `object$response$type`: the binary
  branch keeps the original `n1`/`n0` + `clopper_pearson()` logic
  unchanged; the continuous branch computes `mean()` and a `t_interval()`
  CI per bin. Rather than two parallel `.summarise_quantile_*()`
  implementations duplicating the label-placement math, the dispatch only
  covers computing `y_mid`/`y_mid_lbl`/`ci_lower`/`ci_upper`; the
  `y_lwr_lbl`/`y_upr_lbl`/`y_lbl` placement logic was generalised once
  (using `object$response$limits` for the margin/corner logic instead of
  a hardcoded `[0, 1]` assumption) and applied to both branches'
  `config$summary` afterwards.
- `t_interval()` helper alongside `clopper_pearson()` in
  `R/utils-helpers.R`, with unit tests in
  `tests/testthat/test-utils-helpers.R`.
- `object$style$format_number <- scales::label_number(accuracy = 0.01)`
  added alongside `format_percent`/`format_p` in `er_plot()`, used for
  the continuous path's `y_mid_lbl`.
- `build_quantile_errorbar()` needed no changes -- it already just
  consumes `x_mid`/`y_mid`/`ci_lower`/`ci_upper`/`y_mid_lbl`/`y_lbl` from
  `config$summary` generically.
- The `response_type == "continuous"` guard in `er_plot_show_quantiles()`
  was removed (the `.abort_continuous_unsupported()` call added in Stage
  5 is now only reachable from `er_plot_show_datastrip()` and
  `er_vpc_plot()`).
- Files: `R/er-plot-part.R` (`.part_quantile()`), `R/er-plot-api.R`
  (`er_plot()`'s `style$format_number`, `er_plot_show_quantiles()`'s
  guard removal), `R/utils-helpers.R` (`t_interval()`),
  `R/utils-global.R` (`response` global). Tests: continuous-response
  cases added to `test-er-plot-part.R`, `test-er-plot-partials-quantile.R`,
  and `test-er-plot-api.R` (the latter's old "errors clearly" test
  rewritten to assert support instead).
- Done when: `er_plot_show_quantiles()` on a gaussian/Gamma `erglm_model`
  produces bin means with sensible t-interval error bars on the
  response's own scale -- verified via `config$summary` in tests (CI
  brackets the mean; column names match the binary path minus
  `n1`/`n0`) and manually (values in a fresh R session for
  `biomarker_change ~ aucss`).

**Stage 2 -- `er_vpc_plot()` [done]**
- `er_vpc_plot()` now takes a `response_type = c("auto", "binary",
  "continuous")` argument (same heuristic as `er_plot()`, applied to the
  observed `response` column since there's no `er_plot` object to read
  a resolved type from). `smm_obs` dispatches on it: `"binary"` keeps the
  original `n1`/`n0` + `clopper_pearson()` logic; `"continuous"` computes
  `mean()` + `t_interval()`, reusing the Stage 1 helper directly (no new
  CI code needed). `smm_sim`'s simulation-quantile CI needed no changes,
  as expected -- it's just `mean()`/`quantile()` over simulated draws.
- The `y_mid_lbl` formatter is also dispatched (`scales::label_percent()`
  vs. `scales::label_number()`), matching `.part_quantile()`'s
  `format_percent`/`format_number` split, though note `er_vpc_plot()`'s
  `y_mid_lbl` column isn't actually plotted anywhere in the current
  ggplot construction (pre-existing; not touched here).
- The old unconditional `.abort_continuous_unsupported("er_vpc_plot")`
  guard is removed now that continuous responses are supported.
- Files: `R/er-vpc.R`. Tests: extended `test-er-vpc.R` with a continuous
  case (`er_test_mod_gaussian`/`erglm_vpc_sim()`, asserting CIs bracket
  their means) and a `response_type` override case (forcing a binary 0/1
  column through the continuous path). Verified visually too: observed
  vs. simulated means/CIs for `biomarker_change ~ aucss` overlap sensibly
  across quantile bins.
- Done when: `er_vpc_plot()` on continuous observed/simulated data
  produces a sensible mean-based VPC without erroring or silently
  mis-plotting. Met.

**Stage 3 -- data strip layer [done]**
- The loud-failure guard for `object$response$type == "continuous"` on
  `er_plot_show_datastrip()` already existed from Stage 5 (it was added
  there as a stopgap shared with the quantile/VPC layers before any of
  Stages 1-4 landed). What Stage 3 actually needed, now that Stages 1-2
  have generalised the *other* two callers of
  `.abort_continuous_unsupported()`, was to stop the datastrip's error
  message implying a fix is coming: it previously said "See PLAN.md for
  the planned generalisation to continuous/count responses", which is no
  longer accurate for this specific component (per design decision (2),
  no continuous variant is planned for the data strip, unlike quantiles/
  VPC which are now done).
- `.abort_continuous_unsupported()` gained a `planned` argument
  (`TRUE`/default for the "stopgap, fix coming" framing; `FALSE` for the
  "settled design decision, no fix planned" framing).
  `er_plot_show_datastrip()` is now the helper's only caller, and passes
  `planned = FALSE`.
- Updated the stale `?er_plot` `@details` block, which described both
  `er_plot_show_quantiles()` and `er_plot_show_datastrip()` as "currently
  only support[ing] a binary (0/1) response" -- no longer true for the
  former.
- Files: `R/utils-helpers.R` (`.abort_continuous_unsupported()`),
  `R/er-plot-api.R` (`er_plot_show_datastrip()`, `?er_plot` docs). Tests:
  `test-er-plot-api.R`'s existing "errors clearly" test extended to
  assert the specific "no continuous-response variant ... is currently
  planned" wording, not just that *some* error is raised.
- Done when: calling `er_plot_show_datastrip()` on a continuous-response
  `er_plot` errors with a message that accurately reflects this is a
  permanent limitation, not a stopgap. Met.
- Revisit a genuine continuous-response strip/rug design later, as a
  separate, independently-scoped item, once there's a concrete use case.

**Stage 4 -- count (Poisson) responses [done]**
- Routes through the `"continuous"` path from Stages 1-2 (mean +
  t-interval), as agreed in design decision (4), with no new dispatch
  code -- confirmed by round-tripping an actual
  `erglm_model(ae_count ~ aucss, er_test_data, family = poisson())`
  model through both `er_plot_show_quantiles()` and `er_vpc_plot()`.
  `.detect_response_type()` correctly classifies `ae_count` as
  `"continuous"` (counts aren't confined to `{0, 1}`); bin means track
  the fitted Poisson curve, and observed/simulated VPC summaries overlap
  sensibly across quantile bins. Verified visually as well as via test.
- Confirmed downside of the approximation, exactly as anticipated by
  design decision (4): the symmetric t-interval can produce a negative
  lower bound for low-count bins (e.g. Placebo), which isn't sensible
  for a non-negative count. Not a new bug -- this is the rationale
  behind the noted fast-follow (an exact Poisson CI path), not something
  to fix in this pass. [Fast-follow since implemented: see design
  decision (4) above -- `response_type = "count"` now gives an exact
  Poisson interval instead of the t-interval approximation.]
- The approximation is documented: `?er_plot`'s `response_type` and
  `@details`, and `?er_vpc_plot`'s `response_type`, both explain that
  count responses auto-detect as `"continuous"` and are summarised the
  same way as any other continuous response, with a forward pointer to
  this design decision.
- Files: no `R/` changes needed. Tests: added a count-response round-trip
  test to `test-er-plot-part.R` (`.part_quantile()` via
  `er_plot_show_quantiles()`) and `test-er-vpc.R` (`er_vpc_plot()`),
  both using a `poisson()` `erglm_model(ae_count ~ aucss, ...)` fixture.
- Done when: an `erglm_model(ae_count ~ aucss, erglm_data, family =
  poisson())` model round-trips through Stages 1-3 without special-casing.
  Met.

**Stage 5 -- guard rails for the interim [done]**
- Because Stages 1-4 are sequential work, land a defensive check *first*
  (can piggyback on Stage 0) so that, until each layer is generalised,
  `er_plot_show_quantiles()`/`er_vpc_plot()`/`er_plot_show_datastrip()`
  raise an explicit "continuous responses aren't yet supported by this
  component" error for `response_type == "continuous"` rather than the
  current silent mis-plot. Remove each guard as its stage lands.
- Done when: no code path in the package can silently produce a
  misleading plot for a non-binary response; every unsupported
  combination fails loudly with an actionable message.
- Implemented via a shared `.abort_continuous_unsupported()` helper
  (`R/utils-helpers.R`), called from `er_plot_show_quantiles()`,
  `er_plot_show_datastrip()` (using `object$response$type` from Stage 0),
  and `er_vpc_plot()` (which has no `er_plot` object to read from, so it
  runs `.detect_response_type()` directly on the observed response
  column). `er_plot_show_model()` and `er_plot_show_groups()` are
  unaffected -- they already generalise for free (see above).

**Stage 6 -- tests, vignettes, docs [done]**
- `tests/testthat/helper-data.R` now has both continuous
  (`er_test_mod_gaussian`) and count (`er_test_mod_poisson`) fixtures
  alongside the existing binary ones, guarded the same way
  (`requireNamespace("erglm")`); added while closing out Stage 4.
- `vignettes/articles/plot.Rmd` gained a "Continuous responses" section
  (gaussian model + `er_plot_show_quantiles()` + `er_vpc_plot()`) and the
  "Strip component" section now demonstrates the datastrip's error on a
  continuous-response `er_plot`, rather than being an empty heading. The
  stale "this empirical-summary layer currently assumes a binary
  response" aside on the quantile `conf_level` example (no longer true
  since Stage 1) was also corrected.
- `?er_plot`'s `@examples` gained a third example fitting a
  `gaussian()` `erglm_model()` and running it through
  `er_plot_show_quantiles()`, alongside the pre-existing binary examples.
  `?er_plot`'s `@param response_type`/`@details` already documented the
  response-type behaviour in full (added incrementally in Stages 0-5),
  so no further changes were needed there. `?er_model_interface` is
  correctly response-type-agnostic (it documents the model-side
  contract, not response handling) and needs no changes. `README.Rmd`
  was left binary-only by design -- it's the package's terse
  front-door example, and the fuller continuous-response walkthrough now
  lives in the vignette instead of duplicating it there.
- Done when: `devtools::check()` is clean and the continuous-response path
  has test coverage comparable to the binary path. Met.

### Suggested step ordering

Stages 0 and 5 first (foundation + guard rails, low risk, unblock safe
iteration), then 1 → 2 → 3 → 4 in order, then 6 throughout/at the end as
each stage's tests/docs land alongside it rather than as a single final
pass. Stages 0-6 are now all done, and design decision (4)'s exact-
Poisson-CI fast-follow has also landed -- the response-type
generalisation work originally scoped here (quantiles, VPC, a
documented/guarded omission for the data strip, plus the count-response
fast-follow) is complete. `vignettes/articles/plot.Rmd` was rendered
end-to-end (`rmarkdown::render()`, after `devtools::install()`ing the
updated source) and its new/changed sections (continuous quantiles/VPC,
default vs. `response_type = "count"` quantiles, the datastrip error
demo) were spot-checked visually; all render and look correct.

An initial rendering surfaced a minor clarity gap -- `erglm_data`'s
`ae_count ~ aucss` example never happens to produce a negative
t-interval lower bound, so the default-vs-`response_type = "count"`
comparison plots looked nearly identical -- which was resolved by
adding a small synthetic low-count dataset (placebo arm: 2 events among
20 subjects, `set.seed(84)`) to the "Continuous responses" section
specifically for this comparison. Zoomed in on the placebo arm
(`ggplot2::coord_cartesian(ylim = c(-0.5, 1.5), xlim = c(-50, 800))`),
the default (t-interval) path's error bar visibly dips below zero,
while the `response_type = "count"` (exact Poisson) path's stays
non-negative -- verified visually. Remaining open work is limited to
the stratified-label-overlap item below (now fixed -- see "Other known
issues / follow-ups") and the continuous-response data strip scoped
below.

## Continuous-response data strip (revisiting design decision (2))

### Motivation

Design decision (2) deliberately omitted a continuous-response variant
of `er_plot_show_datastrip()`, on the grounds that the binary "responders
above the line, non-responders below" geometry has no direct analogue
for a continuous response, and that inventing one speculatively wasn't
worth the design effort without a concrete need. That decision explicitly
left the door open to revisiting it "if/when a concrete use case shows
up" -- this section is that revisit. It replaces the binary partition
with a different encoding (below) rather than declining to have a
continuous variant at all.

### Chosen design: single color-encoded strip

One panel (not two), points jittered along `y = 0` exactly as today
(`height = 0.1`, `width = 0`), but with `color` mapped continuously to
the response value instead of the panel being pre-split by `response ==
1`/`== 0`. This is the closest continuous analogue to the existing
jitter grammar -- same axis, same jitter mechanics, same compact strip
footprint -- just without the binary partition, which never had a
continuous equivalent to begin with. Applies to both `"continuous"` and
`"count"` response types (the same "route count through the continuous
path" convention used throughout the rest of this plan).

Rejected alternatives (from the three sketched when scoping this):
- **Threshold-split two-panel** (median or user-supplied cutoff instead
  of `== 1`/`== 0`): rejected because the threshold is an arbitrary,
  user-visible choice for *every* continuous response, and silently
  picking one (e.g. the median) reintroduces exactly the kind of
  under-motivated design decision the original omission was trying to
  avoid.
- **Quantile-binned rug** (one strip per response tertile, reusing
  `cut_quantile()`): rejected as a first pass because it uses more
  vertical space than the single-panel option for comparable
  information content, though it remains a reasonable fallback if the
  single-panel color encoding turns out to be hard to read in practice.

### Complication: composition machinery assumes two named panels

The datastrip's plot-building/composition code
(`.build_strip_plot()` in `R/er-plot-build.R`;
`.polish_margins()`/`.polish_arrangement()`/`.polish_labels()` in
`R/er-plot-compose.R`) hardcodes exactly two named slots,
`object$plot$strip$upper`/`$lower`, keyed off `config$panel %in%
c("upper", "lower", "both")`. Supporting stratification for the new
single-panel design needs more than one panel again, but keyed by
*stratum*, not by response partition -- there's no way to also encode
strata via `color` without dual-encoding the same aesthetic channel with
two different variables (the continuous response and the discrete
strata), so stratification has to become vertical faceting: one
mini-panel per stratum level, each internally colored by the continuous
response.

This means the four composition helpers above need to generalize from
"exactly zero, one, or two fixed slots named `upper`/`lower`" to "a
named list of zero or more panels", with `object$plot$strip` becoming a
named list (e.g. `list(Male = <ggplot>, Female = <ggplot>)` when
stratified-continuous, `list(upper = <ggplot>, lower = <ggplot>)`
unchanged for binary) rather than a struct with fixed `$upper`/`$lower`
fields. This is a shared refactor, not something specific to the
continuous case -- the binary path needs to keep working, with full
regression coverage, through the same generalized code path.

### Complication: the strip's color legend isn't a strata legend

`.polish_labels()` currently assumes that whenever a part's `colour`
aesthetic is present, it means strata, and labels it
`object$strata$label` unconditionally; `.polish_legends()` assumes any
`stratify == TRUE` part's legend is a strata legend to dedupe across
panels. Neither assumption holds for the new strip: its `colour`
aesthetic is the *response* value, and its legend is a continuous
colorbar for `object$response$label`, present regardless of whether
`stratify` is `TRUE` (it's not conditional on strata at all -- it's
mapped in every panel, stratified or not). Both helpers need a way to
distinguish "this part's color means strata" from "this part's color
means the response value" -- e.g. a `config$color_role <- "response"`
(vs. implicitly `"strata"` elsewhere) tag set by whichever builder
constructs the part, consulted by `.polish_labels()`/`.polish_legends()`
instead of inferring meaning from `stratify` alone.

### API changes

Note: the rename described under "Naming decision" above (`er_plot_show_data()`,
`.part_data()`, `build_data_jitter()`, `object$part/plot$data`) has already
landed, ahead of this section's original sequencing. The items below use
the current (post-rename) names throughout.

- `er_plot_show_data()`'s dispatch to `build_data_jitter()` vs.
  a new `build_data_color()` should be automatic, keyed off
  `object$response$type`, mirroring how `.part_quantile()` dispatches
  invisibly rather than asking the caller to name a style. No new
  user-facing `style` value.
- The `panel` argument (`"upper"`/`"lower"`/`"both"`) is binary-specific
  and meaningless for the single continuous panel. Recommend: error if a
  continuous/count-response call passes `panel != "both"` explicitly
  (actionable message, consistent with this package's "fail loudly
  rather than silently do something different than asked" convention
  elsewhere), and treat `panel = "both"` (the default) as "the one
  panel" for continuous/count.
- The existing `.abort_continuous_unsupported(planned = FALSE)` call in
  `er_plot_show_data()` is removed for `"continuous"`/`"count"`
  response types (mirroring how the quantile/VPC guards were removed
  once those were generalized). Check whether `er_plot_show_data()`
  was `.abort_continuous_unsupported()`'s only remaining caller (per
  Stage 3's note) -- if so, the helper (and its now-unused `planned`
  parameter) likely become dead code worth removing rather than leaving
  unreferenced.

### Open questions (not yet decided -- flagging rather than assuming)

- **Color scale.** This package's convention so far (quantile/model/
  group builders) is to map `color`/`fill` and let ggplot2's default
  discrete hue scale apply, with no explicit `scale_color_*()` call
  anywhere. A *continuous* colorbar under the default
  `scale_colour_gradient()` (dark-blue-on-white gradient) may read as
  lower-contrast/less legible than a discrete hue scale would, which is
  a reason to consider breaking convention here specifically (e.g.
  `scale_colour_viridis_c()`) -- but that is a real deviation from house
  style and worth deciding deliberately rather than defaulting into.
- **Legibility at scale.** A single continuous color gradient over a
  jittered 1-D strip is a fairly weak channel for reading exact response
  values (color is good for relative/qualitative reading, poor for
  precise reading) -- this is an inherent tradeoff of the chosen design,
  not a bug, but worth calling out: it will read more as "where are the
  higher/lower responses concentrated along exposure" than "what is
  subject X's response", which may or may not match what users actually
  want from this component. Worth a sanity check against a real
  continuous dataset before committing.

### Suggested staging

- **Stage 7a -- composition refactor (no behavior change). [done]**
  Generalized `.build_strip_plot()`/`.polish_margins()`/
  `.polish_arrangement()`/`.polish_labels()` from fixed `$upper`/`$lower`
  slots to a named list of panels.
  - `.part_strip()`'s config no longer has `$upper`/`$lower` booleans;
    it now has `config$panels` (a character vector of panel names to
    build, in build order -- `c("upper", "lower")`, `c("upper")`, or
    `c("lower")`, per the `panel` argument) and
    `config$panel_position` (a named vector mapping each panel name to
    `"above"`/`"below"`, i.e. its vertical position relative to the base
    plot -- currently always `upper = "above"`, `lower = "below"`, but
    looked up by name rather than hardcoded, so a future panel name
    doesn't require new branches).
  - `.build_strip_plot()` (`R/er-plot-build.R`) now loops over
    `config$panels` once instead of two copy-pasted `if (config$upper)`/
    `if (config$lower)` blocks, building `strip_plots[[panel_name]]` for
    each. Returns the same `list(upper = <ggplot>, lower = <ggplot>)`
    shape as before for the binary case.
  - `.polish_margins()`/`.polish_labels()` (`R/er-plot-compose.R`) now
    iterate over `names(p$strip)` generically -- margins consult
    `panel_position` to decide which side's margin to zero, instead of
    two hardcoded `if (!is.null(p$strip$upper))`/`if (!is.null(p$strip$lower))`
    blocks; labels apply the same `x`/`y`/legend logic to every panel in
    the loop rather than duplicating it per fixed slot.
  - `.polish_arrangement()` splits `names(object$plot$strip)` into
    `above_panels`/`below_panels` via `panel_position`, placing all
    "above" panels before the base plot and all "below" panels after it
    (in place of the previous `strip$upper` block, then base, then
    `strip$lower` block). Panel naming (`"strip_upper"`/`"strip_lower"`)
    and sizing (`height$strip / 2`, unconditionally -- an existing quirk
    where a single panel still only gets half the strip height budget,
    deliberately preserved rather than fixed here, since this stage is
    scoped as no-behavior-change) are untouched for the binary case.
  - Files: `R/er-plot-part.R` (`.part_strip()`), `R/er-plot-build.R`
    (`.build_strip_plot()`), `R/er-plot-compose.R` (`.polish_margins()`,
    `.polish_labels()`, `.polish_arrangement()`). Tests:
    `test-er-plot-part.R`'s `.part_strip()` structure test updated for
    the new config field names (`panels`/`panel_position` in place of
    `lower`/`upper`), asserting the resolved panel list/position mapping
    for both the unstratified and stratified fixtures.
  - Done when: `devtools::check()` is clean and the existing binary
    strip regression tests (unstratified and stratified, including
    `test-er-plot-api.R`'s `strip_upper`/`strip_lower` build/arrangement
    assertions) pass unchanged. Met -- `devtools::check()` clean (0/0/0),
    289 tests passing (up from 285); a stratified binary datastrip plot
    (`sex`-stratified `ae1 ~ aucss`) was also re-rendered end-to-end and
    visually matches the pre-refactor design (flush margins between base
    and both strip panels, per-stratum color/legend intact).
- **Stage 7b -- `build_data_color()` + dispatch.** New builder,
  `.part_data()` dispatch on `object$response$type`, the `color_role`
  tag and its consumption in `.polish_labels()`/`.polish_legends()`, the
  `panel` argument guard for continuous/count, guard-rail removal in
  `er_plot_show_data()`. Tests: unstratified continuous/count
  round-trip, stratified continuous/count round-trip (N panels, one per
  stratum), response-label-not-strata-label assertion, `panel != "both"`
  error assertion.
- **Stage 7c -- docs/vignette.** `?er_plot_show_data` update (already on
  its own Rd topic as of the naming-decision rename above, so this is
  content, not structure); replace `vignettes/articles/plot.Rmd`'s
  current continuous-response error demo (added in Stage 6) with a real
  example; update this section's status and design decision (2) once
  shipped.

## Other known issues / follow-ups

### Stratified quantile labels can visually overlap [fixed]

`build_quantile_errorbar()`'s `y_mid_lbl` text geom used to place each
stratum's label at its own bin's `x_mid`/`y_lbl`, with no dodging between
strata. When two strata's `x_mid` values for the same exposure bin landed
close together (the common case, since bins are quantile cutpoints of the
same exposure variable), their text labels visually collided -- observed
when sanity-checking the Stage 1 continuous-response quantile layer on a
`sex`-stratified `biomarker_change ~ aucss` plot (Q2/Q3 labels for Male
vs. Female overlapped). Not specific to continuous responses -- the same
geometry issue existed for stratified binary quantile plots, it was just
easier to notice with plain numeric labels. The underlying
`config$summary` values (means/rates, CIs) were unaffected; this was
purely a `geom_text()` (and, once dodged, `geom_point()`/
`geom_errorbar()`) placement issue.

Fixed via the first of the sketched options: a new
`.dodge_quantile_strata()` helper (`R/utils-helpers.R`) computes a small,
symmetric-around-`x_mid` per-stratum horizontal offset -- sized as a
fixed fraction (0.05) of the exposure range, so it scales with both the
data's exposure scale and the number of strata -- and adds it as an
`x_dodge` column. `build_quantile_errorbar()`'s stratified branch now
plots points/error bars/labels at `x_dodge` instead of `x_mid` (and gives
the label `geom_text()` a `color` aesthetic matching the point/errorbar,
which it previously lacked, so a dodged label stays visually
attributable to its stratum). The unstratified branch and
`.part_quantile()`'s `config$summary` (and its existing column-name
tests) are untouched -- dodging is computed only at build time, not
stored on the summary object.
- Files: `R/utils-helpers.R` (`.dodge_quantile_strata()`),
  `R/er-plot-partials-quantile.R` (`build_quantile_errorbar()`'s
  stratified branch), `R/utils-global.R` (`x_dodge` global). Tests:
  `.dodge_quantile_strata()` unit tests in `test-utils-helpers.R`
  (symmetric offsets, scales with exposure range, handles non-factor/
  single-stratum input); `build_quantile_errorbar()` dodge behaviour in
  `test-er-plot-partials-quantile.R` (distinct `x_dodge` per stratum
  within a bin, offsets symmetric around `x_mid`, no `x_dodge` column at
  all when unstratified).
- Done when: a `sex`-stratified quantile plot (binary or continuous
  response) no longer has visually-colliding stratum labels, verified via
  test (distinct `x_dodge` positions per stratum per bin) and visually
  (`biomarker_change ~ aucss` by `sex`: points/bars/labels now sit at
  distinct, color-matched x positions per bin rather than stacked at a
  shared `x_mid`). Met -- `devtools::check()` clean (0/0/0), 285 tests
  passing (up from 270).

## Mini-language architecture review

### Motivation

The response-type generalisation above (Stages 0-6, done; Stage 7a-7c,
scoped) forced two things into the open that the mini-language's design
had never made explicit, because nothing before Stage 7 ever needed to
notice them:

1. The four layers don't all behave the same way when their
   `er_plot_show_*()` function is called more than once on the same
   `er_plot` object -- `er_plot_show_groups()` accumulates, the other
   three overwrite. This was never documented as a deliberate property.
2. "Stratification means color/fill, uniformly, with a shared legend" was
   an implicit assumption baked into `.polish_labels()`/`.polish_legends()`,
   and it breaks the moment a layer needs color for something other than
   strata -- exactly the situation the continuous-response data layer
   (Stage 7) is in.

Rather than patch these ad hoc inside Stage 7's implementation, this
section names them explicitly, proposes documentation (not code) to
close the gaps, and settles one terminology question (the "data strip"
name) that Stage 7 would otherwise have to invent mid-implementation.
This is a planning-only pass: nothing in this section changes code,
docs, or names by itself -- it scopes work for later stages, some of
which piggyback on Stage 7's own implementation PR.

**The grammar this section describes is now also written up for users**,
in `vignettes/articles/design.Rmd` (added as Stage D, below) -- the
layer table, the singleton/additive distinction, the stratification
color/facet precedence rule, and the response-type dispatch table all
live there in user-facing form. That article's own closing section says
explicitly that it must be updated in the same change as any future
design decision that alters the grammar (a rename, a change to which
layers are singleton/additive, a new response-type dispatch, etc.) --
treat this PLAN.md section and that vignette as a pair: whenever this
section's proposals are implemented or revised, check
`vignettes/articles/design.Rmd` for staleness at the same time, not as a
follow-up.

### Naming decision: "data strip" -> "data layer" [rename done; `build_data_color()` still pending]

The layer formerly called the "data strip"
(`er_plot_show_datastrip()`, `.part_strip()`, `build_datastrip_jitter()`,
`object$part$strip`/`object$plot$strip`) is now called the **data
layer** in code and docs: `er_plot_show_data()`,
`.part_data()`, `build_data_jitter()` (binary). This matches the
existing `model`/`quantile`/`group` naming pattern -- all four layers
named for *what they show*, not how they're drawn -- and "strip" stopped
being an accurate name once a continuous variant was on the roadmap (a
single color-coded panel, not two stacked jitter panels). `build_data_color()`
(the continuous/count builder) is still Stage 7b's job -- only the
rename itself landed here.

The rename originally was scoped to land as part of Stage 7's
implementation PR rather than as a separate pass, to avoid two
full-package diffs for what's really one unit of work -- see the
checklist below, all now applied as a standalone pass ahead of Stage 7b
(a deliberate deviation from that sequencing, made explicitly rather
than assumed). Symbols/places that changed:

- `er_plot_show_datastrip()` -> `er_plot_show_data()` [done]
- `.part_strip()` -> `.part_data()` [done]
- `build_datastrip_jitter()` -> `build_data_jitter()` [done]; new
  `build_data_color()` still pending, per Stage 7b
- `object$part$strip`, `object$plot$strip` -> `object$part$data`,
  `object$plot$data` [done]
- `config$panel` and its `"upper"`/`"lower"`/`"both"` values (binary-only;
  unchanged by the rename; Stage 7's API-changes section still covers the
  guard for continuous/count, not yet added)
- `object$style$height$strip` -> `object$style$height$data` [done]
- `print.er_plot()`'s `"strip"` branch and its printed label -> now
  `"data"`/`"data:"` [done]
- `.abort_continuous_unsupported()`'s call site (now
  `er_plot_show_data()`) [done]
- Roxygen `@rdname`/`@name` anchors referencing the strip functions
  [done]; `R/er-plot-partials-datastrip.R` renamed to
  `R/er-plot-partials-data.R` [done]
- `vignettes/articles/plot.Rmd`'s "Strip component" section renamed to
  "Data component", prose updated [done]; `vignettes/articles/design.Rmd`
  updated to match (layer table, singleton-status prose, stratification/
  response-type sections) [done]
- `README.Rmd`/`README.md`, `_pkgdown.yml`'s reference index [done]
- This file's own prose (this section) [done]

Also done as part of this pass, ahead of the Stage A' item below since
it turned out to already be satisfied: the `?er_plot` Rd-page split
(`er_plot()`, `er_plot_style()`, `er_plot_show_model()`,
`er_plot_show_quantiles()`, `er_plot_show_data()`, `er_plot_show_groups()`,
`er_plot_build()` each already had, or now have, their own dedicated Rd
topic/`@rdname` rather than sharing `@rdname er_plot`) -- see Stage A'
below for the up-to-date status.

Files touched: `R/er-plot-api.R`, `R/er-plot-part.R`,
`R/er-plot-build.R`, `R/er-plot-compose.R`, `R/utils-helpers.R`,
`R/er-plot-partials.R`, `R/er-plot-partials-data.R` (renamed from
`R/er-plot-partials-datastrip.R`), `NAMESPACE`/`man/*.Rd` (regenerated
via `devtools::document()`), `tests/testthat/test-er-plot-part.R`,
`tests/testthat/test-er-plot-api.R`,
`tests/testthat/test-er-plot-partials-data.R` (renamed from
`test-er-plot-partials-datastrip.R`), `vignettes/articles/plot.Rmd`,
`vignettes/articles/design.Rmd`, `README.Rmd`/`README.md`,
`_pkgdown.yml`. Done when: `devtools::check()` is clean and every test/
vignette/example referring to the old names is updated rather than
merely still passing by coincidence. Met -- `devtools::check()` clean
(0/0/0), 289 tests passing (unchanged from Stage 7a, since this was a
pure rename with no behavior change); both `vignettes/articles/plot.Rmd`
and `vignettes/articles/design.Rmd` re-rendered end-to-end after
`devtools::install()`ing the renamed source, and a stratified binary
data-layer plot was re-rendered and visually spot-checked to confirm the
rename didn't alter output.

### Layer composition semantics: singleton vs. additive

Documenting current (undocumented) behavior: `er_plot_show_model()`,
`er_plot_show_quantiles()`, and `er_plot_show_data()`
(renamed from `er_plot_show_datastrip()` -- see "Naming decision" above)
are **singleton** -- calling one twice
overwrites `object$part$<x>`, silently discarding the first call's
result. `er_plot_show_groups()` is **additive** -- each call's `group_by`
accumulates into its own named entry, so multiple calls produce multiple
side-by-side group panels rather than one call replacing another.

Proposed reading: this is intentional, not accidental, and reflects a
reasonable mental model -- there is only one "the model" and one "the
quantile summary" per plot, but many legitimate ways to slice the
exposure distribution by different grouping variables. Recommend
documenting the distinction explicitly (in `?er_plot`'s `@details`,
`?er_partial`, and the new vignette material below) rather than changing
any behavior. This is flagged as an open question below rather than
assumed, since it's a real design commitment worth confirming rather
than a docs-only formality.

One related loose end, resolved as future-only rather than left open:
because `er_plot_show_model()` is singleton, overlaying two model curves
(e.g. comparing a candidate model against a null/reference model, or an
Emax fit against a linear one) isn't possible today. Of the three
singleton layers, this is the one with a genuine plausible use case --
unlike quantile or data, where calling the same layer twice on the same
response variable has no obvious distinct meaning (overlaid bin-counts
or panel subsets would just be visually ambiguous, not informative).
Recommendation: don't change anything now -- no concrete request exists
yet, and making `model` additive is real work, comparable to what Stage
7 is already doing to make the data layer's strata facets legend-aware
(the model layer would need an analogous per-model legend/label story).
Mirrors design decision (2)'s original stance on the data strip: leave
the door open, revisit only if/when a concrete need shows up. Quantile
and data layers are not expected to ever need this -- only `model` is
flagged as a plausible future additive layer.

### Stratification vs. the data layer's color channel

Stratification's contract -- never written down explicitly before now --
is "encode via color/fill, uniformly across layers, with one shared,
deduplicated legend." The continuous-response data layer (Stage 7) needs
color for the response value itself, so stratification for that one
layer has to become vertical faceting (one mini-panel per stratum level)
instead, per the "Complication: composition machinery assumes two named
panels" and "Complication: the strip's color legend isn't a strata
legend" sections above.

That mechanical fix is already fully scoped in Stage 7a/7b (the
`object$plot$strip` panel-list generalisation, the `config$color_role`
tag, and `.polish_labels()`/`.polish_legends()` dispatching on it). What
was missing from that write-up is the one-sentence general framing:
**a layer's own encoding takes precedence; stratification adapts to
whatever channel is left, defaulting to color/fill and falling back to
per-stratum facets when color is already spoken for.** Recording that
rule once here (and echoing it into Stage 7's docs when it lands) makes
the data layer's facet fallback read as an instance of a general design
rule rather than an ad hoc fix invented for one layer.

Per explicit scope decision, this section does **not** extend that rule
to a general redesign of stratification (multiple stratifying variables,
continuous strata, or applying the color/facet fallback to other
layers). Those remain out of scope until a concrete need for them shows
up, tracked separately if and when that happens.

### Documentation sweep

Two gaps, proposed (not yet written):

- **No conceptual/grammar documentation exists.** [done] `?er_plot`
  documents parameters; `?er_partial` documents the builder contract;
  `vignettes/articles/plot.Rmd` is a sequence of worked examples. None of
  these documented the mini-language's grammar as a grammar: what a
  "layer" is, singleton-vs-additive semantics, how stratification
  composes with each layer (including the data layer's facet exception
  above), and how `response_type` changes each layer's summary
  statistic. Added `vignettes/articles/design.Rmd` (linked from
  `_pkgdown.yml`'s articles list, alongside `plot.Rmd`), covering (a)
  the four layers and what each shows (with a `mermaid` diagram, data ->
  layers -> build -> compose), (b) the singleton/additive distinction
  with runnable examples, (c) how `stratify_by` composes with each
  layer including the color/facet precedence rule, (d) how
  `response_type` dispatches within each layer. Cross-links each layer's
  own Rd topic (Stage A') rather than duplicating their parameter-level
  detail, and links back to `plot.Rmd` for fuller worked examples. Its
  closing section instructs future changes to update it in the same
  change as any grammar-altering decision -- see this section's
  cross-reference note above.
- **`?er_plot`'s `@rdname er_plot` groups too much. [done]** `er_plot()`,
  `er_plot_style()`, `er_plot_show_model()`, `er_plot_show_quantiles()`,
  `er_plot_show_data()` (renamed from `er_plot_show_datastrip()`),
  `er_plot_show_groups()`, and `er_plot_build()` used to share one Rd
  page and one shared `@param` list, even though not every parameter
  applies to every function (`panel` only means something for the data
  layer; `bins` means different things for quantile vs. group bins).
  Verified while starting Stage 7b prep: the split into per-layer Rd
  topics (`?er_plot_show_model`, `?er_plot_show_quantiles`, etc., each
  documenting its own singleton/additive status, response-type
  dispatch, and layer-specific arguments) had, in fact, already
  happened -- `@rdname er_plot` now appears exactly once in
  `R/er-plot-api.R` (attached only to `er_plot()` itself), and every
  other layer function already had its own full roxygen block. Combined
  with this pass's rename, there is now a dedicated `?er_plot_show_data`
  topic (not `?er_plot_show_datastrip`) ready for Stage 7b to write its
  `color_role`/`build_data_color()` documentation straight into. Trade-
  off noted for completeness even though it predates this pass: the
  split changed `@rdname er_plot` anchors that users/scripts may
  reference by topic name.

### Staged roadmap

- **Stage A -- naming decision + rename scoping (docs only originally;
  the rename itself has since landed). [done]** The "data layer" name
  and full symbol inventory above were originally scoped as a checklist
  for Stage 7's implementation PR to execute against; that rename has
  since been applied as its own pass (see "Naming decision" above),
  ahead of Stage 7b, rather than bundled with it as originally planned.
- **Stage A' -- `?er_plot` Rd-page split (docs only, before Stage 7). [done]**
  Split the shared Rd page into per-layer topics as resolved above --
  turned out to already be the case when checked (see the resolved
  question immediately above for detail); nothing left to do here.
- **Stage B -- document singleton/additive semantics.** Pure docs
  (now written into the appropriate per-layer topic from Stage A', plus
  `?er_partial` and the vignette): state that model/quantile/data are
  singleton and group is additive, and that model-overlay is the one
  singleton layer flagged as a plausible (but not yet planned) future
  additive exception -- resolved above, not left open.
- **Stage C -- document the color/facet precedence rule.** Pure docs:
  fold the one-sentence general framing above into wherever Stage 7's
  `color_role` design gets written up (now `?er_plot_show_data` post-
  Stage A'), so the data layer's facet fallback reads as an instance of
  a general rule.
- **Stage D -- conceptual vignette / grammar write-up. [done]**
  `vignettes/articles/design.Rmd` (layers, singleton/additive semantics,
  stratification composition, response-type dispatch), cross-linking the
  per-layer Rd topics from Stage A' rather than duplicating their detail.
  Registered in `_pkgdown.yml`. Any future change to the grammar this
  section describes must update this article in the same change -- see
  the cross-reference note under "Motivation" above.

Sequencing note: Stage A' now precedes Stage 7's implementation (moved
up from a later, optional item); Stages A, B, and C are prerequisites
for, or should land alongside, Stage 7's implementation; Stage D can
happen independently, before or after.

### Resolved questions

- **Singleton/additive scope.** Model, quantile, and data layers stay
  singleton; group stays additive. Model-overlay (comparing two fitted
  models on one plot) is the one plausible future exception, explicitly
  deferred until a concrete need arises -- not planned as part of this
  review. Quantile and data layers are not expected to need an additive
  variant.
- **`?er_plot` Rd-page split.** Yes, and sequenced ahead of Stage 7
  (Stage A' above) rather than as an independent later item, so Stage
  7's new data-layer docs land in their own topic rather than the
  shared page.
