---
name: write-roxygen-docs
description: Guidance for writing and reviewing roxygen2 documentation comments in the erplots R package. Use whenever adding a new exported function, editing an existing @param/@returns/@details/@examples block, or reviewing a roxygen comment before running devtools::document().
---

# Writing roxygen2 Documentation

Roxygen comments become the content of `?function` and the pkgdown reference
site — they are read by a human user deciding whether and how to call a
function, not by a future contributor or an agent. Getting the mechanics
right (tags, `@export`, blank lines) is the easy part; agents reliably get
that right already. The failure modes worth guarding against are about
*content*: putting the wrong thing in a section, writing at the wrong level
of detail, or leaking information that shouldn't be there at all.

This skill assumes familiarity with roxygen2 basics. For deeper background on
any topic below, see [R Packages (2e), ch. 16](https://r-pkgs.org/man.html).

## What goes where

Each part of the introduction has a distinct job. Don't let content drift
into the wrong one:

- **Title** (first sentence, sentence case, no full stop): what the function
  does, distinguishing it from sibling functions. erplots' three model-layer
  builders, `er_style_model_line()`, `er_style_model_ribbonline()`, and
  `er_style_model_spaghetti()`, are distinct visual idioms behind a shared
  `style` argument (not one builder with a mode switch), so their titles
  should each name the idiom (a bare fitted line; a fitted line plus a
  ribbon; a spaghetti plot of simulated draws), not a generic verb like
  "Draw the model layer" that could describe any of the three. The same
  applies to a builder pair sharing everything but which side of an
  observed/simulated comparison they draw, e.g.
  `er_style_vpc_observed_mean_errorbar()`/
  `er_style_vpc_simulated_mean_errorbar()`: each title should say which side
  it computes, not just repeat "mean/errorbar idiom" for both.
- **Description** (next paragraph): one paragraph on *this* function's
  purpose, in different words than the title — not a restatement of it, and
  not a template copied from a sibling function. It's easy to start a new
  quantile builder (say, a third option alongside
  `er_style_quantile_errorbar()`/`er_style_quantile_pointrange()`) by
  copying an existing one's docs and forget to re-target the description;
  the tell is a description that reads correctly for *either* builder but
  never actually says what makes this one distinct (e.g. "draws an error
  bar" vs "draws a point with a range line") — that's a sign the real
  description got left in `@details` instead. It's just as easy to skip the
  description paragraph entirely — roxygen2 doesn't warn you, it silently
  reuses the title as the description, which is *always* a restatement by
  construction.
- **`@details`**: everything else — default behaviour, edge cases, how an
  argument being `NULL` is treated (e.g. `model = NULL` in
  `er_plot_add_summary()` meaning no model-derived statistic, just a plain
  observation-count annotation; `seed = NULL` in the jittered builders
  meaning jitter draws from the ambient RNG stream rather than a fixed one),
  interactions with other parts of the plotting pipeline (e.g. how a data
  builder's `layout` tag determines whether it lands in
  `object$layer$overlay` or `object$layer$data`, and clears the other). It's
  fine for this to be a few sentences to a short paragraph. Details render
  *after* arguments and return value on the help page, so don't put
  anything here that a reader needs before they can parse `@param`.
- **`@param`**: a succinct summary of what the argument controls and, if it
  has a fixed set of values (like `response_type` or a builder's `layout`),
  what they are. State the default inline (e.g. "Defaults to `\"auto\"`")
  since the usage block and the argument description are far apart on the
  rendered page. When the default is a sentinel like `NULL` whose *effect*
  isn't obvious from the value itself, say what it does rather than just
  naming it (e.g. "If `NULL` (the default), no model-derived statistic is
  shown" reads better than "the default is `model = NULL`", which tells the
  reader nothing until they go read `@details` too).
- **`@returns`**: the shape of the return value — for `er_plot()`/
  `er_vpc()`/`er_tte()`, the class of the returned specification object
  (`"er_plot"`, `"er_vpc"`, `"er_tte"`); for the `er_plot_add_*()`/
  `er_vpc_add_*()`/`er_tte_add_*()` verbs, that they return the same class
  with one layer added/replaced; for `er_plot_build()`/`er_tte_build()`,
  the concrete `ggplot2`/`patchwork` object produced; for a `ci_*()`
  helper, the named list or tibble of bounds it returns. Every exported
  function must have this tag.
- **`@examples`**: runnable code showing typical usage. Not a place to
  re-explain arguments already covered in `@param`. erplots never fits a
  model itself, so a self-contained model-layer example needs either a
  companion package (`erglm`/`emaxnls`/`ertte`, each `Suggests`-only, so wrap
  in `if (requireNamespace(\"erglm\", quietly = TRUE)) { ... }`) or the
  package's own tiny test-fixture model where one is exported for
  documentation use; a plain
  `er_plot(erplots_data, auc_ss, responder) |> er_plot_add_quantiles() |> plot()`
  needs neither and is a complete, fast example for anything not requiring
  a fitted model.

## Calibrating detail

Match documentation density to how novel the content actually is:

- Across a shared-signature builder pair — e.g.
  `er_style_vpc_observed_mean_errorbar()`/
  `er_style_vpc_simulated_mean_errorbar()`, or the `_quantile_errorbar()`
  observed/simulated pair — the argument shape is identical (`data`,
  `config`, `stratify`, `exposure`/`time`, `theme`, `...`, per `?er_style`).
  That similarity belongs in the shared interface doc (`?er_style`,
  `?er_model_interface`) or the layer-adder's own docs, not restated at
  length in every builder's page. Spend the words on what's actually
  distinctive: which side of the observed/simulated comparison a builder
  draws, or how its x-position adapts to `object$group$type` versus staying
  fixed.
- A dense wall of text is harder to scan than the same information broken
  into a sentence or two per idea, or a short bullet list (roxygen2 markdown
  supports `* item` lists in any prose section). Prefer that when an
  argument has more than two or three possible values or behaviours (e.g.
  `response_type`'s four values, or `er_style_tag()`'s seven independent
  attributes).
- Don't pad a short, genuinely simple function's documentation just to make
  it look thorough. `er_plot_add_groups()`'s additive-not-singleton
  behaviour, or a `ci_*()` helper, are compact by design; if the description
  already says everything, an empty or one-line `@details` — or omitting
  the tag — is correct.
- Once `@details` covers more than three or four distinct sub-topics (e.g.
  `er_style_tag()` documenting `layout`, `fill_role`, `y_role`, `layer`,
  `zorder`, and the two VPC-only type-checking attributes together), break
  it into markdown headings or `@section` blocks, one per sub-topic, instead
  of one long unbroken block of paragraphs. A reader looking for one
  specific fact shouldn't have to read the whole section serially to find
  it.
- `@section` titles must be capitalized (R Core's own
  [Rd file guidelines](https://developer.r-project.org/Rds.html) state this
  explicitly for both `\title` and `\section` titles). Don't just reuse a
  lowercase identifier verbatim as a heading — prefer a short, readable
  capitalized phrase, and refer to the actual identifier in the body text
  instead, in backticks.

## Keep it user-facing

Roxygen documentation ships to end users via `?function` and pkgdown. It is
governed by the same boundary as `NEWS.md` (see the `write-news-entries`
skill):

- **Never reference agent- or contributor-facing material.** No mentions of
  skills, `AGENTS.md`, `.agents/HISTORY.md`/`.agents/PLAN.md`, or CI
  configuration.
- **Don't name internal dot-prefixed helper functions or otherwise describe
  implementation details that could change.** Explain behaviour in terms of
  what the function does and what the user observes (inputs accepted,
  outputs produced, what the built plot contains), not the private helper
  functions or code paths used to get there. This applies even when the
  temptation is to point at *how* a documented result is computed — e.g.
  document that a stratified `er_tte_add_curve()` legend is titled from
  `stratify_by`'s label, but not that this happens via
  `.polish_tte_labels()`; document that `er_plot_add_data()` clears the
  layer slot not selected by the builder's `layout`, but not that this goes
  through `.layer_data()`. Naming a dot-prefixed internal function in
  documentation also invites users to reach for it with `:::`, which is
  best avoided. If you find yourself writing "internally, this calls..." or
  "`.layer_tte_curve()` is used to...", cut the function name and keep only
  the behavioural consequence.

  Note: several existing roxygen blocks in this package (e.g.
  `er_style_tte_curve()`, `er_style_tte_model()`, `er_style_tte_censor()`,
  `er_style_tte_pvalue()`, `er_style_tte_risktable()`) currently *do* name
  internal helpers like `.layer_tte_curve()` or `.polish_tte_labels()` in
  `@details`. That predates this rule and is tracked as cleanup, not a
  pattern to extend — don't use existing docs as a precedent when writing
  new ones.
- **Write for a reader who has never seen the source.** Avoid phrasing that
  only makes sense with the R script open (e.g. "as shown above", "the
  config list described earlier" referring to code, not prose already in
  the same doc).
- **Cross-reference with square brackets, not just backticks.** Writing
  `` `er_plot_add_model()` `` renders as code but produces no link;
  `[er_plot_add_model()]` (or `[ertte::er_predict_survival()]` for another
  package) is what roxygen2/pkgdown turn into an actual hyperlink. A
  backtick-only mention anywhere a function is referenced — in `@details`,
  `@seealso`, or prose — is a broken cross-reference, not a stylistic
  choice. When the natural link text is a function call but the useful
  target is a different topic, use `` [`function()`][topic] `` for custom
  link text rather than linking to a less useful default target — e.g.
  `` [`er_plot_add_model()`][er_style] `` when the useful target is the
  shared builder-interface page rather than the verb's own.
- **Check the compiled `.Rd` for stray aliases, not just the prose.** A
  `@name`/`@rdname` block (shared docs for several functions/methods)
  attaches to whichever R object immediately follows it in the file. If an
  internal, unrelated object sits between the block and its intended first
  function, roxygen2 silently attaches the block to that object instead and
  gives it a public `\alias`, which can surface as nonsense in the rendered
  `\usage{}`. Reading the roxygen comments won't reveal this; open the
  generated `man/*.Rd` and check that every `\alias{}` is something the
  topic is actually meant to document.
- **A `@name`-only doc page (a conceptual topic with no function attached,
  e.g. `?er_style`, `?er_model_interface`) must not use `@param`.** `@param`
  makes roxygen2 emit a formal `\arguments` section; R-devel NOTEs any Rd
  file that has `\arguments` without a matching `\usage` (this bit erplots
  for real on a CRAN Debian pretest, see `AGENTS.md`'s "Gotchas" section).
  Every `@name`-only page in this package that has a real function
  immediately following it with `@rdname` pointing back (e.g.
  `er_style_group`, `er_style_summary`, `er_vpc`, `er_plot`) gets a genuine
  `\usage` from that function's formals and can use `@param` freely; a page
  with no such function (like `?er_style` itself) must describe its shared
  argument list in a plain `@section Arguments:` (a markdown bullet list)
  instead.

## Checklist before finishing a roxygen block

- [ ] Title names what's distinctive about this function (visual idiom,
      observed vs. simulated side, or generic contract vs. a specific
      builder); description says the same thing in different words, not a
      restatement of the title.
- [ ] Description actually describes *this* function/builder, not a
      template inherited from a sibling that describes the family in
      general instead.
- [ ] An explicit `@description` paragraph was actually written, distinct
      from the title — not left to roxygen2's default of silently reusing
      the title verbatim.
- [ ] Everything in `@details` is genuinely additional to the description,
      not filler to make the section non-empty.
- [ ] If `@details` covers more than three or four sub-topics, it's broken
      into headings/`@section`s rather than left as one long block.
- [ ] Every `@section` title is capitalized, and reads as a short phrase
      rather than a bare lowercase identifier copied from the code.
- [ ] Every `@param` states the default where one exists, and enumerates
      fixed value sets (e.g. `response_type`, a builder's `layout`).
- [ ] `@returns` is present and names the concrete class/shape returned.
- [ ] Every reference to another function (in `@details`, `@seealso`, or
      prose) uses square brackets so it actually renders as a link, not
      backticks alone.
- [ ] No mention of skills, `AGENTS.md`, `.agents/*.md`, CI, or other
      agent/contributor-facing material.
- [ ] No description of implementation details a user would need `:::` to
      verify, and no named internal `.`-prefixed helper — only observable
      inputs/outputs/behavior (unless it's one of the pre-existing
      `er_style_tte_*()` exceptions noted above, tracked as cleanup).
- [ ] A `@name`-only topic with no function immediately following it (e.g.
      `?er_style`) uses `@section Arguments:` instead of `@param`, to avoid
      an Rd file with `\arguments` but no `\usage`.
- [ ] For `@name`/`@rdname` topics, every `\alias{}` in the compiled
      `man/*.Rd` is something the topic is actually meant to document — no
      internal object picked up by accident.
- [ ] Ran `devtools::document()` and skimmed the rendered `man/*.Rd` (or
      `?function` output) rather than just the roxygen comment source. If
      the fix touched code (not just comments) — e.g. reordering
      definitions to fix an alias leak — also ran `devtools::test()`.
