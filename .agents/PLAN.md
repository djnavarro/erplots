# erplots development plan

This document tracks scoped-out future development for erplots -- work
that's been thought about but not done, or deliberately deferred. It is
not a changelog: once an item here is completed, its write-up should
move to [.agents/HISTORY.md](HISTORY.md) and be removed from this file
rather than marked "done" in place. Items are grouped by target release.

## 0.2 release

### Deferred: an additive `model` layer

Currently `er_plot_add_model()` is a singleton (a second call replaces
the first). Overlaying two fitted curves on the same panel (e.g.
comparing two models) isn't supported without a custom builder. Not
scheduled -- no concrete need has surfaced yet.

### Deferred: quantile layer's `_vlines` bin-boundary lines can still land outside a narrowed axis

The model layer's stale-grid bug (#14) and the data/quantile/group
layers' full-data-regardless-of-limits bug (both now fixed -- see
`HISTORY.md`) covered every layer that draws a *point/marker* positioned
by data. Not covered: the quantile layer's `_vlines` builders
(`er_style_quantile_errorbar_vlines()`/`_pointrange_vlines()`) draw a
labelled `geom_vline()` at every element of `config$breaks` -- a fixed
set of cutpoints from `cut_exposure_quantile()`, independent of
`config$summary` and never filtered against `exposure$limits`. A
boundary line/label landing outside a narrowed `xlim` is a smaller
concern than a whole summary marker silently vanishing (the case that
motivated the fix), but is a known, minor gap if a future report surfaces
it. Not scheduled.

### Deferred: VPC mini-grammar follow-ons (advanced)

- A "binless"/LOESS-smoothed alternative to quantile binning (tidyvpc
  supports this).
- Prediction-correction (pcVPC).



## Later release (proposed 0.2.0): TTE plotting grammar (`er_tte`) -- remaining work

Tracked upstream in [ertte#1](https://github.com/djnavarro/ertte/issues/1)
(Workstream C -- "TTE plotting grammar in `erplots`"), co-designed with the
new `ertte` (time-to-event exposure-response modelling) package.

**Done** (see `HISTORY.md`'s "The `er_tte` grammar", "`er_tte_add_model()`",
and "`er_tte_theme()`" entries for the design writeups): the `er_tte()`
object/Kaplan-Meier fit, all five layers -- `er_tte_add_curve()`,
`er_tte_add_censor()`, `er_tte_add_risktable()`, `er_tte_add_pvalue()`,
`er_tte_add_model()` -- and `er_tte_theme()`. The full pipeline from
`PLAN.md`'s original sketch now works end to end:

```r
data |>
  er_tte(time, event, stratify_by = NULL, conf_level = 0.95) |>
  er_tte_add_curve() |>
  er_tte_add_censor() |>
  er_tte_add_risktable() |>
  er_tte_add_pvalue() |>
  er_tte_add_model(fit) |>
  er_tte_theme(...) |>
  plot()
```

**Done**: real `ertte` integration. `ertte` now implements
`er_predict_survival.ertte_model()` (wrapping its own `ertte_predict()`),
alongside its existing `er_predict()`/`er_simulate()`/`er_summary()`
methods for the scalar landmark/RMST reductions used by
`er_plot()`/`er_vpc()`. `ertte` has been added to `Suggests`/`Remotes` in
`DESCRIPTION` (GitHub-only, like `erglm`/`emaxnls`), and
`tests/testthat/test-tte-model-sync.R` is a dedicated integration test
file gated with `skip_if_not_installed("ertte")`, comparing
`er_predict_survival()` output against the test-only
`er_test_toy_tte_model()` (`survival::survreg()`-based, in
`tests/testthat/helper-toy-model.R`) across distributions/covariates, and
exercising `er_tte_add_model()` end to end with real `ertte_aft()`/
`ertte_coxph()` fits -- mirroring `test-toy-model-sync.R`'s `erglm`
pattern.

**Remaining, not yet scheduled for a specific release**: none currently
-- the one item previously tracked here (`er_tte_add_model()`'s
continuous-`stratify_by` approximation) is now moot: `stratify_by` is
required to be discrete across all three mini-grammars (`er_plot()`/
`er_tte()`/`er_vpc()`), so there's no numeric-variable case left to
approximate. See `HISTORY.md` for the writeup.

**Explicitly deferred beyond even this release**: a survival-curve VPC
(simulate event times from an `ertte` model, compare simulated vs.
observed KM). The upstream issue phases this after the core `er_tte`
grammar exists and after `ertte`'s `er_simulate`-equivalent contract is
defined.
