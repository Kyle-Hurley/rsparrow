<plan id="05B">
<title>Plan 05B: Predict Function Consolidation</title>
<status>PENDING</status>
<predecessor>Plan 05A (dead code removal complete)</predecessor>
<successor>Plan 05C</successor>

<goal>
Eliminate ~1500 lines of duplicated prediction logic shared across predict.R (574 lines),
predictBoot.R (475 lines), and predictScenarios.R (842 lines). Extract a shared prediction
kernel. Fix all 15–18 remaining dynamic-source-variable eval(parse()) calls in these three
files by replacing the assign(paste0(...))/eval(parse(srclist[i])) pattern with a named list.
Separately, merge estimateFeval.R and estimateFevalNoadj.R (~95% identical) via an ifadjust
parameter.
</goal>

<context>
The three predict files share nearly identical code for:
  1. Parameter vector setup (betalst from oEstimate)
  2. Reach decay (rchdcayf) and reservoir decay (resdcayf) matrix computation
  3. Source delivery matrix (ddliv1/ddliv2/ddliv3/dddliv)
  4. Incremental load accumulation via Fortran mptnoder/ptnoder
  5. Per-source load vectors named pload_*, mpload_*, pload_nd_*, pload_inc_*

Step 5 uses a fragile pattern: assign(paste0("pload_",name), val) creates local variables,
then srclist[i] = paste0("pload_",name), then eval(parse(text=srclist[i])) retrieves them.
This is the last major eval(parse()) cluster in core modeling code.

estimateFeval.R and estimateFevalNoadj.R differ only in: (a) the ifadjust=1 vs 0 path for
the Fortran call (conditioned vs unconditioned), and (b) weight handling. Merging eliminates
~130 lines of duplication.
</context>

<reference_documents>
  <doc>RSPARROW_master/R/predict.R — 574 lines, canonical prediction function</doc>
  <doc>RSPARROW_master/R/predictBoot.R — 475 lines, bootstrap variant</doc>
  <doc>RSPARROW_master/R/predictScenarios.R — 842 lines, scenario variant + embedded prediction</doc>
  <doc>RSPARROW_master/R/estimateFeval.R — 147 lines, conditioned NLLS objective</doc>
  <doc>RSPARROW_master/R/estimateFevalNoadj.R — 133 lines, unconditioned NLLS objective</doc>
  <doc>RSPARROW_master/R/predictBootstraps.R — bootstrap loop (thin wrapper, keep as-is)</doc>
  <doc>docs/reference/FUNCTION_INVENTORY.md — MERGE classifications for predictBoot, estimateFevalNoadj</doc>
</reference_documents>

<duplication_map>
  <shared_block id="decay_setup" lines_approx="30" present_in="predict.R predictBoot.R predictScenarios.R">
    Setup of rchdcayf (reach decay) and resdcayf (reservoir decay) matrices.
    Identical across all three files. No file-specific variation.
  </shared_block>

  <shared_block id="delivery_setup" lines_approx="25" present_in="predict.R predictBoot.R predictScenarios.R">
    Computation of ddliv1, ddliv2, ddliv3, dddliv (source delivery matrices).
    Identical across all three files. No file-specific variation.
  </shared_block>

  <shared_block id="incremental_load" lines_approx="20" present_in="predict.R predictBoot.R">
    Incremental load computation: pload_inc vector + per-source pload_inc_* via
    assign/srclist_inc pattern. Not present in predictScenarios.R (different output structure).
  </shared_block>

  <shared_block id="fortran_accumulation" lines_approx="40" present_in="predict.R predictBoot.R predictScenarios.R">
    Fortran mptnoder/ptnoder calls for load accumulation across the reach network.
    Signature and input prep largely identical.
  </shared_block>

  <shared_block id="source_load_assembly" lines_approx="60" present_in="predict.R predictBoot.R predictScenarios.R">
    Per-source load vectors: assign(paste0("pload_",Parmnames[j]),pred),
    srclist_total[j] &lt;- paste0("pload_",Parmnames[j]), then eval(parse(srclist[i])).
    This is the eval(parse()) cluster to eliminate.
  </shared_block>

  <file_specific>
    <predict_R>bootcorrection applied as vector multiply; returns predict.list with full
    waterid/pload/yield/conc matrix; no scenario modification of sources.</predict_R>
    <predictBoot_R>bootcorrectionR per-iteration scalar; returns predmatrix only (not predict.list);
    called inside estimateBootstraps loop.</predictBoot_R>
    <predictScenarios_R>Modifies source inputs per scenario_sources/scenario_factors before running
    prediction; embedded in 842-line function with Shiny coupling and CSV output.</predictScenarios_R>
  </file_specific>
</duplication_map>

<eval_parse_fix>
  <problem>
    Current pattern in all three files:
      assign(paste0("pload_", Parmnames[j]), pred)
      srclist_total[j] &lt;- paste0("pload_", Parmnames[j])
      # ... later:
      eval(parse(text = srclist_total[j])) / pload_total
      predmatrix[, 2+i] &lt;- eval(parse(text = srclist_total[i])) * bootcorrection
  </problem>

  <solution>
    Replace with a named list `pload_src`:
      pload_src &lt;- vector("list", length(data.index.list$jsrcvar))
      names(pload_src) &lt;- Parmnames[seq_along(data.index.list$jsrcvar)]
      # ... per source j:
      pload_src[[Parmnames[j]]] &lt;- pred
      # ... later:
      pload_src[[Parmnames[j]]] / pload_total
      predmatrix[, 2+i] &lt;- pload_src[[Parmnames[i]]] * bootcorrection

    Similarly for mpload_src, pload_nd_src, pload_inc_src named lists.
    No eval(), no assign(), no character-vector lookup.
    This fix must be applied consistently wherever srclist_total/srclist_mtotal/
    srclist_nd_total/srclist_inc are built and read.
  </solution>
</eval_parse_fix>

<implementation_steps>
  <step n="1" label="Create R/predict_core.R with shared prediction kernel">
    New internal function: .predict_core(oEstimate, Parmnames, data, data.index.list,
      dlvdsgn, bootcorrection, fortran_fn)
    Returns a list: list(pload_total, mpload_total, pload_nd_total, pload_inc,
      pload_src, mpload_src, pload_nd_src, pload_inc_src, rchdcayf, resdcayf, carryf,
      carryf_nd, incddsrc, incddsrc_nd, incdecay, totdecay, nnode)
    where pload_src etc. are named lists keyed by Parmnames (no eval/parse).

    Internal helpers (sub-functions within predict_core.R or standalone internal files):
      .compute_decay(data, data.index.list, beta1) → list(rchdcayf, resdcayf)
      .compute_delivery(data, data.index.list, beta1, dlvdsgn) → list(ddliv2, ddliv3, dddliv)
      .accumulate_loads(data, data.index.list, incddsrc, incddsrc_nd, carryf, carryf_nd,
        nreach, fortran_fn) → list(pload_total, mpload_total, pload_nd_total)
      .assemble_source_loads(data.index.list, Parmnames, data, beta1, ddliv2, fortran_fn)
        → list(pload_src, mpload_src, pload_nd_src, pload_inc_src)

    Use @keywords internal @noRd on each function.
    Add predict_core.R to DESCRIPTION Collate in alphabetical position.
  </step>

  <step n="2" label="Refactor predict.R to use predict_core">
    predict_sparrow() retains its existing 7-arg signature (no breaking change to API).
    Replace the decay/delivery/accumulation/source-load blocks with calls to predict_core helpers.
    Replace all assign/srclist/eval(parse) patterns with named list access.
    The output assembly (predmatrix, colnames, predict.list) stays in predict.R.
    Verify output is identical to current behavior on UserTutorial data.
    Target: ~200 lines (down from 574).
  </step>

  <step n="3" label="Refactor predictBoot.R to use predict_core">
    predictBoot() retains its existing signature.
    Replace shared blocks with predict_core calls.
    Replace assign/srclist/eval(parse) patterns (6 occurrences) with named list access.
    The predmatrix assembly differs (no predict.list, scalar bootcorrectionR) — keep that logic.
    Target: ~150 lines (down from 475).
  </step>

  <step n="4" label="Refactor predictScenarios.R shared blocks">
    predictScenarios() is 842 lines and includes scenario source modification, embedded
    prediction, Shiny coupling, and CSV output.
    In this step: replace only the shared decay/delivery/accumulation blocks with predict_core
    calls and fix the 5–6 eval(parse()) calls for source variables (assign/srclist pattern).
    Do NOT refactor the Shiny coupling or scenario modification logic (deferred to Plan 05C/05D).
    Target for this step: reduce from 842 to ~650 lines; 0 eval(parse()) in source-load section.
  </step>

  <step n="5" label="Merge estimateFeval.R and estimateFevalNoadj.R">
    Merge estimateFevalNoadj.R into estimateFeval.R.
    Add parameter: ifadjust = 1L (default, conditioned behavior).
    When ifadjust == 0L: use unconditioned weight path (current estimateFevalNoadj behavior).
    Add a one-line wrapper at file bottom (or in estimate.R caller):
      estimateFevalNoadj &lt;- function(...) estimateFeval(..., ifadjust = 0L)
    This preserves backward compatibility if controlFileTasksModel.R passes the function
    by name. Alternatively, update all callers to pass ifadjust=0L explicitly.
    Delete estimateFevalNoadj.R and remove from DESCRIPTION Collate.
    Target: estimateFeval.R grows from 147 to ~175 lines; estimateFevalNoadj.R deleted.
  </step>

  <step n="6" label="Update DESCRIPTION Collate">
    Add predict_core.R in alphabetical position.
    Remove estimateFevalNoadj.R.
  </step>

  <step n="7" label="Verify">
    Run R CMD build succeeds.
    Run existing testthat tests (peripheral only, but confirms no crashes).
    Manually verify on UserTutorial: rsparrow_model() → predict() produces same predict.list
    structure as before (check column names, row count, numeric spot checks).
    Confirm eval(parse()) count in predict.R, predictBoot.R, predictScenarios.R = 0
    for source-load patterns.
    grep -n "eval(parse\|assign(paste0" RSPARROW_master/R/predict.R  # expect 0
    grep -n "eval(parse\|assign(paste0" RSPARROW_master/R/predictBoot.R  # expect 0
    grep -n "eval(parse" RSPARROW_master/R/predictScenarios.R  # expect only scenario-mod patterns
  </step>
</implementation_steps>

<success_criteria>
  <criterion>predict_core.R exists with shared kernel; predict.R/predictBoot.R/predictScenarios.R import it</criterion>
  <criterion>0 assign(paste0("pload_"...))/eval(parse(srclist[...])) patterns in predict.R and predictBoot.R</criterion>
  <criterion>0 such patterns in the load-accumulation section of predictScenarios.R</criterion>
  <criterion>estimateFevalNoadj.R deleted; estimateFeval.R has ifadjust parameter</criterion>
  <criterion>R CMD build succeeds</criterion>
  <criterion>predict.list structure (column names, row count) unchanged for UserTutorial model run</criterion>
  <criterion>Total lines across the three predict files: &lt; 1000 (down from ~1891)</criterion>
</success_criteria>

<failure_criteria>
  <criterion>predict.list column names differ from pre-refactor — indicates source variable naming broke</criterion>
  <criterion>estimateBootstraps produces different bootstrap results — indicates predictBoot refactor error</criterion>
  <criterion>R CMD build error mentioning predict_core.R — check Collate order</criterion>
  <criterion>Any remaining eval(parse) in predict.R or predictBoot.R source-load blocks</criterion>
</failure_criteria>

<risks>
  <risk level="medium">
    predictScenarios.R modifies source inputs BEFORE the prediction kernel runs (changing
    the data column values for scenario_sources). predict_core must receive the already-modified
    data matrix, not the original. Verify the call order is: modify sources → call predict_core.
  </risk>
  <risk level="medium">
    bootcorrection handling differs: predict.R takes a vector (element-wise multiply),
    predictBoot.R takes a scalar (bootcorrectionR). predict_core should NOT apply bootcorrection
    internally — leave it to each caller to apply post-hoc.
  </risk>
  <risk level="low">
    estimateFevalNoadj is passed as a function argument (fn.func parameter) in estimateOptimize.R.
    If the wrapper approach is used, the wrapper name must match what controlFileTasksModel.R
    or estimate.R passes. Verify with:
    grep -n "estimateFevalNoadj\|fn.func" RSPARROW_master/R/estimateOptimize.R
    grep -n "estimateFevalNoadj" RSPARROW_master/R/estimate.R RSPARROW_master/R/controlFileTasksModel.R
  </risk>
  <risk level="low">
    validateFevalNoadj.R (MERGE classification) is a third Feval variant. It was partially
    cleaned in Plan 04B and 04C. Consider whether to merge it into estimateFeval.R in this step
    or defer to Plan 05C. If deferred, note the dependency.
  </risk>
</risks>

<notes>
  - Do not refactor the Shiny/input$ coupling in predictScenarios.R in this step; that requires
    understanding Rshiny=FALSE vs TRUE dispatch. Defer to Plan 05C.
  - predictBootstraps.R is the outer loop calling predictBoot; it stays as-is (it is KEEP).
  - The named-list pattern (pload_src[[name]]) is semantically identical to the old
    assign/eval pattern but is safe, testable, and R-idiomatic.
</notes>

</plan>
