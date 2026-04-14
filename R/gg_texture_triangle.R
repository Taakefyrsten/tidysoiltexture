#' Plot a soil texture triangle with sample points
#'
#' Produces a `ggplot2` object displaying a soil texture triangle with each
#' texture class region drawn as a filled polygon and optional sample points
#' overlaid. Triangle geometry is built from [usda_texture_classes] using
#' an internal ternary-to-Cartesian coordinate conversion.
#'
#' @param data A data frame or tibble containing sample points to plot.
#' @param sand Bare column name (or scalar) for sand percentage (0–100).
#' @param silt Bare column name (or scalar) for silt percentage (0–100).
#' @param clay Bare column name (or scalar) for clay percentage (0–100).
#' @param colour Optional bare column name to map to point colour. Pass `NULL`
#'   (the default) for no colour mapping.
#' @param system Classification system; currently only `"USDA"` is supported.
#' @param style Fill colour style for texture class polygons. `"none"` (default)
#'   draws unfilled polygons; `"wiki"` applies the colour scheme used in the
#'   Wikipedia USDA soil texture diagram.
#' @param breaks Numeric vector of percentage values at which to draw grid lines
#'   and tick marks (values between 1 and 99). Defaults to `c(20, 40, 60, 80)`.
#'   Common alternatives: `c(25, 50, 75)` (quarters), `seq(10, 90, 10)` (deciles),
#'   `seq(5, 95, 5)` (5 % steps).
#' @param grid_colour Colour of the internal grid lines. Defaults to `"grey70"`.
#' @param grid_linetype Line type of the internal grid lines. Defaults to
#'   `"dashed"`. Any value accepted by [ggplot2::geom_line()] is valid
#'   (e.g. `"solid"`, `"dotted"`, `"blank"` to hide the grid entirely).
#' @param grid_linewidth Stroke width of the internal grid lines. Defaults to
#'   `0.25`.
#' @param border_colour Colour of the texture class boundary lines. Defaults to
#'   `"grey40"`. Set to `NA` to hide all class borders.
#' @param border_linewidth Stroke width of the class boundary lines. Defaults
#'   to `0.35`.
#' @param tick_height Height of the tick marks drawn on each triangle edge, in
#'   Cartesian coordinate units. Defaults to `NULL`, which auto-scales with
#'   break density. Set to `0` to hide all tick marks while keeping grid lines
#'   and labels.
#' @param surface Optional. A `"texture_surface"` object produced by
#'   [texture_surface()], specifying a numeric variable to interpolate and
#'   display as a continuous fill gradient across the triangle. When supplied,
#'   any `style` palette fill is suppressed in favour of the surface; the fill
#'   scale is left unset so the user can control it freely with
#'   `+ ggplot2::scale_fill_*()`.\cr
#'   For iso-contour lines on top of the surface (or on a plain triangle), see
#'   [geom_texture_contour()].
#' @param label_style Named list of text styling overrides. Prefer building
#'   this with [texture_label_style()] for argument completion and validation.
#'   Recognised keys:
#'   \describe{
#'     \item{`tick_show`}{Show tick-mark percentage labels (default `TRUE`).}
#'     \item{`tick_size`}{Font size of tick labels. Defaults to auto-scale with
#'       break density (2.2 / 1.8 / 1.4 for ≤5 / ≤10 / >10 breaks).}
#'     \item{`axis_show`}{Show axis name labels (default `TRUE`).}
#'     \item{`axis_size`}{Font size of axis name labels (default `3.2`).}
#'     \item{`class_show`}{Show texture class name labels inside polygons
#'       (default `TRUE`).}
#'     \item{`class_size`}{Font size of texture class labels (default `2.5`).}
#'   }
#'   Only the keys you supply are overridden; unspecified keys use defaults.
#'
#' @return A `ggplot` object.
#'
#' @export
#'
#' @examples
#' soils <- data.frame(
#'   sand = c(70, 20, 40, 10),
#'   silt = c(15, 30, 40, 20),
#'   clay = c(15, 50, 20, 70)
#' )
#'
#' # Defaults
#' gg_texture_triangle(soils, sand = sand, silt = silt, clay = clay)
#'
#' # Wiki colours, 10 % grid, no class labels
#' gg_texture_triangle(soils, sand, silt, clay,
#'   style = "wiki", breaks = seq(10, 90, 10),
#'   label_style = list(class_show = FALSE))
#'
#' # Solid grid in dark grey, hide tick labels
#' gg_texture_triangle(soils, sand, silt, clay,
#'   grid_colour = "grey40", grid_linetype = "solid",
#'   label_style = list(tick_show = FALSE))
gg_texture_triangle <- function(data, sand, silt, clay,
                                colour = NULL, system = "USDA",
                                style = c("none", "wiki"),
                                breaks = c(20, 40, 60, 80),
                                grid_colour      = "grey70",
                                grid_linetype    = "dashed",
                                grid_linewidth   = 0.25,
                                border_colour    = "grey40",
                                border_linewidth = 0.35,
                                tick_height      = NULL,
                                surface          = NULL,
                                label_style      = list()) {
  system <- match.arg(system, choices = c("USDA"))
  style  <- match.arg(style)

  breaks <- sort(as.integer(breaks))
  if (any(breaks <= 0 | breaks >= 100)) {
    stop("`breaks` values must be between 1 and 99.", call. = FALSE)
  }

  colour_quo <- rlang::enquo(colour)

  sand_v <- resolve_arg(rlang::enquo(sand), data, "sand")
  silt_v <- resolve_arg(rlang::enquo(silt), data, "silt")
  clay_v <- resolve_arg(rlang::enquo(clay), data, "clay")

  n      <- nrow(data)
  sand_v <- rep_len(sand_v, n)
  silt_v <- rep_len(silt_v, n)
  clay_v <- rep_len(clay_v, n)

  check_texture_sums(sand_v, silt_v, clay_v)

  h <- sqrt(3) / 2   # height of equilateral triangle with side = 1

  # --- Label style defaults -------------------------------------------------
  pcts     <- breaks / 100
  n_breaks <- length(pcts)

  # Tick size auto-scales with break density; user can override via label_style
  auto_tick_size <- dplyr::case_when(n_breaks <= 5  ~ 2.2,
                                     n_breaks <= 10 ~ 1.8,
                                     TRUE           ~ 1.4)

  ls <- utils::modifyList(
    list(
      tick_show  = TRUE,
      tick_size  = auto_tick_size,
      axis_show  = TRUE,
      axis_size  = 3.2,
      class_show = TRUE,
      class_size = 2.5
    ),
    label_style
  )

  # --- Color palettes -------------------------------------------------------
  # Orientation: Clay=top(0.5,h), Sand=bottom-left(0,0), Silt=bottom-right(1,0)
  palettes <- list(
    none = NULL,
    wiki = c(
      "clay"             = "#FFFF9D",
      "silty clay"       = "#9DFDCE",
      "sandy clay"       = "#FF0000",
      "clay loam"        = "#CFFF63",
      "silty clay loam"  = "#63CF9D",
      "sandy clay loam"  = "#FF9D9D",
      "loam"             = "#CF9D00",
      "silty loam"       = "#9CCE00",
      "silt"             = "#20B020",
      "sandy loam"       = "#FFCFFF",
      "loamy sand"       = "#FFCFCF",
      "sand"             = "#FFCF9D"
    )
  )
  fill_palette <- palettes[[style]]

  # --- Texture class polygons -----------------------------------------------
  poly_data <- tidysoiltexture::usda_texture_classes
  poly_xy   <- ternary_to_cartesian(poly_data$sand, poly_data$silt, poly_data$clay)
  poly_df   <- dplyr::bind_cols(poly_data, poly_xy)

  if (!is.null(fill_palette)) {
    fill_df <- dplyr::tibble(class = names(fill_palette),
                             fill_colour = unname(fill_palette))
    poly_df <- dplyr::left_join(poly_df, fill_df, by = "class")
  } else {
    poly_df$fill_colour <- NA_character_
  }

  # --- Sample point data ----------------------------------------------------
  pts_xy <- ternary_to_cartesian(sand_v, silt_v, clay_v)
  pts_df <- dplyr::as_tibble(data)
  pts_df$.x <- pts_xy$x
  pts_df$.y <- pts_xy$y

  # --- Grid lines and ticks -------------------------------------------------
  # Constant-clay lines:  horizontal at y = p*h, from x = p*0.5 to x = 1 - p*0.5
  # Constant-sand lines:  from (1-p, 0) to ((1-p)*0.5, (1-p)*h)
  # Constant-silt lines:  from (p, 0)   to (0.5 + p*0.5, (1-p)*h)
  #
  # Tick outward normals:
  #   left  edge (Clay axis, silt=0):  (-h, 0.5)
  #   bottom edge (Sand axis, clay=0): (0, -1)
  #   right edge  (Silt axis, sand=0): (h, 0.5)

  # Tick geometry scales with break density to avoid collisions
  tick_len <- dplyr::case_when(n_breaks <= 5  ~ 0.025,
                               n_breaks <= 10 ~ 0.020,
                               TRUE           ~ 0.015)
  tick_off <- dplyr::case_when(n_breaks <= 5  ~ 0.055,
                               n_breaks <= 10 ~ 0.048,
                               TRUE           ~ 0.040)

  # User override: tick_height = 0 hides ticks; any positive value fixes height
  if (!is.null(tick_height)) {
    if (!is.numeric(tick_height) || length(tick_height) != 1L || tick_height < 0) {
      stop("`tick_height` must be a single non-negative number.", call. = FALSE)
    }
    tick_len <- tick_height
  }

  clay_grid <- dplyr::tibble(
    grp = rep(seq_along(pcts), each = 2),
    p   = rep(pcts, each = 2),
    x   = as.vector(rbind(pcts * 0.5,       1 - pcts * 0.5)),
    y   = as.vector(rbind(pcts * h,          pcts * h))
  )

  sand_grid <- dplyr::tibble(
    grp = rep(seq_along(pcts), each = 2),
    p   = rep(pcts, each = 2),
    x   = as.vector(rbind(1 - pcts,          (1 - pcts) * 0.5)),
    y   = as.vector(rbind(rep(0, length(pcts)), (1 - pcts) * h))
  )

  silt_grid <- dplyr::tibble(
    grp = rep(seq_along(pcts), each = 2),
    p   = rep(pcts, each = 2),
    x   = as.vector(rbind(pcts,               0.5 + pcts * 0.5)),
    y   = as.vector(rbind(rep(0, length(pcts)), (1 - pcts) * h))
  )

  grid_df <- dplyr::bind_rows(
    dplyr::mutate(clay_grid, axis = "clay"),
    dplyr::mutate(sand_grid, axis = "sand"),
    dplyr::mutate(silt_grid, axis = "silt")
  )

  # Clay ticks — on left edge (silt=0): outward normal = (-h, 0.5)
  clay_ticks <- dplyr::tibble(
    p     = pcts,
    x0    = pcts * 0.5,
    y0    = pcts * h,
    x1    = pcts * 0.5 - tick_len * h,
    y1    = pcts * h   + tick_len * 0.5,
    lx    = pcts * 0.5 - tick_off * h,
    ly    = pcts * h   + tick_off * 0.5,
    label = paste0(pcts * 100, "%"),
    angle = 60
  )

  # Sand ticks — on bottom edge (clay=0): outward normal = (0, -1)
  sand_ticks <- dplyr::tibble(
    p     = pcts,
    x0    = 1 - pcts,
    y0    = 0,
    x1    = 1 - pcts,
    y1    = -tick_len,
    lx    = 1 - pcts,
    ly    = -tick_off,
    label = paste0(pcts * 100, "%"),
    angle = 0
  )

  # Silt ticks — on right edge (sand=0): outward normal = (h, 0.5)
  silt_ticks <- dplyr::tibble(
    p     = pcts,
    x0    = 0.5 + pcts * 0.5,
    y0    = (1 - pcts) * h,
    x1    = 0.5 + pcts * 0.5 + tick_len * h,
    y1    = (1 - pcts) * h   + tick_len * 0.5,
    lx    = 0.5 + pcts * 0.5 + tick_off * h,
    ly    = (1 - pcts) * h   + tick_off * 0.5,
    label = paste0(pcts * 100, "%"),
    angle = -60
  )

  tick_segments <- dplyr::bind_rows(clay_ticks, sand_ticks, silt_ticks)
  tick_labels   <- dplyr::bind_rows(
    dplyr::mutate(clay_ticks, axis = "clay"),
    dplyr::mutate(sand_ticks, axis = "sand"),
    dplyr::mutate(silt_ticks, axis = "silt")
  )

  # --- Axis labels and arrows -----------------------------------------------
  # Each axis label sits outside its edge midpoint, offset by label_dist.
  # An arrow segment, closer to the edge (arrow_dist), shows direction of
  # increasing concentration.
  #
  # Edge midpoints:
  #   Clay  (left edge):   (0.25, h/2),  outward = (-h, 0.5),  increase dir = (0.5,  h)
  #   Sand  (bottom edge): (0.5,  0),    outward = (0,  -1),   increase dir = (-1,   0)
  #   Silt  (right edge):  (0.75, h/2),  outward = (h,  0.5),  increase dir = (0.5, -h)

  arr_dist   <- 0.09
  label_dist <- 0.13
  arr_half   <- 0.13

  clay_ax <- 0.25 - arr_dist * h;  clay_ay <- h/2 + arr_dist * 0.5
  sand_ax <- 0.5;                  sand_ay <- -arr_dist
  silt_ax <- 0.75 + arr_dist * h;  silt_ay <- h/2 + arr_dist * 0.5

  axis_arrows_df <- dplyr::tibble(
    x0 = c(clay_ax - arr_half * 0.5,
            sand_ax + arr_half,
            silt_ax - arr_half * 0.5),
    y0 = c(clay_ay - arr_half * h,
            sand_ay,
            silt_ay + arr_half * h),
    x1 = c(clay_ax + arr_half * 0.5,
            sand_ax - arr_half,
            silt_ax + arr_half * 0.5),
    y1 = c(clay_ay + arr_half * h,
            sand_ay,
            silt_ay - arr_half * h)
  )

  axis_labels_df <- dplyr::tibble(
    label = c("Clay (%)", "Sand (%)", "Silt (%)"),
    x     = c(0.25 - label_dist * h,  0.5,           0.75 + label_dist * h),
    y     = c(h/2 + label_dist * 0.5, -label_dist,   h/2 + label_dist * 0.5),
    angle = c(60, 0, -60)
  )

  # Centroid data for class labels
  class_label_df <- dplyr::mutate(
    dplyr::summarise(
      dplyr::group_by(poly_df, class),
      x = mean(x), y = mean(y),
      .groups = "drop"
    ),
    angle = dplyr::if_else(class == "loamy sand", -30, 0),
    x = dplyr::if_else(class == "sandy clay", x - 0.02, x),
    y = dplyr::if_else(class == "sandy clay", y - 0.03, y)
  )

  # --- Surface validation ---------------------------------------------------
  use_surface <- inherits(surface, "texture_surface")
  if (!is.null(surface) && !use_surface) {
    stop("`surface` must be a `texture_surface` object from texture_surface().",
         call. = FALSE)
  }

  # --- Assemble ggplot ------------------------------------------------------
  # Layer order (bottom to top):
  #   1.  polygon fills      — discrete palette (suppressed when surface given)
  #   1b. surface raster     — continuous interpolated fill (when provided)
  #   2.  grid lines         — dashes visible through fills
  #   3.  polygon borders    — crisp class boundaries above grid
  #   4.  class labels, ticks, axis annotations
  p <- ggplot2::ggplot() +
    # 1. Texture class fills —
    #    (a) palette fill when style != "none" and no surface
    #    (b) transparent (fill = NA) otherwise so borders still draw cleanly
    { if (!use_surface && !is.null(fill_palette))
        list(
          ggplot2::geom_polygon(
            data    = poly_df,
            mapping = ggplot2::aes(x = x, y = y, group = class,
                                   fill = fill_colour),
            colour  = NA
          ),
          ggplot2::scale_fill_identity(na.value = NA)
        )
      else
        ggplot2::geom_polygon(
          data    = poly_df,
          mapping = ggplot2::aes(x = x, y = y, group = class),
          fill    = NA,
          colour  = NA
        )
    } +
    # 1b. Interpolated surface raster (sits above palette, below grid/borders)
    #     No fill scale emitted — user controls it with + scale_fill_*()
    { if (use_surface) {
        surf_grid <- .texture_interp_grid(
          surface$sand_v, surface$silt_v, surface$clay_v, surface$z_v,
          surface$resolution, surface$power
        )
        ggplot2::geom_raster(
          data    = surf_grid[!is.na(surf_grid$z), ],
          mapping = ggplot2::aes(x = x, y = y, fill = z)
        )
      } else NULL
    } +
    # 2. Grid lines (on top of fills, below borders)
    ggplot2::geom_line(
      data      = grid_df,
      mapping   = ggplot2::aes(x = x, y = y, group = interaction(axis, grp)),
      colour    = grid_colour,
      linewidth = grid_linewidth,
      linetype  = grid_linetype
    ) +
    # 3. Polygon borders only (no fill)
    ggplot2::geom_polygon(
      data      = poly_df,
      mapping   = ggplot2::aes(x = x, y = y, group = class),
      fill      = NA,
      colour    = border_colour,
      linewidth = border_linewidth
    ) +
    # Texture class labels (optional)
    { if (ls$class_show)
        ggplot2::geom_text(
          data     = class_label_df,
          mapping  = ggplot2::aes(x = x, y = y, label = class, angle = angle),
          size     = ls$class_size,
          colour   = "grey30",
          fontface = "italic"
        )
      else NULL
    } +
    # Tick marks (hidden when tick_height = 0)
    { if (tick_len > 0)
        ggplot2::geom_segment(
          data      = tick_segments,
          mapping   = ggplot2::aes(x = x0, y = y0, xend = x1, yend = y1),
          colour    = "grey30",
          linewidth = 0.4
        )
      else NULL
    } +
    # Tick labels (optional)
    { if (ls$tick_show)
        ggplot2::geom_text(
          data    = tick_labels,
          mapping = ggplot2::aes(x = lx, y = ly, label = label, angle = angle),
          size    = ls$tick_size,
          colour  = "grey30"
        )
      else NULL
    } +
    # Axis arrows (direction of increasing %)
    ggplot2::geom_segment(
      data      = axis_arrows_df,
      mapping   = ggplot2::aes(x = x0, y = y0, xend = x1, yend = y1),
      arrow     = ggplot2::arrow(length = ggplot2::unit(0.2, "cm"), type = "closed"),
      colour    = "grey20",
      linewidth = 0.5
    ) +
    # Axis name labels along triangle sides (optional)
    { if (ls$axis_show)
        ggplot2::geom_text(
          data     = axis_labels_df,
          mapping  = ggplot2::aes(x = x, y = y, label = label, angle = angle),
          size     = ls$axis_size,
          fontface = "bold",
          colour   = "grey20"
        )
      else NULL
    } +
    ggplot2::coord_equal(clip = "off") +
    ggplot2::theme_void() +
    ggplot2::theme(plot.margin = ggplot2::margin(20, 50, 35, 50))

  # --- Sample points -------------------------------------------------------
  if (rlang::quo_is_null(colour_quo)) {
    p <- p + ggplot2::geom_point(
      data    = pts_df,
      mapping = ggplot2::aes(x = .x, y = .y),
      size    = 2
    )
  } else {
    colour_nm <- rlang::as_name(colour_quo)
    p <- p + ggplot2::geom_point(
      data    = pts_df,
      mapping = ggplot2::aes(x = .x, y = .y, colour = .data[[colour_nm]]),
      size    = 2
    )
  }

  p
}
