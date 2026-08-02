# erplots development plan

This document tracks scoped-out future development for erplots -- work
that's been thought about but not done, or deliberately deferred. It is
not a changelog: once an item here is completed, its write-up should
move to [.agents/HISTORY.md](HISTORY.md) and be removed from this file
rather than marked "done" in place. Items are grouped by target release.

## 0.1 release (initial CRAN submission)

### `erplots_data` documentation/test gaps

- A dedicated `vignettes/articles/erplots-data.Rmd` walkthrough of all
  five modelling scenarios end-to-end -- currently just a one-sentence
  pointer from `vignettes/erplots.Rmd` plus `?erplots_data`'s own
  `@examples`.
- Tests asserting `study_id`'s independence from dose/exposure/response
  directly -- currently only eyeballed via `table(study_id, dose_group)`
  during development, not asserted anywhere in `tests/testthat/`.

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
