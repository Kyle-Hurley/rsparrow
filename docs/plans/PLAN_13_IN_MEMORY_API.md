<plan id="13" label="In-Memory API — Eliminate CSV File Dependency" status="pending" blocked_by="12">

<objective>
Replace rsparrow_model(path_main, run_id) with an in-memory API that accepts four data frames
directly. Users no longer write CSV files to disk. The sparrow_example dataset provides the
reference inputs. The current CSV-based entry point (read_sparrow_data) is archived. File
output becomes purely opt-in via write_rsparrow_results() as established in Plan 10.
</objective>

<context>
As of Plan 12, rsparrow_model() still requires a directory containing four CSV files
(parameters.csv, design_matrix.csv, dataDictionary.csv, and the main reach data file).
This forces users to serialise their data frames to disk, invent file paths, and manage a
directory — purely as boilerplate to call one function. The sparrow_example dataset already
carries all four data frames as R objects; Plan 13 makes that the primary interface.

Secondary motivation: applyUserModify.R reads and eval(parse())s a user-supplied R script
from disk (the if_userModifyData pathway). Once the API accepts data frames directly, the
appropriate place to modify data is before calling rsparrow_model(), so applyUserModify.R
becomes obsolete and can be archived along with the CSV readers.

A further motivation is test simplicity: every test that currently writes CSVs to tempdir()
just to call rsparrow_model() can be rewritten as a straightforward function call.
</context>

<gh_issues>New issue to open: "Plan 13: in-memory API for rsparrow_model()"</gh_issues>

<reference_documents>
  R/rsparrow_model.R — main entry point (~490 lines); has <<- removed in Plan 10
  R/read_sparrow_data.R — exported CSV reader (to be archived)
  R/startModelRun.R — data prep; calls applyUserModify() via if_userModifyData
  R/controlFileTasksModel.R — master task dispatcher; reads file.output.list
  R/readData.R, R/readParameters.R, R/readDesignMatrix.R, R/read_dataDictionary.R — CSV readers
  R/applyUserModify.R — eval(parse()) user script; to be archived
  data/sparrow_example.rda — reference in-memory inputs
  vignettes/RSPARROW_vignette.Rmd — to be updated; remove "Set Up a Model Directory" section
  docs/api/API_REFERENCE.md — new signature to document
  docs/api/EXPORTS_SPECIFICATION.md — remove read_sparrow_data
  docs/reference/ARCHITECTURE.md — new data-flow diagram
</reference_documents>

<new_api>

New signature for rsparrow_model():

```r
rsparrow_model(
  reaches,            # data.frame: reach network with topology + attributes
  parameters,         # data.frame: sparrowNames, parmInit, parmMin, parmMax, parmType, ...
  design_matrix,      # data.frame: SOURCE rows × DELIVF cols, binary (0/1) matrix
  data_dictionary,    # data.frame: varType, sparrowNames, data1UserNames, varunits
  run_id    = "run1",
  output_dir = NULL,  # NULL = pure in-memory; path → write CSV/plot output files
  if_estimate  = TRUE,
  if_predict   = TRUE,
  if_validate  = FALSE
)
```

All four data frames correspond directly to the four elements of sparrow_example:
  sparrow_example$reaches, $parameters, $design_matrix, $data_dictionary

Backward compatibility: the old path_main/run_id signature is NOT preserved. The new
API is a clean break. Users on the old API should write their CSVs and read them into
data frames before calling rsparrow_model().

The exported read_sparrow_data() function is archived (no longer needed in the new API).
</new_api>

<tasks>

<task id="13-1" status="pending">
<subject>Add internal prep_sparrow_inputs() helper to rsparrow_model.R</subject>
<description>
Create a non-exported helper function prep_sparrow_inputs() that:
  1. Validates all four data frames (required columns present, correct types, no NA in keys).
  2. Converts the logical if_estimate/if_predict/if_validate arguments to "yes"/"no" strings
     expected by internal functions (or update internal functions to accept logicals — prefer
     the latter; change is mechanical and covered in a single grep).
  3. Constructs the file.output.list: when output_dir = NULL, set every write-path slot to
     NULL and set every "if_write_*" flag to FALSE. When output_dir is a path, create the
     directory and populate paths as before.
  4. Reshapes the four data frames into the internal list structure that was previously
     assembled by read_sparrow_data() → readData() + readParameters() + readDesignMatrix()
     + read_dataDictionary().

This replaces the readData/readParameters/readDesignMatrix/read_dataDictionary call chain
at the top of rsparrow_model() without requiring changes to any downstream internal function.

Key column requirements for validation (document these in man/rsparrow_model.Rd):
  reaches: waterid (integer), fnode (integer), tnode (integer), hydseq (numeric or integer),
            demtarea (numeric), demiarea (numeric), rchlen (numeric), rchname (character, optional)
  parameters: sparrowNames, parmInit, parmMin, parmMax, parmType (character)
  design_matrix: row names = source parameter names; column names = delivery parameter names;
                 values 0 or 1
  data_dictionary: varType, sparrowNames, data1UserNames, varunits
</description>
<files_modified>
  EDIT: R/rsparrow_model.R — replace readData/readParameters chain with prep_sparrow_inputs()
</files_modified>
<success_criteria>
  - prep_sparrow_inputs() passes sparrow_example through without error
  - rsparrow_model(sparrow_example$reaches, sparrow_example$parameters,
      sparrow_example$design_matrix, sparrow_example$data_dictionary) works end-to-end
  - output_dir = NULL produces no file I/O side effects
</success_criteria>
</task>

<task id="13-2" status="pending">
<subject>Remove if_userModifyData pathway and applyUserModify() call from startModelRun.R</subject>
<description>
In startModelRun.R, locate the if_userModifyData block (around line 152 per CLAUDE.md).
Remove the entire conditional and the applyUserModify() call. The rationale: the
appropriate place to modify input data is before calling rsparrow_model() — the user has
the data frames in memory and can apply any transformation they wish.

If if_userModifyData is also referenced in controlFileTasksModel.R or elsewhere, remove
those references as well. Do a project-wide grep for "if_userModifyData" and
"applyUserModify" to confirm all call sites.

Do NOT change the function signature of startModelRun() yet — that refactoring belongs in
Plan 16. Only remove the dead code block.
</description>
<files_modified>
  EDIT: R/startModelRun.R — remove if_userModifyData block and applyUserModify() call
  EDIT: R/controlFileTasksModel.R — remove if_userModifyData references (if any)
</files_modified>
<success_criteria>
  - grep -r "if_userModifyData" R/ returns 0 results
  - grep -r "applyUserModify" R/ returns 0 results
  - R CMD check shows no regression in WARNING/ERROR count
</success_criteria>
</task>

<task id="13-3" status="pending">
<subject>Archive obsolete CSV-reading and user-modify R files</subject>
<description>
Move the following files from R/ to inst/archived/legacy_data_import/ (already exists from
Plan 09):

  readData.R
  readParameters.R
  readDesignMatrix.R
  read_dataDictionary.R
  applyUserModify.R

Move the exported function file:
  read_sparrow_data.R → inst/archived/legacy_api/read_sparrow_data.R  (create new subdirectory)

Create inst/archived/legacy_api/ directory for archived exported functions.

For each archived file, add a one-line comment at the top:
  # Archived in Plan 13: replaced by in-memory API (rsparrow_model() data-frame arguments)

Remove the @export tag from read_sparrow_data.R before archiving (it is no longer exported).
Update NAMESPACE: remove the export(read_sparrow_data) line.
Update DESCRIPTION: remove read_sparrow_data from any @importFrom or Exports mention.

After archiving, verify R CMD check passes and the exported function count drops from
14 to 13 (write_rsparrow_results and rsparrow_hydseq remain; read_sparrow_data is removed).
</description>
<files_modified>
  MOVE: R/readData.R → inst/archived/legacy_data_import/readData.R
  MOVE: R/readParameters.R → inst/archived/legacy_data_import/readParameters.R
  MOVE: R/readDesignMatrix.R → inst/archived/legacy_data_import/readDesignMatrix.R
  MOVE: R/read_dataDictionary.R → inst/archived/legacy_data_import/read_dataDictionary.R
  MOVE: R/applyUserModify.R → inst/archived/legacy_data_import/applyUserModify.R
  MOVE: R/read_sparrow_data.R → inst/archived/legacy_api/read_sparrow_data.R
  EDIT: NAMESPACE — remove export(read_sparrow_data)
  DELETE: man/read_sparrow_data.Rd
</files_modified>
<success_criteria>
  - R CMD check 0 ERRORs, no increase in WARNINGs vs Plan 12 baseline
  - library(rsparrow); ls(getNamespace("rsparrow")) does not list read_sparrow_data
  - inst/archived/legacy_api/ directory created and committed
</success_criteria>
</task>

<task id="13-4" status="pending">
<subject>Update vignette to remove "Set Up a Model Directory" section</subject>
<description>
Rewrite the relevant sections of vignettes/RSPARROW_vignette.Rmd:

REMOVE:
  - Any section explaining how to create a model directory
  - Any code that writes CSVs to tempdir()
  - Any reference to read_sparrow_data() or path_main

KEEP AND SIMPLIFY:
  ## Step 1: Load the Example Data
  ```{r}
  library(rsparrow)
  # sparrow_example is available with LazyData: true
  str(sparrow_example, max.level = 1)
  ```

  ## Step 2: Inspect the Network Topology
  ```{r}
  network <- rsparrow_hydseq(sparrow_example$reaches)
  head(network[, c("waterid", "fnode", "tnode", "hydseq")])
  ```

  ## Step 3: Fit the Model
  ```{r, eval = FALSE}
  model <- rsparrow_model(
    sparrow_example$reaches,
    sparrow_example$parameters,
    sparrow_example$design_matrix,
    sparrow_example$data_dictionary
  )
  ```

  ## Step 4: Examine Results
  ```{r, eval = FALSE}
  print(model)
  coef(model)
  ```

The vignette should build in under 30 seconds (eval=FALSE for estimation chunks).

Pre-build the vignette and commit the HTML output to inst/doc/ to support
--no-build-vignettes builds on CRAN.
</description>
<files_modified>
  EDIT: vignettes/RSPARROW_vignette.Rmd
  EDIT: inst/doc/RSPARROW_vignette.html (pre-built)
  EDIT: inst/doc/RSPARROW_vignette.R (pre-built tangled R)
</files_modified>
<success_criteria>
  - Vignette builds without error: R CMD build . (without --no-build-vignettes)
  - No reference to read_sparrow_data, path_main, or CSV directory setup
  - All three steps (hydseq, model, results) are present and syntactically correct
</success_criteria>
</task>

<task id="13-5" status="pending">
<subject>Update @examples in all exported functions for new signature</subject>
<description>
rsparrow_model() @examples currently show:
  \donttest{
    td <- tempdir()
    # ... write CSVs ...
    model <- rsparrow_model(td, "example_run")
  }

Replace with:
  \donttest{
    model <- rsparrow_model(
      sparrow_example$reaches,
      sparrow_example$parameters,
      sparrow_example$design_matrix,
      sparrow_example$data_dictionary
    )
    coef(model)
  }

All other exported functions that depend on a fitted model object can use the same
\donttest{} block to construct it. Functions that have their own fast example
(rsparrow_hydseq) are unchanged.

Remove any @examples that reference read_sparrow_data() or path_main.

After updating @examples, rebuild documentation with roxygen2 (or manually update
the Rd files) and verify with R CMD check --no-manual.
</description>
<files_modified>
  EDIT: R/rsparrow_model.R (@examples block)
  EDIT: man/rsparrow_model.Rd (updated Rd)
  EDIT: Any other man/*.Rd that reference read_sparrow_data or path_main
</files_modified>
<success_criteria>
  - R CMD check --no-manual: 0 example errors
  - No @examples reference read_sparrow_data, path_main, or CSV file setup
</success_criteria>
</task>

<task id="13-6" status="pending">
<subject>Update API and architecture documentation</subject>
<description>
Update the following docs to reflect the new in-memory API:

docs/api/API_REFERENCE.md:
  - Update rsparrow_model() signature section with new four data-frame parameters
  - Remove read_sparrow_data() entry
  - Update output_dir description (NULL = in-memory, path = file output)

docs/api/EXPORTS_SPECIFICATION.md:
  - Remove read_sparrow_data from the exports table
  - Update rsparrow_model entry with new parameter list

docs/reference/ARCHITECTURE.md:
  - Update the "API flow" section: rsparrow_model(reaches, parameters, design_matrix,
    data_dictionary) -> prep_sparrow_inputs() -> startModelRun() -> ...
  - Remove the read_sparrow_data() node from the data flow description

docs/plans/CRAN_ROADMAP.md:
  - Add Plan 13 to <upcoming_plans> (or <completed_plans> if done)
  - Update exported function count: 14 → 13 (read_sparrow_data removed)
</description>
<files_modified>
  EDIT: docs/api/API_REFERENCE.md
  EDIT: docs/api/EXPORTS_SPECIFICATION.md
  EDIT: docs/reference/ARCHITECTURE.md
  EDIT: docs/plans/CRAN_ROADMAP.md
</files_modified>
<success_criteria>
  - API_REFERENCE.md shows new rsparrow_model() signature accurately
  - EXPORTS_SPECIFICATION.md does not list read_sparrow_data
  - ARCHITECTURE.md data-flow matches actual code
</success_criteria>
</task>

<task id="13-7" status="pending">
<subject>Run R CMD check and update MEMORY.md</subject>
<description>
Final verification:

  source scripts/renv.sh
  R CMD build --no-build-vignettes .
  R_LIBS=/home/kp/R/libs _R_CHECK_FORCE_SUGGESTS_=false \
    R CMD check --no-manual rsparrow_2.1.0.tar.gz

Expected: 0 ERRORs, 0 WARNINGs, ≤ 2 NOTEs (same as Plan 12 baseline).

Run full test suite:
  R_LIBS=/home/kp/R/libs R CMD INSTALL --no-multiarch .
  R_LIBS=/home/kp/R/libs Rscript -e "testthat::test_package('rsparrow')"

Update tests that previously wrote CSVs to tempdir() — replace with direct data-frame calls.
Update MEMORY.md: exported function count, archived file list, API description.
</description>
<files_modified>
  EDIT: tests/testthat/*.R — any tests using read_sparrow_data or path_main patterns
  EDIT: memory/MEMORY.md
</files_modified>
<success_criteria>
  - R CMD check: 0 ERRORs, 0 WARNINGs
  - All tests pass (count may decrease if CSV-writing tests are simplified)
  - MEMORY.md reflects 13 exported functions and new API signature
</success_criteria>
</task>

</tasks>

<success_criteria>
<criterion>rsparrow_model(reaches, parameters, design_matrix, data_dictionary) runs end-to-end with sparrow_example</criterion>
<criterion>output_dir = NULL produces no file system writes</criterion>
<criterion>read_sparrow_data removed from NAMESPACE and man/</criterion>
<criterion>applyUserModify, readData, readParameters, readDesignMatrix, read_dataDictionary archived to inst/archived/</criterion>
<criterion>Vignette has no CSV setup section</criterion>
<criterion>R CMD check: 0 ERRORs, 0 WARNINGs, ≤ 2 NOTEs</criterion>
<criterion>All tests pass</criterion>
</success_criteria>

<failure_criteria>
<criterion>Any internal function cannot be reached without file.output.list path fields</criterion>
<criterion>sparrow_example fails validation in prep_sparrow_inputs() due to missing required columns</criterion>
<criterion>R CMD check introduces any new WARNING vs Plan 12 baseline</criterion>
</failure_criteria>

<risks>
<risk level="high">
  Many internal functions thread file.output.list deeply and use its path fields to decide
  whether to write files. When output_dir = NULL, all those path fields must be NULL and
  all "if_write_*" checks must handle NULL gracefully. This requires careful auditing of
  every conditional that tests file.output.list fields.
  Mitigation: set file.output.list$output_dir = NULL and add a single is.null() guard at each
  write site (predictOutCSV, etc.) — Plan 10 already added most of these guards.
</risk>
<risk level="medium">
  prep_sparrow_inputs() must reproduce the exact internal data structure previously built by
  the readData/readParameters chain, including all derived fields. If any derived field is
  missing, downstream functions will fail with cryptic errors.
  Mitigation: read readData.R, readParameters.R, readDesignMatrix.R, read_dataDictionary.R
  carefully before writing prep_sparrow_inputs(). Unit-test with sparrow_example.
</risk>
<risk level="low">
  Tests that currently use read_sparrow_data() or write CSVs will need updating.
  Mitigation: straightforward substitution — replace CSV-writing boilerplate with direct
  data-frame arguments.
</risk>
</risks>

<notes>
- Execution order within this plan: 13-1 (helper) → 13-2 (remove applyUserModify) →
  13-3 (archive files) → 13-4 (vignette) → 13-5 (examples) → 13-6 (docs) → 13-7 (check)
- Plan 14 (dependency reduction) should follow Plan 13 because Plan 13 archives the CSV
  readers that use data.table::fread; Plan 14 then handles the remaining fwrite calls.
- The if_estimate/if_predict/if_validate arguments: currently they are "yes"/"no" strings
  internally. Prefer converting to logical at the rsparrow_model() boundary and keeping
  internal strings unchanged (less churn). Document the conversion in prep_sparrow_inputs().
- After Plan 13, the exported API is: rsparrow_model, write_rsparrow_results, rsparrow_hydseq,
  print/summary/coef/residuals/vcov/plot/predict.rsparrow, rsparrow_bootstrap,
  rsparrow_scenario, rsparrow_validate (13 total; read_sparrow_data removed).
</notes>

</plan>
