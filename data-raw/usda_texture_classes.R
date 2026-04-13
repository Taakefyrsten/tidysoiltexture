## Prepare USDA texture class polygon data
## Source: soiltexture package (TT.classes.tbl / TT.vertices.tbl, USDA.TT system)
## Run this script to regenerate data/usda_texture_classes.rda

library(soiltexture)
library(dplyr)

cls   <- TT.classes.tbl(class.sys = "USDA.TT")
verts <- TT.vertices.tbl(class.sys = "USDA.TT")

# verts columns: points (index), CLAY, SILT, SAND  — values in [0,1], convert to %
verts_pct <- tibble::as_tibble(verts) |>
  dplyr::rename(vertex_id = points) |>
  dplyr::mutate(dplyr::across(c(CLAY, SILT, SAND), \(x) x * 100)) |>
  dplyr::rename(clay = CLAY, silt = SILT, sand = SAND)

# cls columns: abbr, name, points (comma-separated vertex ids as a string)
usda_texture_classes <- tibble::tibble(
  abbr  = cls[, "abbr"],
  class = cls[, "name"],
  points = cls[, "points"]
) |>
  # Expand each class into one row per vertex
  dplyr::mutate(
    vertex_id = purrr::map(points, \(p) as.integer(trimws(strsplit(p, ",")[[1]])))
  ) |>
  tidyr::unnest(vertex_id) |>
  dplyr::mutate(vertex_order = dplyr::row_number(), .by = abbr) |>
  dplyr::left_join(verts_pct, by = "vertex_id") |>
  dplyr::select(class, abbr, vertex_order, sand, silt, clay)

usethis::use_data(usda_texture_classes, overwrite = TRUE)
