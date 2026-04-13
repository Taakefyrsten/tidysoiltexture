# Changelog

## tidysoiltexture 1.0.0

Initial release.

### New functions

- [`classify_texture()`](https://taakefyrsten.github.io/tidysoiltexture/reference/classify_texture.md)
  — USDA texture classification for data frames, sf point objects, and
  terra SpatRaster stacks via S3 dispatch. Fully vectorised
  implementation; classifies 10 000 samples in \< 0.015 s.
- [`gg_texture_triangle()`](https://taakefyrsten.github.io/tidysoiltexture/reference/gg_texture_triangle.md)
  — ggplot2-based texture triangle with customisable grid lines,
  borders, axis ticks, class labels, fill surfaces, and contours.
- [`texture_surface()`](https://taakefyrsten.github.io/tidysoiltexture/reference/texture_surface.md)
  — constructs an IDW-interpolated continuous surface object from point
  data for use with
  [`gg_texture_triangle()`](https://taakefyrsten.github.io/tidysoiltexture/reference/gg_texture_triangle.md).
- [`geom_texture_contour()`](https://taakefyrsten.github.io/tidysoiltexture/reference/geom_texture_contour.md)
  — adds iso-contour lines to a texture triangle plot.
- [`texture_label_style()`](https://taakefyrsten.github.io/tidysoiltexture/reference/texture_label_style.md)
  — validates and constructs label style lists for controlling tick,
  axis, and class label appearance.

### Datasets

- `usda_texture_classes` — polygon boundary data for all 12 USDA texture
  classes in ternary (sand, silt, clay) coordinates.

### Notes

- Spatial methods require `sf` (≥ 1.0) or `terra` (≥ 1.6), listed in
  Suggests. A clear error is raised via
  [`rlang::check_installed()`](https://rlang.r-lib.org/reference/is_installed.html)
  when the relevant package is absent.
- SoilGrids / ESDAC rasters store fractions in g/kg (0–1000); a
  [`cli::cli_warn()`](https://cli.r-lib.org/reference/cli_abort.html)
  fires automatically if values exceed 100.
