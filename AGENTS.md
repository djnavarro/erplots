# AGENTS.md

## What this package is

erplots provides a fluent mini-language for building exposure-response
plots: model curves/ribbons, quantile-binned response-rate/mean
summaries, a raw-data layer, and grouped distribution panels. It is
model-agnostic: erplots never fits a model itself. Any model
implementing `er_predict()` can be visualised; implementing
`er_simulate()` and `er_summary()` additionally enables uncertainty
spaghetti plots/VPCs and summary annotations (e.g. p-values). See
`?er_model_interface`.

`er_plot()` takes a `response_type = c("auto", "binary", "continuous",
"count")` argument (auto-detected from the response column if not
given: logical or values entirely in `{0, 1}` → `"binary"`, else
`"continuous"`; `"auto"` never resolves to `"count"` -- that must be
declared explicitly), stored on `object$response$type`/
`object$response$limits`. The model curve/ribbon
(`er_plot_add_model()`) and group panel (`er_plot_add_groups()`)
layers work for any response type with no dispatch needed. The
quantile summary layer (`er_plot_add_quantiles()`) and `er_vpc_plot()`
are now fully generalised across all three response types (rate +
Clopper-Pearson for `"binary"`; mean + t-interval for `"continuous"`;
mean + exact Poisson interval for `"count"`). The data layer
(`er_plot_add_data()`, renamed from `er_plot_show_datastrip()`) also
works for any response type, with no `"continuous"`/`"count"` error path
left -- see "Planned work" below. (`er_plot_add_data()` went through two
renames: `er_plot_show_datastrip()` -> `er_plot_show_data()` -> its
current name, the latter as part of the naming-scheme review described
in "Extensibility" below.)

`er_plot_add_data()` offers two mutually exclusive structural families,
selected by which `style` function is passed in (no separate layout
argument -- see "Extensibility" below): the default, `er_style_data_overlay()`,
plots raw observations at their true `(exposure, response)` coordinates
directly on the model panel -- a single, response-type-agnostic builder
with a small vertical jitter applied only for binary responses, and a
`color` aesthetic that's always strata (sharing the base plot's own
legend) rather than the response value. `er_style_data_boxjitter()`
(binary-response only) is the older panel-based design (`object$part$data`)
-- a boxplot of the exposure values with jittered points layered on top,
in upper (responders)/lower (non-responders) panels, showing the exposure
*distribution* conditional on response rather than just raw points; fill
means strata for the box and color means strata for the points, mirroring
the model layer's ribbon/line split. The two structural families live in
separate `object$part` slots (`overlay` vs. `data`); passing a builder
from one family clears the other slot. There is no built-in
`"panel"`-layout builder for a continuous/count response -- the older
`build_data_jitter()` (binary) and `build_data_color()` (continuous/count)
were both removed once review found neither earned its keep alongside
`er_style_data_overlay()`/`er_style_data_boxjitter()` (see PLAN.md); a custom
`"panel"`-layout builder for continuous/count remains possible via
`er_style_tag()`, since `.part_data()`'s response-type dispatch was left in
place.

`er_style_data_hex()` is a second `"overlay"`-layout data builder alongside
`er_style_data_overlay()`: a `geom_hex()`-based 2D density, for when N is
large enough that raw points overplot into an unreadable smear (most
useful for continuous/count responses, whose y-values are spread out
rather than piled at 0/1). It requires the `hexbin` package (`Suggests`,
guarded with `rlang::check_installed()`). Because `geom_hex()`'s `fill`
aesthetic already encodes bin density, there's no channel left for
`color = strata`; when stratified, all strata are pooled into a single
hex-binned density (with an `rlang::inform()` message noting this)
rather than partially or misleadingly encoding strata. `er_style_data_hex()`
tags itself via `er_style_tag(style, layout = "overlay", fill_role =
"density")` -- both pieces of builder metadata set in the one call
(mirroring `er_style_group_histogram()`'s `y_role` tag) -- which
`.polish_labels()` reads (via the internal `.style_fill_role()`
accessor) to title the base
plot's `fill` legend "Count" rather than the strata label it uses by
default. This only matters when `er_style_data_hex()`'s `fill` is the sole
`fill` mapping on the base plot: a stratified `er_style_model_ribbonline()`
also maps `fill = strata` (discrete) on its ribbon, and ggplot2 can't
reconcile that with `er_style_data_hex()`'s continuous density `fill` on
the same aesthetic -- it errors ("Continuous value supplied to a
discrete scale") rather than silently misrendering. This is a genuine
ggplot2 limitation, not fixable from inside the builder; pair a
stratified `er_style_data_hex()` plot with a model builder that doesn't map
`fill`, e.g. `er_style_model_line()` (color only).

The group panel layer (`er_plot_add_groups()`) has a third built-in
builder, `er_style_group_histogram()`, alongside `er_style_group_boxplot()`
(the default) and `er_style_group_violin()`. Unlike those two -- which put
the group variable itself on the y-axis (`y = lvl`, one categorical row
per level) -- a histogram needs its y-axis free for counts, so
`er_style_group_histogram()` puts the group levels on facet strips instead
(`facet_grid(rows = vars(lvl), switch = "y")`) and tags itself via
`er_style_tag(style, y_role = "count")`, the same consolidated
setter the data layer's `layout`/`fill_role` tags go through.
`.polish_labels()` reads that tag (via the internal `.style_y_role()`
accessor) to title the y-axis "Count" rather than the group variable's
own label (which is what it still uses for `er_style_group_boxplot()`/
`er_style_group_violin()`, where the group variable *is* the y-axis);
builders that don't set the tag keep that old, categorical-label
behaviour, so this is opt-in rather than a breaking requirement like
`layout` is. Putting the group levels on facet strips also surfaced a
second, unrelated quirk: ggplot2's default text angle for a left-hand
strip (`switch = "y"`) is rotated 90 degrees, sized to fit the (short)
row height rather than the (longer) available width, so long `lvl`
labels like `"Placebo (N=100)"` were getting clipped vertically.
`er_style_group_histogram()` works around this with `theme(strip.text.y.left
= element_text(angle = 0, hjust = 0))`, rotating the text back to
horizontal so the strip auto-expands to fit the full label.

The companion package [erglm](https://github.com/djnavarro/erglm)
(formerly `erlr`) fits GLM-based exposure-response models and implements
this package's generics for its model objects. erplots has no hard
dependency on erglm -- it's listed only under `Suggests`, for
examples/tests/vignettes. Since erglm is GitHub-only (not on CRAN),
`DESCRIPTION` also declares `Remotes: djnavarro/erglm` so CI can resolve
it. Key API points to remember: the example dataset is
`erglm::erglm_data` (not `erlr::lr_data`), and models are fit with
`erglm::erglm_model(formula, data, family = ...)` (family is explicit).
erglm now genuinely supports `binomial`/`poisson`/`gaussian`/`Gamma`
families, with matching binary (`ae1`/`ae2`), count (`ae_count`), and
continuous (`biomarker_change`, `ae_duration`) response columns in
`erglm_data` -- not just binomial. Models are simulated with
`erglm::erglm_vpc_sim()`; the `er_predict()`/`er_simulate()`/
`er_summary()` methods erglm registers for its model objects are correct
for all four families, so no erplots-side changes are needed there.

## Naming scheme

A naming-scheme review (prompted by the `build_*` prefix reading as
unintuitive, and the CI helpers using an inconsistent suffix) settled on
four families, each with its own prefix, documented here so future
additions stay consistent:

- **`er_plot_add_*()`** -- the pipeline verbs that add a layer to an
  `er_plot` spec (`er_plot_add_model()`, `er_plot_add_quantiles()`,
  `er_plot_add_data()`, `er_plot_add_groups()`). Renamed from
  `er_plot_show_*()`: "add" more accurately signals "append to the spec"
  than "show" does, since nothing is actually drawn until
  `er_plot_build()`/`print()`/`plot()`. `er_plot()`, `er_plot_theme()`,
  and `er_plot_build()` keep the bare `er_plot_*` name -- they aren't
  layer-adders.
- **`er_style_*()`** -- the pluggable partial-builder functions (was
  `build_*()`, then `er_builder_*()` -- see the rename below), e.g.
  `er_style_model_ribbonline()`, `er_style_data_overlay()`,
  `er_style_quantile_errorbar()`, `er_style_quantile_errorbar_vlines()`,
  `er_style_group_boxplot()`, `er_style_summary_pvalue()`. The
  `er_`-namespaced shared prefix groups every builder together
  (discoverable via autocomplete/`library(help = "erplots")`) while the
  layer name stays the second token, so `er_style_data_*`,
  `er_style_model_*`, etc. are still grep-able as families. The
  builder-metadata helper(s) a custom builder can tag itself with also
  moved under this prefix -- originally three separate setters
  (`er_layout()`/`er_data_fill`/`er_group_y`), later consolidated into
  one function, `er_style_tag()`, with `layout`/`fill_role`/`y_role`/
  `layer` as independent optional arguments (see "Extensibility" below).
- **`ci_*()`** -- the confidence-interval helpers (was a `*_interval`
  suffix): `ci_clopper_pearson()` (was `clopper_pearson_interval()`),
  `ci_t()` (was `t_interval()`), `ci_poisson()` (was
  `poisson_interval()`). Chosen over `confint_*()` to avoid echoing
  `stats::confint()`'s very different calling convention.
- Internal (dot-prefixed) helpers were mostly left alone: `.part_*()`,
  `.polish_*()`, `.get_*()`/`.set_*()` keep their existing names, and the
  internal `.build_*()` assembly helpers in `R/er-plot-build.R` (e.g.
  `.build_model_geoms()`) no longer risk being confused with the public
  builder family now that the public prefix is `er_style_*` rather
  than `build_*`.

**The `builder`/`er_builder_*()` -> `style`/`er_style_*()` rename.**
A later review revisited the argument name users actually type at the
call site -- `builder` (and `summary_builder`) -- as developer-facing
vocabulary ("which function builds this layer") rather than
plot-design vocabulary ("what visual idiom do I want"). `style` reads
more naturally for a user choosing between, say,
`er_style_data_overlay()` and `er_style_data_boxjitter()`. This
surfaced a genuine naming collision, not just a cosmetic one: every
builder's own signature already had a *different* `style` parameter,
carrying theming state (`theme_base()`, `draw_key`, `format_percent()`,
etc.) sourced from `object$style` and set via `er_plot_style()`. Reusing
`style` for builder-selection would have meant three unrelated things
sharing one name (`object$style`, the builder-signature `style`
parameter, and the new builder-selection argument). This was resolved
in two phases rather than picking a different word for the new
argument, since `style` was judged the best fit for the user-facing
concept and the *existing* internal usage was the one that was
arguably mis-named:

1. The existing theming concept was renamed out of the way first:
   `object$style` -> `object$theme`, `er_plot_style()` ->
   `er_plot_theme()` (still a no-op placeholder), and every builder's
   own last parameter -- `function(data, config, stratify, exposure,
   response, strata, style)` -- was renamed to `theme`.
2. Only then was `style` applied to builder selection: the `builder`/
   `summary_builder` arguments on all four `er_plot_add_*()` functions
   became `style`/`summary_style`, the entire `er_builder_*()` function
   family (all 18 built-ins, across model/summary/quantile/data/group)
   became `er_style_*()`, `er_builder_tag()` became `er_style_tag()`,
   and its attributes/internal readers followed suit
   (`"er_builder_layout"` -> `"er_style_layout"`, `.builder_layout()` ->
   `.style_layout()`, `.check_builder_layer()` -> `.check_style_layer()`,
   etc.).

This was a straight rename with no deprecation shims (as with every
other rename in this section -- see the no-shim rationale further
below), applied across `R/`, `tests/testthat/`, and
`vignettes/articles/`, including renaming the builder source/test files
themselves (`R/er-plot-builder*.R` -> `R/er-plot-style*.R`,
`tests/testthat/test-er-plot-builder-*.R` ->
`tests/testthat/test-er-plot-style-*.R`). One deliberate scoping choice:
"builder" was *not* purged as an English word -- prose that just
describes "a function you write to build geoms" (e.g. "a custom
builder", "the builder signature", the `?er_style` topic's own
"Writing your own builder" section heading) was left alone, since it
reads naturally and isn't an identifier. Only actual API symbols
(function names, argument names, exported helpers, attributes) were
renamed. Verified clean after the rename: `devtools::check()` (0
errors/warnings/notes), `devtools::test()` (490 passing), and a full
render of all five `vignettes/articles/*.Rmd` files via
`rmarkdown::render()`.

## Extensibility: `style` is the sole mechanism (no separate layout argument)

Every `er_plot_add_*()` function (`er_plot_add_model()`,
`er_plot_add_quantiles()`, `er_plot_add_data()`, `er_plot_add_groups()`)
takes a `style` argument (`er_plot_add_model()` additionally takes
`summary_style`) that defaults to one built-in `er_style_*()` function
(`er_style_model_ribbonline()`, `er_style_quantile_errorbar()`,
`er_style_data_overlay()`, `er_style_group_boxplot()`; `summary_style`
defaults to `er_style_summary_pvalue()`) and can be set to any other
function matching the standard `er_style_*()` signature
(`function(data, config, stratify, exposure, response, strata, theme)`)
-- built-in (e.g. `er_style_model_spaghetti()`, `er_style_model_line()`,
`er_style_quantile_pointrange()`, `er_style_data_boxjitter()`,
`er_style_data_hex()`, `er_style_group_violin()`,
`er_style_group_histogram()`) or
fully custom (e.g. a `geom_crossbar()`-based quantile builder, or a
density/histogram-based data-layer builder instead of a scatter). There
used to be a separate `style` string argument alongside `builder` (back
when the builder-selection argument was still called `builder` -- see
the rename above), but it was redundant for three of the four layers
(pure sugar for choosing a default builder function) and was removed;
the builder-selection argument (now itself named `style`) is the only
mechanism, documented in `?er_style`'s "Writing your own builder"
section.

For the data layer specifically, the one thing the old string-based
`style` argument used to do that wasn't just builder selection --
picking the *structural* family a builder is slotted into (single call
merged into the main panel, vs. one-or-more panels stacked below the
base plot) -- is declared *on the builder function itself* via
`er_style_tag(style, layout = c("overlay", "panel"))`, an exported
helper that attaches an `"er_style_layout"` attribute (one of four
independent, optional attributes `er_style_tag()` can set in a single
call -- see below). `er_plot_add_data()` reads this tag off
whatever `style` it's given (internal `.style_layout()`) to decide
whether to route through `.part_overlay()` or `.part_data()`. Both
built-in data builders already carry this tag (`er_style_data_overlay()`:
`"overlay"`; `er_style_data_boxjitter()`: `"panel"`); a
custom data-layer builder that omits it errors immediately and
informatively, rather than silently landing in the wrong structural
slot. This was chosen over encoding layout in a builder's *return
value* because `.part_overlay()`/`.part_data()` build different
`config` shapes before any builder runs, so the layout has to be
knowable without calling the builder -- see PLAN.md's "removing
`style`, making `builder` the sole mechanism" section (predating the
`builder` -> `style` rename above, so read "`builder`" there as what's
now called `style`) for the full rationale.

`er_style_tag(style, layout = NULL, fill_role = NULL, y_role =
NULL, layer = NULL)` is a single consolidated setter for all four
pieces of builder self-declared metadata (`layout`/`fill_role`/`y_role`
were originally three separate functions -- see "Naming scheme" above
and PLAN.md's "consolidating the builder-metadata setters" section for
why they were merged; `layer` was added afterward). Each argument is
independent and optional (aside from `layout` being mandatory for a
data-layer builder specifically); a builder needing more than one tag
sets them in one call, e.g. `er_style_tag(fn, layout = "overlay",
fill_role = "density", layer = "data")`, which is close to what
`er_style_data_hex()` does. The full, worked-example version of "how
to write a custom builder" (what `config` contains per layer, and how
to use `er_style_tag()`'s four arguments) lives in its own article,
`vignettes/articles/extending.Rmd` -- see "Vignette structure" below.

`layer` (one of `"model"`, `"summary"`, `"quantile"`, `"data"`,
`"group"`) is checked, not just stored: every `er_plot_add_*()`
function (`er_plot_add_model()` checks `style` against `"model"` and
`summary_style` against `"summary"`; `er_plot_add_quantiles()`
against `"quantile"`; `er_plot_add_data()` against `"data"`;
`er_plot_add_groups()` against `"group"`) reads a builder's `layer` tag,
if it has one (via the internal `.check_style_layer()` helper), and
errors immediately, naming both the tagged and actual layer, if they
disagree -- e.g. passing `er_style_quantile_errorbar` to
`er_plot_add_data()` errors rather than calling it with the data
layer's `config` shape. Unlike `layout`, `layer` is entirely optional:
an untagged builder (including every custom builder written before
`layer` existed) is simply never checked. All built-in builders across
all five layers now carry this tag.

## Quantile layer builders

The quantile layer (`er_plot_add_quantiles()`) has two base builders,
`er_style_quantile_errorbar()` (point + error bar, the default) and
`er_style_quantile_pointrange()`, plus a `_vlines` variant of each --
`er_style_quantile_errorbar_vlines()`/
`er_style_quantile_pointrange_vlines()` -- that additionally draws a
dotted `geom_vline()` at every *interior* quantile-bin boundary (i.e.
every cutpoint except the exposure variable's overall min/max), a
common real-world exposure-response reporting idiom. The `_vlines`
variants are thin wrappers around their base builder (prepending a
single vline geom to the base builder's own return value), not
independent copies, so they can't drift out of sync with it.
`cut_exposure_quantile()` attaches the `n + 1` quantile cutpoints it
computes (excluding placebo) as a `"breaks"` attribute on its returned
factor; `.part_quantile()` reads this into `config$breaks`, which the
`_vlines` builders (via the internal `.quantile_boundary_vlines()`
helper) consume. `er_builder_quantile_bar()` (bar + error bar) was
removed -- on review it wasn't an idiom that shows up in real
exposure-response reporting, unlike the `_vlines` pattern -- with no
deprecation shim (see "Naming scheme" above for why erplots doesn't use
shims). All four quantile builders are tagged
`er_style_tag(fn, layer = "quantile")`.

## Planned work

See [PLAN.md](PLAN.md) for a condensed historical record of completed
design work (rationale kept, implementation narrative trimmed) and a
short "Open / deferred" list at the end. Everything scoped so far is
done: the binary→continuous/count response generalisation (response-type
detection/declaration, the quantile summary layer, `er_vpc_plot()`), the
data layer's continuous/count-response redesign (`build_data_color()`
and `er_style_data_overlay()`, the latter now the default), the mini-language
documentation review (singleton/additive layer semantics, the
stratification color/facet precedence rule, `?er_style`,
`vignettes/articles/design.Rmd`), formalising the
`builder`/`summary_builder` escape hatch (since renamed to
`style`/`summary_style` -- see "Naming scheme" above), removing the old
string-based `style` argument entirely in favor of the builder-selection
argument alone, with the data layer's structural distinction moved onto
the builder function itself via `er_style_tag()`
(see "Extensibility" above) -- including what's now `vignettes/articles/
extending.Rmd` (originally a section within `design.Rmd`; see "Vignette
structure" below), which walks through a runnable custom
quantile builder -- and then, on review, removing `build_data_jitter()`/
`build_data_color()` in favor of `er_style_data_boxjitter()` (see
"Extensibility" above and PLAN.md), since neither of the removed
builders earned its keep once `er_style_data_overlay()` existed as the
default. The only genuinely open items are deferred, not scheduled --
see PLAN.md's "Open / deferred" section (an additive `model` layer for
overlaying two fitted curves; whether a future continuous/count
`"panel"`-layout builder should use a deliberately chosen continuous
color scale instead of ggplot2's default gradient, and whether it
should be a quantile-binned rug instead of a color-encoded scatter --
both deferred along with `build_data_color()`'s removal). A naming-scheme
review renamed the pipeline verbs (`er_plot_show_*()` ->
`er_plot_add_*()`), the partial builders and their metadata helpers
(`build_*()` -> `er_builder_*()`; `er_layout()`/`er_data_fill`/`er_group_y`
-> `er_builder_layout()`/`er_builder_fill_role()`/`er_builder_y_role()`),
and the CI helpers (`*_interval()` -> `ci_*()`) -- see "Naming scheme"
above. This was a straight rename with no deprecation shims (the
package is GitHub-only/pre-CRAN, so there's no installed user base to
break silently). The plot-grammar article's "Extending
erplots" section was split out into its own article -- see "Vignette
structure" below. Those three builder-metadata setters
were themselves consolidated into a single `er_builder_tag(builder,
layout = NULL, fill_role = NULL, y_role = NULL)`, since each attribute
is independent and optional and a builder needing more than one (e.g.
`er_builder_data_hex()`, which needs `layout` and `fill_role`) had to
chain two calls under the old design -- see "Extensibility" above and
PLAN.md's "consolidating the builder-metadata setters" section. The
optional `layer` attribute discussed alongside that
consolidation (and initially deferred) was implemented: every built-in
builder is now tagged with the layer it belongs to, and every
`er_plot_add_*()` function checks a builder's `layer` tag against the
layer it was actually passed to, if the tag is present -- see
"Extensibility" above and PLAN.md's "adding the optional `layer`
attribute" section. Most recently, a second naming-scheme review
renamed the user-facing builder-selection argument (and, to avoid a
collision with erplots' existing theming state, the theming state
itself first): `object$style`/`er_plot_style()`/the builder-signature
`style` parameter became `object$theme`/`er_plot_theme()`/`theme`, then
`builder`/`summary_builder` and the entire `er_builder_*()` family
became `style`/`summary_style`/`er_style_*()` -- see "Naming scheme"
above for the full rationale and two-phase sequencing.

## Vignette structure

`vignettes/articles/` (pkgdown-only, not shipped -- see "Development
workflow" below) holds five articles: `plot-binary.Rmd`,
`plot-continuous.Rmd`, and `plot-count.Rmd` (worked examples of each
layer, one per response type; binary is the most detailed, the other
two link back to it for the response-type-agnostic model/group
components); `design.Rmd` ("The plotting grammar" -- the singleton/
additive layer distinction, the stratification color/facet precedence
rule, and the response-type dispatch table); and `extending.Rmd`
("Extending erplots: writing your own builder"). The last one used to
be a section inside `design.Rmd`, but was split out into its own
article because it needed to grow -- the original version's illustrative
`build_quantile_crossbar()` example didn't explain what `config` (its
second argument) actually *was*, so `extending.Rmd` now leads with a
table of what each `.part_*()` function's `config` contains (e.g.
`config$summary`'s columns for the quantile layer), inspects it
interactively before writing the crossbar builder, and then adds a
section on `er_style_tag()`'s four independent arguments
(`layout`/`fill_role`/`y_role`/`layer` -- `layout` mandatory for
data-layer builders, the other three optional) with a runnable example
of each, including the built-in
`er_style_data_hex()`/`er_style_group_histogram()` as worked
illustrations of `fill_role`/`y_role` respectively, a custom
`geom_density2d()`-based data builder as a worked illustration of
`layout`, and a runnable wrong-layer error (a quantile builder passed
to `er_plot_add_data()`) as a worked illustration of `layer`.
`design.Rmd`'s own "Extending erplots" section is now just a short
pointer into `extending.Rmd`. `_pkgdown.yml`'s `articles` list was
updated to include `articles/extending` after `articles/design`. Keep
this split in mind if `design.Rmd`'s grammar changes in a way that
affects builders (e.g. a new builder-metadata helper, or a change to
what a `.part_*()` function puts in `config`) -- that detail belongs in
`extending.Rmd`, not back in `design.Rmd`. All five articles were
re-rendered end-to-end via `rmarkdown::render()` after the
`style`/`er_style_*()` rename (see "Naming scheme" above) with no
errors and no leftover old-identifier references in the output.

## Structure

- `R/er-generics.R` -- the model interface: `er_predict()`,
  `er_simulate()`, `er_summary()` generics and their default methods.
- `R/er-plot-api.R` -- the public plot-building API: `er_plot()`,
  `er_plot_add_model()`, `er_plot_add_quantiles()`,
  `er_plot_add_data()`, `er_plot_add_groups()`, `er_plot_build()`,
  plus `print`/`plot` methods for the `er_plot` S3 class, and (also
  defined here, not in a separate file) `er_style_tag()` and its
  internal attribute readers (`.style_layout()`, `.style_fill_role()`,
  `.style_y_role()`, `.style_layer()`, `.check_style_layer()`). Each
  layer function (except `er_plot()` itself) has its own dedicated Rd
  topic (no shared `@rdname`).
- `R/er-plot-part.R` -- internal `.part_*()` functions that assemble the
  configuration for each plot component (this is where `er_predict()` /
  `er_simulate()` / `er_summary()` get called on the user-supplied model).
- `R/er-plot-build.R`, `R/er-plot-compose.R` -- internal plotting/layout
  machinery that turns parts into ggplot2 objects and composes them with
  patchwork.
- `R/er-plot-style-*.R` -- the pluggable `er_style_*()` partial builders
  (one file per component: `er-plot-style-model.R`,
  `er-plot-style-summary.R`, `er-plot-style-quantile.R`,
  `er-plot-style-data.R`, `er-plot-style-group.R`), plus
  `R/er-plot-style.R` (the shared-interface doc page, `?er_style`, with
  no builder functions of its own). See `?er_style` for the interface
  these builders share.
- `R/er-vpc.R` -- `er_vpc_plot()`, a model-agnostic VPC-style plot
  operating on plain observed/simulated data frames.
- `R/utils-helpers.R`, `R/utils-global.R` -- small internal helpers
  (including the binary-response-only `ci_clopper_pearson()`,
  `ci_t()`, `ci_poisson()`, `cut_quantile()`,
  `cut_exposure_quantile()`, and the response-type detector
  `.detect_response_type()`) and `globalVariables()` declarations for
  NSE.

## Development workflow

- Document with roxygen2 (`devtools::document()`); Markdown roxygen is
  enabled (`Roxygen: list(markdown = TRUE)`).
- Run tests with `devtools::test()`; full checks with `devtools::check()`.
  The package should check cleanly (0 errors/warnings/notes).
- Tests live in `tests/testthat/`. Most test files need `erglm` (a
  `Suggests` dependency, used only to fit example models) and are guarded
  with `skip_if_not_installed("erglm")`; shared test fixtures (including
  `er_test_mod_gaussian`, a continuous-response fixture) live in
  `tests/testthat/helper-data.R`. Builder-specific tests live in
  `tests/testthat/test-er-plot-style-{model,summary,quantile,data,group}.R`
  (renamed from `test-er-plot-builder-*.R` alongside the source files).
- Vignettes/articles live in `vignettes/articles/` and are built for the
  pkgdown site, not shipped with the package (see `.Rbuildignore`).

## Conventions

- Use the base R pipe (`|>`), not the magrittr pipe.
- Follow the existing tidyverse-style conventions (dplyr/tibble/rlang/
  ggplot2/patchwork) already used throughout.
- Naming families (see "Naming scheme" above for the full rationale):
  pipeline layer-adders are `er_plot_add_*()` (verbs); partial builders
  are `er_style_*()` (noun phrases naming the visual idiom, with the
  layer name as the second token), selected via each layer-adder's
  `style`/`summary_style` argument; confidence-interval helpers are
  `ci_*()` (noun phrases naming the statistical method); internal
  helpers are prefixed with `.`. "Builder" remains fine as ordinary
  English prose for "a function you write to build geoms" -- only the
  actual API symbols (function/argument names, exported helpers,
  attributes) use the `style` vocabulary.
- Never call a model-fitting function from this package. If a plot
  component needs something from the model, add or extend a generic in
  `R/er-generics.R` instead of reaching into model internals.
