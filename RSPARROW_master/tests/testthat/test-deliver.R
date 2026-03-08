# Tests for deliver() — Plan 06C-1
#
# deliver(nreach, waterid, nnode, data2, incdecay, totdecay)
#   wraps .Fortran("deliv_fraction") — requires compiled rsparrow
#
# data2 columns: [fnode, tnode, frac, iftran, termflag]  (5 columns)
# incdecay: multiplicative incremental decay factor per reach (1.0 = no decay)
# totdecay: multiplicative total decay factor per reach (1.0 = no decay)
# returns: sumatt(nreach) — delivery fraction per reach
#
# NOTE: incdecay=0 and totdecay=0 give delivery fractions of 0 (not 1), because
# the Fortran multiplies sumatt(i) * incdecay(i) as its final step.
# For perfect delivery (no decay), pass incdecay=rep(1,nreach), totdecay=rep(1,nreach).
#
# mini_network topology (waterid → fnode→tnode, sorted by hydseq = waterid):
#   1 (1→10), 2 (2→10), 3 (3→11), 4 (4→11)  ← headwaters
#   5 (10→12), 6 (11→12)                       ← mid reaches
#   7 (12→99)                                   ← terminal (termflag=1)

testthat::skip_if_not_installed("rsparrow")

# Shared fixture helpers
make_deliver_inputs <- function() {
  load(test_path("fixtures/mini_network.rda"))
  net   <- mini_network_raw
  nreach  <- 7L
  waterid <- net$waterid
  nnode   <- as.integer(max(c(net$fnode, net$tnode)))
  data2   <- cbind(net$fnode, net$tnode, net$frac, net$iftran, net$termflag)
  storage.mode(data2) <- "double"
  list(nreach = nreach, waterid = waterid, nnode = nnode, data2 = data2)
}

test_that("deliver returns numeric vector of length nreach", {
  inp <- make_deliver_inputs()
  result <- rsparrow:::deliver(inp$nreach, inp$waterid, inp$nnode, inp$data2,
                               rep(1.0, inp$nreach), rep(1.0, inp$nreach))
  expect_true(is.numeric(result))
  expect_equal(length(result), 7L)
})

test_that("deliver with incdecay=1 and totdecay=1 returns delivery fractions of 1.0", {
  # When decay factors are 1 (multiplicative identity), all reaches
  # have delivery fraction 1.0: load is fully delivered to the outlet.
  inp <- make_deliver_inputs()
  result <- rsparrow:::deliver(inp$nreach, inp$waterid, inp$nnode, inp$data2,
                               rep(1.0, inp$nreach), rep(1.0, inp$nreach))
  expect_numeric_close(result, rep(1.0, 7L), tol = 1e-10,
                       label = "perfect delivery (no decay)")
})

test_that("deliver with incdecay=totdecay=0.5 returns fractions in (0, 1)", {
  # Uniform partial decay: all fractions must be strictly between 0 and 1.
  inp <- make_deliver_inputs()
  result <- rsparrow:::deliver(inp$nreach, inp$waterid, inp$nnode, inp$data2,
                               rep(0.5, inp$nreach), rep(0.5, inp$nreach))
  expect_true(all(result >= 0.0 & result <= 1.0))
  expect_true(all(result > 0.0))   # all positive
  expect_true(all(result < 1.0))   # decay reduces delivery
})

test_that("deliver with decay: upstream reaches have lower delivery than terminal", {
  # With partial decay (incdecay = totdecay = 0.5), load from headwater reaches
  # travels through more reaches and is more attenuated.  The terminal reach
  # (waterid 7) delivers only its own incremental load and has the highest
  # delivery fraction; headwaters (waterid 1-4) have the lowest.
  inp <- make_deliver_inputs()
  result <- rsparrow:::deliver(inp$nreach, inp$waterid, inp$nnode, inp$data2,
                               rep(0.5, inp$nreach), rep(0.5, inp$nreach))

  deliv_terminal   <- result[inp$waterid == 7L]   # reach 7
  deliv_headwaters <- result[inp$waterid %in% 1:4] # reaches 1-4

  expect_true(all(deliv_headwaters < deliv_terminal),
              label = "headwaters have lower delivery than terminal")
})

test_that("deliver data2 column order is correct — swapped columns produce different results", {
  # Swapping frac (col 3) and termflag (col 5) produces different results when
  # termflag != frac (which is true here: frac=1.0 for all, termflag=0 or 1).
  # This guards against accidental column reordering in callers.
  inp <- make_deliver_inputs()
  incdecay <- rep(0.5, inp$nreach)
  totdecay  <- rep(0.5, inp$nreach)

  result_correct <- rsparrow:::deliver(inp$nreach, inp$waterid, inp$nnode,
                                       inp$data2, incdecay, totdecay)

  data2_swapped        <- inp$data2
  data2_swapped[, 3]   <- inp$data2[, 5]  # frac <- termflag
  data2_swapped[, 5]   <- inp$data2[, 3]  # termflag <- frac
  result_swapped <- rsparrow:::deliver(inp$nreach, inp$waterid, inp$nnode,
                                       data2_swapped, incdecay, totdecay)

  expect_false(identical(result_correct, result_swapped),
               label = "swapped columns produce different delivery fractions")
})
