# CRAN submission comments

## Summary

This is a feature release (0.2.0), following 0.1.2 (published
2026-09-09). The main addition is `er_tte()`, a third mini-grammar
(alongside the existing `er_plot()`/`er_vpc()`) for Kaplan-Meier/
survival-over-time figures, and a matching `er_predict_survival()`
model-interface generic. It also includes several pre-1.0 breaking
renames and bug fixes. See `NEWS.md` for the complete list.

## Suggests

`erglm` and `emaxnls` (optional companion model-fitting packages) are
both now on CRAN, so no `Remotes:` entry is needed for either. `ertte`
(also GitHub-only) was added to `Suggests` mid-cycle but has been
removed again before this submission, so this package has no
`Remotes:` field and no GitHub-only `Suggests` dependency at all.

## Test environments

* Local: Ubuntu 24.04, R 4.6.1 (`R CMD check --as-cran`)
* GitHub Actions: ubuntu-latest (R-devel/release/oldrel-1),
  windows-latest (R-release), macos-latest/arm64 (R-release)
* R-hub (<https://github.com/djnavarro/erplots/actions/runs/37194834347>):
  windows, ubuntu-clang, ubuntu-next, donttest -- all `Status: OK`.
  `nosuggests` reports 1 error re-building the vignette, because that
  requires `knitr`/`rmarkdown`, which the platform deliberately omits
  along with the rest of `Suggests` -- expected for any package with a
  `VignetteBuilder`, not a package bug.
* win-builder (R-devel, R-release) and mac-builder (R-release,
  R-devel): all four `Status: OK`, 0 errors/warnings/notes.

## R CMD check results

0 errors | 0 warnings | 0 notes, except the expected `nosuggests` case
above.

## Downstream dependencies

`erglm` and `emaxnls` depend on `erplots` via `Suggests` and are both
on CRAN (genuine reverse dependencies); `ertte` also Suggests
`erplots` but is GitHub-only, checked as a courtesy.
`revdepcheck::revdep_check()` against this submission's source: 0 new
problems for all three.

Thank you for your consideration.

Kind regards,
Danielle Navarro
