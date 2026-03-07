# Plan 03: API Design and Namespace Refactoring

## Objective

Transform rsparrow from a zero-export internal-only package into a proper R package with:
1. A clean, minimal exported API (13 functions) following R conventions
2. Selective importFrom() directives instead of 21 blanket import() statements
3. S3 class "rsparrow" with standard methods (predict, summary, print, coef, residuals, vcov, plot)
4. Proper roxygen2 documentation with @export, @importFrom, @useDynLib tags
5. Auto-generated NAMESPACE (never hand-edited again)

## Current State

- 139 R files, 22 Imports in DESCRIPTION, 22 NAMESPACE directives (all blanket imports)
- Zero exported functions (NAMESPACE contains only import() and useDynLib())
- Legacy workflow: user sources sparrow_control.R, which triggers global state mutations
- All functions are internal; users access via .GlobalEnv side effects
- No S3 classes; functions pass around bare lists with ad-hoc structures
- NAMESPACE is hand-edited (last edit: Plan 02, removing 15 blanket imports)

## Scope

This plan covers **API design and namespace management only**:
- Define the 13 exported functions
- Create skeleton implementations with full roxygen2 docs
- Convert blanket imports to selective imports via roxygen2
- Design S3 class structure (as specification, not implementation)
- Regenerate NAMESPACE from roxygen2 tags

This plan does NOT cover:
- Implementation (deferred to Plan 04: State Elimination)
- Removing global state or eval(parse()) (Plan 04)
- Merging duplicate functions or removing non-core code (Plan 05)
- Test suite creation (Plan 06)

---

## Tasks

### Task 1: Analyze import usage for all 21 packages

**Why:** Need to identify which specific functions are actually used from each package to convert blanket import() to selective importFrom().

**Action:**
- For each of the 21 packages, grep the codebase for function calls
- Document: function name, occurrence count, files used in
- Categorize packages: CORE (nlmrt, numDeriv, sf, spdep), PLOTTING (ggplot2), OPTIONAL (leaflet, plotly, markdown/knitr/rmarkdown), UTILITY (dplyr, stringr)
- Identify candidates for moving from Imports to Suggests
- See `docs/api_design/IMPORTS_GUIDE.md` for detailed instructions

**Risk:** Missing a function will cause runtime errors. Over-importing is safer for Plan 03; trim later.

**Verification:**
- Analysis documented (can be done in task execution notes, doesn't need separate file)
- Each package has a list of functions to import
- Packages categorized as CORE/OPTIONAL/REMOVABLE

---

### Task 2: Create skeleton exported functions with roxygen2 docs

**Why:** Define the user-facing API surface with complete documentation before implementation.

**Action:**
- Create 13 new R files in R/ for exported functions (see `docs/api_design/EXPORTS_SPECIFICATION.md`):
  - `R/rsparrow_model.R` - main entry point
  - `R/predict.rsparrow.R`, `R/summary.rsparrow.R`, `R/print.rsparrow.R` - S3 methods
  - `R/coef.rsparrow.R`, `R/residuals.rsparrow.R`, `R/vcov.rsparrow.R`, `R/plot.rsparrow.R` - more S3 methods
  - `R/rsparrow_bootstrap.R`, `R/rsparrow_scenario.R`, `R/rsparrow_hydseq.R`, `R/rsparrow_validate.R` - advanced functions
  - `R/read_sparrow_data.R` - data reader
- Each function has complete roxygen2: @title, @description, @param (all args), @return, @export, @examples (in \dontrun{})
- For S3 methods, use @method generic class (e.g., `@method predict rsparrow`)
- Function body: `stop("Not yet implemented - see Plan 04: State Elimination")`
- Exception: rsparrow_hydseq() can wrap existing hydseq() function (fully implement)
- See `docs/api_design/API_REFERENCE.md` for roxygen2 templates

**Risk:** None; skeleton functions don't affect existing code.

**Verification:**
- 13 new R files created
- Each has complete roxygen2 documentation with @export
- All examples wrapped in \dontrun{}
- Function bodies contain stop() messages (except rsparrow_hydseq)

---

### Task 3: Add @keywords internal to core internal functions

**Why:** Mark helper functions as internal-only so they don't appear in user documentation.

**Action:**
- Add minimal roxygen2 header with `@keywords internal` to ~40-50 core internal functions:
  - estimate*.R functions (estimateFeval, estimateOptimize, etc.)
  - deliver.R, hydseq.R (the internal versions)
  - Data manipulation utilities
- Optionally add `@noRd` to suppress .Rd file generation
- Skip functions marked for deletion in Plan 05 (diagnosticMaps, makeReport_*, etc.)
- See `docs/api_design/API_REFERENCE.md` for internal function template

**Risk:** Low; just adds documentation, doesn't change behavior.

**Verification:**
- Core internal functions have @keywords internal tags
- No functions inadvertently exported
- R CMD build succeeds

---

### Task 4: Create R/rsparrow-package.R with @importFrom tags

**Why:** Centralize all import directives in one roxygen2-managed file.

**Action:**
- Create `R/rsparrow-package.R` for package-level documentation
- Add roxygen2 @docType package, @name rsparrow-package, @aliases rsparrow
- Add `@useDynLib rsparrow, .registration = TRUE`
- Add ~50-80 `@importFrom` lines based on Task 1 analysis (see `docs/api_design/IMPORTS_GUIDE.md` for each package)
- Examples:
  - `@importFrom data.table data.table setDT := setnames .N .SD`
  - `@importFrom dplyr filter mutate select group_by summarise arrange`
  - `@importFrom magrittr %>%`
  - `@importFrom nlmrt nlfb nlsLM`
  - `@importFrom numDeriv hessian jacobian`
  - `@importFrom sf st_as_sf st_crs st_transform st_geometry`
  - etc.
- End file with `"_PACKAGE"` sentinel for roxygen2

**Risk:** Missing imports will cause check failures; can be fixed iteratively.

**Verification:**
- R/rsparrow-package.R created
- Contains @useDynLib and comprehensive @importFrom tags
- No blanket @import tags

---

### Task 5: Update DESCRIPTION Imports/Suggests

**Why:** Align DESCRIPTION with actual usage; move optional packages to Suggests.

**Action:**
- Keep in **Imports** (11 packages):
  - nlmrt, numDeriv (CORE optimization)
  - data.table, dplyr, magrittr, stringr (data manipulation)
  - sf, sp, spdep (spatial, though sp may be removable later)
  - ggplot2 (basic plotting)
  - tools (file utilities)
- Move to **Suggests** (~10 packages):
  - gplots, gridExtra, plyr (specialized plotting/manipulation)
  - leaflet, leaflet.extras, mapview, plotly (interactive maps/plots)
  - markdown, knitr, rmarkdown (report generation)
- Add conditional checks in code for Suggests packages:
  ```r
  if (!requireNamespace("plotly", quietly = TRUE)) {
    stop("Package 'plotly' needed. Install: install.packages('plotly')")
  }
  ```

**Risk:** Low; CRAN prefers minimal Imports.

**Verification:**
- DESCRIPTION has ≤11 Imports
- DESCRIPTION has ~10 Suggests (including testthat)
- R CMD build succeeds

---

### Task 6: Delete hand-edited NAMESPACE and regenerate with roxygen2

**Why:** Transition to roxygen2-managed NAMESPACE; enables automatic export/import management.

**Action:**
- Delete `RSPARROW_master/NAMESPACE` (hand-edited version)
- Run `roxygen2::roxygenize("RSPARROW_master")` to regenerate
- Inspect new NAMESPACE; should contain:
  - Comment: `# Generated by roxygen2: do not edit by hand`
  - 13 `export()` directives (exported functions)
  - 7 `S3method()` registrations (predict.rsparrow, summary.rsparrow, etc.)
  - ~50-80 `importFrom()` directives (NO blanket import())
  - 1 `useDynLib(rsparrow, .registration = TRUE)` directive
- Also regenerates man/ pages (13 exported + ~40 internal .Rd files)

**Risk:** Missing imports will cause errors; fix by adding to rsparrow-package.R and re-running roxygen2.

**Verification:**
- NAMESPACE has "do not edit by hand" comment
- Contains export() and importFrom() (no import())
- Contains S3method() registrations
- man/ pages regenerated
- R CMD build succeeds

---

### Task 7: Build and check package with new API

**Why:** Verify that package builds, installs, and loads with the new exported API.

**Action:**
- `cd /home/kp/Documents/projects/rsparrow-master`
- `R CMD build --no-build-vignettes RSPARROW_master/` → produces rsparrow_2.1.0.tar.gz
- `R CMD check --as-cran --no-manual rsparrow_2.1.0.tar.gz`
- Expected: 0 errors, 0 warnings, ≤2 notes ("new submission", possibly "functions with \dontrun examples only")
- Install and test:
  ```r
  install.packages("rsparrow_2.1.0.tar.gz", repos = NULL, type = "source")
  library(rsparrow)
  ls("package:rsparrow")  # Should show 13 functions
  methods(predict)        # Should include predict.rsparrow
  ?rsparrow_model         # Check help page
  getDLLRegisteredRoutines("rsparrow")  # Check Fortran routines
  ```

**Risk:** Check warnings about missing imports; add to rsparrow-package.R and rebuild.

**Verification:**
- R CMD check: 0 errors, 0 warnings, ≤2 notes
- Package installs successfully
- library(rsparrow) loads without errors
- 13 exported functions visible
- S3 methods registered
- Fortran routines compiled

---

### Task 8: Update project documentation

**Why:** Record Plan 03 completion in CLAUDE.md, MEMORY.md, and CRAN_PREPARATION_ROADMAP.md.

**Action:**

1. Update `CLAUDE.md` lines 6-9 (project_overview):
   - Change "Plans 01-02 are complete" to "Plans 01-03 are complete"
   - Add: "13 functions exported with S3 class 'rsparrow'. NAMESPACE uses selective importFrom() (~60 directives, zero blanket imports)."

2. Update `CLAUDE.md` lines 25-30 (architecture):
   - Add paragraph describing the 13 exported functions and S3 methods
   - Note that NAMESPACE is now auto-generated

3. Update `CLAUDE.md` lines 73-81 (technical_debt):
   - Add "Resolved in Plan 03:" paragraph

4. Update `~/.claude/projects/-home-kp-Documents-projects-rsparrow-master/memory/MEMORY.md`:
   - Add Task 5 (Plan 03) section with changes summary

5. Update `CRAN_PREPARATION_ROADMAP.md`:
   - Mark completed requirements with `status="done"`
   - Update executive summary
   - Update CRAN checklist items

**Risk:** None; documentation only.

**Verification:**
- All docs updated
- Plan 03 changes recorded
- Next steps clearly stated

---

## Success Criteria

After completing Plan 03, verify:

✅ R CMD build --no-build-vignettes produces rsparrow_2.1.0.tar.gz
✅ R CMD check --as-cran returns 0 errors, 0 warnings, ≤2 notes
✅ library(rsparrow) loads successfully
✅ ls("package:rsparrow") shows 13 exported functions
✅ methods(predict) includes predict.rsparrow
✅ ?rsparrow shows package help page
✅ ?rsparrow_model shows complete documentation with examples
✅ NAMESPACE is auto-generated (contains "do not edit by hand" comment)
✅ NAMESPACE has ~60 importFrom() lines and 0 import() lines
✅ DESCRIPTION Imports field has ≤11 packages
✅ DESCRIPTION Suggests field has ~10 optional packages
✅ All skeleton functions error with "see Plan 04" message
✅ getDLLRegisteredRoutines("rsparrow") shows 6 Fortran routines

## Reference Documents

- `docs/api_design/S3_CLASS_DESIGN.md` - Canonical S3 "rsparrow" object structure
- `docs/api_design/EXPORTS_SPECIFICATION.md` - All 13 exported functions with signatures
- `docs/api_design/IMPORTS_GUIDE.md` - How to analyze and convert imports
- `docs/api_design/API_REFERENCE.md` - Roxygen2 templates and documentation patterns

## Notes

**Implementation is deferred to Plan 04:** This plan creates skeleton functions with complete documentation but placeholder implementations. Actual function bodies will be written in Plan 04 after global state (assign/.GlobalEnv/unPackList) is eliminated.

**NAMESPACE must never be hand-edited after Task 6:** Once roxygen2 takes over, all future changes MUST use roxygen2 tags. Hand-editing will cause conflicts.

**S3 class structure is design-only:** The structure defined in S3_CLASS_DESIGN.md is a specification. Plan 04 will refactor estimate.R/startModelRun.R to return objects matching this design.

**R CMD check warnings are acceptable:** Expect warnings about "\dontrun examples only" until Plan 04 implements the functions. This is normal for skeleton APIs.
