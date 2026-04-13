# Internal helper: ternary -> Cartesian projection
#
# Standard USDA orientation:
#   - Clay apex : top         (0.5, sqrt(3)/2)
#   - Sand apex : bottom-left (0,   0)
#   - Silt apex : bottom-right(1,   0)
#
# Arguments sand, silt, clay are numeric vectors in percent (0–100).
# Returns a data frame with columns x and y.
ternary_to_cartesian <- function(sand, silt, clay) {
  s  <- sand  / 100
  si <- silt  / 100
  cl <- clay  / 100

  h <- sqrt(3) / 2

  # x = s*0 + si*1 + cl*0.5
  # y = s*0 + si*0 + cl*h
  x <- si + cl * 0.5
  y <- cl * h

  data.frame(x = x, y = y)
}
