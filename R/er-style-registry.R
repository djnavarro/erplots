#' @include er-plot-style.R
NULL

# A small registry letting a tagged builder be selected by a short
# string (`style = "logrank"`) instead of the function itself
# (`style = er_style_tte_summary_logrank`). Keyed by `(layer, label)` --
# not `label` alone -- since resolution always happens inside a specific
# `_add_*()` function that already knows its own `layer` constant, so
# there's no risk of two grammars' builders colliding even if they
# happen to reuse the same label string.
#
# This is the one `er_style_tag()` attribute with a *side effect*
# (a registry write) rather than a pure attribute stamp -- every other
# tag is read back later, never acted on at tagging time. Rolled out to
# every layer/grammar's built-in builders; see NEWS.md and
# .agents/HISTORY.md for the design writeup.
#
# Redefinition safety: re-registering the *identical* function under an
# already-used `(layer, label)` key is always a silent no-op (the common
# case when a package is reloaded and its built-in labels are re-tagged
# at load time). Re-registering a *different* function under the same
# key errors by default -- this is what makes re-running a script that
# edits a custom labelled builder and re-taggs it error on the second
# run -- unless the caller passes `overwrite = TRUE` to `er_style_tag()`,
# which replaces the registration unconditionally. Erroring by default
# (rather than warning-and-overwriting) matches the package's general
# preference for explicit opt-in over a silent, potentially surprising
# default -- see AGENTS.md's opt-in-seeding gotcha for the same
# philosophy applied elsewhere.
#
# Staleness under covr::package_coverage(): a raw function reference
# stashed here at registration time can go stale, because covr
# reassigns each instrumented function's *body* in place after the
# package has already loaded (see AGENTS.md's covr gotcha) -- producing
# a new function object under the same namespace binding, which our
# earlier-captured reference doesn't track. `.resolve_style_binding()`
# below sidesteps this by re-resolving to whichever *currently* bound
# object in `style`'s own environment still carries matching
# `er_style_layer`/`er_style_label` attributes, rather than trusting the
# stored reference directly -- attributes survive covr's swap (it copies
# `attributes(target_value)` onto the replacement), so this works
# whether or not `style` has been instrumented. Every lookup path
# (`.lookup_style_label()`, `er_style_labels()`) goes through it.

.er_style_registry <- new.env(parent = emptyenv())

#' @noRd
.register_style_label <- function(layer, label, style, overwrite = FALSE) {
  key <- paste0(layer, "::", label)
  existing <- .er_style_registry[[key]]
  if (!is.null(existing) && !overwrite && !identical(existing, style)) {
    rlang::abort(c(
      paste0(
        "A builder is already registered as `style = \"", label,
        "\"` for the \"", layer, "\" layer."
      ),
      "i" = "Choose a different `label`, or pass `overwrite = TRUE` to `er_style_tag()` to replace it."
    ))
  }
  .er_style_registry[[key]] <- style
  invisible(NULL)
}

#' @noRd
.style_labels_for_layer <- function(layer) {
  keys <- ls(.er_style_registry)
  prefix <- paste0(layer, "::")
  matching <- keys[startsWith(keys, prefix)]
  sub(paste0("^", prefix), "", matching)
}

#' @noRd
.lookup_style_label <- function(layer, label, arg = "style") {
  style <- .er_style_registry[[paste0(layer, "::", label)]]
  if (is.null(style)) {
    available <- .style_labels_for_layer(layer)
    rlang::abort(c(
      paste0(
        "No builder is registered as `", arg, " = \"", label,
        "\"` for the \"", layer, "\" layer."
      ),
      "i" = if (length(available)) {
        paste0("Available: ", paste0("\"", available, "\"", collapse = ", "))
      } else {
        "No labelled builders are registered for this layer."
      }
    ))
  }
  .resolve_style_binding(layer, label, style)
}

#' @noRd
.resolve_style_binding <- function(layer, label, style) {
  env <- environment(style)
  if (is.null(env)) return(style)

  for (nm in ls(env, all.names = TRUE)) {
    candidate <- tryCatch(get(nm, envir = env, inherits = FALSE), error = function(e) NULL)
    if (is.function(candidate) &&
        identical(attr(candidate, "er_style_layer"), layer) &&
        identical(attr(candidate, "er_style_label"), label)) {
      return(candidate)
    }
  }

  style
}

#' List builders registered for string-based `style` dispatch
#'
#' A builder tagged via `er_style_tag(fn, layer = ..., label = ...)` can be
#' selected with a short string (e.g. `style = "logrank"`) instead of the
#' function itself, wherever the corresponding `_add_*()` function supports
#' it. `er_style_labels()` lists what's currently registered, optionally
#' filtered to a single `layer`.
#'
#' @param layer A single layer name (e.g. `"tte_summary"`), or `NULL` (the
#'   default) to list every registered label across all layers.
#'
#' @returns A tibble with one row per registered `(layer, label)` pair and
#'   columns `layer`, `label`, and `style` (the builder function itself).
#'
#' @examples
#' er_style_labels("tte_summary")
#'
#' @export
er_style_labels <- function(layer = NULL) {
  keys <- ls(.er_style_registry)
  if (length(keys) == 0) {
    return(tibble::tibble(layer = character(0), label = character(0), style = list()))
  }

  parts <- strsplit(keys, "::", fixed = TRUE)
  layers <- vapply(parts, `[[`, character(1), 1)
  labels <- vapply(parts, `[[`, character(1), 2)
  raw_styles <- unname(mget(keys, envir = .er_style_registry))

  out <- tibble::tibble(
    layer = layers,
    label = labels,
    style = Map(.resolve_style_binding, layers, labels, raw_styles)
  )

  if (!is.null(layer)) out <- out[out$layer == layer, ]
  out
}
