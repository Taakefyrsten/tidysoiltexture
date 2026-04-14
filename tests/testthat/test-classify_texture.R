test_that("well-known USDA classes are returned correctly", {
  soils <- data.frame(
    sand = c(90, 10,  5, 40, 70),
    silt = c( 5, 10, 85, 40, 20),
    clay = c( 5, 80, 10, 20, 10)
  )
  result <- classify_texture(soils, sand = sand, silt = silt, clay = clay)
  # (5, 85, 10) → "silt" (USDA: silt ≥ 80%, clay < 12%)
  expect_equal(result$.texture_class, c("sand", "clay", "silt", "loam", "sandy loam"))
})

test_that("output is a tibble with .texture_class and .texture_abbr columns appended", {
  df <- data.frame(sand = 40, silt = 40, clay = 20, site = "A")
  result <- classify_texture(df, sand = sand, silt = silt, clay = clay)
  expect_s3_class(result, "tbl_df")
  expect_true(".texture_class" %in% names(result))
  expect_true(".texture_abbr"  %in% names(result))
  expect_true("site"           %in% names(result))
})

test_that("rows where sand + silt + clay != 100 raise an informative error", {
  bad <- data.frame(sand = 50, silt = 30, clay = 10)
  expect_error(
    classify_texture(bad, sand = sand, silt = silt, clay = clay),
    regexp = "sum to 100"
  )
})

test_that("scalar values work as well as column names", {
  df <- data.frame(id = 1:3)
  # all rows get same scalar class — should not error, should return 3 rows
  result <- classify_texture(df, sand = 40, silt = 40, clay = 20)
  expect_equal(nrow(result), 3L)
  expect_true(all(!is.na(result$.texture_class)))
})

test_that("unsupported system argument raises an error", {
  df <- data.frame(sand = 40, silt = 40, clay = 20)
  expect_error(
    classify_texture(df, sand = sand, silt = silt, clay = clay, system = "INVALID"),
    regexp = "should be"
  )
})
