# Classifying soil texture with classify_texture()

``` r
library(tidysoiltexture)
library(dplyr)
library(tibble)
```

## Overview

[`classify_texture()`](https://taakefyrsten.github.io/tidysoiltexture/reference/classify_texture.md)
assigns USDA texture classes (sand, loam, clay, etc.) to soil samples
based on their sand, silt, and clay fractions. It is an S3 generic with
three dispatch methods:

| Input type          | What it dispatches to                                                                                           |
|---------------------|-----------------------------------------------------------------------------------------------------------------|
| Data frame / tibble | [`classify_texture.default()`](https://taakefyrsten.github.io/tidysoiltexture/reference/classify_texture.md)    |
| `sf` point object   | [`classify_texture.sf()`](https://taakefyrsten.github.io/tidysoiltexture/reference/classify_texture.md)         |
| `terra` SpatRaster  | [`classify_texture.SpatRaster()`](https://taakefyrsten.github.io/tidysoiltexture/reference/classify_texture.md) |

All methods accept and return tibbles (or the spatial equivalent), and
all support tidy evaluation — you can pass bare column names or string
names interchangeably.

------------------------------------------------------------------------

## 1. Basic usage

``` r
soils <- tribble(
  ~sample_id, ~sand, ~silt, ~clay,
  "A1",          65,    20,    15,
  "A2",          20,    50,    30,
  "A3",           8,    72,    20,
  "A4",          40,    38,    22,
  "A5",          52,     6,    42,
  "A6",           6,    47,    47
)

classify_texture(soils, sand, silt, clay)
#> # A tibble: 6 × 6
#>   sample_id  sand  silt  clay .texture_class .texture_abbr
#>   <chr>     <dbl> <dbl> <dbl> <chr>          <chr>        
#> 1 A1           65    20    15 sandy loam     SaLo         
#> 2 A2           20    50    30 clay loam      ClLo         
#> 3 A3            8    72    20 silty loam     SiLo         
#> 4 A4           40    38    22 loam           Lo           
#> 5 A5           52     6    42 sandy clay     SaCl         
#> 6 A6            6    47    47 silty clay     SiCl
```

Two columns are appended to the input tibble:

- `.texture_class` — full USDA class name
- `.texture_abbr` — standard abbreviation (e.g. `SaLo`, `Cl`)

------------------------------------------------------------------------

## 2. Tidy evaluation

Column names can be passed as bare symbols or as string-named columns.
The function uses
[`rlang::enquo()`](https://rlang.r-lib.org/reference/enquo.html)
internally so it integrates naturally into dplyr pipelines.

``` r
# Works inside a pipe with renamed columns
soils |>
  rename(s = sand, si = silt, c = clay) |>
  classify_texture(sand = s, silt = si, clay = c)
#> # A tibble: 6 × 6
#>   sample_id     s    si     c .texture_class .texture_abbr
#>   <chr>     <dbl> <dbl> <dbl> <chr>          <chr>        
#> 1 A1           65    20    15 sandy loam     SaLo         
#> 2 A2           20    50    30 clay loam      ClLo         
#> 3 A3            8    72    20 silty loam     SiLo         
#> 4 A4           40    38    22 loam           Lo           
#> 5 A5           52     6    42 sandy clay     SaCl         
#> 6 A6            6    47    47 silty clay     SiCl
```

Scalar values also work for any argument — useful for constant fractions
across a dataset:

``` r
# All samples have the same silt (25%); sand and clay vary
tibble(sand = c(60, 40, 15), clay = c(15, 35, 60)) |>
  classify_texture(sand = sand, silt = 25, clay = clay)
#> # A tibble: 3 × 4
#>    sand  clay .texture_class .texture_abbr
#>   <dbl> <dbl> <chr>          <chr>        
#> 1    60    15 sandy loam     SaLo         
#> 2    40    35 clay loam      ClLo         
#> 3    15    60 clay           Cl
```

------------------------------------------------------------------------

## 3. Validation

[`classify_texture()`](https://taakefyrsten.github.io/tidysoiltexture/reference/classify_texture.md)
validates that the three fractions sum to 100 (within a tolerance of ±
0.5). Rows that don’t sum correctly raise an error.

``` r
# Bad row: fractions sum to 95
tibble(sand = 50, silt = 30, clay = 15) |>
  classify_texture(sand, silt, clay)
#> Error in `check_texture_sums()`:
#> ! Sand, silt, and clay must sum to 100 for every row.
#> ✖ Found {sum(bad)} row(s) where the sum differs from 100 by more than 1.
```

------------------------------------------------------------------------

## 4. The 12 USDA texture classes

`usda_texture_classes` contains the polygon boundary data used
internally.

``` r
usda_texture_classes |>
  distinct(class, abbr) |>
  arrange(class)
#> # A tibble: 12 × 2
#>    class           abbr  
#>    <chr>           <chr> 
#>  1 clay            Cl    
#>  2 clay loam       ClLo  
#>  3 loam            Lo    
#>  4 loamy sand      LoSa  
#>  5 sand            Sa    
#>  6 sandy clay      SaCl  
#>  7 sandy clay loam SaClLo
#>  8 sandy loam      SaLo  
#>  9 silt            Si    
#> 10 silty clay      SiCl  
#> 11 silty clay loam SiClLo
#> 12 silty loam      SiLo
```

A helper lookup table of the 12 classes with representative centroids:

``` r
tribble(
  ~Class,            ~Abbr,     ~Sand, ~Silt, ~Clay,
  "sand",            "Sa",         92,     5,     3,
  "loamy sand",      "LoSa",       80,    12,     8,
  "sandy loam",      "SaLo",       65,    22,    13,
  "loam",            "Lo",         41,    39,    20,
  "silty loam",      "SiLo",       20,    65,    15,
  "silt",            "Si",          7,    85,     8,
  "sandy clay loam", "SaClLo",     60,    13,    27,
  "clay loam",       "ClLo",       32,    34,    34,
  "silty clay loam", "SiClLo",     10,    56,    34,
  "sandy clay",      "SaCl",       52,     6,    42,
  "silty clay",      "SiCl",        6,    47,    47,
  "clay",            "Cl",         20,    20,    60
) |>
  classify_texture(Sand, Silt, Clay) |>
  select(Class, Abbr, .texture_class, .texture_abbr)
#> # A tibble: 12 × 4
#>    Class           Abbr   .texture_class  .texture_abbr
#>    <chr>           <chr>  <chr>           <chr>        
#>  1 sand            Sa     sand            Sa           
#>  2 loamy sand      LoSa   loamy sand      LoSa         
#>  3 sandy loam      SaLo   sandy loam      SaLo         
#>  4 loam            Lo     loam            Lo           
#>  5 silty loam      SiLo   silty loam      SiLo         
#>  6 silt            Si     silt            Si           
#>  7 sandy clay loam SaClLo sandy clay loam SaClLo       
#>  8 clay loam       ClLo   clay loam       ClLo         
#>  9 silty clay loam SiClLo silty clay loam SiClLo       
#> 10 sandy clay      SaCl   sandy clay      SaCl         
#> 11 silty clay      SiCl   silty clay      SiCl         
#> 12 clay            Cl     clay            Cl
```

All 12 centroids classify correctly — the `.texture_class` column
matches the `Class` column.

------------------------------------------------------------------------

## 5. Batch classification and performance

The vectorised backend processes all N points per class simultaneously,
not row by row. This makes it practical for large datasets.

``` r
set.seed(5519)
big <- tibble(
  sand = runif(10000, 5, 85),
  clay = runif(10000, 5, 45)
) |>
  mutate(silt = 100 - sand - clay) |>
  filter(silt >= 2) |>
  slice_head(n = 10000)

elapsed <- system.time(
  result <- classify_texture(big, sand, silt, clay)
)["elapsed"]

cat(sprintf("10 000 samples in %.3f s\n", elapsed))
#> 10 000 samples in 0.025 s
cat(sprintf("NAs: %d\n", sum(is.na(result$.texture_class))))
#> NAs: 0
```

------------------------------------------------------------------------

## 6. sf dispatch

If your data is an `sf` point object,
[`classify_texture()`](https://taakefyrsten.github.io/tidysoiltexture/reference/classify_texture.md)
detects the class and dispatches to the `.sf` method. Geometry is
preserved.

``` r
library(sf)
#> Linking to GEOS 3.12.1, GDAL 3.8.4, PROJ 9.4.0; sf_use_s2() is TRUE

pts_sf <- st_as_sf(
  soils,
  coords = c("sand", "silt"),   # using sand/silt as dummy coordinates
  crs    = NA_crs_
)
pts_sf$sand <- soils$sand
pts_sf$silt <- soils$silt
pts_sf$clay <- soils$clay

out_sf <- classify_texture(pts_sf, sand = sand, silt = silt, clay = clay)
class(out_sf)         # still an sf object
#> [1] "sf"         "tbl_df"     "tbl"        "data.frame"
names(out_sf)         # .texture_class and .texture_abbr appended
#> [1] "sample_id"      "clay"           "geometry"       "sand"          
#> [5] "silt"           ".texture_class" ".texture_abbr"
```

------------------------------------------------------------------------

## 7. SpatRaster dispatch

For raster stacks (e.g. from SoilGrids),
[`classify_texture()`](https://taakefyrsten.github.io/tidysoiltexture/reference/classify_texture.md)
dispatches to the `.SpatRaster` method and returns a categorical raster
with 12 levels.

``` r
library(terra)
#> terra 1.9.11

# Build a small 10×10 test raster
r <- rast(ncols = 10, nrows = 10, nlyrs = 3,
          xmin = 0, xmax = 1, ymin = 0, ymax = 1)
names(r) <- c("sand", "silt", "clay")

set.seed(7712)
sand_v <- runif(100, 10, 70)
clay_v <- runif(100, 5, 40)
silt_v <- 100 - sand_v - clay_v
values(r) <- cbind(sand_v, silt_v, clay_v)

r_class <- classify_texture(r, sand = "sand", silt = "silt", clay = "clay")
print(r_class)
#> class       : SpatRaster 
#> size        : 10, 10, 1  (nrow, ncol, nlyr)
#> resolution  : 0.1, 0.1  (x, y)
#> extent      : 0, 1, 0, 1  (xmin, xmax, ymin, ymax)
#> coord. ref. : lon/lat WGS 84 (CRS84) (OGC:CRS84) 
#> source(s)   : memory
#> categories  : texture_class 
#> name        : texture_class 
#> min value   :    sandy clay 
#> max value   :    sandy loam
levels(r_class)[[1]]
#>    id   texture_class
#> 1   1            clay
#> 2   2      silty clay
#> 3   3      sandy clay
#> 4   4       clay loam
#> 5   5 silty clay loam
#> 6   6 sandy clay loam
#> 7   7            loam
#> 8   8      silty loam
#> 9   9      sandy loam
#> 10 10            silt
#> 11 11      loamy sand
#> 12 12            sand
```

**SoilGrids note:** SoilGrids stores fractions in g/kg (0–1000). Divide
by 10 before classifying.
[`classify_texture()`](https://taakefyrsten.github.io/tidysoiltexture/reference/classify_texture.md)
will emit a `cli_warn()` if any value exceeds 100, so the error surfaces
clearly.

``` r
r_sg <- rast("SoilGrids_sand_silt_clay.tif")   # g/kg layers
r_class <- classify_texture(r_sg / 10,
                             sand = "sand", silt = "silt", clay = "clay")
```

------------------------------------------------------------------------

## 8. Edge cases: boundary points and vertices

The ray-casting algorithm includes a collinearity check so points that
fall exactly on class boundaries (shared edges, polygon vertices) are
classified correctly rather than returning `NA`.

``` r
# Clay/silty clay boundary at clay=40%, silt=60%
boundary_pts <- tribble(
  ~description,          ~sand, ~silt, ~clay,
  "clay vertex",             0,    40,    60,
  "silt/silty clay border",  0,    60,    40,
  "clay loam centroid",     32,    34,    34
)

classify_texture(boundary_pts, sand, silt, clay) |>
  select(description, .texture_class)
#> # A tibble: 3 × 2
#>   description            .texture_class
#>   <chr>                  <chr>         
#> 1 clay vertex            clay          
#> 2 silt/silty clay border silty clay    
#> 3 clay loam centroid     clay loam
```

------------------------------------------------------------------------

## See also

- [`vignette("gg-texture-triangle")`](https://taakefyrsten.github.io/tidysoiltexture/articles/gg-texture-triangle.md)
  — visualise classified samples on a texture triangle
- [`vignette("gis-workflow")`](https://taakefyrsten.github.io/tidysoiltexture/articles/gis-workflow.md)
  — full GIS workflow with sf and terra
