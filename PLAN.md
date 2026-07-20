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

2. **Data strip for continuous responses.** Omit it for v1, as a
   documented limitation, rather than design a continuous-specific
   replacement now. The two-panel "responders above the line,
   non-responders below" design is structurally about a binary flag --
   there's no variant of *that* geometry for a continuous response, only
   a different plot entirely (e.g. a rug or raw scatter), and building
   that speculatively before anyone needs it isn't worth the design
   effort yet. Revisit if/when a concrete use case shows up.

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
demo) were spot-checked visually; all render and look correct. One
minor, non-blocking observation from that check: for `erglm_data`'s
`ae_count ~ aucss` example, none of the default (t-interval) path's
`ci_lower` values actually go negative, so the vignette's two
count-response plots (`continuous-3` vs. `count-1`) look nearly
identical -- the claimed advantage of `response_type = "count"` (never
producing a negative lower bound) is true in general (and covered by
`test-utils-helpers.R`'s `poisson_interval()` unit tests) but isn't
concretely visible in this particular rendering. See "Other known
issues" below. Remaining open work is limited to that item and the
stratified-label-overlap item below; there is no other scoped work left
in this plan.

## Other known issues / follow-ups

### Vignette's count-response example doesn't visually demonstrate the exact-Poisson-interval advantage

`vignettes/articles/plot.Rmd`'s "Continuous responses" section shows
`ae_count ~ aucss` quantile plots under both the default (auto-detected
`"continuous"`, t-interval) and explicit `response_type = "count"`
(exact Poisson interval) paths, with text claiming the latter "never
produces a negative lower bound -- useful for low-count bins, where the
t-interval approximation can." For `erglm_data`'s actual bin means, none
of the t-interval lower bounds happen to go negative, so the two plots
render nearly identically and the claimed advantage, while true and
unit-tested (see `poisson_interval()`'s tests in
`test-utils-helpers.R`), isn't visible in this specific rendering.

Possible fixes, not yet scoped: pick (or synthesize) an example with a
genuinely low-count bin where the t-interval lower bound does go
negative, so the two plots visibly differ; or soften the vignette's
prose to note the difference is usually subtle for `erglm_data`
specifically and point readers to the unit tests for a concrete
negative-bound example instead. Low priority -- the underlying
implementation and its test coverage are already correct; this is a
vignette clarity nit, not a code bug.

### Stratified quantile labels can visually overlap

`build_quantile_errorbar()`'s `y_mid_lbl` text geom places each stratum's
label at its own bin's `x_mid`/`y_lbl`, with no dodging between strata.
When two strata's `x_mid` values for the same exposure bin land close
together (the common case, since bins are quantile cutpoints of the same
exposure variable), their text labels can visually collide -- observed
when sanity-checking the Stage 1 continuous-response quantile layer on a
`sex`-stratified `biomarker_change ~ aucss` plot (Q2/Q3 labels for Male
vs. Female overlapped). This is not specific to continuous responses --
the same geometry issue exists for stratified binary quantile plots, it
was just easier to notice with plain numeric labels. The underlying
`config$summary` values (means/rates, CIs) are unaffected; this is purely
a `geom_text()` placement issue.

Possible fixes, not yet scoped in detail: nudge/dodge `y_mid_lbl` text
horizontally per stratum (e.g. via `position_dodge()` or a manual
per-stratum x-offset proportional to bin width), or drop the in-plot
numeric labels in favour of a legend-only encoding when `stratify ==
TRUE`. Low priority relative to the response-type generalisation above;
revisit once Stages 1-4 land, since Stage 2 (`er_vpc_plot()`) and
Stage 4 (count responses) will produce more stratified continuous plots
where this becomes more visible.
