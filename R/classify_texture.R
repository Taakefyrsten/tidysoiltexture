#' Classify soil texture from sand, silt, and clay percentages
#'
#' Classifies each row of `data` into a USDA soil texture class. Dispatches
#' on the class of `data`, so the same function works with plain data frames
#' or tibbles, `sf` point objects, and `terra` `SpatRaster` stacks.
#'
#' @param data A data frame / tibble, an `sf` object, or a `SpatRaster`.
#' @param sand For data frames and `sf`: bare column name (or scalar) giving
#'   sand percentage (0–100). For `SpatRaster`: character layer name
#'   (default `"sand"`).
#' @param silt As `sand`, for silt percentage.
#' @param clay As `sand`, for clay percentage.
#' @param system Classification system. Currently only `"USDA"` is supported.
#' @param ... Reserved for future use.
#'
#' @return
#' * **data frame / tibble**: the input with two appended columns,
#'   `.texture_class` and `.texture_abbr`.
#' * **sf**: the input `sf` object with the same two columns appended,
#'   geometry preserved.
#' * **SpatRaster**: a single-layer categorical `SpatRaster` named
#'   `"texture_class"`, with integer cell values mapped to class names via
#'   `terra::levels()`.
#'
#' @export
#'
#' @examples
#' # --- data frame / tibble -------------------------------------------------
#' soils <- tibble::tibble(
#'   sand = c(70, 20, 40, 10),
#'   silt = c(15, 30, 40, 20),
#'   clay = c(15, 50, 20, 70)
#' )
#' classify_texture(soils, sand = sand, silt = silt, clay = clay)
classify_texture <- function(data, sand, silt, clay, system = "USDA", ...) {
  UseMethod("classify_texture")
}


# Default method (data.frame / tibble) ------------------------------------

#' @rdname classify_texture
#' @export
classify_texture.default <- function(data, sand, silt, clay,
                                     system = "USDA", ...) {
  system <- match.arg(system, choices = c("USDA"))

  sand_v <- resolve_arg(rlang::enquo(sand), data, "sand")
  silt_v <- resolve_arg(rlang::enquo(silt), data, "silt")
  clay_v <- resolve_arg(rlang::enquo(clay), data, "clay")

  n      <- nrow(data)
  sand_v <- rep_len(sand_v, n)
  silt_v <- rep_len(silt_v, n)
  clay_v <- rep_len(clay_v, n)

  check_texture_sums(sand_v, silt_v, clay_v)

  result <- .classify_texture_core(sand_v, silt_v, clay_v,
                                    tidysoiltexture::usda_texture_classes)

  tibble::as_tibble(data) |>
    dplyr::mutate(.texture_class = result$class,
                  .texture_abbr  = result$abbr)
}


# Classification core (internal) -----------------------------------------
# Takes resolved numeric vectors; returns a list(class, abbr).
# All N points are tested against each polygon simultaneously (vectorised),
# making this efficient for large raster extractions.

.classify_texture_core <- function(sand_v, silt_v, clay_v, poly_data) {
  n       <- length(sand_v)
  pts     <- ternary_to_cartesian(sand_v, silt_v, clay_v)
  classes <- unique(poly_data$class)

  # Pre-compute polygon Cartesian coords and abbreviations once
  poly_cart <- lapply(classes, function(cl) {
    rows <- poly_data[poly_data$class == cl, ]
    ternary_to_cartesian(rows$sand, rows$silt, rows$clay)
  })
  poly_abbr <- vapply(classes, function(cl) {
    poly_data$abbr[poly_data$class == cl][1L]
  }, character(1L))

  # Vectorised assignment: iterate over K=12 classes; test all unassigned
  # points simultaneously. The vertex loop (K_verts ≈ 4–11) is the only
  # remaining R-level loop; all N-point arithmetic is vectorised C ops.
  class_idx <- rep(NA_integer_, n)

  for (k in seq_along(classes)) {
    unassigned <- which(is.na(class_idx))
    if (length(unassigned) == 0L) break
    hits <- .points_in_polygon_vec(
      pts$x[unassigned], pts$y[unassigned],
      poly_cart[[k]]$x,  poly_cart[[k]]$y
    )
    class_idx[unassigned[hits]] <- k
  }

  list(
    class = dplyr::if_else(!is.na(class_idx), classes[class_idx],  NA_character_),
    abbr  = dplyr::if_else(!is.na(class_idx), poly_abbr[class_idx], NA_character_)
  )
}


# Scalar point-in-polygon ------------------------------------------------
# Kept for single-point callers (e.g. IDW grid masking).
# On-edge collinearity check runs before ray-casting so boundary points on
# shared polygon edges (sand=0, silt=0 axes) return TRUE correctly.

point_in_polygon <- function(px, py, vx, vy) {
  n   <- length(vx)
  eps <- 1e-9

  j <- n
  for (i in seq_len(n)) {
    x1 <- vx[j]; y1 <- vy[j]; x2 <- vx[i]; y2 <- vy[i]
    cross <- (x2 - x1) * (py - y1) - (y2 - y1) * (px - x1)
    if (abs(cross) < eps &&
        px >= min(x1, x2) - eps && px <= max(x1, x2) + eps &&
        py >= min(y1, y2) - eps && py <= max(y1, y2) + eps) {
      return(TRUE)
    }
    j <- i
  }

  inside <- FALSE
  j <- n
  for (i in seq_len(n)) {
    xi <- vx[i]; yi <- vy[i]; xj <- vx[j]; yj <- vy[j]
    if (((yi > py) != (yj > py)) &&
        (px < (xj - xi) * (py - yi) / (yj - yi) + xi)) {
      inside <- !inside
    }
    j <- i
  }
  inside
}


# Vectorised point-in-polygon --------------------------------------------
# Tests all N points in (px, py) against a single polygon (vx, vy).
# x1/x2/y1/y2 are scalar vertex coords; px/py are length-N vectors.
# Only the vertex loop (K_verts) remains at R level.

.points_in_polygon_vec <- function(px, py, vx, vy) {
  n_verts <- length(vx)
  eps     <- 1e-9

  on_edge <- logical(length(px))
  j <- n_verts
  for (i in seq_len(n_verts)) {
    x1 <- vx[j]; y1 <- vy[j]; x2 <- vx[i]; y2 <- vy[i]
    cross <- (x2 - x1) * (py - y1) - (y2 - y1) * (px - x1)
    on_edge <- on_edge | (
      abs(cross) < eps &
      px >= min(x1, x2) - eps & px <= max(x1, x2) + eps &
      py >= min(y1, y2) - eps & py <= max(y1, y2) + eps
    )
    j <- i
  }

  inside <- logical(length(px))
  j <- n_verts
  for (i in seq_len(n_verts)) {
    xi <- vx[i]; yi <- vy[i]; xj <- vx[j]; yj <- vy[j]
    cond <- ((yi > py) != (yj > py)) &
            (px < (xj - xi) * (py - yi) / (yj - yi) + xi)
    inside <- xor(inside, cond)
    j <- i
  }

  on_edge | inside
}
