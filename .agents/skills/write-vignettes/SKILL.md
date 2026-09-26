---
name: write-vignettes
description: Guidance for writing and reviewing pkgdown articles (vignettes/articles/*.Rmd) in the erplots R package. Use whenever drafting a new article, restructuring an existing one, or reviewing one for stylistic consistency before it ships.
---

# Writing erplots vignettes

erplots' articles (`vignettes/articles/*.Rmd`, see the "Vignette structure"
section of `AGENTS.md`) are tutorial prose for a human user deciding how to
use the package, rendered by pkgdown and never shipped inside the built
package. That audience and delivery mechanism shape everything below: write
for someone reading the rendered HTML page, not the `.Rmd` source, and never
assume they've read another article first unless you link them there
explicitly.

This skill distills conventions already established across the package's
existing articles (`design.Rmd`, `theming.Rmd`, `extending.Rmd`,
`model-interface.Rmd`, `plot-binary.Rmd`/`plot-continuous.Rmd`/
`plot-count.Rmd`, `plot-vpc.Rmd`, `plot-tte.Rmd`, `internals.Rmd`) plus
general prose-quality guidance adapted from a similar skill written for a
different repo (djnavarro/minis' `writing-vignettes` skill) and from another
package's well-regarded vignettes (djnavarro/sessioncheck). Follow erplots'
own existing conventions where they conflict with either external source --
they're listed below precisely because they've already been applied
consistently across nine-plus articles, and a new article should read like
it belongs with the others.

## Mechanics

- **Frontmatter is title-only**: `title: "..."`, no `author`/`date`. Match
  the article's role in `_pkgdown.yml`'s `articles:` navbar grouping when
  choosing a title -- it's what readers see in the nav dropdown, not just
  the page `<h1>`.
- **Standard setup chunk**, verbatim, immediately after the frontmatter:
  ```{r, include = FALSE}
  knitr::opts_chunk$set(
    collapse = TRUE,
    comment = "#>"
  )
  ```
- **A `setup` chunk** (`` ```{r setup} ``) loads `library(erplots)` plus
  whatever companion package the article's examples need
  (`erglm`/`emaxnls`/`ertte`) -- these are `Suggests`-only dependencies of
  erplots itself, but articles are pkgdown-only (excluded from the built
  package, see `.Rbuildignore`) and rendered in a controlled environment, so
  there's no `requireNamespace()`/`eval = requireNamespace(...)` guard in
  any existing article. Don't add one unless a companion package genuinely
  becomes optional for that specific article's content.
- **Chunk labels are short and kebab/snake-cased** (`fit`, `basic-plot-1`,
  `stratification-2`, `summary-pvalue`), one per logical step, not one giant
  unlabelled chunk per section.
- **`##`/`###` headings** structure the body; a short article
  (`theming.Rmd`) uses flat `##` sections, a longer one nests `###`
  subsections under a `##` per response type or scenario (`plot-vpc.Rmd`'s
  `## Binary response` / `### VPC by exposure` pattern). Keep heading depth
  to two levels -- no article currently goes to `####`.

## Opening paragraph

State what the article is *for* and, in the same paragraph or the next,
what it deliberately does **not** cover, pointing at the article that does.
This "scope fence" appears in nearly every existing article and heads off a
reader wondering why some adjacent topic isn't here:

> The goal of this article is to describe the **grammar** that erplots uses
> to generate exposure-response plots. It's not intended to describe all the
> style options available to users, or cover the mechanics of how plots are
> constructed. If you want to see those in more detail, there are articles
> covering [binary](plot-binary.html), [continuous](plot-continuous.html),
> and [count](plot-count.html) response data.

A tutorial-style article (the three `plot-*.Rmd` articles, `theming.Rmd`)
instead opens by naming the concrete thing it walks through and the model
object the examples will use, then narrows to what makes *this* article
distinct from its response-type siblings (e.g. `plot-binary.Rmd` is "the
most detailed" per `AGENTS.md`; `plot-continuous.Rmd`/`plot-count.Rmd` link
back to it for shared content rather than re-explaining the model/summary/
group layers).

## Cross-referencing between articles

- Links between articles are **relative, extensionless-source but
  `.html`-rendered**: `[theming erplots](theming.html)`,
  `[the plot grammar article](design.html)`. Never link to the `.Rmd`
  source or use an absolute URL for another article in this package.
- Link text is a short descriptive phrase naming what the reader will find
  there ("the plot grammar article", "Implementing the model interface"),
  not a bare filename or "here".
- A link can target a specific heading via its slug, e.g.
  `[continuous](plot-continuous.html#quantile-layer)` --
  `plot-binary.Rmd`/`plot-continuous.Rmd`/`plot-count.Rmd` use this
  extensively to point at the equivalent section in a sibling article
  instead of restating it.
- Function names referenced in prose are backtick-quoted
  (`` `er_plot_add_model()` ``); pkgdown does not auto-link these the way
  `NEWS.md`/roxygen do, so a function that's genuinely a subject of the
  article's discussion (not just mentioned in passing) is usually also
  covered by a cross-reference link to the article that explains it, not
  left as a bare code span with no way to learn more.
- Do not bold package names (erplots, erglm, emaxnls, ertte) in prose --
  unlike the minis repo's convention of bolding a source package's first
  mention, erplots articles just use the plain word ("erplots never fits a
  model", "fitted using the erglm package"). Reserve bold for genuinely new
  terminology being introduced (e.g. **grammar**, **restart the R
  session**-style emphasis on a key recommendation).

## Sentence-level style

- **Second person for instructions, third person for the package's own
  behaviour.** "You then pipe it through one or more layer functions" /
  "erplots expects you to fit the model yourself and pass it in explicitly."
  A pedagogical first-person plural ("We'll start by showing the
  limitations of the default style...", "we bin by `weight` instead") is
  established practice for walking the reader through a worked example
  step by step, and is fine to use for that purpose -- it reads as "you and
  I, working through this together," not as an author inserting personal
  opinion. Avoid singular first person ("I") -- `extending.Rmd` currently
  uses it twice and both are worth fixing, not a pattern to extend. Don't
  reach for "we" outside a pedagogical walkthrough (e.g. as a stand-in for
  "erplots" itself, or to hedge an opinion -- "we think this is usually
  best" should just be stated as fact or attributed to the reader's
  situation instead).
- **Starting a sentence with a code span is fine and already common**
  (`` `er_plot_theme()` slots into the same pipeline... ``) -- this differs
  from the minis skill's "never start a sentence with inline code" rule,
  which doesn't reflect erplots' own established practice. Don't force a
  noun in front of every code-initial sentence; only add one where it
  genuinely reads better.
- **Avoid unexplained jargon.** Where a term is genuinely necessary
  (singleton/additive, layout family, zorder), it's the article's job to
  define it in prose the first time it's used, not assume the reader
  already knows the internal vocabulary from `AGENTS.md`.
- **British/Australian spelling**: colour, behaviour, visualise, centred.
- **Conversational but not chatty.** Contractions ("it's", "doesn't") and
  short asides are fine; keep asides about the *package's* behaviour and
  design rationale, not about the writing process itself.
- **State the "why", not just the "what", for a design choice a reader
  might otherwise think is arbitrary** -- e.g. `plot-binary.Rmd` explaining
  *why* erplots doesn't fit the model itself, `theming.Rmd` explaining that
  every `er_plot_theme()` argument defaults to `NULL` meaning "leave
  unchanged" (not just stating the fact, but that this is what lets
  repeated calls accumulate).

## Scope discipline specific to this package

- **Never call a model-fitting function inside example code without
  narrating it as the user's own responsibility.** Every article that fits
  a model (`erglm_model(...)`) says so explicitly near the first such call
  -- this isn't incidental prose, it's reinforcing the package's own "erplots
  never fits a model" design rule from `AGENTS.md` for the reader.
- **No agent-facing content in the rendered article body** -- no mention of
  skills, `AGENTS.md`, or `.agents/*.md`. The one sanctioned exception is an
  HTML comment marked `<!-- agent-note: ... -->` (as in `design.Rmd`),
  which is invisible in the rendered page and exists purely to flag, to a
  future editor, that a specific kind of package change (e.g. renaming a
  layer, changing singleton/additive semantics) obligates an update to that
  article. Add one of these when writing an article that documents
  something likely to drift silently out of sync with the code, matching
  `design.Rmd`'s existing wording style; don't add one to every article
  reflexively.
- **`internals.Rmd`-style disclaimer banner**: an article documenting
  genuinely unstable, unexported internals (not the public API) opens its
  body with a blockquote flagged `> **This article documents an
  implementation detail, not a public interface.**`, explaining what's
  unstable and why nothing should depend on it. Reuse this pattern verbatim
  in tone if a future article needs to document another internal-only
  topic; don't apply it to an article about public, documented functions.
- **Keep `design.Rmd`/`extending.Rmd` in sync with the grammar itself.** Per
  `AGENTS.md`'s "Vignette structure" section, a change to the plotting
  grammar that affects builders (a new `er_style_tag()` argument, a change
  to what a `.layer_*()` function puts in `config`) must be reflected in
  both articles in the same change -- `design.Rmd` states the concept,
  `extending.Rmd` should only point to it, not duplicate it.

## Final step: cross-article consistency check

After writing or editing one or more articles, skim the others for drift
this change should have introduced but might have missed:

- A sibling article (e.g. `plot-continuous.Rmd`/`plot-count.Rmd` relative to
  `plot-binary.Rmd`) that links to a heading slug you just renamed.
- A builder/layer table (`extending.Rmd`'s layer/builder table,
  `design.Rmd`'s pipeline diagram) that's now missing a new builder or still
  lists a renamed/removed one.
- Terminology introduced in one article (bolded on first use) that a later
  article uses without that same bolding or a different word for the same
  concept.
- Typos, doubled words, and stray double-spaces -- easy to introduce while
  editing one article and easy to miss without rereading it alongside its
  neighbours.

Re-render any touched article (pkgdown build, or
`rmarkdown::render()`/knit it directly) and read the actual rendered output,
not just the `.Rmd` source, before considering the edit done -- code chunk
output and cross-reference links are exactly the things that look fine in
source but break silently when rendered.

## Checklist before finishing an article

- [ ] Frontmatter is title-only; the article is wired into
      `_pkgdown.yml`'s `articles:` section under the right navbar group.
- [ ] Standard `knitr::opts_chunk$set(collapse = TRUE, comment = "#>")`
      chunk and a labelled `setup` chunk are present.
- [ ] Opening paragraph states the article's purpose and, if relevant, what
      it deliberately excludes with a link to where that lives instead.
- [ ] Cross-article links use the relative `article-name.html` form (with
      an `#anchor` where linking to a specific section), never the `.Rmd`
      source or an absolute URL.
- [ ] No package name is bolded in prose; genuinely new terminology is
      bolded on first introduction only.
- [ ] Second/third person throughout; any first-person plural is
      pedagogical ("we'll..." walking through a worked example) rather than
      a stand-in for the package or an inserted opinion, and there's no
      singular "I".
- [ ] British/Australian spelling used consistently.
- [ ] Any example that fits a model narrates that the user is doing so
      themselves, consistent with "erplots never fits a model".
- [ ] No agent-facing material in the visible article body; an
      `<!-- agent-note: ... -->` comment is used only where a future code
      change should trigger a rewrite of this specific article.
- [ ] If the edit changed the plotting grammar itself, `design.Rmd` and
      `extending.Rmd` were both checked and updated together.
- [ ] The rendered output (not just the `.Rmd` source) was checked after
      editing, and sibling articles were skimmed for links/terminology/
      tables that now need updating too.
