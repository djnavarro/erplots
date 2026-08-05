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

**Done** (see `HISTORY.md`'s "The `er_tte` grammar" entry for the design
writeup): the `er_tte()` object/Kaplan-Meier fit, and four of its five
layers -- `er_tte_add_curve()`, `er_tte_add_censor()`,
`er_tte_add_risktable()`, `er_tte_add_pvalue()`.

**Remaining**, and still not scheduled for a specific release -- blocked
on `ertte` itself, which doesn't exist yet and has open design questions
(AFT vs. PH parameterisation, delta-method vs. profile CIs); building
`er_tte_add_model()`'s prediction contract now risks rework once
`ertte`'s model object stabilizes:

```r
data |>
  er_tte(time, event, stratify_by = NULL, n_strata = 4, conf_level = 0.95) |>
  er_tte_add_curve() |>
  er_tte_add_censor() |>
  er_tte_add_risktable() |>
  er_tte_add_pvalue() |>
  er_tte_add_model(fit) |>    # parametric S(t) overlay from an ertte model, singleton -- not yet built
  er_tte_theme(...) |>        # not yet built; `object$theme$title`/`subtitle`/`caption` already exist on
                               # `er_tte()`'s object but nothing sets them yet
  plot()
```

- `er_tte_add_model()` needs a prediction contract distinct from
  `er_predict()` (a time grid in, `S(t)` + CI per stratum out) --
  proposed as a new generic, `er_predict_survival(model, newdata,
  time_grid, conf_level, ...)`, added to `R/er-generics.R` alongside the
  existing three rather than overloading `er_predict()` with a `type=`
  argument.
- File layout mirrors the `er-plot-*`/`er-vpc-*` split; `R/er-tte-api.R`,
  `-add.R`, `-layer.R`, and `-style-{curve,censor,risktable,pvalue}.R`
  already exist, so this only needs a new `-style-model.R` (plus
  whatever `-build.R`/`-theme.R` split proves warranted once
  `er_tte_theme()` exists), and a test-only toy TTE model
  (`survival::survreg()`-based) so model-layer tests don't depend on
  `ertte` existing yet -- real `ertte` integration tests get added later,
  gated with `skip_if_not_installed("ertte")`, matching how `erglm`-
  specific tests are already gated.

**Explicitly deferred beyond even this release**: a survival-curve VPC
(simulate event times from an `ertte` model, compare simulated vs.
observed KM). The upstream issue phases this after the core `er_tte`
grammar exists and after `ertte`'s `er_simulate`-equivalent contract is
defined.

**Open questions** (to resolve before starting on `er_tte_add_model()`):
confirm `er_predict_survival()`'s exact signature, in particular whether
strata membership is carried on `newdata` or is implicit in `model`.
