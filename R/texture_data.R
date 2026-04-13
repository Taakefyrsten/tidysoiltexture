#' USDA soil texture class polygon vertices
#'
#' A tidy data frame containing the polygon vertex coordinates for each of the
#' 12 USDA soil texture classes, suitable for drawing a texture triangle with
#' [gg_texture_triangle()] and for point-in-polygon classification with
#' [classify_texture()].
#'
#' Polygon vertices are listed in order around each polygon. Sand, silt, and
#' clay values are in percent (0–100) and sum to 100 per vertex.
#'
#' @format A tibble with 58 rows and 6 columns:
#' \describe{
#'   \item{class}{Full texture class name (e.g. `"clay loam"`).}
#'   \item{abbr}{Short abbreviation (e.g. `"ClLo"`).}
#'   \item{vertex_order}{Integer giving the order of the vertex within the polygon.}
#'   \item{sand}{Sand percentage at this vertex.}
#'   \item{silt}{Silt percentage at this vertex.}
#'   \item{clay}{Clay percentage at this vertex.}
#' }
#'
#' @source Extracted from the \pkg{soiltexture} package
#'   (`TT.classes.tbl()` / `TT.vertices.tbl()`, system `"USDA.TT"`).
#'   See `data-raw/usda_texture_classes.R` for the preparation script.
"usda_texture_classes"
