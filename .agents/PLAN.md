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

## Later release (proposed 0.2.0): TTE plotting grammar (`er_tte`)

Tracked upstream in [ertte#1](https://github.com/djnavarro/ertte/issues/1)
(Workstream C -- "TTE plotting grammar in `erplots`"), co-designed with the
new `ertte` (time-to-event exposure-response modelling) package. Full
design writeup and phased build order live in the implementation plan
produced for this work; this entry just records scope and sequencing so
the decision isn't lost.

**Not scheduled for 0.1.** erplots 0.1 is otherwise ready to submit
(blocked only on the CRAN submission-ordering items above); the TTE
grammar is a large, net-new mini-grammar -- its own time-x-axis/
survival-y-axis coordinate system, step curves, censoring marks, a
number-at-risk table, and a log-rank annotation, none of which reuse the
existing `er_predict()`-vs-exposure machinery `er_plot()`/`er_vpc()`
share. `ertte` itself doesn't exist yet and has open design questions
(AFT vs. PH parameterisation, delta-method vs. profile CIs); building
`er_tte_add_model()`'s prediction contract now risks rework once
`ertte`'s model object stabilizes. Large enough in scope to justify its
own minor release (proposed 0.2.0) rather than sharing "0.2" with the two
smaller deferred items above.

**Proposed shape**, mirroring `er_plot()`/`er_vpc()`'s object/layer/
builder architecture:

```r
data |>
  er_tte(time, event, stratify_by = NULL, n_strata = 4, conf_level = 0.95) |>
  er_tte_add_curve() |>       # KM step curve + CI ribbon, singleton
  er_tte_add_censor() |>      # censoring tick marks, singleton
  er_tte_add_risktable() |>   # number-at-risk table, patchwork panel, singleton
  er_tte_add_pvalue() |>      # log-rank annotation, singleton
  er_tte_add_model(fit) |>    # parametric S(t) overlay from an ertte model, singleton
  er_tte_theme(...) |>
  plot()
```

Key decisions carried by this plan:

- The empirical KM curve, censoring marks, risk table, and log-rank test
  are computed directly from raw `(time, event)` data (no model
  involved), the same way `er_vpc_add_observed()` bins raw data without
  one. This requires a real Kaplan-Meier estimator and log-rank test
  inside erplots, not just a place to draw someone else's tidy table --
  **confirmed**: `survival` added to `DESCRIPTION`'s `Imports` (a
  "Recommended" package bundled with base R, so effectively free). The
  KM fit (`survival::survfit()`) and, when `stratify_by` has more than
  one level, the log-rank test (`survival::survdiff()`) are computed
  once in `er_tte()` and shared across layers rather than recomputed per
  add-verb.
- `er_tte_add_model()` needs a prediction contract distinct from
  `er_predict()` (a time grid in, `S(t)` + CI per stratum out) --
  proposed as a new generic, `er_predict_survival(model, newdata,
  time_grid, conf_level, ...)`, added to `R/er-generics.R` alongside the
  existing three rather than overloading `er_predict()` with a `type=`
  argument.
- File layout mirrors the `er-plot-*`/`er-vpc-*` split (`R/er-tte-api.R`,
  `-add.R`, `-layer.R`, `-build.R`, `-style-{curve,censor,risktable,
  pvalue,model}.R`, `-theme.R`), plus a test-only toy TTE model
  (`survival::survreg()`-based) so model-layer tests don't depend on
  `ertte` existing yet -- real `ertte` integration tests get added later,
  gated with `skip_if_not_installed("ertte")`, matching how `erglm`-
  specific tests are already gated.

**Explicitly deferred beyond even this release**: a survival-curve VPC
(simulate event times from an `ertte` model, compare simulated vs.
observed KM). The upstream issue phases this after the core `er_tte`
grammar exists and after `ertte`'s `er_simulate`-equivalent contract is
defined.

**Open questions** (to resolve before starting Phase 2): confirm
`er_predict_survival()`'s exact signature, in particular whether strata
membership is carried on `newdata` or is implicit in `model`; confirm
whether `er_tte_add_pvalue()` reuses `er_style_summary_pvalue()`'s
`format_p` formatter plumbing.

`survival` `Imports` dependency: **confirmed**, see above.
