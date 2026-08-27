# CRAN submission comments

## Summary

This is a new package. Summary of the package as per DESCRIPTION:

`erplots` provides a fluent mini-language for building exposure-response
plots (model curves/ribbons, quantile-binned summaries, raw-data layers,
grouped distribution panels, and a visual predictive check grammar) from
observed data and a fitted exposure-response model. It is deliberately
model-agnostic: it never fits a model itself, and any model implementing
a small S3 interface (`er_predict()`, optionally `er_simulate()` and
`er_summary()`) can be visualised with it.

Local tests, CI checks, Rhub checks, and win-builder checks are all reported
below, with no issues. There is also a brief discussion of the relationship
between `erplots` and the companion package `erglm` now on CRAN (as the first
package that implements the interface).  

Thank you for your consideration.

Kind regards,
Danielle Navarro

## Resubmission

This is a resubmission, responding to human review feedback on the 0.1.1
submission. In this version I have:

* Removed the single quotes around function names (`er_predict()`,
  `er_simulate()`, `er_summary()`) in the `Description` field of
  DESCRIPTION -- quoting is now reserved for package/software/API names
  only, per the reviewer's note.
* Checked for references describing the package's methods to add to
  `Description` in `authors (year) <doi:...>` form. `erplots` is a
  plotting grammar with no associated methods paper, so no reference has
  been added.
* Investigated the reported `Warning: Examples in comments in:
  er_model_interface.Rd`. `R/er-generics.R` (the source for this Rd page)
  has no `@examples` block and the built `.Rd` has no `\examples` section,
  and we were unable to reproduce the warning locally (`R CMD check
  --as-cran`, `tools::checkRd()`), including by re-checking out and
  re-`roxygenize()`-ing the exact commit submitted as 0.1.1, which
  produced no changes. We have nevertheless re-`roxygenize()`d this
  submission as suggested, and confirmed every exported topic carries a
  `@returns`/`\value` tag; the sole exception, `erplots_data.Rd`, is a
  `\docType{data}` page, which per
  <https://contributor.r-project.org/cran-cookbook/docs_issues.html#missing-value-tags-in-.rd-files>
  does not require one. Happy to investigate further with any additional
  detail on how the warning was produced.
* Removed a hard-coded RNG seed (a literal `1234L` in `R/er-plot-layer.R`,
  used so that `er_style_data_overlay()`/`er_style_data_boxjitter()`'s
  jittered points rendered identically across repeated `plot()` calls on
  the same object). Seeding is now opt-in only: a caller can pass
  `seed = <value>` through `er_plot_add_data()`'s own `...` for
  reproducible jitter; with no `seed` supplied (the default), no seed
  management happens at all, and jitter differs from one build to the
  next, like any other jittered geom.
* Swept the rest of the package for other RNG seed usage while fixing
  the above, and found one further inconsistency: `er_plot_add_groups()`'s
  jittered builders (`er_style_group_boxjitter()`, `er_style_group_violinjitter()`)
  drew their jitter with no seed control at all (not hard-coded, just
  unseedable). Brought these in line with the same opt-in-only pattern
  for consistency, which required moving `withr` from `Suggests` to
  `Imports` (previously only used in tests). Every other seed-adjacent
  code path already followed this pattern:
  `er_style_model_spaghetti()`'s simulated draws, and the `seed`
  parameters `er_simulate()`/`er_vpc_add_simulated()` forward to a
  model's own method, all default to `NULL` with no fallback.

Re-checked locally (`R CMD check --as-cran`) after these fixes: 0 errors |
0 warnings | 1 note (the standard "New submission" note only). Full test
suite (1186 tests) also passes.

## Test environments

* Local: Ubuntu 24.04, R 4.6.1 (`R CMD check --as-cran`)
* GitHub Actions (`R-CMD-check.yaml`): ubuntu-latest (R-devel, R-release,
  R-oldrel-1), windows-latest (R-release), macos-latest/arm64 (R-release)
* R-hub (`R-hub` workflow, run on 2026-08-09,
  <https://github.com/djnavarro/erplots/actions/runs/31286358791>):
  * `windows` (R-devel), `macos-arm64` (R-devel), `ubuntu-clang`
    (R-devel, Ubuntu 22.04 + clang), `ubuntu-next` (R-patched/R-next,
    Ubuntu 24.04), `donttest` (Ubuntu 22.04, `\donttest{}` examples
    run): all clean.
  * `nosuggests` (Fedora 42, none of `Suggests` installed): 0 test
    failures (1032 passed, 52 skipped) and 0 example failures, but
    `R CMD check` still reports `1 error` because re-building the
    package's `knitr`/`rmarkdown` vignette requires those packages to
    be installed regardless of the "no suggests" condition --
    expected for any package with a `VignetteBuilder` and not a
    package bug.
* win-builder (submitted 2026-08-09 via `devtools::check_win_devel()`/
  `check_win_release()`/`check_win_oldrelease()`): R-devel (r90381),
  R-release (4.6.1), and R-oldrelease (4.5.3) all `Status: 1 NOTE` --
  only the standard "New submission" NOTE, nothing else. R-devel and
  R-oldrelease also print an `INFO` line ("Package suggested but not
  available for checking: 'erglm'"), which is a win-builder mirror
  limitation, not a package issue -- `erglm` is on CRAN and every
  example/test that uses it is guarded with
  `requireNamespace(..., quietly = TRUE)`/`skip_if_not_installed()`.

## R CMD check results

0 errors | 0 warnings | 1 note

* The one NOTE is the standard `New submission` NOTE win-builder and
  CRAN's own incoming checks raise for every first submission.
* Local, GitHub Actions, and R-hub checks (`nosuggests` aside) show
  0 errors | 0 warnings | 0 notes -- see "Test environments" above for
  the one expected, non-package `nosuggests`/vignette-rebuild
  exception on R-hub.

## Downstream companion package and `Suggests`

`erplots` is designed to be used alongside separate model-fitting
packages that implement its S3 interface, none of which are required to
install or use `erplots` itself (every example and test that touches one
is guarded with `requireNamespace(..., quietly = TRUE)` or
`testthat::skip_if_not_installed()`).

* **`erglm`** (GLM-based exposure-response models) is listed in
  `Suggests`. It was accepted to CRAN on 2026-08-08 (version 0.1.1),
  immediately ahead of this submission, and registers its `er_predict()`/
  `er_simulate()`/`er_summary()` methods for `erplots` lazily at load
  time (via `.s3_register()`), so neither package hard-depends on the
  other. `erplots`'s own `Suggests: erglm` carries no version floor, and
  no `Remotes:` entry is needed, since the CRAN release already provides
  everything `erplots`'s examples/tests use.

## Other notes

* Two vignettes ship with the package (`vignettes/erplots.Rmd` plus the
  vignette index); a larger set of worked-example articles lives in
  `vignettes/articles/` for the pkgdown site only and is excluded from
  the build via `.Rbuildignore`, so it is not part of this submission.
* This is a first submission of `erplots` itself, but one CRAN reverse
  dependency already exists: `erglm` (accepted to CRAN on 2026-08-08, 
  see above) lists `erplots` in `Suggests`. Checked
  with `revdepcheck::revdep_check()` against this submission's source;
  no problems found (see `revdep/cran.md`). Two further companion
  packages, `emaxnls` and `ertte`, were also checked as a courtesy but
  are GitHub-only (neither is a CRAN reverse dependency at present).
