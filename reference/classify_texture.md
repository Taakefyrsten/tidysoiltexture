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
  `terra::levels()`.

## Examples

``` r
# --- data frame / tibble -------------------------------------------------
soils <- tibble::tibble(
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
  pts_sf <- sf::st_as_sf(soils, coords = c("lon", "lat"), crs = 4326)
  pts_sf$sand <- c(70, 20, 40, 10)
  pts_sf$silt <- c(15, 30, 40, 20)
  pts_sf$clay <- c(15, 50, 20, 70)
  classify_texture(pts_sf, sand = sand, silt = silt, clay = clay)
}
#> Error in x[coords]: Can't subset columns that don't exist.
#> ✖ Columns `lon` and `lat` don't exist.

# --- terra SpatRaster stack ----------------------------------------------
if (requireNamespace("terra", quietly = TRUE)) {
  r <- terra::rast(ncols = 10, nrows = 10, nlyrs = 3)
  names(r) <- c("sand", "silt", "clay")
  terra::values(r) <- c(
    runif(100, 10, 80),   # sand
    runif(100, 5,  50),   # silt
    runif(100, 5,  40)    # clay — will have invalid sums; demo only
  )
  classify_texture(r, sand = "sand", silt = "silt", clay = "clay")
}
```
