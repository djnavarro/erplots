# CRAN submission comments

## Summary

This is a patch release (0.2.1), fixing the `WARN` currently reported on
the CRAN checks page for 0.2.0 (`Check: for unstated dependencies in
'tests', '::' or ':::' import not declared from: 'ertte'`).

`ertte` was deliberately dropped from `Suggests` before the 0.2.0
submission because it wasn't yet on CRAN at the time (see that release's
own `cran-comments.md`), but `tests/testthat/test-tte-model-sync.R` --
a `skip_if_not_installed("ertte")`-gated integration test file -- calls
`ertte::` directly. That was silently fine while `ertte` was GitHub-only
and absent from CRAN's check machines; now that `ertte` 0.1.1 is on CRAN,
their machines install and run it, surfacing the undeclared dependency.
This release re-adds `ertte` to `Suggests` (no `Remotes:` entry needed,
since it's on CRAN) -- no other code changes.

## Test environments

* Local: Ubuntu 24.04, R 4.6.1 (`R CMD check --as-cran`), with `ertte`
  0.1.0 installed -- confirms `tests/testthat/test-tte-model-sync.R`
  passes against a real `ertte` fit now that the dependency is declared.
* GitHub Actions: ubuntu-latest (R-devel/release/oldrel-1),
  windows-latest (R-release), macos-latest/arm64 (R-release)
* win-builder (R-devel, R-release): `Status: OK`, 0 errors/warnings/notes.

## R CMD check results

0 errors | 0 warnings | 0 notes.

## Downstream dependencies

`erglm` and `emaxnls` depend on `erplots` via `Suggests`; `ertte` depends
on `erplots` via `Suggests` too, and `erplots` now depends on `ertte` via
`Suggests` in the same direction (both sides declared, no cycle issue
since neither is a hard dependency). `revdepcheck::revdep_check()`
against this submission's source: 0 new problems for all three.

Thank you for your consideration.

Kind regards,
Danielle Navarro
