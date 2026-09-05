# Collect every symbol referenced in call position (or via ::/:::) from a
# language object, function, or expression. Used by the capability guards in
# test-no-fuzzy.R. Empty arguments (x[, 1]) must be tested by INDEX and never
# bound to a variable -- evaluating a name bound to the empty symbol IS the
# missing-argument error.
referenced_symbols <- function(x) {
  refs <- new.env(parent = emptyenv())
  walk <- function(e) {
    if (is.call(e)) {
      h <- e[[1]]
      if (is.symbol(h)) {
        assign(as.character(h), TRUE, refs)
        if (as.character(h) %in% c("::", ":::")) {
          assign(as.character(e[[2]]), TRUE, refs)
          assign(as.character(e[[3]]), TRUE, refs)
        }
      }
      if (is.call(h)) walk(h)
      args <- as.list(e)[-1]
      for (i in seq_along(args)) {
        if (!identical(args[[i]], quote(expr = ))) walk(args[[i]])
      }
    } else if (is.function(e)) {
      walk(body(e))
      d <- formals(e)
      for (i in seq_along(d)) {
        if (!identical(d[[i]], quote(expr = ))) walk(d[[i]])
      }
    } else if (is.pairlist(e) || is.expression(e) || is.list(e)) {
      for (i in seq_along(e)) {
        if (!identical(e[[i]], quote(expr = ))) walk(e[[i]])
      }
    }
  }
  walk(x)
  ls(refs)
}
