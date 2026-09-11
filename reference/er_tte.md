# The time-to-event plotting mini-language

Create an `er_tte` specification for a Kaplan-Meier/survival-over-time
figure. This is a separate mini-grammar from
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)/[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md):
those two share an exposure-response-vs-exposure coordinate system
([`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)'s
contract is "response value at a given exposure"), whereas `er_tte()`
uses a time x-axis/survival-probability y-axis – the natural coordinate
system for a Kaplan-Meier curve, not something
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s
layers can express.

## Usage

``` r
er_tte(data, time, event, stratify_by = NULL, n_strata = 4, conf_level = 0.95)
```

## Arguments

- data:

  Data frame or tibble containing the observed data.

- time:

  Event/censoring time (unquoted expression, evaluated in `data`). Must
  be non-negative.

- event:

  Event indicator (unquoted expression, evaluated in `data`): `TRUE`/`1`
  for an event, `FALSE`/`0` for censoring.

- stratify_by:

  Optional stratification variable (unquoted, bare column name). A
  categorical variable is used as-is; a numeric variable is split into
  `n_strata` quantile bins. Defaults to `NULL` (a single, unstratified
  curve).

- n_strata:

  Number of quantile bins, when `stratify_by` is numeric. Ignored when
  `stratify_by` is `NULL` or categorical.

- conf_level:

  Confidence level for the Kaplan-Meier confidence band. Must be
  strictly between 0 and 1.

## Value

An (empty of layers) plot object of class `er_tte`, with the
Kaplan-Meier fit already computed on `object$km`.

## Details

`er_tte()` computes the (single-arm) Kaplan-Meier estimate once, via
[`survival::survfit()`](https://rdrr.io/pkg/survival/man/survfit.html),
and stores the fit plus a tidy per-event-time table (`time`, `n_risk`,
`n_event`, `n_censor`, `surv`, `lower`, `upper`) on `object$km`. Layers
added afterwards – the curve
([`er_tte_add_curve()`](https://erplots.djnavarro.net/reference/er_tte_add_curve.md)),
censoring marks
([`er_tte_add_censor()`](https://erplots.djnavarro.net/reference/er_tte_add_censor.md)),
a number-at-risk panel
([`er_tte_add_risktable()`](https://erplots.djnavarro.net/reference/er_tte_add_risktable.md)),
log-rank annotation
([`er_tte_add_pvalue()`](https://erplots.djnavarro.net/reference/er_tte_add_pvalue.md)),
and a parametric model overlay
([`er_tte_add_model()`](https://erplots.djnavarro.net/reference/er_tte_add_model.md))
– read from this shared fit rather than recomputing it (the model layer
alone reads from the caller-supplied `model` instead, via
[`er_predict_survival()`](https://erplots.djnavarro.net/reference/er_model_interface.md)).

Unlike
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)/[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md),
`time`/`event` accept arbitrary tidy-eval expressions, not just bare
column names – time-to-event data very commonly needs an inline
transform to get an event indicator (e.g. `status == 2` for a coded
status variable, or `!is.na(progression_date)`), and requiring the
caller to first
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
that column into existence would just be boilerplate. The evaluated
`time`/`event` vectors are stored as `.er_tte_time`/`.er_tte_event`
columns on `object$data`; their
[`rlang::as_label()`](https://rlang.r-lib.org/reference/as_label.html)-derived
text is kept as `object$time$label`/ `object$event$label` for display
purposes.

`event` must evaluate to a logical vector (`TRUE` = event occurred) or a
numeric vector taking only the values `0` (censored) and `1` (event) –
exactly the same binary encoding
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)
requires of a `response_type = "binary"` response.

Optional `stratify_by` splits the Kaplan-Meier estimate into one curve
per level, via
[`survival::survfit()`](https://rdrr.io/pkg/survival/man/survfit.html)'s
`~ strata` formula side – mirroring
[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md)'s
`stratify_by`: a categorical variable is used as-is; a numeric variable
is automatically split into `n_strata` quantile bins (via
[`cut_exposure_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md),
so `0`/placebo is kept in its own bin), with a message reporting that
this happened. Unlike `time`/`event`, `stratify_by` must be a bare
column name (not an arbitrary expression), matching
`exposure`/`response`/`stratify_by` elsewhere in the package.
`object$km$table` gains a `strata` column when stratified;
`object$strata` (`var`/`label`/`type`/`n_strata`) mirrors
[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md)'s own
`object$strata`.

## See also

[er_model_interface](https://erplots.djnavarro.net/reference/er_model_interface.md)

## Examples

``` r
library(survival)
lung |>
  er_tte(time, status == 2)
#> <er_tte>
#>   tte variables:
#>     - time:   time
#>     - event:  status == 2
#>   kaplan-meier fit (single-arm):
#>     - n subjects:       228
#>     - n events:         165
#>     - median survival:  310
#>   plot layers: <none>
#>   output built: no

# `lung$sex` is coded numerically (1/2); convert to a factor first, or
# a numeric `stratify_by` is quantile-binned instead of used as-is
lung |>
  transform(sex = factor(sex, labels = c("Male", "Female"))) |>
  er_tte(time, status == 2, stratify_by = sex)
#> <er_tte>
#>   tte variables:
#>     - time:   time
#>     - event:  status == 2
#>     - stratify_by: sex (discrete)
#>   kaplan-meier fit:
#>     - Male: n=138, events=112, median=270
#>     - Female: n=90, events=53, median=426
#>   plot layers: <none>
#>   output built: no
```
