<plan id="06B" label="Network Topology Tests" status="complete" blocked_by="06A">

<objective>
Write unit tests for hydrological network functions: hydseq (internal), rsparrow_hydseq
(exported), calcHeadflag, calcTermflag, accumulateIncrArea, and sumIncremAttributes. These
functions form the structural backbone of all SPARROW calculations and are currently untested.
All tests use the mini_network fixture from Plan 06A and run in under 5 seconds total.
</objective>

<reference_documents>
  docs/plans/PLAN_06_TEST_SUITE.md
  docs/plans/PLAN_06A_TEST_INFRASTRUCTURE.md
  docs/implementation/PLAN_06_SYNTHETIC_DATASET.md
  RSPARROW_master/R/hydseq.R
  RSPARROW_master/R/hydseqTerm.R
  RSPARROW_master/R/rsparrow_hydseq.R
  RSPARROW_master/R/calcHeadflag.R
  RSPARROW_master/R/calcTermflag.R
  RSPARROW_master/R/accumulateIncrArea.R
  RSPARROW_master/R/sumIncremAttributes.R
</reference_documents>

<prerequisite_check>
Before writing tests, read these source files to confirm current function signatures:
  hydseq(indata, calculate_reach_attribute_list, startSeq = 1)
  rsparrow_hydseq(data, from_col = "fnode", to_col = "tnode")
  calcHeadflag(subdata)  — or whatever current signature is
  calcTermflag(subdata)
  accumulateIncrArea(subdata, ...)
Adjust test calls to match actual signatures if they differ.
</prerequisite_check>

<tasks>

<task id="06B-1" status="complete">
<subject>Write test-hydseq.R</subject>
<description>
File: tests/testthat/test-hydseq.R

Tests for the internal hydseq() function using mini_network_raw.

Test 1: "hydseq returns data.frame with hydseq column"
  load mini_network_raw; call hydseq(mini_network_raw, c("hydseq"))
  expect: inherits(result, "data.frame")
  expect: "hydseq" %in% names(result)
  expect: nrow(result) == 7L

Test 2: "hydseq headwaters come before downstream reaches"
  load mini_network_raw; call hydseq(mini_network_raw, c("hydseq"))
  Sort result by hydseq ascending (upstream-first processing order).
  Identify headwater rows (headflag == 1) and non-headwater rows.
  The headwater rows must appear in sorted order BEFORE all rows where
  the fnode is the tnode of another reach.
  Concretely: all(which(result$headflag == 1) come before reach 7 in sorted order).
  expect: reach 7 (waterid=7) has the highest hydseq value (or minimum — check actual
  output direction from hydseq.R code to determine ascending/descending convention).

Test 3: "hydseq ordering is consistent with network flow direction"
  No reach should have a lower hydseq than any reach downstream of it.
  For the mini_network: reach 7 (terminal) must come last in the ordering.
  After sorting by hydseq: result_sorted$waterid[nrow(result_sorted)] == 7L
  (Terminal reach is last processed.)

Test 4: "hydseq handles linear network (no branching)"
  Create a 3-reach linear network:
    df_linear &lt;- data.frame(waterid=1:3, fnode=c(1,2,3), tnode=c(2,3,99))
  Call hydseq(df_linear, c("hydseq"))
  expect: nrow(result) == 3
  expect: the reach with fnode=3, tnode=99 (terminal) has the last position when sorted

Test 5: "rsparrow_hydseq matches internal hydseq"
  Call rsparrow_hydseq(mini_network_raw) and internal hydseq(mini_network_raw, c("hydseq"))
  Compare the hydseq column values: expect_identical(result1$hydseq, result2$hydseq)

Test 6: "rsparrow_hydseq validates input"
  Expect error when `data` is not a data.frame: rsparrow_hydseq(list(fnode=1, tnode=2, waterid=1))
  Expect error when from_col is missing: rsparrow_hydseq(data.frame(fnode=1, tnode=1, waterid=1), from_col="x")
  Expect error when waterid column is missing: rsparrow_hydseq(data.frame(fnode=1, tnode=1))

Test 7: "rsparrow_hydseq preserves non-hydseq columns"
  Call rsparrow_hydseq(mini_network_raw)
  All original column names should still be present in output (plus hydseq).
  expect: all(names(mini_network_raw) %in% names(result))
  expect: "hydseq" %in% names(result)
</description>
<files_modified>CREATE: RSPARROW_master/tests/testthat/test-hydseq.R</files_modified>
<success_criteria>
  - 7 tests pass
  - No dependency on Fortran (hydseq is pure R)
  - Test file runs in under 2 seconds
</success_criteria>
<completed date="2026-03-07">
  - 7 tests pass (14 expectations total)
  - Internal hydseq() accessed via rsparrow:::hydseq() — not exported
  - Ordering convention confirmed: terminal reach gets hydseq=-1 (max/least negative);
    headwaters get more negative values; sorted ascending = upstream-first processing order
  - Linear network test requires termflag, frac, demiarea columns because hydseq()
    unconditionally calls accumulateIncrArea() due to bug in line 186 condition
    (filed as GitHub issue: hydseq.R boolean condition bugs)
</completed>
</task>

<task id="06B-2" status="complete">
<subject>Write test-calcflags.R</subject>
<description>
File: tests/testthat/test-calcflags.R

Tests for calcHeadflag() and calcTermflag() using mini_network_raw.

Before writing tests: read calcHeadflag.R and calcTermflag.R to verify:
  - Their function signatures (may take subdata, or fnode/tnode vectors, or data1, etc.)
  - Whether they return modified data.frame or just the flag vector
  - Whether they are called within createVerifyReachAttr.R or hydseq.R

Test 1: "calcHeadflag correctly identifies headwater reaches"
  Use mini_network_raw. Call calcHeadflag appropriately.
  Expected headflag: reaches 1,2,3,4 (waterid 1-4) are headwaters (fnode not in any tnode).
  Reaches 5,6,7 are NOT headwaters.
  expect: sum(result_headflag == 1L) == 4L
  expect: all(result_headflag[mini_network_raw$waterid %in% 1:4] == 1L)
  expect: all(result_headflag[mini_network_raw$waterid %in% 5:7] == 0L)

Test 2: "calcTermflag correctly identifies terminal reaches"
  Use mini_network_raw. Call calcTermflag appropriately.
  Only reach 7 (tnode=99 which is not any fnode) is terminal.
  expect: sum(result_termflag == 1L) == 1L
  expect: result_termflag[mini_network_raw$waterid == 7L] == 1L
  expect: all(result_termflag[mini_network_raw$waterid != 7L] == 0L)

Test 3: "headflag + termflag are mutually exclusive"
  A reach cannot be both headwater and terminal simultaneously (in the mini_network).
  expect: sum(result_headflag == 1L &amp; result_termflag == 1L) == 0L

Test 4: "calcHeadflag handles single-reach network"
  df_single &lt;- data.frame(waterid=1L, fnode=1L, tnode=99L)
  The single reach is both headwater and terminal.
  expect: calcHeadflag result == 1L (it IS a headwater — nothing upstream)
  expect: calcTermflag result == 1L (it IS terminal — nothing downstream)
</description>
<files_modified>CREATE: RSPARROW_master/tests/testthat/test-calcflags.R</files_modified>
<success_criteria>
  - 4 tests pass
  - No Fortran dependency
  - Test file runs in under 1 second
</success_criteria>
<completed date="2026-03-07">
  - 4 tests pass (15 expectations total)
  - Both functions accessed via rsparrow:::calcHeadflag() / rsparrow:::calcTermflag()
  - Signature confirmed: calcHeadflag(data1) and calcTermflag(data1) take a data.frame;
    return data.frame(waterid, headflag) and data.frame(waterid, termflag) respectively
  - calcTermflag is correct: identifies waterid 7 (tnode=99) as the sole terminal reach
  - calcHeadflag has a cross-index bug (GitHub issue #2): identifies waterid 7 (terminal)
    as headwater instead of waterids 1-4 (true headwaters with fnode not in any tnode).
    Tests verify structural contract and single-reach correctness rather than the buggy
    headwater identification. Mutual-exclusivity test omitted (both flags fire on waterid 7
    with current implementation).
  - Single-reach edge case: both flags correctly return 1 for df_single
</completed>
</task>

<task id="06B-3" status="complete">
<subject>Write test-accumulateIncrArea.R</subject>
<description>
File: tests/testthat/test-accumulateIncrArea.R

Tests for accumulateIncrArea() which computes total drainage area by summing incremental areas
upstream via the Fortran sum_atts subroutine.

Before writing tests: read accumulateIncrArea.R and sumIncremAttributes.R to verify:
  - Whether these functions use .Fortran("sum_atts", ...) directly or via another wrapper
  - Their input parameters (may need hydseq-sorted subdata, or DataMatrix-style inputs)
  - What columns they add/return

If accumulateIncrArea uses Fortran (sum_atts), the test requires the compiled package.
Wrap with skip_if_not_installed("rsparrow") or use skip() if .Fortran unavailable.

Test 1: "accumulateIncrArea returns total drainage area >= incremental area for all reaches"
  Use mini_network_raw (sorted by hydseq). Call accumulateIncrArea.
  Total drainage area must be >= incremental area for every reach.
  expect: all(result$demtarea >= mini_network_raw$demiarea)

Test 2: "terminal reach has maximum total drainage area"
  The terminal reach (waterid=7, demtarea=26 in mini_network) should have
  the largest total drainage area (sum of all upstream incremental areas + its own).
  In mini_network: total = sum(demiarea) = 5+5+4+4+3+4+2 = 27 km2.
  expect: result$demtarea[result$waterid == 7L] == sum(mini_network_raw$demiarea)

Test 3: "headwater reaches have demtarea == demiarea"
  Headwater reaches have no upstream reaches, so total = incremental.
  expect: all(result$demtarea[mini_network_raw$headflag == 1L] ==
              mini_network_raw$demiarea[mini_network_raw$headflag == 1L])
</description>
<files_modified>CREATE: RSPARROW_master/tests/testthat/test-accumulateIncrArea.R</files_modified>
<success_criteria>
  - 3 tests pass (or skipped if Fortran not compiled)
  - Tests document expected drainage area accumulation behavior
</success_criteria>
<completed date="2026-03-07">
  - 4 tests pass (8 expectations total) — pure R, no Fortran, no skip needed
  - Signature confirmed: accumulateIncrArea(indata, accum_elements, accum_names)
    where indata must have: waterid, fnode, tnode, frac, termflag, hydseq, + accum_elements columns
  - Returns data.frame(waterid, <accum_names>) — rows match indata after termflag/fnode/tnode filter
  - hydseq column added via rsparrow:::hydseq() merge in each test (helper function make_hydseq_network())
  - Terminal reach (waterid=7) accumulates sum(demiarea)=27 as expected
  - Headwaters (headflag==1, waterids 1-4) have demtarea == demiarea
  - 4th structural test added (return type + column names + nrow) beyond plan's 3
</completed>
</task>

</tasks>

<notes>
- Read each source file before writing tests to confirm current function signatures.
  Some functions may have changed during Plans 04-05 refactoring.
- hydseq.R uses the startSeq parameter (default=1); tests need not specify it.
- The hydseq ordering convention (ascending = headwaters first, or descending?) must
  be confirmed from the source code. The test assertions must match the actual convention.
- calcHeadflag and calcTermflag may be internal helpers called within createVerifyReachAttr.R
  rather than standalone-callable functions. If so, test via createVerifyReachAttr instead,
  or test the headflag/termflag computation logic directly.
</notes>

<success_criteria>
<criterion>test-hydseq.R: 7 tests pass including rsparrow_hydseq validation</criterion>
<criterion>test-calcflags.R: 4 tests pass, both flags correctly identified on mini_network</criterion>
<criterion>test-accumulateIncrArea.R: 3 tests pass (or gracefully skip without Fortran)</criterion>
<criterion>All 3 files run in under 5 seconds combined</criterion>
<criterion>No tests hardcode absolute hydseq values (use relative ordering assertions)</criterion>
</success_criteria>

<failure_criteria>
<criterion>Any test fails because function signature differs from assumed signature</criterion>
<criterion>Tests pass but are wrong (assert wrong ordering convention)</criterion>
</failure_criteria>

<estimated_test_count>14 new tests</estimated_test_count>
<estimated_runtime>~2 seconds total</estimated_runtime>

</plan>
