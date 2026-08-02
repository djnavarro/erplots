# erplots development plan

This document tracks scoped-out future development for erplots -- work
that's been thought about but not done, or deliberately deferred. It is
not a changelog: once an item here is completed, its write-up should
move to [.agents/HISTORY.md](HISTORY.md) and be removed from this file
rather than marked "done" in place. Items are grouped by target release.

## 0.1 release (initial CRAN submission)

### Stress test before submission

A fresh round of stress testing against the full breadth of layers/
builders/response types (150+ combinations across `er_plot`/`er_vpc`)
turned up no failures in the main sweep, but targeted single-layer edge
cases found two real bugs:

- `.polish_legends()` crashing when a lone stratified overlay/summary
  layer is the only stratified thing on the plot -- **fixed**, see
  `.agents/HISTORY.md`.
- `.check_theme_limits()` crashing with an opaque "missing value where
  TRUE/FALSE needed" when `xlim`/`ylim` contains `NA` (e.g. `xlim =
  c(0, NA)`, the standard ggplot2 idiom for "float this bound") --
  **fixed**, see `.agents/HISTORY.md`. `NA` is rejected outright (not
  supported) rather than threaded through to the internal computations
  that also consume these limits.

Both bugs found so far are fixed; no further stress-test follow-ups are
currently queued here, but this section stays open in case another pass
turns up more before submission.

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
