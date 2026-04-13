# Suppress R CMD check NOTE "no visible binding for global variable"
# for column names used with dplyr/ggplot2 inside gg_texture_triangle()
# and geom_texture_contour().
utils::globalVariables(c(
  "x", "y", "z", "fill_colour",
  "axis", "grp", "angle",
  "x0", "y0", "x1", "y1",
  "lx", "ly", "label",
  ".x", ".y", ".data"
))
