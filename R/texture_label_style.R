#' Styling options for text elements in the texture triangle
#'
#' Constructs a validated list of label styling overrides for the `label_style`
#' argument of [gg_texture_triangle()]. Only specify the arguments you want to
#' change; all others are inherited from the function defaults.
#'
#' @param tick_show  Logical. Show tick-mark percentage labels alongside each
#'   edge tick. Default (when omitted): `TRUE`.
#' @param tick_size  Positive numeric. Font size for tick labels. Default: auto-
#'   scaled by break density (2.2 / 1.8 / 1.4 for ≤5 / ≤10 / >10 breaks).
#' @param axis_show  Logical. Show axis name labels ("Clay (%)" etc.) along
#'   each triangle side. Default: `TRUE`.
#' @param axis_size  Positive numeric. Font size for axis name labels.
#'   Default: `3.2`.
#' @param class_show Logical. Show texture class names inside each polygon
#'   region. Default: `TRUE`.
#' @param class_size Positive numeric. Font size for texture class labels.
#'   Default: `2.5`.
#'
#' @return A named list suitable for passing to the `label_style` argument of
#'   [gg_texture_triangle()]. Only keys explicitly supplied are included, so
#'   the function defaults remain active for anything left unspecified.
#'
#' @export
#'
#' @examples
#' soils <- tibble::tibble(
#'   sand = c(70, 20, 40),
#'   silt = c(15, 30, 40),
#'   clay = c(15, 50, 20)
#' )
#'
#' # Hide class names, increase axis label size
#' gg_texture_triangle(soils, sand, silt, clay,
#'   label_style = texture_label_style(class_show = FALSE, axis_size = 4.5))
#'
#' # Bare triangle — only axis arrows remain
#' gg_texture_triangle(soils, sand, silt, clay,
#'   label_style = texture_label_style(tick_show = FALSE,
#'                                     axis_show = FALSE,
#'                                     class_show = FALSE))
texture_label_style <- function(tick_show  = NULL,
                                tick_size  = NULL,
                                axis_show  = NULL,
                                axis_size  = NULL,
                                class_show = NULL,
                                class_size = NULL) {
  # Validate logical flags
  for (nm in c("tick_show", "axis_show", "class_show")) {
    val <- get(nm)
    if (!is.null(val)) {
      if (!is.logical(val) || length(val) != 1L || is.na(val)) {
        stop(sprintf("`%s` must be a single TRUE or FALSE.", nm), call. = FALSE)
      }
    }
  }

  # Validate positive-numeric sizes
  for (nm in c("tick_size", "axis_size", "class_size")) {
    val <- get(nm)
    if (!is.null(val)) {
      if (!is.numeric(val) || length(val) != 1L || is.na(val) || val <= 0) {
        stop(sprintf("`%s` must be a single positive number.", nm), call. = FALSE)
      }
    }
  }

  out <- list(
    tick_show  = tick_show,
    tick_size  = tick_size,
    axis_show  = axis_show,
    axis_size  = axis_size,
    class_show = class_show,
    class_size = class_size
  )

  # Drop keys that were not supplied so modifyList() leaves defaults intact
  out[!vapply(out, is.null, logical(1L))]
}
