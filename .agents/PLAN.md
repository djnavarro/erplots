# erplots development plan

This document tracks scoped-out future development for erplots -- work
that's been thought about but not done, or deliberately deferred. It is
not a changelog: once an item here is completed, its write-up should
move to [.agents/HISTORY.md](HISTORY.md) and be removed from this file
rather than marked "done" in place. Items are grouped by target release.

## 0.2 release

No outstanding items. The `er_tte()` mini-grammar (the bulk of the 0.2
scope) is complete, including full `ertte` integration -- see
`HISTORY.md`'s "The `er_tte` grammar", "`er_tte_add_model()`", and
"`er_tte_theme()`" entries for the design writeups.

## 0.3 and later

### Deferred: an additive `model` layer

Currently `er_plot_add_model()` is a singleton (a second call replaces
the first). Overlaying two fitted curves on the same panel (e.g.
comparing two models) isn't supported without a custom builder. Not
scheduled -- no concrete need has surfaced yet.

### Deferred: VPC mini-grammar follow-ons (advanced)

- A "binless"/LOESS-smoothed alternative to quantile binning (tidyvpc
  supports this).
- Prediction-correction (pcVPC).

### Deferred: survival-curve VPC

A VPC analogue for the `er_tte()` grammar: simulate event times from a
model that implements `er_predict_survival()` (or an `er_simulate()`-
equivalent contract for survival models, not yet defined), and compare
the resulting simulated Kaplan-Meier curve(s) against the observed KM
curve -- mirroring what `er_vpc()` already does for the scalar-response
grammars. Not scheduled: it depends on a simulation contract for
survival models that doesn't exist yet in either `erplots` or any
companion package, and no concrete need has surfaced beyond the general
appeal of feature parity with `er_vpc()`.
