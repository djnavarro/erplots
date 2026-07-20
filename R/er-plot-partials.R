
#' Partial builders for exposure-response plots
#'
#' @param data The original data frame
#' @param config Configuration for the specific plot
#' @param stratify Logical indicating whether to stratify
#' @param exposure Exposure variable
#' @param response Response variable
#' @param strata Stratification variable
#' @param style Style components
#'
#' @details Things we can have partials for:
#' 
#' - model
#' - summary
#' - quantile
#' - data
#' - group
#' 
#' Arguments are standardised to allow users to write their own 
#' as needed
#' 
#' @returns A geom, or a list of geoms. More precisely, a list of
#' objects that can be added to a ggplot2 plot. The expectation is
#' that these objects will be added to a partially-constructed plot
#' which, at a minimum, already has the base theme applied. For 
#' "model", "summary", and "quantile", the pieces will be added to
#' a plot that already has a coord that sets the axis limits. For
#' the "data" and "group" plots, the plot object does not yet
#' have a coord. The expectation, however, is that the builder will
#' supply an x-axis limit that is consistent with the base plot. That
#' is, since all component plots use the exposure variable for the
#' x-axis, they should use the values stored in `exposure$limits` tp
#' set the x-axis limits.   
#' 
#' @name er_partial
#' 
NULL
