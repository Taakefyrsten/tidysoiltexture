# USDA soil texture class polygon vertices

A tidy data frame containing the polygon vertex coordinates for each of
the 12 USDA soil texture classes, suitable for drawing a texture
triangle with
[`gg_texture_triangle()`](https://taakefyrsten.github.io/tidysoiltexture/reference/gg_texture_triangle.md)
and for point-in-polygon classification with
[`classify_texture()`](https://taakefyrsten.github.io/tidysoiltexture/reference/classify_texture.md).

## Usage

``` r
usda_texture_classes
```

## Format

A tibble with 58 rows and 6 columns:

- class:

  Full texture class name (e.g. `"clay loam"`).

- abbr:

  Short abbreviation (e.g. `"ClLo"`).

- vertex_order:

  Integer giving the order of the vertex within the polygon.

- sand:

  Sand percentage at this vertex.

- silt:

  Silt percentage at this vertex.

- clay:

  Clay percentage at this vertex.

## Source

Extracted from the soiltexture package (`TT.classes.tbl()` /
`TT.vertices.tbl()`, system `"USDA.TT"`). See
`data-raw/usda_texture_classes.R` for the preparation script.

## Details

Polygon vertices are listed in order around each polygon. Sand, silt,
and clay values are in percent (0–100) and sum to 100 per vertex.
