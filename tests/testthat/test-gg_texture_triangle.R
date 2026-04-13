test_that("returns a ggplot object", {
  soils <- tibble::tibble(
    sand = c(40, 70, 10),
    silt = c(40, 20, 20),
    clay = c(20, 10, 70)
  )
  p <- gg_texture_triangle(soils, sand = sand, silt = silt, clay = clay)
  expect_s3_class(p, "gg")
})

test_that("colour = NULL produces no colour aesthetic on points", {
  soils <- tibble::tibble(sand = 40, silt = 40, clay = 20)
  p     <- gg_texture_triangle(soils, sand = sand, silt = silt, clay = clay)
  # The colour aesthetic should NOT appear in the point layer's mapping
  point_layer <- Filter(\(l) inherits(l$geom, "GeomPoint"), p$layers)
  mappings    <- names(point_layer[[1]]$mapping)
  expect_false("colour" %in% mappings)
})

test_that("colour column name is mapped to the point colour aesthetic", {
  soils <- tibble::tibble(
    sand     = c(40, 70),
    silt     = c(40, 20),
    clay     = c(20, 10),
    group_id = c("A", "B")
  )
  p           <- gg_texture_triangle(soils, sand = sand, silt = silt, clay = clay,
                                     colour = group_id)
  point_layer <- Filter(\(l) inherits(l$geom, "GeomPoint"), p$layers)
  mappings    <- names(point_layer[[1]]$mapping)
  expect_true("colour" %in% mappings)
})

test_that("invalid system argument raises an error", {
  soils <- tibble::tibble(sand = 40, silt = 40, clay = 20)
  expect_error(
    gg_texture_triangle(soils, sand = sand, silt = silt, clay = clay, system = "UNKNOWN"),
    regexp = "should be"
  )
})

test_that("rows with sand + silt + clay != 100 raise an informative error", {
  bad <- tibble::tibble(sand = 50, silt = 30, clay = 5)
  expect_error(
    gg_texture_triangle(bad, sand = sand, silt = silt, clay = clay),
    regexp = "sum to 100"
  )
})
