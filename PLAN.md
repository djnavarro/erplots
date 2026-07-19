# erplots development plan

This document tracks scoped-out future development for erplots. It is
not a changelog. Items here are proposals to be reviewed before
implementation, not committed designs.

## Extend beyond binary responses to continuous (and count) responses

### Motivation

erplots is designed to be model-agnostic on the *fitted model* side (any
model implementing
[`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)/[`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)/[`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
can be plotted), but several of its data layers still hardcode an
assumption that the observed response is binary (0/1). Generalising
these layers would let erplots visualise, e.g., continuous-response
exposure-response models (dose-response/emax-style models) as well as
logistic-regression style binary-response models, without changing the
model-side contract.

### What already generalises for free

- The model curve/ribbon and spaghetti layers
  ([`er_plot_show_model()`](https://erplots.djnavarro.net/reference/er_plot.md),
  [`build_model_ribbonline()`](https://erplots.djnavarro.net/reference/er_partial.md),
  [`build_model_spaghetti()`](https://erplots.djnavarro.net/reference/er_partial.md))
  only ever consume
  [`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)/[`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  output (`fit_resp`/`ci_lower`/`ci_upper`, or simulated draws) –
  there’s no assumption about response type anywhere in that code path.
  No changes needed.
- The group panel
  ([`er_plot_show_groups()`](https://erplots.djnavarro.net/reference/er_plot.md),
  boxplot/violin of exposure by group) only ever looks at the exposure
  variable, not the response. No changes needed.

### What needs to change

- **Quantile summary layer**
  ([`er_plot_show_quantiles()`](https://erplots.djnavarro.net/reference/er_plot.md),
  `.part_quantile()`,
  [`build_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_partial.md)):
  computes, per exposure bin, `n1`/`n0` counts and a Clopper-Pearson CI
  for the response *rate*. For a continuous response this should instead
  compute a mean and a CI for the mean (e.g. t-based, or SE-based).
  Needs a response-type-dispatched summary step – most likely a small
  internal generic (analogous to the existing `build_*` partial pattern)
  with `summarise_quantile.binary()` / `summarise_quantile.continuous()`
  implementations, selected either by explicit argument or by
  auto-detecting whether the response column is binary (all values in
  `{0, 1}`, or logical).
- **Data strip layer**
  ([`er_plot_show_datastrip()`](https://erplots.djnavarro.net/reference/er_plot.md),
  [`build_datastrip_jitter()`](https://erplots.djnavarro.net/reference/er_partial.md)):
  the “responders above the line, non-responders below” two-panel jitter
  strip is inherently a binary-response visualisation. It doesn’t have
  an obvious continuous analogue (a plain exposure-vs-response scatter
  would be the closest equivalent, but that’s a different plot, not a
  variant of the same one). This is the layer most likely to need a
  genuinely different design for continuous responses, or to simply not
  be offered for continuous-response plots.
- **[`er_vpc_plot()`](https://erplots.djnavarro.net/reference/er_vpc_plot.md)**:
  currently compares observed vs. simulated response *rates* (with
  Clopper-Pearson CIs for the observed side, simulation quantiles for
  the simulated side). Generalises fairly directly to comparing means
  (with an appropriate CI for the observed mean) – this is the easiest
  of the three to generalise.
- **Response-type detection/declaration**: needs a decision on whether
  response type is auto-detected (e.g., “binary” if the response column
  only takes values in `{0, 1}`/is logical, “continuous” otherwise) or
  explicitly declared (e.g. a `response_type` argument on
  [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)).
  Auto-detection is more convenient but has failure modes (e.g. a 0/1
  count variable that isn’t actually a binary response); an explicit
  argument with a sensible auto-detected default is probably the safer
  choice.
- **Count (Poisson-like) responses**: not clearly binary or continuous.
  Treating them as “continuous” (mean + CI) is probably an adequate
  approximation for a first pass, but worth flagging as a known
  simplification rather than deciding definitively now.

### Design decisions (reviewed)

The questions below were originally left open; each now has a working
recommendation so implementation isn’t blocked, but all are still up for
debate if new information changes the calculus.

1.  **Response-type detection.** Add an explicit `response_type`
    argument (probably on
    [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
    since it governs which builders are valid for the whole plot, not
    just one component), defaulting to `"auto"`. The auto-detection
    heuristic: values entirely in `{0, 1}` or a logical column →
    `"binary"`, otherwise → `"continuous"`. This mirrors the “automatic
    with an escape hatch” pattern already adopted on the erlr side
    (e.g. its SCM test-selection decision) – convenient by default,
    overridable when the heuristic gets it wrong (e.g. a genuine 0/1
    count variable).

2.  **Data strip for continuous responses.** Omit it for v1, as a
    documented limitation, rather than design a continuous-specific
    replacement now. The two-panel “responders above the line,
    non-responders below” design is structurally about a binary flag –
    there’s no variant of *that* geometry for a continuous response,
    only a different plot entirely (e.g. a rug or raw scatter), and
    building that speculatively before anyone needs it isn’t worth the
    design effort yet. Revisit if/when a concrete use case shows up.

3.  **Quantile-bin CI method for continuous responses.** Use a
    t-interval, not a bootstrap. This mirrors the convention
    erlr/erglm’s own generalisation plan settled on for the analogous
    problem (families with estimated dispersion – gaussian, Gamma – use
    `Pr(>|t|)`-based inference, not a chi-squared/asymptotic-normal
    approximation), so the two packages stay consistent, and it’s
    simpler to implement and explain than a bootstrap.

4.  **Count responses.** Treat them as “continuous” for v1 (mean ± CI
    via the same t-interval as (3)), documented as a known
    approximation. Fast follow, once there’s a concrete need: add an
    exact Poisson CI path (analogous to how the binary path uses an
    exact Clopper-Pearson interval rather than a normal approximation) –
    the machinery for swapping in a response-type-specific interval
    method already exists once (1)-(3) are in place, so this is a small
    addition, not a redesign. Not worth building speculatively now given
    erglm’s own v1 family scope already treats poisson support as a real
    but secondary priority.

5.  **Coordination with `erlr`/`erglm`.** Don’t block on erglm’s rename
    timeline. erplots’ continuous-response work only needs *some* model
    object implementing
    [`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
    for a continuous response to test against – that’s easy to stub
    today with a plain `glm(family = gaussian())` (or even
    [`lm()`](https://rdrr.io/r/stats/lm.html)) and a few lines of local
    `er_predict.<class>()`/`er_summary.<class>()` methods in this
    package’s own test suite, without waiting for erglm to exist.
    Revisit using erglm’s actual continuous-response support once it
    lands, but start this work independently.

### Suggested step ordering

1.  Decide response-type detection/declaration mechanism.
2.  Generalise the quantile summary layer (binary vs. continuous paths).
3.  Generalise
    [`er_vpc_plot()`](https://erplots.djnavarro.net/reference/er_vpc_plot.md)’s
    summary statistic/CI computation.
4.  Design a continuous-response equivalent (or replacement) for the
    data strip layer.
5.  Expand tests/vignettes to cover continuous-response models (using
    `erglm` once available, or a plain
    [`lm()`](https://rdrr.io/r/stats/lm.html)/[`nls()`](https://rdrr.io/r/stats/nls.html)
    model in the interim with hand-written
    [`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
    methods).
