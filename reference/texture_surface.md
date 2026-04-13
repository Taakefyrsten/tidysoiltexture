# Prepare a surface for interpolated rendering on a texture triangle

Constructs and validates a surface specification for use with the
`surface` argument of
[`gg_texture_triangle()`](https://taakefyrsten.github.io/tidysoiltexture/reference/gg_texture_triangle.md).
Resolves sand/silt/clay/z columns from a data frame and stores the IDW
interpolation settings. The actual grid computation is deferred until
plotting.

## Usage

``` r
texture_surface(data, sand, silt, clay, z, resolution = 150L, power = 2)
```

## Arguments

- data:

  A data frame containing sample points with ternary coordinates and a
  numeric response variable.

- sand, silt, clay:

  Bare column names for the ternary coordinates (0–100).

- z:

  Bare column name for the numeric value to interpolate and display as a
  fill colour.

- resolution:

  Integer. Number of grid cells along the x-axis of the interpolation
  grid. Higher values give smoother surfaces at the cost of speed.
  Default `150L`.

- power:

  Positive numeric. IDW distance-decay exponent. Higher values give each
  data point more local influence. Default `2`.

## Value

An object of class `"texture_surface"` for use with
[`gg_texture_triangle()`](https://taakefyrsten.github.io/tidysoiltexture/reference/gg_texture_triangle.md).

## Details

Interpolation is performed using Inverse Distance Weighting (IDW) in
Cartesian space; no external packages are required.

## Examples

``` r
# Generate synthetic data with a property that varies across texture space
set.seed(42)
surf_df <- tibble::tibble(
  sand = runif(60, 5, 90),
  clay = runif(60, 5, 60),
  silt = 100 - sand - clay
) |>
  dplyr::filter(silt >= 0) |>
  dplyr::mutate(prop = sand * 0.3 + clay * 0.5 + rnorm(dplyr::n(), 0, 5))

pts <- tibble::tibble(sand = c(40, 20), silt = c(40, 30), clay = c(20, 50))

gg_texture_triangle(pts, sand, silt, clay,
  surface = texture_surface(surf_df, sand, silt, clay, z = prop)) +
  ggplot2::scale_fill_viridis_c(name = "prop")
```
