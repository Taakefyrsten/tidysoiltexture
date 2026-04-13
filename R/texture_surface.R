# Internal ---------------------------------------------------------------

#' Build a regular Cartesian grid and interpolate z using IDW
#'
#' @param sand_v,silt_v,clay_v,z_v Numeric vectors (resolved from user data).
#' @param resolution Integer grid width along x.
#' @param power IDW distance-decay exponent.
#' @return A data frame with columns x, y, z (NA outside triangle).
#' @noRd
.texture_interp_grid <- function(sand_v, silt_v, clay_v, z_v,
                                  resolution, power) {
  h  <- sqrt(3) / 2
  xy <- ternary_to_cartesian(sand_v, silt_v, clay_v)

  x_seq <- seq(0, 1, length.out = resolution)
  y_seq <- seq(0, h, length.out = max(2L, round(resolution * h)))
  grid  <- expand.grid(x = x_seq, y = y_seq)

  # Back-convert to ternary to test interior membership
  clay_g <- grid$y / h
  silt_g <- grid$x - clay_g * 0.5
  sand_g <- 1 - clay_g - silt_g
  inside <- sand_g >= -1e-9 & silt_g >= -1e-9 & clay_g >= -1e-9

  # Vectorised IDW: distance from every grid point to every data point
  dx <- outer(grid$x, xy$x, `-`)
  dy <- outer(grid$y, xy$y, `-`)
  d2 <- dx^2 + dy^2
  w  <- 1 / pmax(d2, .Machine$double.eps)^(power / 2)
  z_hat <- rowSums(w * matrix(z_v, nrow(w), ncol(w), byrow = TRUE)) /
           rowSums(w)

  grid$z <- ifelse(inside, z_hat, NA_real_)
  grid
}


# Exported ---------------------------------------------------------------

#' Prepare a surface for interpolated rendering on a texture triangle
#'
#' Constructs and validates a surface specification for use with the `surface`
#' argument of [gg_texture_triangle()]. Resolves sand/silt/clay/z columns from
#' a data frame and stores the IDW interpolation settings. The actual grid
#' computation is deferred until plotting.
#'
#' Interpolation is performed using Inverse Distance Weighting (IDW) in
#' Cartesian space; no external packages are required.
#'
#' @param data A data frame containing sample points with ternary coordinates
#'   and a numeric response variable.
#' @param sand,silt,clay Bare column names for the ternary coordinates (0–100).
#' @param z Bare column name for the numeric value to interpolate and display
#'   as a fill colour.
#' @param resolution Integer. Number of grid cells along the x-axis of the
#'   interpolation grid. Higher values give smoother surfaces at the cost of
#'   speed. Default `150L`.
#' @param power Positive numeric. IDW distance-decay exponent. Higher values
#'   give each data point more local influence. Default `2`.
#'
#' @return An object of class `"texture_surface"` for use with
#'   [gg_texture_triangle()].
#'
#' @export
#'
#' @examples
#' # Generate synthetic data with a property that varies across texture space
#' set.seed(42)
#' surf_df <- tibble::tibble(
#'   sand = runif(60, 5, 90),
#'   clay = runif(60, 5, 60),
#'   silt = 100 - sand - clay
#' ) |>
#'   dplyr::filter(silt >= 0) |>
#'   dplyr::mutate(prop = sand * 0.3 + clay * 0.5 + rnorm(dplyr::n(), 0, 5))
#'
#' pts <- tibble::tibble(sand = c(40, 20), silt = c(40, 30), clay = c(20, 50))
#'
#' gg_texture_triangle(pts, sand, silt, clay,
#'   surface = texture_surface(surf_df, sand, silt, clay, z = prop)) +
#'   ggplot2::scale_fill_viridis_c(name = "prop")
texture_surface <- function(data, sand, silt, clay, z,
                             resolution = 150L, power = 2) {
  sand_v <- resolve_arg(rlang::enquo(sand), data, "sand")
  silt_v <- resolve_arg(rlang::enquo(silt), data, "silt")
  clay_v <- resolve_arg(rlang::enquo(clay), data, "clay")
  z_v    <- resolve_arg(rlang::enquo(z),    data, "z")

  n      <- nrow(data)
  sand_v <- rep_len(sand_v, n)
  silt_v <- rep_len(silt_v, n)
  clay_v <- rep_len(clay_v, n)

  check_texture_sums(sand_v, silt_v, clay_v)

  if (!is.numeric(z_v)) {
    stop("`z` must be a numeric column.", call. = FALSE)
  }
  resolution <- as.integer(resolution)
  if (length(resolution) != 1L || is.na(resolution) || resolution < 10L) {
    stop("`resolution` must be a single integer >= 10.", call. = FALSE)
  }
  power <- as.numeric(power)
  if (length(power) != 1L || is.na(power) || power <= 0) {
    stop("`power` must be a single positive number.", call. = FALSE)
  }

  structure(
    list(sand_v = sand_v, silt_v = silt_v, clay_v = clay_v, z_v = z_v,
         resolution = resolution, power = power),
    class = "texture_surface"
  )
}


#' Add iso-contour lines to a texture triangle plot
#'
#' Interpolates a numeric variable from scattered ternary sample points onto a
#' regular Cartesian grid (using IDW) and draws contour lines at the specified
#' values. Add to a plot produced by [gg_texture_triangle()] with `+`.
#'
#' Contour lines are rendered on top of all triangle layers, making them
#' suitable for highlighting analytical thresholds (e.g. a significance
#' boundary at `p = 0.05`).
#'
#' @param data A data frame containing sample points.
#' @param sand,silt,clay Bare column names for the ternary coordinates (0–100).
#' @param z Bare column name for the numeric value to interpolate.
#' @param breaks Numeric vector of z values at which to draw contour lines.
#'   Passed to [ggplot2::geom_contour()]. If `NULL` (default), ggplot2 chooses
#'   breaks automatically.
#' @param resolution Integer. Interpolation grid width (default `150L`).
#' @param power Positive numeric. IDW exponent (default `2`).
#' @param ... Additional arguments passed to [ggplot2::geom_contour()]
#'   (e.g. `linewidth`, `colour`, `linetype`).
#'
#' @return A `geom_contour` ggplot2 layer.
#'
#' @export
#'
#' @examples
#' set.seed(7)
#' surf_df <- tibble::tibble(
#'   sand = runif(80, 5, 90),
#'   clay = runif(80, 5, 60),
#'   silt = 100 - sand - clay
#' ) |>
#'   dplyr::filter(silt >= 0) |>
#'   dplyr::mutate(p_val = pnorm(scale(clay)[, 1]))
#'
#' pts <- tibble::tibble(sand = c(40, 20), silt = c(40, 30), clay = c(20, 50))
#'
#' gg_texture_triangle(pts, sand, silt, clay) +
#'   geom_texture_contour(surf_df, sand, silt, clay, z = p_val,
#'                        breaks = 0.05, linewidth = 1.4, colour = "red")
geom_texture_contour <- function(data, sand, silt, clay, z,
                                  breaks     = NULL,
                                  resolution = 150L,
                                  power      = 2,
                                  ...) {
  sand_v <- resolve_arg(rlang::enquo(sand), data, "sand")
  silt_v <- resolve_arg(rlang::enquo(silt), data, "silt")
  clay_v <- resolve_arg(rlang::enquo(clay), data, "clay")
  z_v    <- resolve_arg(rlang::enquo(z),    data, "z")

  n      <- nrow(data)
  sand_v <- rep_len(sand_v, n)
  silt_v <- rep_len(silt_v, n)
  clay_v <- rep_len(clay_v, n)

  check_texture_sums(sand_v, silt_v, clay_v)

  grid_df <- .texture_interp_grid(sand_v, silt_v, clay_v, z_v,
                                   as.integer(resolution), as.numeric(power))

  contour_args <- list(
    data    = grid_df,
    mapping = ggplot2::aes(x = x, y = y, z = z),
    na.rm   = TRUE,
    ...
  )
  if (!is.null(breaks)) contour_args$breaks <- breaks

  do.call(ggplot2::geom_contour, contour_args)
}
