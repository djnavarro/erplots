# CRAN submission comments

## Summary

This is a new package, first submission to CRAN.

`erplots` provides a fluent mini-language for building exposure-response
plots (model curves/ribbons, quantile-binned summaries, raw-data layers,
grouped distribution panels, and a visual predictive check grammar) from
observed data and a fitted exposure-response model. It is deliberately
model-agnostic: it never fits a model itself, and any model implementing
a small S3 interface (`er_predict()`, optionally `er_simulate()` and
`er_summary()`) can be visualised with it.

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
    be installed regardless of the "no suggests" condition -- this is
    expected for any package with a `VignetteBuilder` and is not a
    package bug (every code path that touches an optional dependency
    is separately guarded with `requireNamespace()`/
    `skip_if_not_installed()`, which is what this platform is actually
    checking).
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

## Downstream companion packages and `Suggests`

`erplots` is designed to be used alongside separate model-fitting
packages that implement its S3 interface; none of these are required to
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

* **`emaxnls`** (Emax/sigmoidal dose-response models via nonlinear least
  squares) is *not* listed as a dependency in this submission, even
  though it is a long-standing companion package and is itself already
  on CRAN (version 0.1.1, published 2026-06-30). That CRAN release
  predates the `erplots` integration: it registers no
  `er_predict()`/`er_simulate()`/`er_summary()` methods, so pairing it
  with `erplots` today would silently do nothing. The integration exists
  only in `emaxnls`'s unreleased development version. Rather than add a
  `Suggests` entry with a `Remotes:`-only version floor pointing at an
  unreleased dependency, we have deferred this pairing entirely: no code
  path, example, or test in this submission references `emaxnls`. We
  plan a small 0.1.1 follow-up release re-adding `emaxnls` to `Suggests`
  once a CRAN release of `emaxnls` itself includes the registered
  methods.

## Other notes

* Two vignettes ship with the package (`vignettes/erplots.Rmd` plus the
  vignette index); a larger set of worked-example articles lives in
  `vignettes/articles/` for the pkgdown site only and is excluded from
  the build via `.Rbuildignore`, so it is not part of this submission.
* This is a first submission, so there are no reverse dependencies to
  check.
