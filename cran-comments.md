# CRAN submission comments

## Package summary

`erplots` provides a fluent mini-language for building exposure-response
plots (model curves/ribbons, quantile-binned summaries, raw-data layers,
grouped distribution panels, a visual predictive check grammar, and now
a time-to-event/Kaplan-Meier grammar) from observed data and a fitted
exposure-response model. It is deliberately model-agnostic: it never
fits a model itself, and any model implementing a small S3 interface
(`er_predict()`, optionally `er_simulate()`/`er_summary()`/
`er_predict_survival()`) can be visualised with it.

This is a routine feature release (0.2.0), following the 0.1.2 CRAN
release (published 2026-09-09). Highlights (see `NEWS.md` for the
complete list):

* Added `er_tte()`, a third mini-grammar for Kaplan-Meier/
  survival-over-time figures (a time axis, a survival-probability axis,
  and an optional discrete `stratify_by`), with five layers
  (`er_tte_add_curve()`/`_censor()`/`_risktable()`/`_summary()`/
  `_model()`) and a matching `er_tte_theme()`.
* Added `er_predict_survival()`, a fourth model-interface generic
  powering `er_tte_add_model()`'s fitted `S(t)` overlay.
* `cut_quantile()`/`cut_exposure_quantile()` gain `ties`/`quantile_type`/
  `labeller` arguments for controlling tie-breaking, the quantile
  algorithm, and bin labelling; `er_vpc()` gains a matching `stratify_by`
  for faceted panels.
* `er_style_tag()` gains a `label` argument so built-in builders can be
  selected by a short string (e.g. `style = "spaghetti"`) instead of the
  function itself; see `er_style_labels()`.
* Several breaking renames tidying argument order/naming across the
  three grammars (`zorder` -> `draw_order`, grammar-prefixed `layer`
  values, standardised `style`/`keep_strata`/`conf_level` argument
  position, `bins` -> `n_bins`, several `size` -> `point_size`/
  `scale_factor` renames) -- all pre-1.0, so no deprecation shims are
  provided (see `NEWS.md`'s "Breaking changes" section for the full
  list and rationale).
* Bug fixes: stale model curves after `er_plot_theme(xlim = ...)`,
  out-of-range data/quantile/VPC markers now dropped (with a warning)
  instead of silently drawn past the panel, `stratify_by` now errors on
  a numeric column instead of silently mis-rendering, and
  `er_plot_add_groups()`'s `bins` argument now actually takes effect.

## Suggests/companion packages

`erplots` is designed to be used alongside separate model-fitting
packages that implement its S3 interface, none of which are required to
install or use `erplots` itself (every example and test that touches one
is guarded with `requireNamespace(..., quietly = TRUE)` or
`testthat::skip_if_not_installed()`).

* **`erglm`** (GLM-based exposure-response models) and **`emaxnls`**
  (Emax/sigmoidal dose-response models) are both listed in `Suggests`
  and both now on CRAN at version 0.2.0 -- `emaxnls`'s previous version
  floor (`>= 0.1.1.9000`, needed because the CRAN release at the time of
  the 0.1.2 submission didn't yet register `erplots`'s S3 methods) is
  satisfied by the current CRAN release, so no `Remotes:` entry is
  needed for either.
* **`ertte`** (the time-to-event member of the same package family,
  implementing `er_predict_survival()` for `er_tte_add_model()`) remains
  GitHub-only and has accordingly been dropped from `Suggests`
  entirely for this submission -- `er_tte()`/`er_tte_add_model()` are
  fully usable with any model implementing the documented interface
  (see `vignettes/articles/model-interface.Rmd`'s `toy_survival`
  example), `ertte` just isn't required or referenced anywhere in the
  shipped package (examples, tests, and vignettes) any more.
* As a result, this submission has no `Remotes:` field and no
  GitHub-only `Suggests` dependency at all.

## Example timing

One example (`?erplots_data`) previously took ~14s, driven by two
`emaxnls`-based blocks whose dominant cost was `emaxnls::er_predict()`'s
confidence-interval computation (~7-11s per call, independent of the
fitting data size). Those two blocks have been removed from the
example (the remaining four `erglm`-based blocks already cover every
response type, at ~0.25s each); no example now exceeds CRAN's 5s
guideline.

## Test environments

* Local: Ubuntu 24.04, R 4.6.1 (`devtools::check(cran = TRUE)`) --
  0 errors, 0 warnings, 0 notes; full test suite (1632 tests) passes.
* GitHub Actions (`R-CMD-check.yaml`): ubuntu-latest (R-devel, R-release,
  R-oldrel-1), windows-latest (R-release), macos-latest/arm64 (R-release)
* R-hub (`R-hub` workflow, run on 2026-10-04,
  <https://github.com/djnavarro/erplots/actions/runs/37194834347>):
  * `windows` (R-devel), `ubuntu-clang` (R-devel, Ubuntu 22.04 + clang),
    `ubuntu-next` (R-patched/R-next, Ubuntu 24.04), `donttest`
    (Ubuntu 22.04, `\donttest{}` examples run): all `Status: OK`.
  * `macos-arm64` (R-devel): cancelled after stalling for ~9 minutes
    inside `setup-deps` while `pak` was resolving the macOS-arm64
    binary repository listing -- an upstream `pak`/mirror
    responsiveness issue on the R-hub runner, before `R CMD check`
    itself ever started, not an `erplots` problem. (The 0.1.2
    submission's R-hub run hit an analogous macOS-runner
    infrastructure issue on this same platform.)
  * `nosuggests` (Fedora 42, none of `Suggests` installed): 0 test
    failures, 0 example failures, but `R CMD check` still reports
    `1 error` because re-building the package's `knitr`/`rmarkdown`
    vignette requires those packages regardless of the "no suggests"
    condition -- expected for any package with a `VignetteBuilder`, not
    an `erplots` bug (same result, same explanation, as the 0.1.2
    submission's R-hub run).
* win-builder (submitted 2026-10-04 via `devtools::check_win_devel()`/
  `check_win_release()`): R-devel and R-release both `Status: OK`, 0
  errors, 0 warnings, 0 notes -- no "New submission" NOTE this time,
  since 0.1.2 is already on CRAN
  (<https://win-builder.r-project.org/ZXGPZqXAf2XS/00check.log>,
  <https://win-builder.r-project.org/O9c4j60MFkTo/00check.log>).
* mac-builder (submitted 2026-10-04 via `devtools::check_mac_release()`/
  `check_mac_devel()`, covering the `macos-arm64` gap left by the
  cancelled R-hub job above): both `Status: OK`, 0 errors, 0 warnings,
  0 notes
  (<https://mac.r-project.org/macbuilder/results/1791110071-bcd7a9987ddca4c9/>,
  <https://mac.r-project.org/macbuilder/results/1791110097-37cd0a1d8c11d4d0/>).

## R CMD check results

0 errors | 0 warnings | 0 notes across every environment above except
the one expected, non-package `nosuggests` exception on R-hub.

## Downstream dependencies

`erglm` depends on `erplots` via `Suggests` and is the one actual CRAN
reverse dependency. `emaxnls` and `ertte` also list `erplots` in
`Suggests` (for their own integration tests) and were checked as a
courtesy, even though neither is a CRAN reverse dependency (both are
GitHub-only). Rechecked with `revdepcheck::revdep_check()` against this
submission's source (2026-10-04): 0 new problems for all three
(`E:0 W:0 N:0` each; see `revdep/cran.md`/`revdep/problems.md`).

Thank you for your consideration.

Kind regards,
Danielle Navarro
