# Internal utilities for tidysoiltexture

# Resolve a quosure to either a column vector or a scalar numeric.
resolve_arg <- function(quo, data, arg_name) {
  expr <- rlang::get_expr(quo)
  if (rlang::is_symbol(expr)) {
    nm <- rlang::as_string(expr)
    if (nm %in% names(data)) {
      return(data[[nm]])
    }
  }
  val <- rlang::eval_tidy(quo, data = data)
  if (!is.numeric(val)) {
    cli::cli_abort(
      c(
        "{.arg {arg_name}} must be a numeric column name or scalar.",
        "x" = "Got an object of class {.cls {class(val)}}."
      )
    )
  }
  val
}

# Check that sand + silt + clay ≈ 100 for every row (tolerates floating point).
check_texture_sums <- function(sand, silt, clay) {
  totals <- sand + silt + clay
  bad    <- abs(totals - 100) > 1
  if (any(bad)) {
    cli::cli_abort(
      c(
        "Sand, silt, and clay must sum to 100 for every row.",
        "x" = "Found {sum(bad)} row(s) where the sum differs from 100 by more than 1."
      )
    )
  }
  invisible(NULL)
}
