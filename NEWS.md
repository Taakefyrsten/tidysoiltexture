# tidysoiltexture 1.0.0

Initial release.

## New functions

* `classify_texture()` — USDA texture classification for data frames, sf point
  objects, and terra SpatRaster stacks via S3 dispatch. Fully vectorised
  implementation; classifies 10 000 samples in < 0.015 s.
* `gg_texture_triangle()` — ggplot2-based texture triangle with customisable
  grid lines, borders, axis ticks, class labels, fill surfaces, and contours.
* `texture_surface()` — constructs an IDW-interpolated continuous surface
  object from point data for use with `gg_texture_triangle()`.
* `geom_texture_contour()` — adds iso-contour lines to a texture triangle plot.
* `texture_label_style()` — validates and constructs label style lists for
  controlling tick, axis, and class label appearance.

## Datasets

* `usda_texture_classes` — polygon boundary data for all 12 USDA texture
  classes in ternary (sand, silt, clay) coordinates.

## Notes

* Spatial methods require `sf` (≥ 1.0) or `terra` (≥ 1.6), listed in
  Suggests. A clear error is raised via `rlang::check_installed()` when
  the relevant package is absent.
* SoilGrids / ESDAC rasters store fractions in g/kg (0–1000); a
  `cli::cli_warn()` fires automatically if values exceed 100.
