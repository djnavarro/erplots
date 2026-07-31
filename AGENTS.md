# AGENTS.md

## What this package is

erplots provides a fluent mini-language for building exposure-response
plots: model curves/ribbons, a summary annotation, quantile-binned
response-rate/mean summaries, a raw-data layer, and grouped distribution
panels. It is model-agnostic: erplots never fits a model itself. Any
model implementing `er_predict()` can be visualised; implementing
`er_simulate()` and `er_summary()` additionally enables uncertainty
spaghetti plots/VPCs and model-derived summary annotations (e.g.
p-values, via `er_plot_add_summary()` -- see "The summary layer is
independent of the model layer" below). See `?er_model_interface`.

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
`er_style_tag()`, since `.layer_data()`'s response-type dispatch was left in
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
`erglm_data` -- not just binomial. The preferred way to build a VPC is
now `er_vpc_plot(model = <erglm model>)`, going through
`er_simulate()`'s `sim_resp` extension -- see "`er_vpc_plot()` and the
`sim_resp` extension to `er_simulate()`" below. `erglm::erglm_vpc_sim()`
(the older, bespoke helper this superseded) has since actually been
removed from erglm, so no erplots-side docs, vignettes, examples, or
tests reference it any longer.

A second, independent companion package,
[emaxnls](https://github.com/djnavarro/emaxnls), fits Emax (sigmoidal
dose-response) models via nonlinear least squares and likewise
registers `er_predict()`/`er_simulate()`/`er_summary()` for its own
model classes -- confirming the model interface generalises to a
second, unrelated model-fitting package rather than being implicitly
shaped around erglm. Same posture as erglm: `Suggests`-only (no hard
dependency), with a matching `Remotes: djnavarro/emaxnls` entry in
`DESCRIPTION` since it's also GitHub-only. `emax_nls()` fits continuous
responses; `emax_logistic()` fits binary responses but returns an
object of class `c("emaxlogistic", "emaxnls")`, so it dispatches to the
same `er_predict.emaxnls()`/`er_simulate.emaxnls()`/
`er_summary.emaxnls()` methods via plain S3 inheritance (there's no
separate `.emaxlogistic` method) -- those methods branch internally to
keep predictions in `[0, 1]` and report `r_squared = NA` (rather than a
meaningless value) in `er_summary()`'s `glance` when called on an
`emaxlogistic` object. emaxnls doesn't support count responses at all,
so there's no dispatch to verify there. `er_summary.emaxnls()` always
returns `p_value = NULL` (an Emax model has no single privileged
coefficient to headline) and instead populates `coefficients` (one row
per `E0`/`Emax`/`logEC50` parameter) and `glance`, so
`er_style_summary_coefficients()` is the natural summary builder for
emaxnls models rather than the default `er_style_summary_pvalue()`. The
example dataset is `emaxnls::emax_df`
(continuous response `rsp_1`, binary response `rsp_2`, exposure
`exp_1`). A worked example using `emax_nls()` lives in
`vignettes/articles/plot-continuous.Rmd`'s "A second model package:
emaxnls" section (with a note on `emax_logistic()`'s binary-response
dispatch, cross-referencing `plot-binary.Rmd` rather than duplicating a
full binary example); no equivalent worked example was added to
`plot-binary.Rmd` itself.

## `er_plot_theme()`: implemented (was a no-op placeholder)

`er_plot_theme()` used to be a two-line stub (`function(object, labels)
{ return(object) }`) documented as "not yet implemented". It's now a
working interface for the styling knobs a ggplot2 user would expect to
control -- labels, plot-level title/subtitle/caption, axis limits, the
overall visual theme, the discrete color/fill palette used for
stratification, value formatters, the legend key glyph, and relative
panel heights -- without touching which variable is mapped to which
aesthetic (that's still controlled by a layer's `style`/`er_style_tag()`,
not this function).

**Signature and semantics.** All arguments are flat (not grouped into
nested lists like `labels = list(...)`, matching every other
`er_plot_add_*()` function) and default to `NULL`, meaning "leave
whatever was set before unchanged" -- so `er_plot_theme()` can be called
more than once on the same object, each call only touching the arguments
it actually supplies (the same accumulate-by-default behaviour as
`ggplot2::theme()`'s own merging). There is no way to reset a field back
to its `er_plot()` default other than re-supplying that default's value
explicitly. Each argument is validated by a small dedicated helper
(`.check_theme_string()`, `.check_theme_limits()`, `.check_theme_class()`,
`.check_theme_function()`, `.check_theme_number()`, all `@noRd` in
`R/er-plot-api.R`) before being written:

- `xlab`/`ylab`/`strata_lab` -> `object$exposure$label`/
  `object$response$label`/`object$strata$label`. `strata_lab` errors if
  `stratify_by` wasn't set in `er_plot()` -- there's no legend to label.
- `title`/`subtitle`/`caption` -> new `object$theme$title`/`subtitle`/
  `caption` fields (all `NULL` by default, set in `er_plot()`), applied
  via `patchwork::plot_annotation()` in `er_plot_build()` (which already
  passed `theme =` there for the annotation-level theme).
- `xlim`/`ylim` -> `object$exposure$limits`/`object$response$limits`.
  These were already read lazily by every builder/`coord_cartesian()`
  call at build time (not at add-layer time), so overriding them needed
  no other code changes and works regardless of call order relative to
  `er_plot_add_*()`.
- `theme_base`/`theme_extra` -> `object$theme$theme_base`/
  `object$theme$theme_extra` (renamed from `theme_args` -- see the
  refactor below). Supplying `theme_extra` fully replaces the existing
  default (panel border + `legend.position = "bottom"`) rather than
  merging with it.
- `color_discrete`/`fill_discrete` -> new `object$theme$color_discrete`/
  `object$theme$fill_discrete` fields (`NULL` by default). Discrete
  ggplot2 scale objects only, validated via `inherits(x, "Scale")`.
  Continuous palette control (density/response-colored layers) was
  deferred at the time this section was written, then implemented in a
  later round -- see "Continuous color/fill palette control" below.
- `format_p`/`format_percent`/`format_number` -> the existing
  `object$theme$format_*` fields (unchanged consumption elsewhere).
- `draw_key` -> the existing `object$theme$draw_key` field (unchanged
  consumption elsewhere).
- `height_base`/`height_data`/`height_group` -> merged into
  `object$theme$height` via `utils::modifyList()`, so supplying only one
  leaves the other two unchanged.

**The `theme_base`/`theme_args` -> plain-object refactor.** Before this
work, `object$theme$theme_base` and `object$theme$theme_args` were
zero-argument functions (`function() ggplot2::theme_bw()` etc.) called
at every use site, even though nothing ever passed them arguments. This
was simplified to store the plain ggplot2 theme objects directly
(`object$theme$theme_base <- ggplot2::theme_bw()`), which is both simpler
internally and lets `er_plot_theme()` accept a theme object directly from
users the way they'd normally write `+ theme_bw()`. `theme_args` was
renamed to `theme_extra` in the same pass, to match the new user-facing
argument name (straight rename, no shim, per this package's usual
convention). Call sites updated: `.build_base_plot()`,
`.build_data_plot()`, `.build_group_plot()` (`R/er-plot-build.R`,
dropping the trailing `()`), `.polish_theme()` (`R/er-plot-compose.R`),
and `er_plot_build()`'s `patchwork::plot_annotation(theme = ...)` call
(`R/er-plot-api.R`).

**Applying the discrete palette (`.polish_scales()`).** A new
`R/er-plot-compose.R` function, called from `er_plot_build()` right
after `.polish_labels()`, adds `object$theme$color_discrete`/
`fill_discrete` (when set) to every eligible plot. "Eligible" reuses the
same role checks `.polish_labels()` already computes to decide whether
`colour`/`fill` on a given plot means strata (discrete, eligible) or
density/response-value (continuous, left alone): the base plot is
skipped for `fill` when the overlay style is tagged `fill_role =
"density"` (e.g. `er_style_data_hex()`); data panels are skipped when
`config$color_role == "response"`; group panels are always eligible
(group builders only ever use strata for color/fill). One known rough
edge, not solved: if a future custom builder adds its own
`scale_color_*()`/`scale_fill_*()` directly, `.polish_scales()` will add
a second scale on top rather than detecting/deferring to the builder's
own choice (ggplot2 emits a message and the later one wins) -- no
built-in builder does this today, so it isn't a live bug.

**Deferred / explicitly out of scope for this round:** continuous
color/fill palette control (`er_style_data_hex()`'s density fill, a
continuous/count response's response-colored data layer) -- would need
`color_continuous`/`fill_continuous` arguments and the symmetric branch
of `.polish_scales()`'s eligibility logic (see "Continuous color/fill
palette control" below -- this was implemented in a later round);
per-layer/per-geom style knobs (alpha, linewidth, hardcoded greys) --
these belong to individual `er_style_*()` builders' own arguments/
`...`-passthrough, not the global theme; validating that a
`color_discrete`/`fill_discrete` scale's own aesthetic (`"colour"` vs
`"fill"`) matches which argument it was passed as -- a mismatch
surfaces as ggplot2's own error/warning at build time rather than being
caught by `er_plot_theme()` itself.

Covered by a new `tests/testthat/test-er-plot-theme.R` (partial-update
semantics across repeated calls, each argument's validation, an
integration test applying several overrides at once, and a regression
check that `color_discrete`/`fill_discrete` don't affect an
`er_style_data_hex()` density fill). Verified clean: `devtools::test()`
(618 passing) and `devtools::check()` (0 errors/warnings/notes).
`vignettes/articles/design.Rmd` was not updated to demonstrate
`er_plot_theme()` -- flagged as a follow-up, not done as part of this
change.

## Continuous color/fill palette control in `er_plot_theme()`

The gap flagged above -- `color_discrete`/`fill_discrete` only ever
apply where `colour`/`fill` means strata, leaving `er_style_data_hex()`'s
bin-density fill (and a hypothetical continuous/count response's
response-colored data layer -- no built-in consumer, but
`.layer_data()`'s `config$color_role == "response"` dispatch was left
in place for a custom builder) stuck at ggplot2's default gradient --
was closed by adding `color_continuous`/`fill_continuous` to
`er_plot_theme()`. These validate against ggplot2's `"ScaleContinuous"`
class specifically (tighter than `color_discrete`/`fill_discrete`'s
generic `"Scale"` check), so passing a *discrete* scale to
`color_continuous` is rejected rather than silently accepted.
`.polish_scales()` gained the mirror image of its existing discrete
branches: `fill_continuous` applies to the base plot's `fill` only when
an overlay builder is tagged `fill_role = "density"`; `color_continuous`/
`fill_continuous` apply to a data panel only when `config$color_role ==
"response"`. Each of the four `er_plot_theme()` palette arguments only
ever touches the aesthetic role it names, so they can be supplied
together without one clobbering the other (e.g. a stratified model
ribbon's discrete `fill = strata` alongside `er_style_data_hex()`'s
continuous density `fill` -- though those two specifically can't
coexist on the *same* plot regardless of theming, since ggplot2 itself
rejects two scales for one aesthetic; see `er_style_data_hex()`'s own
docs).

Covered by new tests in `tests/testthat/test-er-plot-theme.R`
(validation, including the discrete-scale-rejected case; a regression
check that `fill_continuous` correctly overrides `er_style_data_hex()`'s
density fill without being clobbered by a simultaneously-supplied
`fill_discrete`; and a custom `"panel"`-layout builder exercising the
`color_role == "response"` branch, since no built-in one exists).
`vignettes/articles/theming.Rmd` gained a "Continuous color/fill
palette" section (using `er_style_data_hex()`) alongside its existing
discrete one. Verified clean: `devtools::test()` (634 passing),
`devtools::check()` (0 errors/warnings/notes), and `theming.Rmd`
re-rendered end-to-end via `rmarkdown::render()`.

## `er_style_data_hex()`'s default fill palette fades to the panel background near zero

`er_style_data_hex()` used to leave its `fill` aesthetic (bin density)
at ggplot2's own default continuous fill gradient, whose low end is
already a moderate blue rather than something that reads as "no data
here" -- a real usability gap now that `erplots_data` (4,000 rows) makes
this builder's main use case (avoiding scatter overplot) concrete. It
now adds its own default, `ggplot2::scale_fill_gradient(low = "grey90",
high = "#132B43")`, so a cell's fill fades toward (though doesn't fully
reach) the panel background as its count approaches zero -- `grey90`
rather than pure white, so a very-low-density cell still reads as a
drawn hex rather than disappearing indistinguishably into the `theme_bw()`
background. This default is only added when the user hasn't
already supplied `er_plot_theme(fill_continuous = ...)` -- checked via
the builder's own `theme$fill_continuous` (the `theme` argument passed
into every builder *is* `object$theme`, so this needed no new plumbing)
-- so overriding the palette doesn't trip ggplot2's "already present"
duplicate-scale warning that `.polish_scales()` layering a second scale
on top would otherwise cause. Covered by an updated test in
`tests/testthat/test-er-plot-style-data.R` (renamed from "returns a
single hex geom" to "returns a hex geom plus its default fill scale",
now asserting length 2 and checking the scale's `low` color via its
captured `$call`). `devtools::test()` (813 passing) and
`devtools::document()` both clean; the one pre-existing `WARN` in the
suite (`geom_violin()`'s `draw_quantiles` deprecation) is unrelated.

Deliberately not done as part of this change: no equivalent default was
added for `color_continuous`/a hypothetical `color_role == "response"`
data panel (no built-in builder uses that role today, so there's
nothing to apply a default to yet); `vignettes/articles/theming.Rmd`'s
existing "Continuous color/fill palette" section (which already
demonstrates overriding `er_style_data_hex()`'s fill) was not
re-rendered to show the new default explicitly, since the section's own
prose doesn't describe what the *unstyled* default looks like.

## `er_style_tag()`'s `zorder` attribute: a background/foreground stacking position for overlay-layout data builders

`er_style_data_hex()`'s geoms cover the whole panel (no gaps for a
lower layer to show through), so being added last -- the fixed
z-order every overlay-layout data builder used to share, added after
model/summary/quantile so a scatter overlay's individual points are
never hidden behind a translucent model ribbon -- meant it completely
buried the model curve/ribbon and the summary annotation whenever all
three shared the main panel. A design review considered two fixes: (1)
a builder-declared z-order tag, so only a full-coverage builder like
`er_style_data_hex()` opts into drawing first, or (2) switching the
whole package to ggplot2-style semantics where the order layers are
*added* in the `er_plot_add_*()` pipeline determines z-order. (2) was
rejected as a much bigger architectural bet for a currently-hypothetical
benefit: it would require new object state tracking call order among
the (at most four) main-panel layers, a policy decision for what
happens to that order when a singleton layer is replaced by a second
call, and -- most importantly -- it would break the package's existing,
foundational "pipe order never affects the result" property (every
`er_plot_add_*()` call writes into its own named `object$layer$*` slot,
assembled deterministically by `er_plot_build()` regardless of call
order) for exactly one dimension (main-panel z-order) while leaving
that property intact everywhere else in the spec -- a real, if narrow,
inconsistency to document and reason about. (1) was implemented
instead, since it required no new object state, changed no existing
builder's behaviour, and follows the same self-declared-metadata
pattern `layout`/`fill_role`/`y_role`/`layer` already established.

`er_style_tag()` gained a fifth independent, optional argument,
`zorder`, one of `"foreground"` (the default when a builder omits the
tag, unchanged behaviour: overlay geoms added last, after
model/summary/quantile) or `"background"` (overlay geoms added first,
before model/summary/quantile). It's stored as the `"er_style_zorder"`
attribute and read via a new internal `.style_zorder()` (which, unlike
`.style_layout()`, doesn't error on an untagged builder -- it defaults
to `"foreground"`, since every existing builder is meant to keep
working unchanged). `zorder` only has an effect for an overlay-layout
data builder; a panel-layout builder's geoms are never in the same
ggplot object as model/summary/quantile, so the tag is inert there.
`.build_base_plot()` (`R/er-plot-build.R`) now checks
`object$layer$overlay`'s style for this tag *before* adding the
model/summary/quantile geoms, adding the overlay geoms first when it's
`"background"`; `er_plot_build()`'s own overlay-adding step (previously
unconditional, always after `.build_base_plot()` returns) now skips
re-adding them when the tag is `"background"`, since `.build_base_plot()`
already did.

`er_style_data_hex()` is now tagged `zorder = "background"`, and
also gained a modest default `alpha = 0.85` on its `geom_hex()` (a new,
overridable formal, same pattern as `bins`) -- giving the
now-visible-again model curve/summary annotation a little extra
contrast against even a densely populated hex cell, on top of the fix
to ordering itself. Neither change affects any other builder.

Covered by new tests in `tests/testthat/test-er-plot-api.R`: `zorder`'s
validation (including the untagged-defaults-to-`"foreground"` case),
`er_style_data_hex()` carrying the tag, and two integration tests
building a plot with a custom `zorder = "background"` overlay style
(confirming its geoms precede the model layer's in
`object$plot$base$layers`) and with the default (`"foreground"`)
`er_style_data_overlay()` (confirming the opposite, unchanged ordering).
Verified: `devtools::test()` (823 passing, up from 813; the one
pre-existing `WARN` -- `geom_violin()`'s `draw_quantiles` deprecation --
is unrelated) and `devtools::check()` (0 errors/warnings/notes).

Not done as part of this change: no vignette was updated to demonstrate
`zorder` (`extending.Rmd`'s `er_style_tag()` walkthrough covers
`layout`/`fill_role`/`y_role`/`layer` but not yet `zorder`); no halo/
outline contrast treatment was added to any model-layer builder (flagged
during the design review as a possible follow-up if `alpha = 0.85` alone
doesn't give enough contrast in practice).

A follow-up pass closed two of the three vignette/staleness gaps this
change left open (`extending.Rmd`'s own `zorder` walkthrough remains
the one still-open item, listed above). `theming.Rmd`'s "Continuous
color/fill palette" section previously only showed `er_style_data_hex()`
with a `fill_continuous` override, never the builder's own unstyled
default -- it now leads with a plot using no `fill_continuous` at all
(demonstrating the grey90-to-navy default, and incidentally also
showing the model line correctly visible on top of the hex fill, thanks
to the `zorder` fix) before the existing override example.
`design.Rmd`'s "Extending erplots" pointer section understated
`er_style_tag()`'s metadata list as just `layout`/`fill_role`/`y_role`
-- missing `layer` (a pre-existing gap predating this round) and now
`zorder` -- corrected to name all five. Verified: both
`vignettes/articles/theming.Rmd` and `vignettes/articles/design.Rmd`
re-rendered end-to-end via `rmarkdown::render()` with no errors.

A second follow-up pass closed the one item still left open above:
`extending.Rmd` gained a `### zorder` section, worked the same way as
its `layout`/`fill_role`/`y_role`/`layer` sections -- explaining the
concept, showing `er_style_data_hex()`'s own `"er_style_zorder"`
attribute, and a custom `"overlay"`-layout builder (a filled 2D density
contour, `geom_density_2d_filled()`) demonstrated twice: once tagged
`zorder = "background"` (model curve stays visible, drawn on top) and
once without the tag (model curve is completely buried, drawn
underneath) -- a direct, runnable illustration of the bug this tag
fixes. The "One function, four independent arguments" section was
renumbered to five and its code example/summary table both gained a
`zorder` row/argument. Verified: `rmarkdown::render()` of
`vignettes/articles/extending.Rmd` with no errors.

A third follow-up considered whether `?er_style` (the shared
builder-interface doc page, `R/er-plot-style.R`) should also gain a
`zorder` mention. That page already discusses `layout` and `layer` in
some depth, but conspicuously never mentions `fill_role`/`y_role` at
all -- those are left entirely to the family-specific pages
(`er_style_data`, `er_style_group`), on the reasoning that `layout` and
`layer` are broad/cross-cutting (`layer` applies to every builder
family; `layout` is the mandatory routing mechanism for data builders)
while `fill_role`/`y_role` are narrow, single-family concerns. `zorder`
is closer in scope to `fill_role` (optional, narrow -- only meaningful
for one structural sub-family, overlay-layout data builders) than to
`layout`/`layer`, so a full walkthrough wasn't added to `?er_style` to
avoid breaking that established precedent and duplicating what
`er_style_data()`'s own docs (and `extending.Rmd`) already cover in
depth. It did, however, get a single pointer sentence appended to
`?er_style`'s existing `layout` paragraph -- since `zorder` is set via
the same `er_style_tag()` call and is conceptually a sibling of
`layout` (both are data-layer structural tags) -- noting that an
overlay-layout builder can also declare its stacking position, with a
cross-reference to `er_style_data()` for the full explanation. Verified:
`devtools::document()` regenerated `er_style.Rd` cleanly, and
`devtools::test()` passed (823 passing, unaffected -- this was a
documentation-only change).

## Fixed: an `er_plot` with no layers at all errored instead of drawing a blank canvas

`er_plot_build()`'s trigger condition for building the base panel
(`object$plot$base <- .build_base_plot(object)`) only checked for the
model/summary/quantile/overlay layers, mirroring the documented "a
group-only or panel-layout-data-only plot has no base panel" exception.
But when *no* layer at all had been added -- e.g. `data |> er_plot(x,
y) |> plot()`, the minimal "empty canvas" example now used at the top of
`vignettes/erplots.Rmd` -- this meant `object$plot$base`,
`object$plot$data`, and `object$plot$group` were all `NULL`, so
`.polish_arrangement()`'s `plot_list` ended up empty and
`patchwork::wrap_plots(list(), ...)` failed inside `grid::unit()` with
an opaque `'x' and 'units' must have length > 0` error, rather than
rendering the blank axes-only panel a user would reasonably expect
(the same way `ggplot(df, aes(x, y))` with no geoms renders fine).
Fixed by widening the trigger condition: build the base panel either
when at least one of those four layers is present (unchanged), *or*
when there are no layers at all (a new `has_any_layer` check spanning
all six layers, including `data`/`group`) -- so a genuinely group-only
or panel-layout-data-only plot still correctly has no base panel (that
existing behaviour/test is unchanged), but the fully-empty case now
gets an empty `ggplot() + theme_base() + scale/coord` panel instead of
falling through to nothing. Covered by a new test in
`tests/testthat/test-er-plot-api.R`, alongside the existing "group-only"/
"panel-layout data-only" no-base-layer tests it sits next to.

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
- Internal (dot-prefixed) helpers were mostly left alone: `.layer_*()`,
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

**The `part`/`component` -> `layer` consolidation.** The constituent
pieces of an `er_plot` (model, quantile, data/overlay, group) had drifted
into three overlapping vocabularies: "layer" (the dominant, user-facing
term -- the `er_plot_add_*()` verbs, the singleton/additive rule, and
`er_style_tag()`'s own `layer` argument all already used it), "part"
(the purely internal storage/naming: `object$part`, the `.part_*()`
assembly functions in what was `R/er-plot-part.R`), and "component"
(stray prose/section headings in the worked-example vignettes and one
`print.er_plot()` line, never a deliberate third choice). A review
consolidated everything onto "layer": `object$part` -> `object$layer`;
`.part_model()`/`.part_quantile()`/`.part_data()`/`.part_overlay()`/
`.part_group()` -> `.layer_model()`/`.layer_quantile()`/`.layer_data()`/
`.layer_overlay()`/`.layer_group()` (and the file itself,
`R/er-plot-part.R` -> `R/er-plot-layer.R`, plus its test file,
`test-er-plot-part.R` -> `test-er-plot-layer.R`); `print.er_plot()`'s
`"  plot components:"` output -> `"  plot layers:"`; and every stray
"component" heading/cross-reference in `plot-binary.Rmd`/
`plot-continuous.Rmd`/`plot-count.Rmd` (`## Model component` etc. ->
`## Model layer` etc., including anchor links) and `design.Rmd` ->
"layer". `er_style_tag()`'s own `layer` argument/`"er_style_layer"`
attribute/`.style_layer()`/`.check_style_layer()` needed no change --
that vocabulary was already correct. "Part"/"component" survive only as
ordinary English prose where they don't name this concept (e.g. "a
public part of the API", ggplot2's own "theme components" in a `@param`
doc). Straight rename, no deprecation shim, per the usual rationale.
Verified clean afterward: `devtools::document()`, `devtools::test()`
(490 passing), `devtools::check()` (0/0/0), and a full re-render of all
five `vignettes/articles/*.Rmd` files plus `README.Rmd`.

## Extensibility: `style` is the sole mechanism (no separate layout argument)

Every `er_plot_add_*()` function (`er_plot_add_model()`,
`er_plot_add_summary()`, `er_plot_add_quantiles()`, `er_plot_add_data()`,
`er_plot_add_groups()`) takes a `style` argument that defaults to one
built-in `er_style_*()` function (`er_style_model_ribbonline()`,
`er_style_summary_pvalue()`, `er_style_quantile_errorbar()`,
`er_style_data_overlay()`, `er_style_group_boxplot()`) and can be set to
any other function matching the standard `er_style_*()` signature
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
whether to route through `.layer_overlay()` or `.layer_data()`. Both
built-in data builders already carry this tag (`er_style_data_overlay()`:
`"overlay"`; `er_style_data_boxjitter()`: `"panel"`); a
custom data-layer builder that omits it errors immediately and
informatively, rather than silently landing in the wrong structural
slot. This was chosen over encoding layout in a builder's *return
value* because `.layer_overlay()`/`.layer_data()` build different
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
function (`er_plot_add_model()` checks `style` against `"model"`;
`er_plot_add_summary()` checks `style` against `"summary"`;
`er_plot_add_quantiles()`
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
factor; `.layer_quantile()` reads this into `config$breaks`, which the
`_vlines` builders (via the internal `.quantile_boundary_vlines()`
helper) consume. `er_builder_quantile_bar()` (bar + error bar) was
removed -- on review it wasn't an idiom that shows up in real
exposure-response reporting, unlike the `_vlines` pattern -- with no
deprecation shim (see "Naming scheme" above for why erplots doesn't use
shims). All four quantile builders are tagged
`er_style_tag(fn, layer = "quantile")`.

## The summary layer is independent of the model layer

`summary` used to be a secondary argument of `er_plot_add_model()`
(`summary_style`, defaulting to `er_style_summary_pvalue()`), nested
inside the model layer's own `config` (`config$style <- list(model =
style, summary = summary_style)`) and computed by `.layer_model()`
alongside the curve/ribbon predictions. A review promoted it to its own
peer layer, `er_plot_add_summary()`, storing into `object$layer$summary`
via a new `.layer_summary()` (in `R/er-plot-layer.R`), for two reasons:
(1) a summary annotation doesn't have to be a *model* summary at all --
e.g. a purely descriptive observation count -- so requiring
`er_plot_add_model()` to be called first, just to get an annotation, was
an artificial coupling; and (2) it matches how every other constituent
of an `er_plot` (model, quantile, data, group) is already its own
independent, singleton (except `group`) layer with its own
`er_plot_add_*()` verb.

`er_plot_add_summary(object, model = NULL, keep_strata = NULL, style =
NULL, ...)` takes `model` as an *optional* argument (unlike
`er_plot_add_model()`, where it's required) -- `NULL` is valid and simply
means no model-derived statistic is available. `style` defaults to
`er_style_summary_pvalue()` (draws a p-value from the model's own
[er_summary()], via `config$p_value`); `er_style_summary_n()` is a new,
model-agnostic alternative (total observation count, or one count per
stratum level when stratified) that ignores `model` entirely and reads
straight from `data`, demonstrating that a summary builder need not
depend on a model. `er_plot_add_model()` itself dropped `summary_style`
entirely (straight removal, no deprecation shim, per this package's
usual convention) and now only draws the curve/ribbon.

Two follow-on design decisions, both made when the layer was split out:

- **Corner placement no longer depends on the model curve.**
  `config$corner_distance` (a named `top_left`/`top_right`/
  `bottom_left`/`bottom_right` vector of minimum distances, used to place
  the annotation in the least-crowded corner) used to be computed from
  the model's fitted curve (`config$predictions`'s `fit_resp`). Since
  `er_plot_add_summary()` can now be called with no model at all, this
  was switched to a single code path based on the raw observed data
  instead: `.layer_summary()` computes it from `object$data`'s own
  `(exposure, response)` points, rescaled onto `[0, 1]` via
  `object$exposure$limits`/`object$response$limits` -- the same
  rescale-then-`sqrt(x^2+y^2)`-per-corner-then-`min()` shape as before,
  just fed raw points instead of the curve. This is a deliberate, visible
  behaviour change to existing plots' label placement, not just an
  implementation detail, and applies uniformly whether or not a model
  was supplied.
- **The "skip when stratified" decision moved into the builder.**
  `.layer_model()` used to refuse to compute a p-value at all when the
  layer was stratified (one p-value doesn't unambiguously describe
  multiple curves). `.layer_summary()` now computes `config$p_value`
  unconditionally whenever a `model` is supplied, and
  `er_style_summary_pvalue()` itself checks `stratify` and returns
  `list()` if `TRUE`. This lets a different summary builder make its own
  call -- `er_style_summary_n()`, for instance, is most useful precisely
  when stratified (one count per stratum level), so it doesn't suppress
  itself.

Both `er_style_summary_pvalue()` and `er_style_summary_n()` are tagged
`er_style_tag(fn, layer = "summary")`. `er_plot_build()`'s base-plot
trigger condition gained `object$layer$summary`, so a plot with only a
summary layer (no model/quantile/data-overlay) still builds a base
panel. One visible side effect worth flagging: every existing
`er_plot_add_model(mod)` call used to draw a p-value annotation by
default (since `summary_style` defaulted on); it no longer does --
showing one now requires an explicit `er_plot_add_summary(model = mod)`
call. At the time of this change, the three response-type worked-example
vignettes were not updated to add it, since none of their prose
specifically discussed the p-value annotation, and their rendered
model-layer examples showed no summary annotation where they used to; a
later change closed that gap by adding a dedicated "Summary layer"
section -- see "Vignette structure" below.

## Passing extra arguments to a builder (`...` passthrough)

Every `er_plot_add_*()` function (`er_plot_add_model()`,
`er_plot_add_summary()`, `er_plot_add_quantiles()`, `er_plot_add_data()`,
`er_plot_add_groups()`) takes its own `...`, forwarded unchanged to
whichever `er_style_*()` builder it calls at build time. The standard
builder signature grew a trailing `...` to receive this:
`function(data, config, stratify, exposure, response, strata, theme,
...)`, applied (straight rename, no shim) to all built-in builders;
one that doesn't need any extra arguments just declares `...` and
ignores it. Extra arguments must be named -- checked at each
`er_plot_add_*()` call site via the internal `.check_dots_named()`
helper in `R/utils-helpers.R` (there's no exported `rlang::check_dots_named()`
in the rlang version this package depends on, so this is a small
hand-rolled equivalent) -- since they're spliced in positionally after
the seven standard arguments (`do.call(style, c(list(data, config, ...,
theme), config$dots))` at each of the call sites in
`R/er-plot-build.R`); an unnamed one would otherwise silently bind to
the wrong parameter. Each `.layer_*()` function gained a `dots`
parameter (default `list()`), storing it on `config$dots` (shared across
every per-group config for `.layer_group()`).

The motivating concrete case: `er_style_model_spaghetti()` calls
[er_simulate()], and erglm's implementation auto-selects and reports a
seed whenever none is supplied. `er_style_model_spaghetti()` now reads a
`seed` out of its own `...` (via `rlang::list2(...)`), falling back to
`config$seed` (currently always `NULL` for the model layer -- a
pre-existing gap this doesn't otherwise fix) when none is given, so
`er_plot_add_model(mod, style = er_style_model_spaghetti, seed = 9626)`
lets a caller silence that message with a reproducible seed of their
own. The two quantile `_vlines` wrapper builders and
`er_style_model_spaghetti()`'s own ribbonline fallback call forward
`...` into their inner call, so they don't drop extra arguments meant
for the base builder they wrap/fall back to. Documented in `?er_style`'s
new "Passing extra arguments to a builder" section.

## The `er_summary()` return-value contract

`er_summary()`'s return value was originally undocumented beyond "a named
list of scalar summary statistics (e.g. `list(p_value = 0.013)`)" -- fine
for erglm, whose GLM-based models have one unambiguous exposure
coefficient to report a p-value for, but not obviously generalisable to a
sister package like emaxnls, whose nonlinear Emax models have several
named parameters (`E0`/`Emax`/`EC50`/`Hill`) with no single privileged
term. A design review settled on a purely additive contract, documented in
`?er_model_interface`: `er_summary()` returns `NULL`, or a named list with
any of three independently-optional, reserved keys (unrecognized keys are
permitted and ignored by built-ins, for a model package's own
custom-builder escape hatch) --

- `p_value` (scalar or `NULL`, unchanged from before): a single headline
  p-value, only when the model has one unambiguous candidate. A
  multi-parameter model with no privileged term should return `NULL`
  here rather than pick one arbitrarily.
- `coefficients` (tibble/data frame or `NULL`): one row per model
  parameter, snake_case columns (`term`, optional `label`, `estimate`,
  optional `std_error`/`statistic`/`p_value`/`conf_low`/`conf_high`) --
  snake_case rather than `broom::tidy()`'s dotted names, matching this
  package's existing convention (`p_value`, `corner_distance`).
- `glance` (single-row tibble/data frame or `NULL`): model-level
  goodness-of-fit, `broom::glance()`-style (`n`, `df_residual`, `logLik`,
  `aic`, `bic`, `deviance`, `r_squared`, `converged`). Reserved now so a
  second contract revision isn't needed later; no built-in builder
  consumes it yet.

`.layer_summary()` (`R/er-plot-layer.R`) now stores the full, raw
`er_summary()` return value as `config$summary`, alongside the existing
`config$p_value` (still extracted separately so `er_style_summary_pvalue()`
didn't need to change). A new builder, `er_style_summary_coefficients()`
(`R/er-plot-style-summary.R`, tagged `layer = "summary"`), demonstrates
`coefficients` in use: one line per row (`label`-or-`term`: `estimate`,
plus `(p = ...)` when that row has a non-`NA` `p_value`) in a
`geom_label()`, placed via the same `config$corner_distance` logic as the
other two summary builders; it draws nothing if `coefficients` is absent
or the layer is stratified (same posture as `er_style_summary_pvalue()`).
Column access inside it uses `"col" %in% names(coefs)` rather than `$`
directly, since tibble's `$` warns on an absent column.

This is purely additive -- erglm's existing `er_summary.erglm_model()`
(returning only `list(p_value = ...)`) continues to work unchanged.
Explicitly deferred: enriching erglm's own method with
`coefficients`/`glance`, and an actual `er_summary.emaxnls()`
implementation -- neither is erplots-side work.

A fourth builder, `er_style_summary_gof()` (`R/er-plot-style-summary.R`,
tagged `layer = "summary"`), was added as the first consumer of
`$glance`: a single-line, comma-separated annotation drawn from a
curated subset of `glance`'s reserved columns (`N`, `AIC`, `BIC`, `R²`
-- deliberately not `df_residual`/`logLik`/`deviance`/`converged`, to
keep the annotation compact), showing only whichever of those four are
actually present and non-`NA` in a given model's `glance`. Same posture
as the other two model-derived summary builders: draws nothing if none
of the four fields are available, or if the layer is stratified.

**Documentation follow-ups.** A dedicated "Summary layer" section was
added to `plot-binary.Rmd`, with worked examples of
`er_style_summary_pvalue()` (the default) and `er_style_summary_gof()`
-- the latter demonstrating a `glance`-populating `er_summary()` method
defined and registered on the spot via `registerS3method()`, since
erglm's own `er_summary.erglm_model()` doesn't populate `glance` yet.
`plot-continuous.Rmd`/`plot-count.Rmd` link back to it rather than
duplicating the worked example, mirroring the existing model/group-layer
cross-referencing pattern -- see "Vignette structure" below.
`design.Rmd`'s layer-overview table was updated to name all four summary
builders (it previously named only two, from before
`_coefficients()`/`_gof()` existed), and a follow-up audit for lingering
staleness from the summary layer's earlier promotion to independence
found: `design.Rmd`'s own ASCII pipeline diagram was still missing
`er_plot_add_summary()` entirely (a plain enumeration, not caught by
searching for "N layers" phrasing); and two roxygen doc strings
(`er_plot_add_groups()`'s own details, `?er_style`'s structural-family
paragraph) still said "the other three layers" where it's now four --
all fixed. `PLAN.md`'s "Completed: mini-language documentation (grammar
review)" section -- `design.Rmd`'s own cross-reference target, per its
"Keeping this article in sync" note -- was updated to record the
promotion and the layer-table change alongside these fixes.

## `er_vpc_plot()` and the `sim_resp` extension to `er_simulate()`

`er_vpc_plot()` used to be the one part of the mini-language not built
on the model interface: it took a `sim` data frame that had to be
produced by a bespoke, model-package-specific helper (e.g.
`erglm::erglm_vpc_sim()`), so every model package needed its own
VPC-shaped simulation function outside of `er_predict()`/
`er_simulate()`/`er_summary()`. This was closed by widening
`er_simulate()`'s contract additively, rather than adding a fourth
generic: a method may now return an optional `sim_resp` column
alongside the existing `fit_resp`, giving a full response-scale draw
for that replicate/observation (parameter uncertainty *and*
observation-level sampling/residual noise -- e.g. a 0/1 draw for a
binary response, an integer draw for a count response, a draw
including residual variance for a continuous response), as opposed to
`fit_resp`'s point on the mean curve (parameter uncertainty only, used
by `er_style_model_spaghetti()`). `sim_resp` is independently optional:
a method can supply `fit_resp` alone (as every implementation did
before `sim_resp` existed, and as remains sufficient for spaghetti
plots) or both columns from the same call. See `?er_model_interface`
for the full contract.

A separate generic (e.g. `er_simulate_response()`) was considered and
rejected: erglm and emaxnls both already have `stats::simulate()`
methods that compute both the mean/expected response and a full
response draw in one call (erglm's `simulate.erglm_model()` returns
`mu`/`val`; emaxnls's `simulate.emaxnls()`/`simulate.emaxlogistic()`
have the equivalent noise-drawing machinery in
`.emax_resample()`/`.emax_logistic_resample()`), so extending
`er_simulate()`'s *return value* to optionally include the noisy draw
was a smaller, more natural change than inventing and documenting a
whole second simulation generic -- both existing model packages needed
only a few lines added to their `er_simulate()` methods to wire in
noise they already knew how to draw elsewhere.

`er_vpc_plot()` gained a `model` argument (mutually exclusive with the
existing `sim` argument -- exactly one of the two must be supplied) and
new `nsim`/`seed` arguments (only meaningful with `model`). When
`model` is supplied, `er_vpc_plot()` calls `er_simulate(model, newdata
= data, nsim = nsim, seed = seed)` internally and looks for
`sim_resp`; if it's missing (either because `er_simulate()` returned
`NULL` -- no simulation support at all -- or because the method only
ever populated `fit_resp`), it errors informatively rather than
silently treating `fit_resp` as if it were a noisy draw, which would
produce a falsely narrow, misleading VPC band. The `sim`-based code path is unchanged and remains supported
indefinitely -- useful for a hand-built simulation, or a model-specific
helper that predates or bypasses the `er_simulate()` interface.

Both companion packages have been updated to implement the extended
contract: `erglm`'s `.erglm_simulate_draws()` (the engine behind
`er_simulate.erglm_model()`) now also computes `sim_resp` via the
existing `.erglm_draw_response()` helper (the same family-appropriate
noise model erglm's older, now-superseded `erglm_vpc_sim()` used, just
wired into a second entry point); `emaxnls`'s `er_simulate.emaxnls()`
now does the same via `Normal(fit_resp, sigma(model))` for `emaxnls`
objects or `Bernoulli(fit_resp)` for `emaxlogistic` objects, mirroring
`.emax_resample()`/`.emax_logistic_resample()`. Both changes were
implemented via pull requests (erglm PR #6, emaxnls PR #67) that have
since been merged, so `er_vpc_plot(model = ...)`'s example in
`R/er-vpc.R` and its test coverage now pass against each package's
default branch, as resolved via this repo's `Remotes:` entries. With
`erglm_vpc_sim()` has since actually been removed from erglm (confirmed
against erglm's own repo: commit `e706ebb`, "Remove `erglm_vpc_sim()`,
superseded by `er_vpc_plot(model = ...)`", on `origin/main`) -- erplots'
own docs, vignettes (`README.Rmd`,
`vignettes/articles/plot-{binary,continuous,count}.Rmd`), and examples
were all already updated to go through `er_vpc_plot(model = ...)`
instead, so none of them call `erglm_vpc_sim()`.
`tests/testthat/test-er-vpc.R`'s `sim`-argument tests were also already
proactively migrated off `erglm_vpc_sim()` ahead of its removal: a small
`vpc_sim_fixture()` helper at the top of that file builds the same
`sim`-shaped data frame directly via `er_simulate(model, newdata = data,
nsim = ..., seed = seed)` plus a `sim_resp` -> response-column swap
(mirroring what `er_vpc_plot(model = ...)` does internally), so no test
in the suite ever calls `erglm::erglm_vpc_sim()`. Verified against the
reinstalled, `erglm_vpc_sim()`-free erglm: full `devtools::test()` and
`devtools::check()` both clean.

## Documentation sweep: no internal implementation details outside `internals.Rmd`

A review swept `man/*.Rd` (via their roxygen sources) and
`vignettes/articles/*.Rmd` for references to internal implementation
details -- dot-prefixed functions (`.layer_*()`, `.polish_*()`,
`.build_overlay_geoms()`, `.get_model_predictions()`, etc.), internal
`R/` file paths, and direct access into the `er_plot` object's own
internal slots (`object$layer`, `object$data`, `object$part`) -- on the
principle that user-facing documentation shouldn't encourage relying on
internals that may change between releases. `vignettes/articles/internals.Rmd`
is the sole exception, by design (its explicit purpose is documenting
those internals) and was left untouched.

Found and rewritten: `R/er-plot-style.R`'s `?er_style` topic (several
mentions of `.build_overlay_geoms()`, `.layer_*()`, `.layer_data()`,
`.polish_labels()`/`.polish_legends()`, `R/er-plot-compose.R`,
`object$layer`, and the historical, already-removed `build_data_color()`);
`er_plot_add_summary()`'s roxygen (`object$data`'s raw coordinates, in
`R/er-plot-api.R`); and `design.Rmd`/`extending.Rmd`/`model-interface.Rmd`
(the same family of internal function/file references, plus
`extending.Rmd`'s worked "inspect `config$summary`" example, which used
to fetch it via direct slot access, `plt$layer$quantile$config$summary`).
That last one was rewritten as a "spy" builder -- a tiny custom `style`
function that just `print()`s `config` and returns `list()` -- passed as
the layer's own `style` argument, so config can still be inspected
interactively without depending on the object's internal storage shape;
this is the recommended pattern for anyone wanting to inspect a layer's
`config` while developing a custom builder.

**What was deliberately left alone.** References to `config$predictions`/
`config$summary`/`config$breaks`/`config$color_role`/etc. -- the
contents of the `config` argument passed to a custom `er_style_*()`
builder -- are not internal details; `config`'s shape per layer is the
documented, public extension contract (`?er_style`, `extending.Rmd`),
so describing what it contains is required, not something to scrub.
Plain (`#`, not `#'`) source-code comments inside builder function
bodies (e.g. `er-plot-style-data.R`'s comment pointing a future
maintainer at `.build_overlay_geoms()` in `R/er-plot-build.R`,
`er-plot-style-group.R`'s comment about `.polish_labels()`) were also
left alone -- they're maintainer-facing code comments, not generated
into any `.Rd` page or vignette, so they don't reach end users. Likewise
`@noRd`-tagged roxygen (e.g. `.dodge_quantile_strata()`'s own doc
comment in `R/utils-helpers.R`, which references `.layer_quantile()`)
was left alone, since `@noRd` means it's never rendered into a `.Rd`
page either. The exported `ci_clopper_pearson()`/`ci_t()`/`ci_poisson()`
functions named in `design.Rmd`'s quantile-layer table are genuinely
public API (`@export`ed, listed in `NAMESPACE`), not internal
implementation, so those references were kept as-is.

Verified after the edits: `devtools::document()` (regenerated
`er_plot_add_summary.Rd`/`er_style.Rd` cleanly), `devtools::test()` (809
passing), and `rmarkdown::render()` of `design.Rmd`/`extending.Rmd`/
`model-interface.Rmd` with no errors.

## Roxygen convention sweep: short `@description`/`@param`, detail deferred to `@details`/`@returns`

A second documentation review (following the internal-implementation-details
sweep above) checked every roxygen block against a consistent convention:
`@description` is a plain 1-2 sentence summary, each `@param` is 1-2
sentences, and anything longer -- caveats, error conditions, cross-builder
comparisons, defaults with rationale -- is deferred to `@details` (or
`@returns` for return-value nuance). Most of the package already followed
this (`R/er-generics.R`, `R/er-plot-style-model.R`, `R/er-plot-style-data.R`,
`R/er-plot-style-group.R`, `R/er-vpc.R`, `R/utils-helpers.R` needed no
changes). Two genuine content bugs were found and fixed along the way,
both caused by a stray blank (non-`#'`) line splitting what was meant to
be one `@details` paragraph across two roxygen blocks that only merged
back together in the rendered `.Rd` because they shared the same `@name`/
followed the same function -- roxygen2 does not require blocks to be
contiguous to merge them, so the split was silent (no build warning) but
left the *prose* broken:

- `R/er-plot-style-quantile.R`'s `@details` had a duplicated sentence
  about the `layer = "quantile"` tag (once phrased as "tagged `layer =
  \"quantile\"`", once as "`er_style_tag(fn, layer = \"quantile\")`") --
  merged into one non-repeated sentence.
- `R/er-plot-style-summary.R`'s `@details` had a sentence fragment
  missing its subject ("doesn't have to originate from a fitted model at
  all.", with no preceding noun) -- rewritten as part of the
  `er_style_summary_n()` sentence it was originally describing.

Trimmed `@param`s (with their overflow moved into each function's
existing `@details`, extending it rather than adding a new section) in
`R/er-plot-api.R`: `er_plot_theme()`'s `theme_extra` and `dodge_width`;
`er_plot_add_data()`'s `keep_strata`, `style`, and `panel`; and
`er_plot_add_groups()`'s `style` and `keep_strata`. Each of these used to
run 3+ sentences deep into cross-references and edge cases that belong
in prose describing the function as a whole, not a single argument.

**What was deliberately left alone (at the time -- since revisited).**
Files/blocks with no separate `@description` paragraph at all (e.g.
`R/er-plot-style-model.R`, `R/er-plot-style-data.R`,
`R/er-plot-style-group.R`, whose title doubles
as the description via roxygen2's own fallback) were not given an
invented description -- the convention is about trimming what's there,
not padding what's absent. See "Third documentation sweep" below, where
this specific decision was reversed for the six builder-family topics
and three `ci_*()` helpers that had no `@description` at all. `@details`
sections that were already long
but organised as one-idea-per-paragraph (e.g. `er_model_interface`'s
`@returns`, `er_style_summary`'s per-builder rundown) were left as-is;
length in `@details`/`@returns` is expected and appropriate, only
`@description`/`@param` have the 1-2 sentence ceiling.

Verified: `devtools::document()` regenerated `er_plot_theme.Rd`,
`er_plot_add_data.Rd`, `er_plot_add_groups.Rd`, `er_style_quantile.Rd`,
`er_style_summary.Rd` cleanly (spot-checked each rendered
`\description{}`/`\details{}` for the fixed prose), and `devtools::test()`
passed (809 passing) -- this was a documentation-only change with no
code-path effects.

## Third documentation sweep: added missing `@description` blocks, purged remaining "previous behaviour" language

A follow-up review revisited two loose ends left by the two documentation
sweeps above.

**Missing `@description` blocks.** The "Roxygen convention sweep" above
explicitly declined to add invented `@description` text to blocks that had
none (title doubling as description via roxygen2's own fallback). On
reflection this left nine rendered `.Rd` pages with `\title{}` and
`\description{}` containing identical text -- not a stylistic quirk but a
genuine documentation gap, since a description should say what the
function *does*, not just restate its name. Fixed by adding a real 1-2
sentence `@description` to: the six builder-family topics (`er_style.Rd`,
`er_style_data.Rd`, `er_style_group.Rd`, `er_style_model.Rd`,
`er_style_quantile.Rd`, `er_style_summary.Rd`, each naming the specific
builders in that family and what they draw) and the three
confidence-interval helpers (`ci_clopper_pearson()`, `ci_t()`,
`ci_poisson()`, one sentence each stating what interval it computes).

**Removing remaining "previous behaviour" language.** A second pass swept
`R/*.R` roxygen and `vignettes/articles/*.Rmd` for language describing a
current default or behaviour by reference to what came before it (e.g.
"matching the previous fixed value", "the previous behaviour", "the
older, panel-based design", "keeps the old behaviour") -- appropriate for
this AGENTS.md file, whose whole purpose is a historical record, but not
for user-facing docs, which should describe erplots as it is today rather
than as a diff against an earlier version. Fixed: six `@param` entries in
`R/er-plot-style-model.R` (`ribbon_fill`, `ribbon_alpha`, `ribbon_edges`,
`linewidth`, `alpha`, `nsim`) that justified their defaults by saying they
matched a prior fixed value -- reworded to just state the default;
`R/er-plot-style.R`'s dangling cross-reference to "one flagged future
exception (an additive `model` layer...)", pointing at a roadmap item that
doesn't actually appear in `er_plot()`'s own docs -- removed; five
vignettes (`plot-binary.Rmd`, `plot-continuous.Rmd`, `plot-count.Rmd`,
`design.Rmd`, `extending.Rmd`) plus one `@examples` comment in
`R/er-plot-api.R` that called `er_style_data_boxjitter()` "the older"
design relative to `er_style_data_overlay()` -- reworded to describe both
builders by their structural design (panel-based vs. overlay) rather than
by age/precedence; and `extending.Rmd`'s "keeps the old behaviour" ->
"keeps the default behaviour". `PLAN.md` was not touched by this sweep --
its own historical-record language (e.g. "matching the previous
conditional behaviour" in the builder-style-customisation section) is
appropriate there, since `PLAN.md`'s explicit purpose, like this file's,
is recording *why* things changed.

Verified: `devtools::document()` regenerated the nine `.Rd` files
cleanly, and `devtools::test()` passed (809 passing) both before and
after.

## Internal toy `lm`/`glm` test wrapper (reduces the test suite's dependency on erglm)

The test suite used to lean on `erglm` for almost every fixture -- not
because erglm itself was being tested, but because it was the easiest way
to get a fitted model object to exercise the (model-agnostic) plotting
machinery. This was considered, and explicitly rejected, as a case for
adding *user-facing* native `lm`/`glm` support to erplots itself (which
would meaningfully blur the "erplots never fits a model" design principle
and undercut erglm's own reason to exist); instead, the fix was scoped to
test infrastructure only.

`tests/testthat/helper-toy-model.R` defines `er_test_toy_model()`, an
unexported, test-only S3 class covering exactly two cases --
Gaussian/identity ("linear regression") and binomial/logit ("logistic
regression") -- implemented via a plain `stats::glm()` call, since
`erglm::erglm_model()` itself is nothing more than a tagged `glm()` call
(`.as_erglm(stats::glm(formula, data, family))`). Its
`er_predict()`/`er_simulate()`/`er_summary()` methods are direct mirrors of
erglm's own (`erglm:::erglm_predict()`, `erglm:::.erglm_simulate_draws()`/
`.erglm_draw_response()`, `erglm:::er_summary.erglm_model()`) -- same
link-scale prediction + inverse-link + z-interval; same
`mvtnorm::rmvnorm()` parameter draws plus family-appropriate response
noise; same coefficient/glance extraction from `summary()`. This is why a
dedicated sync-check file, `tests/testthat/test-toy-model-sync.R` (gated on
erglm being installed, since it fits a real erglm model to compare
against), exists: it fits the same formula/data through both
`er_test_toy_model()` and `erglm::erglm_model()` and asserts their
`er_predict()`/`er_summary()` outputs agree exactly, and that
`er_simulate()`'s draws agree structurally/distributionally (not
value-for-value, since the two implementations' RNG call shapes differ
even though the algorithm is the same). If a future erglm release changes
its prediction/summary/simulation algorithm, this file -- not some other,
unrelated test -- is the one that would start failing, making the drift
visible rather than silent. Deliberately narrow: `er_test_toy_model()`
doesn't support Poisson/Gamma/non-canonical links, so `er_test_mod_poisson`
(`helper-data.R`) stays erglm-backed and gated behind
`skip_if_not_installed("erglm")`, as do the handful of tests that
specifically exercise it or other genuinely erglm-specific behavior.
`mvtnorm` was added to `DESCRIPTION`'s `Suggests` for this (test-only use,
same as erglm's own dependency on it).

`er_test_data` (the shared dataset fixture, `helper-data.R`) used to be
`erglm::erglm_data` directly, gated behind `requireNamespace("erglm")`.
It's now a frozen snapshot, checked in at
`tests/testthat/fixtures/er_test_data.rds` (fully synthetic, ~10 KB
compressed, no licensing/privacy concern), loaded unconditionally via
`readRDS(testthat::test_path("fixtures", "er_test_data.rds"))`. Column
names/values are identical to the erglm original, so none of the dozens of
existing `er_test_data$aucss`/`ae1`/etc. references elsewhere in the suite
needed to change -- refreshing this snapshot (if erglm's own `erglm_data`
is ever revised) is a manual, not automatic, step, documented in a comment
at its point of use. `er_test_mod1`/`er_test_mod2`/`er_test_mod_gaussian`
are now built via `er_test_toy_model()` and are unconditionally available;
the ~20 inline `erglm::erglm_model()` calls scattered through
`test-er-plot-api.R`/`test-er-plot-layer.R`/`test-er-plot-style-model.R`/
`test-er-plot-theme.R`/`test-er-vpc.R` (all binomial/gaussian; none
Poisson) were migrated to `er_test_toy_model()` the same way. Across the
whole suite, `skip_if_not_installed("erglm")` usage dropped from 133
occurrences to 9 -- the 4 tests that genuinely need the Poisson fixture,
plus the 5 sync-check tests in `test-toy-model-sync.R` that exist
specifically to compare against a real erglm fit.

Since `helper-*.R` files load in alphabetical order and
`helper-toy-model.R` needs to be available before `helper-data.R` runs,
`helper-data.R` sources it explicitly (`source(testthat::test_path(...),
local = TRUE)`) rather than relying on load order; `local = TRUE` is
required so the sourced function lands in the same environment
`helper-data.R` itself is being evaluated in (the alternative,
`local = FALSE`, sources into `globalenv()`, which isn't necessarily an
ancestor of that environment under `testthat`/`pkgload`'s helper-loading
machinery).

Verified: `devtools::test()` (847 passing, the one pre-existing
`draw_quantiles` deprecation warning unaffected) and `devtools::check()`
(1 pre-existing `ERROR` -- a local environment mismatch between the
installed, CRAN-released `emaxnls` and the GitHub dev version erplots'
own `@examples` expect, unrelated to this change and present identically
before and after it; 0 warnings, 0 notes, both before and after).

## Planned work

See [PLAN.md](PLAN.md) for a condensed historical record of completed
design work (rationale kept, implementation narrative trimmed) and a
short "Open / deferred" list at the end.

**The one item flagged as genuinely open (not merely deferred) has since
been resolved.** `er_plot_add_model(mod, keep_strata = FALSE)` (or
omitting `stratify_by` from `er_plot()` altogether) on a model whose
formula has covariates beyond the exposure variable used to fail inside
the model's own `predict()` call, because `.get_model_predictions()`
built `newdata` from only the exposure grid (plus strata levels, if
stratified), with no way to know what other covariates the fitted
model's formula references. Fixed without needing to decide whose
responsibility filling those covariates in "should" be: since
`.get_model_predictions()` already has access to `object$data` (the
original fitting data), it now fills in every *other* column present in
`object$data` at a reference value (first factor level, mean for
numeric) before calling `er_predict()` -- an unused extra column is
harmless to a `predict()` call, so this works regardless of whether a
given column is actually in the model's formula, needs no formula
introspection, and required no upstream erglm/emaxnls changes. See
PLAN.md's "Completed: `keep_strata = FALSE` / missing-covariate
`newdata` crash" section for the full rationale and what was
deliberately *not* needed as a result (no `?er_model_interface`
contract change forcing model authors to defensively handle incomplete
`newdata` themselves; no `stats::terms()`/`all.vars()` introspection).

Everything else scoped so far is done, including several rounds not
reflected below (see PLAN.md for the condensed rationale of each): the
binary→continuous/count response generalisation (response-type
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
default. Later still: implementing `er_plot_theme()` (was a no-op
placeholder), fixing the no-layers-at-all crash, promoting the summary
layer to independence, the `er_summary()` `coefficients`/`glance`
contract, the `sim_resp` extension powering `er_vpc_plot(model = ...)`,
the missing-covariate `newdata` crash fix, and continuous
`color_continuous`/`fill_continuous` palette control in
`er_plot_theme()`, and confirming (once erglm actually removed
`erglm_vpc_sim()` upstream) that nothing in erplots -- code, tests,
docs, or vignettes -- still depended on it -- each covered in its own
section above, and each also recorded in PLAN.md as a completed entry.
The remaining genuinely-deferred items (not scheduled, no concrete need
yet) are in PLAN.md's "Open / deferred" section: an additive `model`
layer for overlaying two fitted curves; and whether a future
continuous/count `"panel"`-layout builder should use a deliberately
chosen continuous color scale instead of ggplot2's default gradient,
and whether it should be a quantile-binned rug instead of a
color-encoded scatter (both deferred along with `build_data_color()`'s
removal). A naming-scheme
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
above for the full rationale and two-phase sequencing. Most recently,
`summary_style` was itself promoted out of `er_plot_add_model()` into
its own peer layer, `er_plot_add_summary()`, with a new,
model-agnostic `er_style_summary_n()` builder added alongside the
migrated `er_style_summary_pvalue()` -- see "The summary layer is
independent of the model layer" above.

## Vignette structure

`vignettes/articles/` (pkgdown-only, not shipped -- see "Development
workflow" below) holds seven articles: `plot-binary.Rmd`,
`plot-continuous.Rmd`, and `plot-count.Rmd` (worked examples of each
layer, one per response type; binary is the most detailed, the other
two link back to it for the response-type-agnostic model/summary/group
components -- including a "Summary layer" section demonstrating
`er_style_summary_pvalue()`/`er_style_summary_gof()`, added after the
summary layer's promotion to independence; see "The `er_summary()`
return-value contract" above); `design.Rmd` ("The plotting grammar" --
the singleton/additive layer distinction, the stratification color/facet
precedence rule, and the response-type dispatch table); `theming.Rmd`
("Theming erplots" -- see its own paragraph below); `extending.Rmd`
("Extending erplots: writing your own builder"); and
`model-interface.Rmd` ("Implementing the model interface" -- see its own
paragraph below). `extending.Rmd` used to
be a section inside `design.Rmd`, but was split out into its own
article because it needed to grow -- the original version's illustrative
`build_quantile_crossbar()` example didn't explain what `config` (its
second argument) actually *was*, so `extending.Rmd` now leads with a
table of what each `.layer_*()` function's `config` contains (e.g.
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
what a `.layer_*()` function puts in `config`) -- that detail belongs in
`extending.Rmd`, not back in `design.Rmd`. All five articles were
re-rendered end-to-end via `rmarkdown::render()` after the
`style`/`er_style_*()` rename (see "Naming scheme" above) with no
errors and no leftover old-identifier references in the output.

`theming.Rmd` ("Theming erplots") documents `er_plot_theme()` -- one
section per argument group (labels, plot-level title/subtitle/caption,
axis limits, visual theme, discrete color/fill palette, formatters,
legend key glyph, panel heights), plus a section on the
accumulate/partial-update semantics of calling `er_plot_theme()` more
than once. It was added as a *standalone* article rather than a section
within `design.Rmd` or within each of `plot-binary`/`plot-continuous`/
`plot-count.Rmd`, on the reasoning that theming is an orthogonal concern
to the mini-language grammar (`design.Rmd`'s own opening paragraph
already disclaims covering "style options"; `er_plot_theme()` itself
never remaps which variable drives which aesthetic, only how the result
looks) and is response-type-/layer-agnostic (unlike everything else in
the three worked-example articles, which are organised by layer within
one response type) -- adding it to all three would have meant
near-verbatim triplication. Deliberately titled "Theming", not
"Styling", to avoid resurrecting the exact `style`/`theme` naming
collision the "Naming scheme" section above describes resolving.
Cross-referenced from: `design.Rmd` (a short "Theming is a separate
concern" pointer section, mirroring its existing "Extending erplots"
pointer, stating the layer-`style`-vs-plot-`theme` distinction);
`vignettes/erplots.Rmd` (a worked "Theming" section near the end, using
the stratified model already fitted earlier in that vignette, plus a
"Where to next" bullet); and one sentence each in `plot-binary.Rmd`/
`plot-continuous.Rmd`/`plot-count.Rmd`'s shared opening paragraph (no
new section in any of the three). `_pkgdown.yml`'s `articles` list
gained `articles/theming`, positioned after `articles/design` and
before `articles/extending`. In the same pass, fixed a
since-stale reference in `extending.Rmd`'s "what `theme` contains" table
(`theme$theme_base()` -> `theme$theme_base`), left over from the
`theme_base`/`theme_args` function-to-plain-object refactor described
above -- a reminder that a refactor to `object$theme`'s shape should
grep the vignettes for the old call convention, not just `R/`. All
touched/added articles/vignette re-rendered via `rmarkdown::render()`
with no errors; `devtools::test()` (618 passing) unaffected, since this
was a documentation-only change.

`model-interface.Rmd` ("Implementing the model interface") unpacks
`?er_model_interface`'s terse contract statement into a full worked
article aimed at maintainers of *other* modelling packages who want their
model classes to work with erplots -- distinct from `extending.Rmd`,
which is aimed at erplots *users* who want to change how a layer draws
an already-working model. Its target reader is assumed to already be
comfortable with S3 dispatch and `predict()` methods, so its prose is
noticeably terser/denser than the other five articles (a deliberate,
one-off departure from their style, agreed on for this article
specifically). It builds two self-contained, dependency-light toy model
classes from scratch (not relying on erglm/emaxnls internals) to
demonstrate each generic: `toy_model` (a tagged `glm` wrapper -- single
exposure coefficient, so `er_summary()` returns a bare `p_value`; the
`er_simulate()` method draws parameter vectors via `mvtnorm::rmvnorm()`
and adds a Bernoulli `sim_resp` on top of `fit_resp`, enough to exercise
both `er_style_model_spaghetti()` and `er_vpc_plot(model = ...)`) and
`toy_emax` (a tagged `nls()` Emax fit on `biomarker_change ~ aucss` --
three parameters with no single privileged term, so `er_summary()`
returns `p_value = NULL` and populates `coefficients` instead, paired
with `er_style_summary_coefficients()` rather than the default
`er_style_summary_pvalue()`; its `er_predict()` method computes a
delta-method CI via a hand-rolled numerical gradient, since
`predict.nls()` doesn't support `se.fit`/`interval` the way `predict.lm()`
does). A closing "Real-world implementations" section points to
erglm's/emaxnls's actual methods as the non-simplified analogues of
`toy_model`/`toy_emax` respectively, without duplicating their source.
`_pkgdown.yml`'s `articles` list gained `articles/model-interface` after
`articles/extending`. Rendered end-to-end via `rmarkdown::render()` with
no errors when added.

## Bundled example dataset: `erplots_data`

erplots ships its own simulated example dataset, `erplots_data`
(`data/erplots_data.rda`, generated by `data-raw/erplots_data.R`,
documented in `R/data.R`), so the package's own `@examples`/vignettes
don't have to depend on a `Suggests`-only companion package just to
demonstrate the mini-language, and so there's a dataset purpose-built to
exercise every response type and modelling scenario at once -- unlike
`erglm::erglm_data` (one exposure column) or `emaxnls::emax_df` (one
exposure column), this one has **three** continuous exposure columns and
is large enough (4,000 rows) to make raw-point overplotting genuinely
visible.

4,000 simulated subjects, one row each (cross-sectional, no repeated
measures): a placebo arm plus four active dose levels (`dose_mg`/
`dose_group`, ~800 subjects per arm), a few plausible covariates
(`bodyweight_kg`, `age_years`, `sex`, `renal_function`), three exposure
columns from a simplified, internally-consistent PK-flavored simulation
(individual clearance driven by bodyweight/renal function; `auc_ss`,
`cmax_ss`, `cmin_ss` -- not a literal PK/ODE model, just plausible and
correlated), and five response columns, each paired with the exposure
column and mechanism that makes it a clean fit for one modelling
scenario: `biomarker_change` (continuous, Emax on `auc_ss`), `responder`
(binary, Emax on the logit scale on `cmax_ss` -- e.g.
`emaxnls::emax_logistic()`), `adverse_event` (binary, plain log-linear
logistic regression on `auc_ss`), `symptom_score` (continuous, linear on
`cmin_ss`), and `n_events` (count, log-linear Poisson on `auc_ss`). All
five were validated by actually fitting each scenario against
`erglm`/`emaxnls` and confirming the simulated parameters were recovered.

A sixth column, `study_id` (`"Study 1"`-`"Study 4"`, unevenly sized --
400/800/1200/1600 subjects), is a purely administrative label generated
independently of dose/exposure/response, with no purpose other than
being convenient to filter on: subsetting to one study gives a much
smaller sample that still spans the full dose range, useful for
illustrating how a plot looks with less data (e.g. whether a raw-point
overlay becomes legible again once N drops, where at the full 4,000 rows
`er_style_data_hex()` is the better choice -- both are demonstrated in
`?erplots_data`'s `@examples`, guarded with `requireNamespace()` since
erglm/emaxnls remain `Suggests`-only).

`data-raw/` is excluded from the built package via `.Rbuildignore`
(the existing convention for non-shipped source). `vignettes/erplots.Rmd`
gained one short pointer sentence to `?erplots_data` near its existing
introduction of `erglm_data`; no dedicated walkthrough article was added
for this dataset (deferred, not scheduled -- see PLAN.md). Verified:
`devtools::document()`, `devtools::test()` (809 passing, unaffected --
this was additive), and `devtools::check()` (0 errors/warnings/notes).

## Structure

- `R/er-generics.R` -- the model interface: `er_predict()`,
  `er_simulate()`, `er_summary()` generics and their default methods.
- `R/er-plot-api.R` -- the `er_plot` object's core lifecycle only:
  `er_plot()`, `er_plot_build()`, and `print`/`plot` methods for the
  `er_plot` S3 class.
- `R/er-plot-add.R` -- the five pipeline verbs, `er_plot_add_model()`,
  `er_plot_add_summary()`, `er_plot_add_quantiles()`,
  `er_plot_add_data()`, `er_plot_add_groups()`. Each has its own
  dedicated Rd topic (no shared `@rdname`). Split out of
  `er-plot-api.R` in a file-organisation review -- see "File
  reorganisation" below.
- `R/er-plot-theme.R` -- `er_plot_theme()` and its `.check_theme_*()`
  validation helpers. Also split out of `er-plot-api.R`.
- `R/er-plot-layer.R` -- internal `.layer_*()` functions that assemble the
  configuration for each plot layer (this is where `er_predict()` /
  `er_simulate()` / `er_summary()` get called on the user-supplied model).
- `R/er-plot-build.R`, `R/er-plot-compose.R` -- internal plotting/layout
  machinery that turns parts into ggplot2 objects and composes them with
  patchwork.
- `R/er-plot-style-*.R` -- the pluggable `er_style_*()` partial builders
  (one file per component: `er-plot-style-model.R`,
  `er-plot-style-summary.R`, `er-plot-style-quantile.R`,
  `er-plot-style-data.R`, `er-plot-style-group.R`), plus
  `R/er-plot-style.R` (the shared-interface doc page, `?er_style`).
  `er-plot-style.R` also holds the actual builder-tagging code --
  `er_style_tag()` and its internal attribute readers/checker
  (`.style_layout()`, `.style_fill_role()`, `.style_y_role()`,
  `.style_layer()`, `.style_zorder()`, `.check_style_layer()`) --
  moved here (from `er-plot-api.R`) since this is the file that already
  documents the tagging concept; see "File reorganisation" below for
  why each `er-plot-style-{data,group,model,quantile,summary}.R` file
  carries a roxygen `@include er-plot-style.R` tag. See `?er_style` for
  the interface these builders share.
- `R/er-vpc.R` -- `er_vpc_plot()`, a model-agnostic VPC-style plot
  operating on plain observed/simulated data frames, or (preferred) a
  `model` argument that goes through `er_simulate()`'s `sim_resp`
  extension -- see "`er_vpc_plot()` and the `sim_resp` extension to
  `er_simulate()`" above.
- `R/utils-helpers.R` -- small internal helpers (including the
  binary-response-only `ci_clopper_pearson()`, `ci_t()`,
  `ci_poisson()`, `cut_quantile()`, `cut_exposure_quantile()`, and the
  response-type detector `.detect_response_type()`) and, at the bottom
  of the file, the `globalVariables()` declarations for NSE (folded in
  from the former `R/utils-global.R` -- see "File reorganisation"
  below).
- `R/data.R` -- roxygen documentation for the bundled `erplots_data`
  dataset (the object itself lives in `data/erplots_data.rda`, generated
  by `data-raw/erplots_data.R`; see "Bundled example dataset" above).

## File reorganisation: splitting up `er-plot-api.R`

A file-organisation review found that `R/er-plot-api.R` had grown to
1255 lines and drifted into mixing four distinct concerns: the
`er_plot` object's core lifecycle (`er_plot()`, `er_plot_build()`,
`print`/`plot` methods), theming (`er_plot_theme()` plus its
`.check_theme_*()` validators), the builder-tagging machinery
(`er_style_tag()` plus its attribute readers), and the five
`er_plot_add_*()` pipeline verbs. Every other `R/` file was checked at
the same time and found to already match its filename/purpose, so no
other splits were made. This was a pure move -- no code or roxygen
content changed, only which file each function lives in.

`er-plot-api.R` was trimmed to just the lifecycle functions.
`er_plot_theme()` and its validators moved to a new `R/er-plot-theme.R`.
The five `er_plot_add_*()` verbs moved to a new `R/er-plot-add.R`,
kept together (rather than split one-per-layer) since they share a
common validation pattern and this mirrors how `er-plot-layer.R`/
`er-plot-build.R` already hold all five layers' internals in one file
each. `er_style_tag()` and its attribute readers moved into the
existing `R/er-plot-style.R` -- previously pure roxygen documentation
(the `?er_style` topic) with no code of its own -- making it the actual
home of the tagging machinery it already documented.

That last move surfaced a genuine load-order bug: `er_style_tag()` is
called at *package load time* (not just inside a function body) by
every built-in `er_style_*()` builder, e.g. `er_style_data_overlay <-
er_style_tag(function(...) ..., layout = "overlay", layer = "data")`
at the top level of `er-plot-style-data.R`. R sources `R/*.R` files in
alphabetical order by default (no `Collate` field existed before this
change), and `"er-plot-style-data.R"` (etc.) sort *before*
`"er-plot-style.R"` (`-` sorts before `.`) -- so moving `er_style_tag()`
into `er-plot-style.R` broke every other style file's load, each
failing with `could not find function "er_style_tag"`. This worked
by accident before the split, only because `er-plot-api.R` happened to
sort alphabetically before all five `er-plot-style-*.R` files.

Fixed properly rather than by renaming files to force a lucky sort
order: each of `er-plot-style-{data,group,model,quantile,summary}.R`
now carries a roxygen `#' @include er-plot-style.R` tag (placed after
each file's title/description, alongside its `@param`s -- putting
`@include` as the literal first line of the block instead breaks
roxygen2's title detection, silently producing a title-less/
description-less `.Rd` page). `devtools::document()` reads these tags
and writes the resulting order into `DESCRIPTION`'s `Collate` field
automatically, so load order is now explicit and enforced rather than
an accident of alphabetical filenames. If a future builder file is
added that calls `er_style_tag()` (or anything else from
`er-plot-style.R`) at its own top level, it needs the same `@include`
tag.

In the same pass, `R/utils-global.R` (a 30-line file holding only a
single `utils::globalVariables()` call) was folded into the end of
`R/utils-helpers.R` and deleted, since a whole file for one
declaration was its own small case of over-fragmentation.

Verified: `devtools::document()` (regenerated `Collate` cleanly, no
broken `@include`/link warnings once run in a fresh session --
roxygen2 raised transient "could not resolve link" warnings when
re-run in an R session that already had an older `erplots` loaded,
which cleared up on a fresh `Rscript -e 'devtools::document()'`; not a
real problem, just a reminder that repeated in-session
`devtools::document()` calls can show stale-link noise),
`devtools::test()` (847 passing, unchanged), and `devtools::check()`
(0 errors/warnings/notes).

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

## r-universe: `Suggests: emaxnls (>= 0.1.1.9000)` guards against resolving the CRAN release instead of the dev build

erplots is published on r-universe (`djnavarro.r-universe.dev`), whose
build/check pipeline installs `Suggests`/`Remotes` dependencies itself
rather than relying on a pre-populated library. This broke once
`emaxnls` was published to CRAN (as plain `emaxnls`, version `0.1.1`):
that CRAN release predates erplots integration entirely (no
`emax_logistic()`/`emaxlogistic` class, and -- confirmed by inspecting
its installed `NAMESPACE` -- no `S3method()` registration for
`er_predict`/`er_simulate`/`er_summary`, even though an
`er_predict.emaxnls()` function happens to still exist internally from
an earlier partial merge; without the `S3method()` entry, `UseMethod()`
dispatch never finds it). With an unconstrained `Suggests: emaxnls`,
r-universe's dependency resolver treated the CRAN release as a
perfectly valid match for the `Suggests` entry and didn't fall through
to the `Remotes: djnavarro/emaxnls` GitHub source (`Remotes:` is
generally only forced when CRAN can't satisfy a dependency at all, or a
version constraint requires it -- with both a CRAN and a Remotes
candidate satisfying an unconstrained dependency, precedence isn't
guaranteed to favor Remotes). The result: every `@examples` block using
`emax_nls()`/`emax_logistic()` followed by `er_plot_add_model()` failed
on r-universe's real build targets (linux/macos/windows; `wasm` and the
plain `source` build happened not to hit the failing code path) with
`Error in er_predict(): No 'er_predict()' method is available for
objects of class <emaxnls>.` -- reproduced locally by installing
`emaxnls` from CRAN alone (`0.1.1`, dispatch fails) versus from
`djnavarro.r-universe.dev` (`0.1.1.9000`, dispatch works).

Fixed by pinning a version floor in `DESCRIPTION` that only the GitHub
dev build satisfies: `Suggests: emaxnls (>= 0.1.1.9000)`. This removes
the ambiguity -- CRAN's `0.1.1` no longer satisfies the constraint, so
the resolver must fall through to `Remotes: djnavarro/emaxnls`. No
equivalent fix was needed for `erglm`, since it remains GitHub-only (not
on CRAN) and so has no competing CRAN candidate to be resolved
ambiguously against.

**This constraint needs revisiting once emaxnls's own CRAN release
catches up.** Once a future CRAN release of emaxnls actually registers
the `er_predict`/`er_simulate`/`er_summary` S3 methods, this pin should
either be dropped (if that CRAN version is an acceptable floor on its
own) or bumped to whatever new dev-only feature, if any, erplots next
comes to depend on -- don't just leave `>= 0.1.1.9000` in place
indefinitely once it's no longer the operative constraint.

## Conventions

- Use the base R pipe (`|>`), not the magrittr pipe.
- Follow the existing tidyverse-style conventions (dplyr/tibble/rlang/
  ggplot2/patchwork) already used throughout.
- Naming families (see "Naming scheme" above for the full rationale):
  pipeline layer-adders are `er_plot_add_*()` (verbs); partial builders
  are `er_style_*()` (noun phrases naming the visual idiom, with the
  layer name as the second token), selected via each layer-adder's
  `style` argument; confidence-interval helpers are
  `ci_*()` (noun phrases naming the statistical method); internal
  helpers are prefixed with `.`. "Builder" remains fine as ordinary
  English prose for "a function you write to build geoms" -- only the
  actual API symbols (function/argument names, exported helpers,
  attributes) use the `style` vocabulary.
- Never call a model-fitting function from this package. If a plot
  component needs something from the model, add or extend a generic in
  `R/er-generics.R` instead of reaching into model internals.
