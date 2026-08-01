# erplots development plan

This document tracks scoped-out future development for erplots -- work
that's been thought about but not done, or deliberately deferred. It is
not a changelog: once an item here is completed, its write-up should
move to [.agents/HISTORY.md](HISTORY.md) and be removed from this file
rather than marked "done" in place.

## Open decision: `er_style_group_violin()`'s dead `quantile.linetype` argument

`quantile.linetype = "solid"` is currently inert -- `draw_quantiles`,
the `geom_violin()` argument that actually enables drawn quantile lines,
is never set, so this parameter has no effect regardless of its value.
Needs a decision next time this builder is touched: either wire it up
properly (add a `quantiles = NULL` argument mapped to `draw_quantiles`)
or drop `quantile.linetype` entirely.

## Deferred: data-layer continuous/count `"panel"`-layout builder design

No built-in `"panel"`-layout builder exists for a continuous/count
response (only `er_style_data_boxjitter()`, binary-only). If one is
added, two open questions from the `build_data_color()` removal remain
unresolved:

- Should it use a deliberately chosen continuous color scale rather than
  ggplot2's default gradient?
- Should it be a quantile-binned rug rather than a color-encoded
  scatter?

A custom builder remains possible today via `er_style_tag()`, since
`.layer_data()`'s response-type dispatch was left in place for this.

## Deferred: an additive `model` layer

Currently `er_plot_add_model()` is a singleton (a second call replaces
the first). Overlaying two fitted curves on the same panel (e.g.
comparing two models) isn't supported without a custom builder. Not
scheduled -- no concrete need has surfaced yet.

## Deferred: VPC mini-grammar follow-ons

Scoped out but not started when the VPC mini-grammar
(`er_vpc()`/`er_vpc_add_observed()`/`er_vpc_add_simulated()`) was built,
deliberately narrower than `er_plot()` itself:

- Stratified/faceted VPC panels (the `er_plot()` `group`-layer analogue
  -- one panel per stratum level).
- A dedicated `er_vpc_theme()` -- ordinary `+ theme()`/`+ labs()` on the
  built/returned ggplot2 object remains the escape hatch for now.
- A "binless"/LOESS-smoothed alternative to quantile binning (tidyvpc
  supports this).
- Prediction-correction (pcVPC).
- A dedicated `vignettes/articles/vpc.Rmd` worked example -- the only
  existing worked example lives in `model-interface.Rmd`'s
  `er_simulate()` section and only demonstrates the default builders,
  not the percentile-band idiom.

## Deferred: `erplots_data` documentation/test gaps

- A dedicated `vignettes/articles/erplots-data.Rmd` walkthrough of all
  five modelling scenarios end-to-end -- currently just a one-sentence
  pointer from `vignettes/erplots.Rmd` plus `?erplots_data`'s own
  `@examples`.
- Tests asserting `study_id`'s independence from dose/exposure/response
  directly -- currently only eyeballed via `table(study_id, dose_group)`
  during development, not asserted anywhere in `tests/testthat/`.
