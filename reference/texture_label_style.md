# Styling options for text elements in the texture triangle

Constructs a validated list of label styling overrides for the
`label_style` argument of
[`gg_texture_triangle()`](https://taakefyrsten.github.io/tidysoiltexture/reference/gg_texture_triangle.md).
Only specify the arguments you want to change; all others are inherited
from the function defaults.

## Usage

``` r
texture_label_style(
  tick_show = NULL,
  tick_size = NULL,
  axis_show = NULL,
  axis_size = NULL,
  class_show = NULL,
  class_size = NULL
)
```

## Arguments

- tick_show:

  Logical. Show tick-mark percentage labels alongside each edge tick.
  Default (when omitted): `TRUE`.

- tick_size:

  Positive numeric. Font size for tick labels. Default: auto- scaled by
  break density (2.2 / 1.8 / 1.4 for ≤5 / ≤10 / \>10 breaks).

- axis_show:

  Logical. Show axis name labels ("Clay (%)" etc.) along each triangle
  side. Default: `TRUE`.

- axis_size:

  Positive numeric. Font size for axis name labels. Default: `3.2`.

- class_show:

  Logical. Show texture class names inside each polygon region. Default:
  `TRUE`.

- class_size:

  Positive numeric. Font size for texture class labels. Default: `2.5`.

## Value

A named list suitable for passing to the `label_style` argument of
[`gg_texture_triangle()`](https://taakefyrsten.github.io/tidysoiltexture/reference/gg_texture_triangle.md).
Only keys explicitly supplied are included, so the function defaults
remain active for anything left unspecified.

## Examples

``` r
soils <- tibble::tibble(
  sand = c(70, 20, 40),
  silt = c(15, 30, 40),
  clay = c(15, 50, 20)
)

# Hide class names, increase axis label size
gg_texture_triangle(soils, sand, silt, clay,
  label_style = texture_label_style(class_show = FALSE, axis_size = 4.5))


# Bare triangle — only axis arrows remain
gg_texture_triangle(soils, sand, silt, clay,
  label_style = texture_label_style(tick_show = FALSE,
                                    axis_show = FALSE,
                                    class_show = FALSE))
```
