<plan id="06" label="Test Suite Creation" status="in_progress">

<overview>
Plan 06 builds the test suite required for CRAN submission. The package currently has 16 test
files: 7 test deleted makeReport_* functions (dead after Plan 05D) and 9 cover peripheral
utilities. Zero coverage exists on the mathematical core (estimateFeval, predict_sparrow,
deliver, hydseq, Fortran wrappers). Plan 06 is decomposed into six sequential sub-plans that
build from infrastructure through unit tests to integration tests.

CRAN requirements addressed:
  - testthat (>= 3.0.0) in DESCRIPTION Suggests + Config/testthat/edition: 3
  - All tests complete within 10-minute CRAN time limit
  - Tests pass on macOS, Linux, and Windows
  - No tests require real UserTutorial files (use synthetic fixtures)

Primary reference documents:
  docs/reference/TESTING_STRATEGY.md
  docs/reference/DATA_STRUCTURES.md
  docs/reference/FUNCTION_INVENTORY.md
  docs/implementation/PLAN_06_SYNTHETIC_DATASET.md (spec for test fixtures)
</overview>

<sub_plans>

<sub_plan id="06A" file="PLAN_06A_TEST_INFRASTRUCTURE.md" status="complete">
Test Infrastructure Setup — upgrades DESCRIPTION, removes broken tests, creates synthetic
network fixture and shared helper utilities. Must complete before all other sub-plans.
Completed 2026-02-23: 23 tests pass, 0 fail. testthat edition 3 active.
</sub_plan>

<sub_plan id="06B" file="PLAN_06B_NETWORK_TESTS.md" status="pending" blocked_by="06A">
Network Topology Tests — unit tests for hydseq, rsparrow_hydseq (exported), calcHeadflag,
calcTermflag, accumulateIncrArea. Uses mini_network fixture from 06A.
Estimated test runtime: &lt;5 seconds.
</sub_plan>

<sub_plan id="06C" file="PLAN_06C_FORTRAN_TESTS.md" status="pending" blocked_by="06A">
Fortran Interface Tests — unit tests for deliver(), and the tnoder/ptnoder/deliv_fraction
Fortran subroutines exercised via estimateFeval and predict_sparrow stubs with minimal
inputs. Requires compiled package.
Estimated test runtime: &lt;5 seconds.
</sub_plan>

<sub_plan id="06D" file="PLAN_06D_ESTIMATION_TESTS.md" status="pending" blocked_by="06C">
Estimation Core Tests — unit tests for estimateFeval (ifadjust=1 and 0), estimateWeightedErrors,
setNLLSWeights. A short-run estimateOptimize test verifying convergence structure.
Estimated test runtime: &lt;30 seconds.
</sub_plan>

<sub_plan id="06E" file="PLAN_06E_PREDICTION_TESTS.md" status="pending" blocked_by="06C">
Prediction Tests — unit tests for predict_sparrow and predict_core with pre-built estimate.list
fixtures; verify output list structure, matrix dimensions, and numeric values within tolerance.
Estimated test runtime: &lt;10 seconds.
</sub_plan>

<sub_plan id="06F" file="PLAN_06F_API_TESTS.md" status="pending" blocked_by="06A">
Exported API Tests — tests for all 13 exported functions: rsparrow_hydseq, read_sparrow_data,
and all S3 methods (print/summary/coef/residuals/vcov/plot.rsparrow). Uses mock rsparrow
objects and temp directories. Does NOT require a compiled model run.
Estimated test runtime: &lt;10 seconds.
</sub_plan>

</sub_plans>

<dependency_graph>
06A (infrastructure) ──→ 06B (network)
                    ├──→ 06C (fortran) ──→ 06D (estimation)
                    │                  └──→ 06E (prediction)
                    └──→ 06F (api)
</dependency_graph>

<cran_checklist_items_addressed>
  - testthat (>= 3.0.0) in Suggests + Config/testthat/edition: 3 → Plan 06A
  - All tests pass in R CMD check → Plans 06A through 06F
  - Total test time &lt; 10 minutes → each sub-plan estimates &lt;1 minute
  - Integration test with UserTutorial data → deferred (skip_on_cran, no fixture needed for CRAN)
</cran_checklist_items_addressed>

<out_of_scope>
  - Integration test running rsparrow_model() end-to-end (needs UserTutorial data, slow — skip_on_cran
    wrapper can be added post-submission)
  - >80% coverage target (initial submission needs core coverage; additional tests are Plan 07)
  - Second vignette on scenarios and bootstrapping (separate deliverable)
  - Decomposing monolithic functions (estimate.R 889 lines — separate refactoring task)
</out_of_scope>

</plan>
