# Safety net for the "Styles" section rollout (see AGENTS.md/PLAN.md):
# every `_add_*()` function's .Rd is meant to carry a `\section{Styles}{}`
# block with one row per builder registered for that layer, so a user
# reading `?er_plot_add_model` etc. sees every available `style` choice
# and a link to its own help page without having to guess names from
# `@param style`'s prose first. This file guards against two ways that
# table can drift out of sync with the actual registry in
# `R/er-style-registry.R`:
#
#   1. A layer's .Rd never gets a `Styles` section in the first place.
#   2. A new builder is registered (`er_style_tag(fn, layer = ..., label
#      = ...)`) but nobody adds its row to the existing table.
#
# It intentionally does *not* check the one-sentence description text
# itself -- that's free-form prose reviewed by eye at PR time -- only
# that every currently-registered label string appears somewhere inside
# the section, and that there's roughly one `[er_style_*()]`-style
# cross-reference per label (a proxy for "each row links to its
# builder's own doc page", without hard-coding every builder's name).
#
# Written before the table rollout itself: every `test_that()` below is
# expected to fail until that layer's .Rd gains its `Styles` section,
# and to stay green afterwards as new builders are added.

# Canonical layer -> .Rd file mapping. Kept as a single named vector so
# adding a thirteenth grammar/layer someday means editing one line here,
# not restructuring the test.
.styles_sync_rd_files <- c(
  plot_model     = "er_plot_add_model.Rd",
  plot_summary   = "er_plot_add_summary.Rd",
  plot_quantile  = "er_plot_add_quantiles.Rd",
  plot_data      = "er_plot_add_data.Rd",
  plot_group     = "er_plot_add_groups.Rd",
  vpc_observed   = "er_vpc_add_observed.Rd",
  vpc_simulated  = "er_vpc_add_simulated.Rd",
  tte_curve      = "er_tte_add_curve.Rd",
  tte_censor     = "er_tte_add_censor.Rd",
  tte_risktable  = "er_tte_add_risktable.Rd",
  tte_model      = "er_tte_add_model.Rd",
  tte_summary    = "er_tte_add_summary.Rd"
)

# Extracts the plain-text body of `\section{<section>}{...}` from an .Rd
# file's source, tracking brace depth so nested `\code{}`/`\link{}` etc.
# inside the section don't truncate the match early. Returns
# `NA_character_` if the section tag isn't present at all.
.read_rd_section <- function(rd_path, section) {
  if (!file.exists(rd_path)) return(NA_character_)

  txt <- paste(readLines(rd_path, warn = FALSE), collapse = "\n")
  pattern <- paste0("\\\\section\\{", section, "\\}\\{")
  m <- regexpr(pattern, txt, perl = TRUE)
  if (m[1] == -1) return(NA_character_)

  start <- m[1] + attr(m, "match.length")
  n <- nchar(txt)
  depth <- 1L
  i <- start
  while (depth > 0L && i <= n) {
    ch <- substr(txt, i, i)
    if (ch == "{") depth <- depth + 1L
    if (ch == "}") depth <- depth - 1L
    i <- i + 1L
  }

  if (depth > 0L) {
    # Unbalanced braces -- treat as "section not found" rather than
    # returning a truncated/garbage body.
    return(NA_character_)
  }

  substr(txt, start, i - 2L)
}

test_that("the layer -> .Rd mapping covers every registered layer, and vice versa", {
  registered_layers <- unique(er_style_labels()$layer)
  expect_setequal(names(.styles_sync_rd_files), registered_layers)
})

for (.layer in names(.styles_sync_rd_files)) {
  # Capture per-iteration so each closure below sees its own `.layer`,
  # not whichever value the loop variable holds when the test actually
  # runs.
  local({
    layer <- .layer
    rd_file <- .styles_sync_rd_files[[layer]]

    test_that(paste0(rd_file, " documents a Styles section for the \"", layer, "\" layer"), {
      rd_path <- testthat::test_path("..", "..", "man", rd_file)
      # `man/*.Rd` sources ship in the source tree (where `devtools::test()`/
      # `devtools::check()` run from) but not in an *installed* package --
      # R CMD check's own "checking tests" step runs the suite against the
      # installed copy, which has no `man/` directory at all. This is a
      # dev-time documentation check, not a runtime behavioural one, so it
      # skips (rather than falsely failing every layer) whenever `man/`
      # isn't reachable from the test's own location.
      skip_if_not(
        dir.exists(dirname(rd_path)),
        "man/ directory not available (likely testing an installed package, e.g. under R CMD check)"
      )
      section <- .read_rd_section(rd_path, "Styles")

      expect_false(
        is.na(section),
        label = paste0(
          "man/", rd_file, " has no `\\section{Styles}{}` block -- ",
          "add one with a row per builder registered for the \"", layer, "\" layer"
        )
      )
    })

    test_that(paste0(rd_file, "'s Styles section lists every registered \"", layer, "\" label"), {
      rd_path <- testthat::test_path("..", "..", "man", rd_file)
      section <- .read_rd_section(rd_path, "Styles")
      skip_if(is.na(section), "no Styles section yet (see the previous test)")

      labels <- er_style_labels(layer)$label
      skip_if(length(labels) == 0L, "no builders registered for this layer")

      missing <- labels[!vapply(labels, function(lbl) grepl(lbl, section, fixed = TRUE), logical(1))]
      expect_length(missing, 0L)
    })

    test_that(paste0(rd_file, "'s Styles section links roughly one builder per registered label"), {
      rd_path <- testthat::test_path("..", "..", "man", rd_file)
      section <- .read_rd_section(rd_path, "Styles")
      skip_if(is.na(section), "no Styles section yet (see the earlier test)")

      labels <- er_style_labels(layer)$label
      skip_if(length(labels) == 0L, "no builders registered for this layer")

      # Roxygen renders `[er_style_x()]` as a `\code{\link[=er_style_x]{...}}`
      # (or similar) cross-reference; count `er_style_` occurrences as a
      # cheap proxy for "there's a builder link per row" without pinning
      # down every individual builder name here.
      link_count <- lengths(regmatches(section, gregexpr("er_style_[A-Za-z0-9_.]+", section)))
      expect_gte(link_count, length(labels))
    })
  })
}
