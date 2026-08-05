# erplots development plan

This document tracks scoped-out future development for erplots -- work
that's been thought about but not done, or deliberately deferred. It is
not a changelog: once an item here is completed, its write-up should
move to [.agents/HISTORY.md](HISTORY.md) and be removed from this file
rather than marked "done" in place. Items are grouped by target release.

## 0.1 release (initial CRAN submission)

### CRAN release strategy

Plan out submission order/dependency handling before submitting:

- `erglm` as a `Suggests` dependency is fine *if* `erglm` 0.1.1 is
  accepted to CRAN before `erplots` 0.1 is submitted -- confirm that
  ordering holds, or fall back to gating erglm-dependent tests/examples
  more defensively if it slips.
- `emaxnls` is trickier: it's already on CRAN, but the CRAN release
  doesn't register the `er_predict()`/`er_simulate()`/`er_summary()`
  methods erplots relies on (only `Remotes: djnavarro/emaxnls`'s
  GitHub version does, per the `>= 0.1.1.9000` floor in
  `DESCRIPTION`). Need a plan for what erplots 0.1 says/does about
  `emaxnls` on CRAN -- e.g. whether to wait for a new `emaxnls` CRAN
  release that registers the methods, document the gap prominently,
  or otherwise avoid implying CRAN's `emaxnls` works with erplots
  out of the box.

## 0.2 release

### Deferred: an additive `model` layer

Currently `er_plot_add_model()` is a singleton (a second call replaces
the first). Overlaying two fitted curves on the same panel (e.g.
comparing two models) isn't supported without a custom builder. Not
scheduled -- no concrete need has surfaced yet.

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
  er_tte(time, event, stratify_by = NULL, n_strata = 4, conf_level = 0.95) |>
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

**Remaining, not yet scheduled for a specific release**:

- `er_tte_add_model()`'s documented approximation -- when
  `object$strata$type == "continuous"`, the strata variable rides on
  `newdata` as its quantile-bin label (e.g. `"Q1"`), not the raw numeric
  covariate. This is fine as long as the fitted model's own covariates
  don't include that same raw numeric variable, but if they do (e.g.
  `stratify_by = age` with a model fitted on `age` directly, rather than
  on a different exposure column), the resulting `newdata$age` column
  is a factor of bin labels and the underlying `predict()` call fails
  with a low-level, uninformative error (e.g. survreg's
  `"non-conformable arguments"`) rather than something actionable.
  Consider either an informative upfront check (does any term in
  `model`'s formula match `object$strata$var` when
  `object$strata$type == "continuous"`?) or resolving it properly by
  carrying both the bin label and a representative numeric value.

**Explicitly deferred beyond even this release**: a survival-curve VPC
(simulate event times from an `ertte` model, compare simulated vs.
observed KM). The upstream issue phases this after the core `er_tte`
grammar exists and after `ertte`'s `er_simulate`-equivalent contract is
defined.
