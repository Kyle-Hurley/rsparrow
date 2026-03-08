<plan id="12" label="Example Dataset, Vignette, and Final Polish" status="pending" blocked_by="07,08,09,10,11">

<objective>
Create a bundled example dataset in data/, write an introductory vignette demonstrating the
full rsparrow workflow, update @examples across all 13 exported functions to use the bundled
data, and pass R CMD check --as-cran with 0 ERRORs and 0 WARNINGs. This plan completes
CRAN preparation.
</objective>

<context>
After Plans 07–11, the package has clean code and 0 R CMD check WARNINGs. The remaining
blockers to CRAN submission are:
  - No example dataset in data/ (GH #9) — @examples cannot be runnable without it
  - No current vignette demonstrating the refactored API (GH #8) — the existing vignette
    references the old control-script workflow
  - DESCRIPTION URL/BugReports fields may be stale

The example dataset must be small enough (~50–100 reaches) for @examples to run quickly
during R CMD check. The CRAN check timeout is 10 minutes for all examples + tests combined.
The vignette should demonstrate the full workflow using the example dataset but with heavy
use of \donttest{} or pre-computed results for the time-consuming estimation step.
</context>

<gh_issues>GH #8, #9</gh_issues>

<reference_documents>
  docs/plans/CRAN_ROADMAP.md — testing_and_examples, vignettes_and_tutorials
  tests/testthat/fixtures/mini_network.rda — 7-reach synthetic network (Plan 06A)
  tests/testthat/fixtures/mini_model_inputs.rda — synthetic inputs (Plan 06A)
  R/rsparrow_model.R — main entry point; @examples needs update
  R/read_sparrow_data.R — data reader; @examples needs update
  vignettes/ — existing vignette to be rewritten
  UserTutorial/ — potential source for example data subset
</reference_documents>

<tasks>

<task id="12-1" status="pending">
<subject>Design and create the sparrow_example dataset</subject>
<description>
Create a synthetic or UserTutorial-derived example dataset with 50–100 reaches for use
in @examples and the vignette. The dataset must:
  - Be small enough for examples to run in under 30 seconds total
  - Represent a realistic SPARROW network topology (Y-shaped or linear tributary network)
  - Include the minimum required columns for rsparrow_model() to run:
    waterid, fnode, tnode, hydseq, rchname (or equivalent), plus at least one source
    variable and one land-to-water delivery variable
  - Be entirely synthetic (no real monitoring data to avoid data-sharing concerns)
    OR be a clearly documented subset of the publicly available UserTutorial data

Derivation options (choose one):
  Option A — Extend the 7-reach mini_network from Plan 06A to ~50 reaches with
             synthetic but physically plausible attribute values. This is the
             cleanest approach: fully synthetic, no external dependencies.
  Option B — Extract a 50–100 reach subset from UserTutorial/ with documented
             provenance. This has realistic magnitudes but requires the user tutorial
             data to be available during package development (not at runtime).

Recommended: Option A (fully synthetic).

Create R/data.R with roxygen2 documentation:

  #' Example SPARROW watershed network
  #'
  #' A synthetic 60-reach watershed network for demonstrating the rsparrow package.
  #' The network represents a Y-shaped river system with two tributary branches
  #' draining to a single outlet reach.
  #'
  #' @format A list with the following elements:
  #'   \describe{
  #'     \item{reaches}{data.frame with 60 rows and [N] columns of reach attributes}
  #'     \item{sites}{data.frame with [M] rows of monitoring site data}
  #'     \item{parameters}{data.frame of parameter specifications}
  #'     \item{design_matrix}{matrix defining source-delivery parameter associations}
  #'     \item{data_dictionary}{data.frame mapping sparrowNames to data column names}
  #'   }
  #' @source Synthetic data generated for package demonstration purposes.
  "sparrow_example"

Save the dataset object:
  usethis::use_data(sparrow_example, overwrite = TRUE)
  # OR: save(sparrow_example, file = "data/sparrow_example.rda", compress = "xz")

Verify the dataset loads:
  data(sparrow_example, package = "rsparrow")
  str(sparrow_example)
</description>
<files_modified>
  CREATE: R/data.R (dataset documentation)
  CREATE: data/sparrow_example.rda
</files_modified>
<success_criteria>
  - data/sparrow_example.rda loads cleanly: data(sparrow_example, package="rsparrow")
  - Dataset is ≤ 1 MB compressed
  - roxygen2 documentation in R/data.R passes R CMD check (no missing @format fields)
  - 60 reaches with sufficient columns for rsparrow_hydseq() to run
</success_criteria>
</task>

<task id="12-2" status="pending">
<subject>Verify the example dataset runs through the full rsparrow workflow</subject>
<description>
Before updating @examples and writing the vignette, confirm the example dataset actually
works end-to-end through the rsparrow workflow.

Test script (run interactively, not as a package test):

  library(rsparrow)
  data(sparrow_example)

  # Step 1: Hydseq
  network_ordered <- rsparrow_hydseq(sparrow_example$reaches)

  # Step 2: Read data (if read_sparrow_data() accepts in-memory objects)
  # OR: Write the example data to tempdir() as CSVs and call read_sparrow_data()
  td <- tempdir()
  # write CSVs...
  sparrow_data <- read_sparrow_data(path_main = td, run_id = "example")

  # Step 3: Estimate (wrap in \donttest for vignette/examples)
  model <- rsparrow_model(path_main = td, run_id = "example",
                          if_estimate = TRUE, if_predict = TRUE)

  # Step 4: Inspect results
  print(model)
  coef(model)
  residuals(model)

  # Step 5: Predict
  preds <- predict(model)

If rsparrow_model() requires CSV control files (parameters.csv, design_matrix.csv,
dataDictionary.csv), write helper functions or documented instructions for creating them
from sparrow_example. This establishes the exact workflow that the vignette will show.

Document any adjustments needed to the example dataset structure based on what rsparrow_model()
actually requires.
</description>
<files_modified>None — interactive verification only</files_modified>
<success_criteria>
  - Full workflow completes without error using sparrow_example
  - rsparrow_hydseq(), read_sparrow_data(), rsparrow_model(), predict() all work
  - Workflow can be reproduced in under 60 seconds on a typical machine
</success_criteria>
</task>

<task id="12-3" status="pending">
<subject>Update @examples in all 13 exported functions</subject>
<description>
Replace or supplement existing @examples in all 13 exported functions with runnable code
using sparrow_example. Current @examples use \dontrun{} placeholders or UserTutorial paths.

Rules:
  - Fast examples (< 5 seconds): run as-is (no \dontrun{} or \donttest{})
  - Slow examples (estimation, prediction, bootstrap): wrap in \donttest{}
  - Examples that require file paths: use tempdir() and write the example data there
  - All @examples must be syntactically valid and pass R CMD check --as-cran example checks

Exported functions and example approach:

rsparrow_hydseq() — FAST: takes a data.frame; use sparrow_example$reaches
  data(sparrow_example); rsparrow_hydseq(sparrow_example$reaches)

read_sparrow_data() — MEDIUM: reads CSVs; write example CSVs to tempdir()
  \donttest{} around the file-writing + read steps

rsparrow_model() — SLOW: full estimation; wrap in \donttest{}
  \donttest{ td <- tempdir(); ... model <- rsparrow_model(td, "example") }

print.rsparrow() — FAST: needs a model object; use pre-built mock or \donttest{}
  \donttest{ ... print(model) }

summary.rsparrow() — same as print

coef.rsparrow() — FAST with mock; \donttest{} with real model

residuals.rsparrow() — FAST with mock

vcov.rsparrow() — FAST with mock

plot.rsparrow() — MEDIUM: requires graphics device; \donttest{}

predict.rsparrow() — SLOW: requires fitted model; \donttest{}

rsparrow_bootstrap() — SLOW: many iterations; \donttest{}

rsparrow_scenario() — SLOW: requires fitted model + scenario spec; \donttest{}

rsparrow_validate() — SLOW: requires fitted model with validation sites; \donttest{}

After updating all @examples, rebuild documentation and run example checks:
  R_LIBS=/home/kp/R/libs Rscript -e "roxygen2::roxygenise('.')"
  R CMD build --no-build-vignettes .
  R_LIBS=/home/kp/R/libs _R_CHECK_FORCE_SUGGESTS_=false \
    R CMD check rsparrow_2.1.0.tar.gz
  # Look specifically for: "Error in example(...)" in the check output
</description>
<files_modified>
  EDIT: R/rsparrow_hydseq.R (update @examples)
  EDIT: R/read_sparrow_data.R (update @examples)
  EDIT: R/rsparrow_model.R (update @examples)
  EDIT: R/print.rsparrow.R (update @examples)
  EDIT: R/summary.rsparrow.R (update @examples)
  EDIT: R/coef.rsparrow.R (update @examples)
  EDIT: R/residuals.rsparrow.R (update @examples)
  EDIT: R/vcov.rsparrow.R (update @examples)
  EDIT: R/plot.rsparrow.R (update @examples)
  EDIT: R/predict.rsparrow.R (update @examples)
  EDIT: R/rsparrow_bootstrap.R (update @examples)
  EDIT: R/rsparrow_scenario.R (update @examples)
  EDIT: R/rsparrow_validate.R (update @examples)
  EDIT: man/*.Rd (regenerated by roxygen2)
</files_modified>
<success_criteria>
  - All 13 exported functions have @examples that pass R CMD check
  - No "Error in example" output in R CMD check
  - rsparrow_hydseq() example runs without \donttest{}
  - Slow examples correctly wrapped in \donttest{}
</success_criteria>
</task>

<task id="12-4" status="pending">
<subject>Write introductory vignette — "Introduction to rsparrow"</subject>
<description>
Create vignettes/introduction.Rmd demonstrating the full rsparrow workflow using sparrow_example.
The existing vignette (if any) references the old control-script workflow and must be rewritten.

Vignette structure:

  ---
  title: "Introduction to rsparrow"
  output: rmarkdown::html_vignette
  vignette: >
    %\VignetteIndexEntry{Introduction to rsparrow}
    %\VignetteEngine{knitr::rmarkdown}
    %\VignetteEncoding{UTF-8}
  ---

  ## Overview
  Brief description of SPARROW methodology (1 paragraph).
  Reference: SPARROW models three watershed processes: source generation, land-to-water
  delivery, and in-stream/reservoir transport and decay.

  ## Installation
  install.packages("rsparrow")

  ## The Example Dataset
  Describe sparrow_example: 60-reach synthetic network, structure, what each element contains.

  ## Step 1: Examine the Network Topology
  ```{r}
  library(rsparrow)
  data(sparrow_example)
  network <- rsparrow_hydseq(sparrow_example$reaches)
  head(network[, c("waterid", "fnode", "tnode", "hydseq")])
  ```

  ## Step 2: Read Model Data
  ```{r, eval=FALSE}
  # Write example data to a temporary directory
  td <- file.path(tempdir(), "sparrow_run")
  dir.create(td, showWarnings = FALSE)
  # [code to write CSVs from sparrow_example]
  sparrow_data <- read_sparrow_data(path_main = td, run_id = "example")
  ```

  ## Step 3: Estimate the Model
  ```{r, eval=FALSE}
  model <- rsparrow_model(path_main = td, run_id = "example",
                          if_estimate = TRUE, if_predict = TRUE)
  ```
  (eval=FALSE because estimation is slow; show pre-computed results instead)

  ## Step 4: Examine Results
  ```{r, eval=FALSE}
  print(model)
  coef(model)
  summary(model)
  ```
  (Show representative output as static text or a stored object)

  ## Step 5: Predictions
  ```{r, eval=FALSE}
  preds <- predict(model)
  head(preds)
  ```

  ## Step 6: Scenarios
  ```{r, eval=FALSE}
  scenario <- rsparrow_scenario(model, source_changes = list(s1 = 0.5))
  ```

  ## Further Reading
  Link to SPARROW documentation, USGS, package website.

Use eval=FALSE for estimation and prediction chunks, replacing with pre-computed example
output shown as R output blocks. This keeps the vignette build time under 30 seconds.

Add knitr and rmarkdown to DESCRIPTION Suggests if not already present.
</description>
<files_modified>
  CREATE or REWRITE: vignettes/introduction.Rmd
  EDIT: DESCRIPTION (add knitr, rmarkdown to Suggests if missing)
</files_modified>
<success_criteria>
  - Vignette builds without error: R CMD build . (without --no-build-vignettes)
  - Vignette is listed in R CMD check output with no WARNING
  - Vignette HTML renders all sections correctly
  - Vignette build time < 30 seconds
</success_criteria>
</task>

<task id="12-5" status="pending">
<subject>Update DESCRIPTION URL and BugReports fields</subject>
<description>
The DESCRIPTION URL field may reference the old USGS code.usgs.gov repository.
Update it to the canonical GitHub URL and add a BugReports field.

  URL: https://github.com/Kyle-Hurley/rsparrow
  BugReports: https://github.com/Kyle-Hurley/rsparrow/issues

Also review remaining DESCRIPTION fields for CRAN compliance:
  - Title: must be in Title Case, ≤ 65 characters, no trailing period
  - Description: must be a complete sentence, ≥ 2 sentences, no repetition of Title
  - Version: confirm still 2.1.0 or bump if changes since Plan 06F warrant it
  - Authors@R: verify Kyle Hurley has cre role with valid email
  - Date: update if present (CRAN discourages Date field; consider removing it)

After edits:
  R CMD check rsparrow_2.1.0.tar.gz 2>&1 | grep -E "DESCRIPTION|Maintainer|Author|URL"
  Expected: 0 WARNINGs related to DESCRIPTION fields
</description>
<files_modified>EDIT: DESCRIPTION</files_modified>
<success_criteria>
  - URL points to active GitHub repository
  - BugReports points to GitHub issues
  - 0 DESCRIPTION-related WARNINGs in R CMD check
</success_criteria>
</task>

<task id="12-6" status="pending">
<subject>Final R CMD check --as-cran and cross-platform verification</subject>
<description>
Run the definitive pre-submission check:

  source scripts/renv.sh
  R CMD build .
  R_LIBS=/home/kp/R/libs _R_CHECK_FORCE_SUGGESTS_=false \
    R CMD check --as-cran rsparrow_2.1.0.tar.gz

Target:
  0 ERRORs
  0 WARNINGs
  ≤ 1 NOTE (acceptable: "New submission" on first CRAN check via winbuilder/macbuilder)

If any WARNING or ERROR appears, fix it before proceeding.

Also submit to CRAN's check services for cross-platform verification:
  - win-builder: https://win-builder.r-project.org/ (test on Windows R-devel)
  - macOS builder: https://mac.r-project.org/macbuilder/ (test on macOS)
  OR use rhub2 if available: rhub::rhub_check()

Review winbuilder/macbuilder results for platform-specific issues:
  - Path separator issues (.Platform$file.sep vs file.path())
  - Fortran compilation on Windows (requires Rtools)
  - Any Windows-specific behavior differences

Fix any issues found. Re-run R CMD check --as-cran until clean.

Also run the full test suite one final time:
  R_LIBS=/home/kp/R/libs R CMD INSTALL --no-multiarch .
  R_LIBS=/home/kp/R/libs Rscript -e "testthat::test_package('rsparrow')"
  Expected: all tests pass in < 10 minutes total

Close GH #8 and GH #9.
Update CRAN_ROADMAP.md: mark all checklist items as pass.
</description>
<files_modified>
  EDIT: Any files needed to fix cross-platform issues
  EDIT: docs/plans/CRAN_ROADMAP.md (final checklist update)
</files_modified>
<success_criteria>
  - R CMD check --as-cran: 0 ERRORs, 0 WARNINGs, ≤ 1 NOTE
  - winbuilder check passes (0 ERRORs, 0 WARNINGs)
  - All tests pass
  - GH #8, #9 closed
  - CRAN_ROADMAP.md fully updated
</success_criteria>
</task>

</tasks>

<success_criteria>
<criterion>data/sparrow_example.rda present, documented, ≤ 1 MB, loads cleanly (GH #9 closed)</criterion>
<criterion>vignettes/introduction.Rmd builds in < 30 seconds, renders correctly (GH #8 closed)</criterion>
<criterion>All 13 exported functions have passing @examples in R CMD check</criterion>
<criterion>DESCRIPTION URL and BugReports fields point to active GitHub URLs</criterion>
<criterion>R CMD check --as-cran: 0 ERRORs, 0 WARNINGs, ≤ 1 NOTE</criterion>
<criterion>winbuilder check: 0 ERRORs, 0 WARNINGs</criterion>
<criterion>All tests pass in < 10 minutes</criterion>
<criterion>CRAN_ROADMAP.md checklist: all items marked pass</criterion>
</success_criteria>

<failure_criteria>
<criterion>R CMD check --as-cran produces any WARNING</criterion>
<criterion>Vignette build fails or takes > 5 minutes</criterion>
<criterion>Example dataset causes any @examples to error in R CMD check</criterion>
<criterion>winbuilder finds a Fortran compilation error on Windows</criterion>
</failure_criteria>

<risks>
<risk level="medium">
  Constructing a 50–100 reach synthetic dataset that actually runs through rsparrow_model()
  requires matching the exact CSV format expected by read_sparrow_data(). The format is
  complex (parameters.csv, design_matrix.csv, dataDictionary.csv). Build the dataset
  iteratively: start with rsparrow_hydseq() (simplest), then add what read_sparrow_data()
  needs, then what rsparrow_model() needs.
</risk>
<risk level="medium">
  The vignette must use eval=FALSE for the estimation step (too slow for CRAN checks).
  This means users reading the vignette see code but not output for the main steps.
  Consider including pre-computed output as code blocks (```output) to illustrate what
  users will see when they run the code themselves.
</risk>
<risk level="low">
  Fortran compilation on Windows requires Rtools and gfortran. winbuilder tests this
  automatically. The Fortran sources already have Windows-specific directives removed
  (Plan 01). If winbuilder fails, check that the DESCRIPTION SystemRequirements field
  mentions gfortran or that the package compiles with the Rtools Fortran compiler.
</risk>
</risks>

<notes>
- This plan is the final plan before CRAN submission. All code-quality and compliance
  work is done in Plans 07–11. Plan 12 is about usability and final polish.
- The existing mini_network.rda and mini_model_inputs.rda fixtures from Plan 06A are
  for tests only and are in tests/testthat/fixtures/. They are NOT the example dataset.
  The example dataset in data/ is a separate, user-facing object that is installed with
  the package and accessible via data(sparrow_example).
- After this plan, the package should be ready to submit via devtools::submit_cran()
  or direct upload to https://cran.r-project.org/submit.html.
- GH issues #1 (hydseq boolean bug) and #2 (calcHeadflag bug) are in archived functions.
  Those issues should be closed with a note that the functions were archived in Plan 09.
  GH issues #3 (DESCRIPTION Author) and #4 (setNLLSWeights) should be resolved by Plans
  11 and 07 respectively — confirm they are closed before starting Plan 12.
</notes>

</plan>
