# CRAN submission comments

## New package summary

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

## Resubmission summary

This is a resubmission, responding to the reviewer feedback on the 0.1.1
submission. The comments below summarise each of the issues raised in the
review process, and the steps taken to address them:

* The review flagged that the `Description` field in DESCRIPTION had
  incorrectly placed single quotes around function names. This has now
  been corrected: quoting is now reserved for package/software/API names
  only, per the reviewer's note.

* The second query raised in the review was whether the package should
  include a DOI or other link to a methodological paper that outlines
  the theory underpinning the package. At this stage there is no published
  write up of the mini-grammar used in this package apart from its own
  documentation and pkgdown site (already linked in the DESCRIPTION file),
  so there is no link that can be added here.

* I have investigated the reported `Warning: Examples in comments in:
  er_model_interface.Rd` warning that appeared during CRAN review. The 
  `R/er-generics.R` file is the source for this Rd page: it has no 
  `@examples` block and the built `.Rd` has no `\examples` section, and 
  I was unable to reproduce the warning locally via `R CMD check --as-cran`. 
  I also revisited the exact commit submitted as 0.1.1 and confirmed that 
  rebuilding the documentation against it produced no changes, so the 
  documentation itself was not out of date for that commit. I can't fully 
  rule out, though, that the tarball I actually uploaded was built before 
  running `roxygenize()` on a still-in-progress version of the 
  documentation -- if that's what happened, apologies for the oversight. 
  In any case, I've rerun `roxygenize()` on this submission as 
  suggested in the CRAN review, and confirmed every exported topic carries 
  a `@returns`/`\value` tag. The only exception to this is `erplots_data.Rd`, 
  which is a data page and, as I understand it from reading the CRAN 
  cookbook, does not require one. My hope is that this addresses the issue.
  Naturally, I am happy to investigate further if the issue reoccurs.

* I have removed a hard-coded RNG seed (a literal `1234L` that was 
  accidentally retained in `R/er-plot-layer.R`). The use of RNG seeds is 
  now opt-in only: a caller can pass `seed = <value>` through the dots 
  in `er_plot_add_data()`; with no `seed` supplied (the default), no seed
  management happens at all, and jitter differs from one call to the
  next, like any other jittered geom.

* Related to the point above, I've also swept the rest of the package for 
  other RNG seed usage while fixing the above, and found an additional 
  inconsistency: the jittered builders for `er_plot_add_groups()` previously
  drew their jitter with no seed control at all (not hard-coded, just
  unseedable). This has also been corrected: the same opt-in-only pattern
  is used for consistency. As consequence `withr` has now moved from 
  `Suggests` to `Imports` (previously only used in tests). 

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
