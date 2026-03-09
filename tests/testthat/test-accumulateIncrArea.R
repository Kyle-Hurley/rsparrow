# Tests for accumulateIncrArea() — Plan 06B-3
#
# accumulateIncrArea(indata, accum_elements, accum_names)
#   indata         : data.frame with waterid, fnode, tnode, frac, termflag,
#                    hydseq, and the accum_elements column(s)
#   accum_elements : character vector of column names to accumulate
#   accum_names    : character vector of output column names
#   returns        : data.frame(waterid, <accum_names>)
#
# This function is pure R — no Fortran dependency, no skip needed.
#
# mini_network topology (waterid → fnode→tnode):
#   1 (1→10), 2 (2→10), 3 (3→11), 4 (4→11)   ← headwaters
#   5 (10→12), 6 (11→12)                        ← mid reaches
#   7 (12→99)                                    ← terminal
#
# demiarea: 5,5,4,4,3,4,2  → sum = 27
# Expected accumulated demtarea: 5,5,4,4,13,12,27

# Helper: load mini_network_raw and add hydseq column via rsparrow:::hydseq()
make_hydseq_network <- function() {
  load(test_path("fixtures/mini_network.rda"))
  hseq <- rsparrow:::hydseq(mini_network_raw, c("hydseq"))
  merge(mini_network_raw, hseq[, c("waterid", "hydseq")], by = "waterid")
}

test_that("accumulateIncrArea returns data.frame with waterid and named output column", {
  indata <- make_hydseq_network()
  result <- rsparrow:::accumulateIncrArea(indata, "demiarea", "demtarea")

  expect_true(inherits(result, "data.frame"))
  expect_true("waterid" %in% names(result))
  expect_true("demtarea" %in% names(result))
  expect_equal(nrow(result), 7L)
})

test_that("accumulated area is >= incremental area for every reach", {
  indata <- make_hydseq_network()
  result <- rsparrow:::accumulateIncrArea(indata, "demiarea", "demtarea")
  merged <- merge(result, indata[, c("waterid", "demiarea")], by = "waterid")

  expect_true(all(merged$demtarea >= merged$demiarea))
})

test_that("terminal reach accumulates total drainage area (sum of all demiarea)", {
  indata <- make_hydseq_network()
  result <- rsparrow:::accumulateIncrArea(indata, "demiarea", "demtarea")

  total_expected <- sum(indata$demiarea)  # 5+5+4+4+3+4+2 = 27
  terminal_demtarea <- result$demtarea[result$waterid == 7L]

  expect_equal(terminal_demtarea, total_expected)
})

test_that("headwater reaches have demtarea equal to their own demiarea", {
  indata <- make_hydseq_network()
  result <- rsparrow:::accumulateIncrArea(indata, "demiarea", "demtarea")
  merged <- merge(result, indata[, c("waterid", "demiarea", "headflag")], by = "waterid")
  headwaters <- merged[merged$headflag == 1L, ]

  # headwaters (waterid 1-4) have no upstream reaches, so accumulated == incremental
  expect_true(nrow(headwaters) > 0L)
  expect_true(all(headwaters$demtarea == headwaters$demiarea))
})
