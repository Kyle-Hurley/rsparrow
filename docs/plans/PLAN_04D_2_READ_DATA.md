<plan id="04-D-2">
<name>read_sparrow_data() Implementation</name>
<part_of>Plan 04-D sub-session 2 of 4 — implements Task 10 from PLAN_04D_API_IMPLEMENTATION.md</part_of>
<previous_plans>04-A (tasks 1-3), 04-B (tasks 4-5), 04-C (tasks 6-7), 04-D-1 (S3 methods)</previous_plans>

<context>
Plans 04-A through 04-C and sub-session 04D-1 complete.
This sub-session implements read_sparrow_data(), the public-facing data loader that
validates the project directory, reads control CSVs, and returns a named list consumed
by rsparrow_model() in sub-session 04D-3.

Complexity: LOW-MEDIUM. Calls only two internal functions: read_dataDictionary() and
readData(). No estimation machinery is involved. The main risk is getting the
file.output.list field names to match what startModelRun() will expect in 04D-3.
</context>

<prerequisites>
- Plans 04-A through 04-D-1 complete
- R CMD check: 0 errors before starting
- Confirm stub:
    grep -n "Not yet implemented" RSPARROW_master/R/read_sparrow_data.R
- Verify internal functions exist:
    grep -n "^read_dataDictionary <- function" RSPARROW_master/R/read_dataDictionary.R
    grep -n "^readData <- function" RSPARROW_master/R/readData.R
</prerequisites>

<reference_documents>
Read before starting:
  docs/implementation/PLAN_04_SKELETON_IMPLEMENTATIONS.md  — implementation name="read_sparrow_data"
  docs/plans/PLAN_04D_API_IMPLEMENTATION.md               — task id="10"
  RSPARROW_master/UserTutorial/                            — example project for verification
</reference_documents>

<verify_internal_signatures label="Run before writing any code">
Verify the current signatures of the two internal functions read_sparrow_data() will call:
  grep -n "^read_dataDictionary <- function" RSPARROW_master/R/read_dataDictionary.R
  grep -n "^readData <- function"            RSPARROW_master/R/readData.R
  head -30 RSPARROW_master/R/read_dataDictionary.R
  head -30 RSPARROW_master/R/readData.R

Also check what file.output.list fields startModelRun() currently reads:
  grep -n "file\.output\.list\$" RSPARROW_master/R/startModelRun.R | head -30
This ensures the file.output.list built here will satisfy 04D-3's needs.
</verify_internal_signatures>

<scope>
<in_scope>
- Task 10: Implement read_sparrow_data() in RSPARROW_master/R/read_sparrow_data.R
- Validate path_main directory exists
- Check for required control files: parameters.csv, design_matrix.csv, dataDictionary.csv
- Construct file.output.list (minimum fields for read_dataDictionary + readData)
- Call read_dataDictionary(file.output.list) to get data_names
- Call readData(file.output.list, data_names) to get data1
- Return named list: list(file.output.list, data1, data_names)
</in_scope>
<out_of_scope>
- Reading betavalues.csv or dmatrixin.csv (depends on estimation settings; belongs in startModelRun)
- Building the complete file.output.list for all of startModelRun (that happens in 04D-3)
- Any estimation, prediction, or optimization
- The rsparrow_model() wrapper (sub-session 04D-3)
</out_of_scope>
</scope>

<tasks>

<task id="10" priority="high">
<name>Implement read_sparrow_data()</name>
<file>RSPARROW_master/R/read_sparrow_data.R</file>
<description>
Replace stop("Not yet implemented") with a working implementation. The pseudocode below
is from PLAN_04_SKELETON_IMPLEMENTATIONS.md; adjust based on actual signatures of
read_dataDictionary() and readData() discovered in verify_internal_signatures above.

Pseudocode (adjust field names to match actual internal function signatures):

  read_sparrow_data <- function(path_main, run_id = "run1") {
    # 1. Validate inputs
    if (!dir.exists(path_main))
      stop("path_main does not exist: ", path_main)
    required_files <- c("parameters.csv", "design_matrix.csv", "dataDictionary.csv")
    missing_files <- required_files[
      !file.exists(file.path(path_main, required_files))
    ]
    if (length(missing_files) > 0)
      stop("Missing required control files: ",
           paste(missing_files, collapse = ", "),
           "\n  Expected in: ", path_main)

    # 2. Create results output directory
    path_results <- file.path(path_main, "results", run_id)
    dir.create(path_results, recursive = TRUE, showWarnings = FALSE)

    # 3. Build file.output.list — minimum fields needed by read_dataDictionary and readData
    #    IMPORTANT: verify exact field names against the internal functions before coding
    file.output.list <- list(
      path_main            = path_main,
      run_id               = run_id,
      path_results         = path_results,
      parameters_file      = file.path(path_main, "parameters.csv"),
      design_matrix_file   = file.path(path_main, "design_matrix.csv"),
      data_dictionary_file = file.path(path_main, "dataDictionary.csv")
      # Additional fields added as startModelRun() is wired up in 04D-3
    )

    # 4. Read control files using internal functions
    data_names <- read_dataDictionary(file.output.list)
    data1      <- readData(file.output.list, data_names)

    # 5. Return named list
    list(
      file.output.list = file.output.list,
      data1            = data1,
      data_names       = data_names
    )
  }

IMPORTANT ADJUSTMENT REQUIRED: The field names inside file.output.list (parameters_file,
design_matrix_file, data_dictionary_file, etc.) must match what read_dataDictionary() and
readData() actually look for. Check their source before finalising the list structure.
</description>
<note>
betavalues.csv and dmatrixin.csv are NOT read here — they depend on if_estimate and other
settings that belong in startModelRun(). read_sparrow_data() reads only the data and
control files that are needed regardless of whether estimation is run.

The file.output.list structure will grow during sub-session 04D-3 as startModelRun() is
wired up. Build only the minimum fields needed for the two internal function calls here.
</note>
<success>
- No stop("Not yet implemented") in file
- Function returns a named list with keys: file.output.list, data1, data_names
- Informative error messages for missing directory and missing files
</success>
</task>

</tasks>

<verification label="Use UserTutorial as test case">
After implementing, test with the example project (adjust path as needed):

  library(rsparrow)
  result <- read_sparrow_data("/path/to/UserTutorial")
  names(result)       # should be: "file.output.list" "data1" "data_names"
  names(result$data_names)   # should show column metadata
  nrow(result$data1)         # should show number of reach records

Also verify error handling:
  read_sparrow_data("/nonexistent/path")   # must error: "path_main does not exist"
  read_sparrow_data("/tmp")               # must error: "Missing required control files"

<grep_checks label="Must return 0 results">
  grep -n "Not yet implemented" RSPARROW_master/R/read_sparrow_data.R
</grep_checks>
<build_check>
  R CMD build --no-build-vignettes RSPARROW_master/
  R CMD check rsparrow_2.1.0.tar.gz
  # Must produce 0 new errors vs 04D-1 baseline
</build_check>
</verification>

<risks>
<risk name="file.output.list_field_name_mismatch">
The pseudocode uses assumed field names (parameters_file, design_matrix_file, etc.).
The actual internal functions (read_dataDictionary, readData) may use different names —
especially if they were written using the legacy path-construction pattern where
file.output.list$path_main is combined with hardcoded filenames inside the function.
Always grep the internal function sources before finalising the list structure.
Mitigation: grep -n "file\.output\.list\$" RSPARROW_master/R/read_dataDictionary.R
</risk>
<risk name="readData_argument_count_mismatch">
readData() may require more arguments than (file.output.list, data_names) if additional
settings objects were passed to it in the legacy flow. Check its full signature.
Mitigation: head -10 RSPARROW_master/R/readData.R
</risk>
</risks>

<success_criteria>
- grep -n "Not yet implemented" RSPARROW_master/R/read_sparrow_data.R → 0 results
- read_sparrow_data(UserTutorial_path) returns list with 3 keys without error
- Informative error for missing path and missing files
- R CMD check introduces no new errors vs 04D-1 baseline
</success_criteria>

<failure_criteria>
- File still contains "Not yet implemented" → sub-session incomplete
- Function throws unexpected error from read_dataDictionary or readData → field name mismatch;
  investigate signatures and adjust file.output.list before proceeding to 04D-3
- R CMD check introduces new errors → fix before proceeding to 04D-3
</failure_criteria>

<next_session>04D-3: rsparrow_model() — main estimation entry point (HIGH complexity; own session)</next_session>

</plan>
