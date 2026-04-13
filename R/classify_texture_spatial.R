# Spatial methods for classify_texture()
# Both methods require optional packages (sf / terra) declared in Suggests.
# rlang::check_installed() gives a clear error if the package is missing.


# sf method ---------------------------------------------------------------

#' @rdname classify_texture
#' @export
#' @examples
#'
#' # --- sf point object -----------------------------------------------------
#' if (requireNamespace("sf", quietly = TRUE)) {
#'   pts <- data.frame(
#'     sand = c(70, 20, 40, 10),
#'     silt = c(15, 30, 40, 20),
#'     clay = c(15, 50, 20, 70),
#'     lon  = c(10.1, 10.2, 10.3, 10.4),
#'     lat  = c(59.1, 59.2, 59.3, 59.4)
#'   )
#'   pts_sf <- sf::st_as_sf(pts, coords = c("lon", "lat"), crs = 4326)
#'   classify_texture(pts_sf, sand = sand, silt = silt, clay = clay)
#' }
classify_texture.sf <- function(data, sand, silt, clay,
                                system = "USDA", ...) {
  rlang::check_installed("sf", reason = "to classify an sf object")
  system <- match.arg(system, choices = c("USDA"))

  # Resolve tidy-eval args directly from the sf object (sf IS a data frame)
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

  # Attach columns while preserving geometry and sf class
  data$.texture_class <- result$class
  data$.texture_abbr  <- result$abbr
  data
}


# SpatRaster method -------------------------------------------------------

#' @rdname classify_texture
#' @export
#' @examples
#'
#' # --- terra SpatRaster stack ----------------------------------------------
#' if (requireNamespace("terra", quietly = TRUE)) {
#'   r <- terra::rast(ncols = 10, nrows = 10, nlyrs = 3)
#'   names(r) <- c("sand", "silt", "clay")
#'   terra::values(r) <- c(
#'     runif(100, 10, 80),   # sand
#'     runif(100, 5,  50),   # silt
#'     runif(100, 5,  40)    # clay — will have invalid sums; demo only
#'   )
#'   classify_texture(r, sand = "sand", silt = "silt", clay = "clay")
#' }
classify_texture.SpatRaster <- function(data,
                                        sand   = "sand",
                                        silt   = "silt",
                                        clay   = "clay",
                                        system = "USDA", ...) {
  rlang::check_installed("terra", reason = "to classify a SpatRaster")
  system <- match.arg(system, choices = c("USDA"))

  # Validate layer names
  lyr_names <- names(data)
  for (lyr in c(sand, silt, clay)) {
    if (!lyr %in% lyr_names) {
      stop(
        sprintf("Layer '%s' not found in SpatRaster. Available layers: %s",
                lyr, paste(lyr_names, collapse = ", ")),
        call. = FALSE
      )
    }
  }

  # Extract all cell values as a numeric matrix (n_cells × 3)
  vals <- terra::values(data[[c(sand, silt, clay)]])
  colnames(vals) <- c("sand", "silt", "clay")

  # Only attempt classification where all three fractions are non-NA
  valid      <- which(stats::complete.cases(vals))
  n_valid    <- length(valid)
  poly_data  <- tidysoiltexture::usda_texture_classes
  all_classes <- unique(poly_data$class)   # canonical 12-class ordering

  out_int <- rep(NA_integer_, nrow(vals))

  if (n_valid > 0L) {
    sand_v <- vals[valid, "sand"]
    silt_v <- vals[valid, "silt"]
    clay_v <- vals[valid, "clay"]

    # SoilGrids and similar products store fractions in g/kg (0–1000) rather
    # than percent (0–100). Catch this before check_texture_sums() so the user
    # gets a clear, actionable message instead of a cryptic "sums ≠ 100" error.
    if (max(sand_v, silt_v, clay_v, na.rm = TRUE) > 100) {
      cli::cli_warn(c(
        "One or more sand/silt/clay values exceed 100.",
        "i" = "Raster layers from SoilGrids and ESDAC are in {.strong g/kg} \\
               (0\\u20131000), not percent.",
        "i" = "Divide all three layers by 10 before classifying: \\
               {.code r / 10}."
      ))
    }

    # Validate ternary sums for the valid cells
    check_texture_sums(sand_v, silt_v, clay_v)

    result      <- .classify_texture_core(sand_v, silt_v, clay_v, poly_data)
    out_int[valid] <- match(result$class, all_classes)
  }

  # Build single-layer categorical SpatRaster with same extent / CRS
  out <- terra::rast(data[[1]])
  names(out)        <- "texture_class"
  terra::values(out) <- out_int

  # Attach levels (RAT): integer → class name
  levels(out) <- data.frame(
    id            = seq_along(all_classes),
    texture_class = all_classes
  )

  out
}
