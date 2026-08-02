# erplots development plan

This document tracks scoped-out future development for erplots -- work
that's been thought about but not done, or deliberately deferred. It is
not a changelog: once an item here is completed, its write-up should
move to [.agents/HISTORY.md](HISTORY.md) and be removed from this file
rather than marked "done" in place. Items are grouped by target release.

## 0.1 release (initial CRAN submission)

### Stress test before submission

A fresh round of stress testing against the full breadth of layers/
builders/response types added since the last pass -- looking for
validation gaps, unhelpful errors, and outright bugs surfaced by
combinations that haven't been exercised in `tests/testthat/`.

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
