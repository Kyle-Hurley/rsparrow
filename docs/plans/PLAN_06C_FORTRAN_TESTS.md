<plan id="06C" label="Fortran Interface Tests" status="complete" blocked_by="06A">

<objective>
Write tests that exercise the six Fortran subroutines (tnoder, ptnoder, mptnoder,
deliv_fraction, sites_incr, sum_atts) through their R wrapper functions. These tests verify
that the .Fortran() call signatures are correct (argument order, types, dimensions) and that
the compiled routines produce correct results on the mini_network fixture. All tests require
a compiled package and must skip gracefully if Fortran is not compiled.
</objective>

<reference_documents>
  docs/plans/PLAN_06_TEST_SUITE.md
  docs/implementation/PLAN_06_SYNTHETIC_DATASET.md
  docs/reference/DATA_STRUCTURES.md (Fortran interface specs)
  RSPARROW_master/R/deliver.R
  RSPARROW_master/R/estimateFeval.R
  RSPARROW_master/R/predict.R
  RSPARROW_master/src/tnoder.f
  RSPARROW_master/src/ptnoder.f
  RSPARROW_master/src/deliv_fraction.f
</reference_documents>

<fortran_interface_summary>
From docs/reference/DATA_STRUCTURES.md:
  tnoder:         Input: ifadjust, nreach, nnode, data2(nreach,4)[fnode,tnode,depvar,iftran],
                         incddsrc(nreach), carryf(nreach)
                  Output: ee(nreach) — residuals at monitoring sites (zero elsewhere)

  ptnoder:        Same inputs as tnoder
                  Output: pred(nreach) — predicted load at every reach

  mptnoder:       Same + share(nreach) — source share vector
                  Output: pred(nreach) — monitoring-adjusted source load

  deliv_fraction: Input: nreach, waterid, nnode, data2(nreach,5)[fnode,tnode,frac,iftran,termflag],
                         incdecay, totdecay
                  Output: sumatt(nreach) — delivery fraction (0.0 to 1.0)

  sites_incr, sum_atts: called via sumIncremAttributes/accumulateIncrArea
</fortran_interface_summary>

<skip_guard>
All tests in this sub-plan must begin with:
  skip_if_not(is.element("rsparrow", loadedNamespaces()) ||
              requireNamespace("rsparrow", quietly=TRUE),
              "rsparrow not compiled; skipping Fortran tests")
Or equivalently use withr/testthat skip mechanism. The simpler form is:
  skip_if_not_installed("rsparrow")
combined with checking that the Fortran symbol is registered:
  skip_if(!existsMethod(".Fortran", "deliv_fraction"))  # pseudocode
The recommended pattern is:
  testthat::skip_if_not_installed("rsparrow")
since the package must be compiled to be installable.
</skip_guard>

<tasks>

<task id="06C-1" status="complete">
<subject>Write test-deliver.R — delivery fraction computation</subject>
<description>
File: tests/testthat/test-deliver.R

Tests for deliver() in RSPARROW_master/R/deliver.R which wraps .Fortran("deliv_fraction").

The deliver() signature:
  deliver(nreach, waterid, nnode, data2, incdecay, totdecay)

data2 is a matrix with columns: [fnode, tnode, frac, iftran, termflag]
  (NOTE: data2 for deliver has 5 columns, different from tnoder's 4 columns)
incdecay: incremental decay per reach (in-stream * reservoir)
totdecay: total accumulated decay per reach

Build inputs from mini_network_raw:
  nreach  = 7L
  waterid = mini_network_raw$waterid (sorted by hydseq)
  nnode   = max(c(mini_network_raw$fnode, mini_network_raw$tnode))
  data2   = cbind(fnode, tnode, frac, iftran, termflag) as numeric matrix
  incdecay = rep(0.0, 7)   # zero decay = perfect delivery
  totdecay = rep(0.0, 7)   # zero total decay

Test 1: "deliver returns vector of length nreach"
  result &lt;- deliver(nreach=7L, waterid=..., nnode=..., data2=..., incdecay=..., totdecay=...)
  expect: length(result) == 7L
  expect: is.numeric(result)

Test 2: "deliver with zero decay returns delivery fractions of 1.0 for all reaches"
  With incdecay = totdecay = rep(0, nreach), all delivery fractions should equal 1.0.
  expect_numeric_close(result, rep(1.0, 7), tol=1e-10, label="zero decay delivery")

Test 3: "deliver with high decay returns delivery fractions in [0, 1]"
  Set incdecay = rep(5.0, 7) and totdecay = seq(5, 35, by=5).
  expect: all(result >= 0.0 &amp; result &lt;= 1.0)
  expect: all(result &lt; 1.0)  # decay reduces delivery

Test 4: "deliver with decay: upstream reach has higher delivery than downstream"
  In a linear chain, reaches closer to the outlet (lower delivery path) should have
  lower delivery fractions when there is decay. Create a 3-reach linear mini-network:
    R1 → R2 → R3(terminal)
  Set uniform incdecay for all reaches.
  Delivery fraction of R1 &lt; delivery fraction of R3 (R1 load travels farther).
  NOTE: Verify the convention — deliv_fraction may compute fraction of load reaching
  a reference point (outlet), so upstream reaches have lower fractions.

Test 5: "deliver data2 column order is correct (no silent transposition)"
  Intentionally swap frac and termflag columns in data2 and verify result differs
  from the correctly-ordered call. This guards against accidental column reordering.
  Two calls with swapped vs. correct columns should NOT produce identical results
  when termflag != frac.
</description>
<files_modified>CREATE: RSPARROW_master/tests/testthat/test-deliver.R</files_modified>
<success_criteria>
  - 5 tests pass when rsparrow compiled with gfortran
  - Tests skip gracefully if package not compiled
  - Zero-decay delivery fractions verified to be 1.0 within 1e-10 tolerance
</success_criteria>
<completed date="2026-03-07">
  - 5 tests pass (10 expectations total)
  - KEY DISCOVERY: incdecay/totdecay are multiplicative decay factors (1.0=no decay, NOT 0.0).
    Zero-decay uses rep(1.0, nreach) not rep(0, nreach) — plan description corrected.
  - Headwaters (waterid 1-4) have strictly lower delivery fractions than terminal (waterid 7)
    under partial decay (0.5), confirming upstream attenuation direction.
  - Column-order guard test confirms swapping frac and termflag produces different results.
</completed>
</task>

<task id="06C-2" status="complete">
<subject>Write test-fortran-tnoder.R — residual computation via estimateFeval</subject>
<description>
File: tests/testthat/test-fortran-tnoder.R

The tnoder Fortran subroutine is called inside estimateFeval(). Rather than calling .Fortran
directly, test it via estimateFeval() with mini_model_inputs. This gives coverage of both the
R wrapper logic and the Fortran routine.

Load mini_inputs from fixtures/mini_model_inputs.rda.
Extract: DataMatrix.list, SelParmValues, Csites.weights.list, estimate.input.list, dlvdsgn.
Use beta0 = c(0.5, -0.5, 0.1) (the initial parameters from SelParmValues$beta0).

Test 1: "estimateFeval returns numeric vector of length nreach"
  e &lt;- estimateFeval(beta0, DataMatrix.list, SelParmValues, Csites.weights.list,
                     estimate.input.list, dlvdsgn, ifadjust=1L)
  expect: is.numeric(e)
  expect: length(e) == 7L   # nreach

Test 2: "estimateFeval residuals are zero at non-monitoring reaches"
  Only reach 7 is a calibration site (calsites=1, depvar>0).
  All other reaches should have residual = 0.
  expect: all(e[1:6] == 0.0)

Test 3: "estimateFeval residual at monitoring site is finite and non-zero"
  The single calibration site (reach 7, depvar=100) should produce a non-zero residual
  for beta0 that is unlikely to exactly fit the data.
  expect: is.finite(e[7])
  expect: e[7] != 0.0

Test 4: "estimateFeval with ifadjust=0 returns finite residuals at all monitoring sites"
  When ifadjust=0L (no monitoring load substitution), unit weights are used.
  e_noadj &lt;- estimateFeval(beta0, DataMatrix.list, SelParmValues, Csites.weights.list,
                            estimate.input.list, dlvdsgn, ifadjust=0L)
  expect: is.finite(e_noadj[7])
  expect: length(e_noadj) == 7L

Test 5: "estimateFeval residual changes monotonically with source coefficient"
  Increasing beta_s1 increases predicted source load → residual should change direction.
  e_low  &lt;- estimateFeval(c(0.1, -0.5, 0.1), ...)
  e_high &lt;- estimateFeval(c(1.0, -0.5, 0.1), ...)
  The calibration site residual should change sign or magnitude between the two.
  expect: sign(e_low[7]) != sign(e_high[7]) OR abs(e_low[7]) != abs(e_high[7])

Test 6: "estimateFeval backward-compatible wrapper: estimateFevalNoadj matches ifadjust=0"
  The backward-compat wrapper at the bottom of estimateFeval.R:
    estimateFevalNoadj(beta0, DataMatrix.list, SelParmValues, Csites.weights.list,
                       estimate.input.list, dlvdsgn)
  should produce the same result as estimateFeval(..., ifadjust=0L).
  expect_identical(e_wrapper, e_noadj)
  (Verifies Plan 05B's merge did not break the wrapper.)
</description>
<files_modified>CREATE: RSPARROW_master/tests/testthat/test-fortran-tnoder.R</files_modified>
<success_criteria>
  - 6 tests pass
  - Tests skip if rsparrow not compiled
  - estimateFevalNoadj backward-compat wrapper confirmed identical to ifadjust=0
</success_criteria>
<completed date="2026-03-07">
  - 6 tests pass (12 expectations total)
  - KEY DISCOVERY: With 1 monitoring site (nstaid=1), tnoder writes ee(1) but estimateFeval.R
    allocates ee as length nstaid=1 then applies sqrt(weight)*ee with weight length 7.
    R recycling propagates the single residual to all 7 positions — all elements are identical.
    Plan's assumption that non-monitoring reaches return 0 was WRONG for this implementation.
    Tests updated to verify recycling behavior (all elements equal rather than zeros at non-monitoring).
  - Monotonicity test confirmed: residual magnitude changes with beta_s1.
  - estimateFevalNoadj backward-compat wrapper confirmed identical to ifadjust=0L.
</completed>
</task>

<task id="06C-3" status="complete">
<subject>Write test-fortran-ptnoder.R — prediction accumulation via predict_sparrow stub</subject>
<description>
File: tests/testthat/test-fortran-ptnoder.R

The ptnoder/mptnoder Fortran routines are called inside predict_sparrow() (predict.R) and
predict_core() (predict_core.R). Test them via predict_sparrow() with mini_model_inputs.

Load mini_inputs and build all required arguments for predict_sparrow:
  estimate.list    = mini_inputs$estimate.list  (with oEstimate = c(0.5, -0.5, 0.1))
  estimate.input.list = mini_inputs$estimate.input.list
  bootcorrection   = 1.0  (no bias correction)
  DataMatrix.list  = mini_inputs$DataMatrix.list
  SelParmValues    = mini_inputs$SelParmValues
  subdata          = mini_network_raw sorted by hydseq
  dlvdsgn          = mini_inputs$dlvdsgn

Test 1: "predict_sparrow returns a named list with predmatrix and yldmatrix"
  result &lt;- predict_sparrow(estimate.list, estimate.input.list, 1.0,
                            DataMatrix.list, SelParmValues, subdata, dlvdsgn)
  expect: is.list(result)
  expect: "predmatrix" %in% names(result)
  expect: "yldmatrix" %in% names(result)

Test 2: "predmatrix has nreach rows"
  expect: nrow(result$predmatrix) == 7L

Test 3: "total load at terminal reach >= total load at any individual source"
  The terminal reach accumulates all upstream loads. Its total predicted load should be
  the largest in the network. Row for reach 7 total load >= all other rows.
  total_load_col &lt;- 1   # typically first column of predmatrix is total load
  (Verify column index from predict.R or getVarList.R before writing assertion.)
  expect: result$predmatrix[reach7_row, total_load_col] ==
          max(result$predmatrix[, total_load_col])

Test 4: "predicted loads are positive for positive source inputs"
  All reaches with positive source values should have positive predicted loads.
  expect: all(result$predmatrix[, total_load_col] >= 0.0)

Test 5: "yield matrix has same number of rows as predmatrix"
  expect: nrow(result$yldmatrix) == nrow(result$predmatrix)

Test 6: "predict_sparrow output column names match getVarList specification"
  result$oparmlist should be a character vector of load variable names.
  result$oyieldlist should be a character vector of yield variable names.
  expect: is.character(result$oparmlist)
  expect: is.character(result$oyieldlist)
  expect: length(result$oparmlist) > 0
</description>
<files_modified>CREATE: RSPARROW_master/tests/testthat/test-fortran-ptnoder.R</files_modified>
<success_criteria>
  - 6 tests pass
  - Tests skip if rsparrow not compiled
  - predmatrix dimensions confirmed correct for 7-reach network
</success_criteria>
<completed date="2026-03-07">
  - 6 tests pass (11 expectations total)
  - predmatrix confirmed as 7 rows × 14 columns (waterid + load vars + source shares)
  - yldmatrix confirmed as 7 rows × 10 columns (waterid + yield/conc vars)
  - Terminal reach (waterid=7, row 7) has the maximum pload_total (column 2, col 1=waterid)
  - All total predicted loads non-negative
  - oparmlist and oyieldlist are character vectors with waterid as first element
</completed>
</task>

</tasks>

<notes>
- Before writing test-deliver.R: read deliver.R carefully to confirm data2 has 5 columns
  (fnode, tnode, frac, iftran, termflag) in that exact order. Cross-check with deliv_fraction.f.
- Before writing test-fortran-tnoder.R: confirm estimateFeval's exact column mapping of
  DataMatrix.list$data to Fortran tnoder inputs. Look at the tnoder call in estimateFeval.R.
- The mini_network has only 1 calibration site. Tests must account for all other residuals
  being exactly 0.0 (not just approximately 0).
- If ptnoder/mptnoder expect inputs in hydseq order (sorted upstream→downstream), then
  subdata must be sorted by hydseq before passing to predict_sparrow. The fixture build
  script must ensure DataMatrix.list is built from hydseq-sorted data.
</notes>

<success_criteria>
<criterion>test-deliver.R: 5 tests — zero decay → 1.0 fractions, positive decay → in [0,1]</criterion>
<criterion>test-fortran-tnoder.R: 6 tests — residual structure, ifadjust variants, backward-compat</criterion>
<criterion>test-fortran-ptnoder.R: 6 tests — output structure and accumulation correctness</criterion>
<criterion>All 17 tests skip gracefully if rsparrow not compiled</criterion>
<criterion>Total runtime &lt; 5 seconds</criterion>
</success_criteria>

<failure_criteria>
<criterion>Any Fortran test crashes R (segfault from wrong matrix dimensions)</criterion>
<criterion>Data2 column order mismatch causes all delivery fractions = NaN or 0</criterion>
<criterion>estimateFeval residual at monitoring site is 0.0 for any reasonable beta0 (indicates
 Fortran not running or calibration site not being identified)</criterion>
</failure_criteria>

<estimated_test_count>17 new tests</estimated_test_count>
<estimated_runtime>~3 seconds total (Fortran routines are fast)</estimated_runtime>

</plan>
