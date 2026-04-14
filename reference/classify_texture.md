# Classify soil texture from sand, silt, and clay percentages

Classifies each row of `data` into a USDA soil texture class. Dispatches
on the class of `data`, so the same function works with plain data
frames or tibbles, `sf` point objects, and `terra` `SpatRaster` stacks.

## Usage

``` r
classify_texture(data, sand, silt, clay, system = "USDA", ...)

# Default S3 method
classify_texture(data, sand, silt, clay, system = "USDA", ...)

# S3 method for class 'sf'
classify_texture(data, sand, silt, clay, system = "USDA", ...)

# S3 method for class 'SpatRaster'
classify_texture(
  data,
  sand = "sand",
  silt = "silt",
  clay = "clay",
  system = "USDA",
  ...
)
```

## Arguments

- data:

  A data frame / tibble, an `sf` object, or a `SpatRaster`.

- sand:

  For data frames and `sf`: bare column name (or scalar) giving sand
  percentage (0–100). For `SpatRaster`: character layer name (default
  `"sand"`).

- silt:

  As `sand`, for silt percentage.

- clay:

  As `sand`, for clay percentage.

- system:

  Classification system. Currently only `"USDA"` is supported.

- ...:

  Reserved for future use.

## Value

- **data frame / tibble**: the input with two appended columns,
  `.texture_class` and `.texture_abbr`.

- **sf**: the input `sf` object with the same two columns appended,
  geometry preserved.

- **SpatRaster**: a single-layer categorical `SpatRaster` named
  `"texture_class"`, with integer cell values mapped to class names via
  [`terra::levels()`](https://rspatial.github.io/terra/reference/factors.html).

## Examples

``` r
# --- data frame / tibble -------------------------------------------------
soils <- data.frame(
  sand = c(70, 20, 40, 10),
  silt = c(15, 30, 40, 20),
  clay = c(15, 50, 20, 70)
)
classify_texture(soils, sand = sand, silt = silt, clay = clay)
#> # A tibble: 4 × 5
#>    sand  silt  clay .texture_class .texture_abbr
#>   <dbl> <dbl> <dbl> <chr>          <chr>        
#> 1    70    15    15 sandy loam     SaLo         
#> 2    20    30    50 clay           Cl           
#> 3    40    40    20 loam           Lo           
#> 4    10    20    70 clay           Cl           

# --- sf point object -----------------------------------------------------
if (requireNamespace("sf", quietly = TRUE)) {
  pts <- data.frame(
    sand = c(70, 20, 40, 10),
    silt = c(15, 30, 40, 20),
    clay = c(15, 50, 20, 70),
    lon  = c(10.1, 10.2, 10.3, 10.4),
    lat  = c(59.1, 59.2, 59.3, 59.4)
  )
  pts_sf <- sf::st_as_sf(pts, coords = c("lon", "lat"), crs = 4326)
  classify_texture(pts_sf, sand = sand, silt = silt, clay = clay)
}
#> Simple feature collection with 4 features and 5 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 10.1 ymin: 59.1 xmax: 10.4 ymax: 59.4
#> Geodetic CRS:  WGS 84
#>   sand silt clay          geometry .texture_class .texture_abbr
#> 1   70   15   15 POINT (10.1 59.1)     sandy loam          SaLo
#> 2   20   30   50 POINT (10.2 59.2)           clay            Cl
#> 3   40   40   20 POINT (10.3 59.3)           loam            Lo
#> 4   10   20   70 POINT (10.4 59.4)           clay            Cl

# --- terra SpatRaster stack ----------------------------------------------
if (requireNamespace("terra", quietly = TRUE)) {
  set.seed(1)
  n_cells <- 100L
  sand_v  <- runif(n_cells, 5, 65)
  clay_v  <- runif(n_cells, 5, 30)   # sand + clay always < 100
  silt_v  <- 100 - sand_v - clay_v
  r <- terra::rast(ncols = 10, nrows = 10, nlyrs = 3,
                   xmin = 0, xmax = 1, ymin = 0, ymax = 1)
  names(r) <- c("sand", "silt", "clay")
  terra::values(r) <- cbind(sand_v, silt_v, clay_v)
  classify_texture(r, sand = "sand", silt = "silt", clay = "clay")
}
#> class       : SpatRaster 
#> size        : 10, 10, 1  (nrow, ncol, nlyr)
#> resolution  : 0.1, 0.1  (x, y)
#> extent      : 0, 1, 0, 1  (xmin, xmax, ymin, ymax)
#> coord. ref. : lon/lat WGS 84 (CRS84) (OGC:CRS84) 
#> source(s)   : memory
#> categories  : texture_class 
#> name        : texture_class 
#> min value   :     clay loam 
#> max value   :          silt 
```
