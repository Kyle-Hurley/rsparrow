# PLAN 02: Non-Core Code Separation and Dependency Reduction

## Context

Plan 01 established the package structure foundation (rename, DLLs, license, DESCRIPTION).
The package builds as rsparrow_2.1.0 but still has 183 R files, 38 Imports, and zero exports.
Before designing a clean API (Plan 03+), we must remove non-core code — Shiny/GUI files and
legacy scaffolding — so the remaining codebase is tractable. This plan separates 25 Shiny files
into inst/shiny_dss/ (for a future companion package), deletes 19 pure-legacy scaffolding files,
trims 18 packages from Imports, and removes 15 NAMESPACE import() lines.

**Before:** 183 R files, 180 man pages, 40 Imports, 37 NAMESPACE import() lines
**After:**  139 R files, 136 man pages, 22 Imports, 22 NAMESPACE import() lines

---

## Task 1: Pre-flight baseline

Record current counts for verification:
- `ls RSPARROW_master/R/ | wc -l` → 183
- `ls RSPARROW_master/man/ | wc -l` → 180
- Count Imports in DESCRIPTION → 40
- Count import() lines in NAMESPACE → 37
- `R CMD build --no-build-vignettes RSPARROW_master/` → must succeed

---

## Task 2: Create inst/shiny_dss/ and move 25 Shiny/GUI files

Create `RSPARROW_master/inst/shiny_dss/` and move these files from `R/`:

**Core Shiny app (3 files):**
- shinyMap2.R (673 lines) — main DSS app
- goShinyPlot.R (597 lines) — interactive plot generation
- runBatchShiny.R (33 lines) — batch Shiny launcher

**Shiny UI modules (7 files):**
- shinyScenarios.R, shinySiteAttr.R, streamCatch.R
- dropFunc.R, handsOnUI.R, shapeFunc.R
- createInteractiveChoices.R

**Shiny server modules (6 files):**
- shinyScenariosMod.R, handsOnMod.R, compileALL.R, compileInput.R
- selectAll.R, updateVariable.R

**Shiny validation/utility (6 files):**
- shinyErrorTrap.R, shinySavePlot.R
- testCosmetic.R, testRedTbl.R, validCosmetic.R
- allowRemoveRow.R

**Shiny data processing (3 files):**
- convertHotTables.R, sourceRedFunc.R, createRTables.R

**Verification:** `ls RSPARROW_master/inst/shiny_dss/ | wc -l` → 25

---

## Task 3: Delete 19 legacy scaffolding files from R/

All callers are either executeRSPARROW.R (legacy-only) or no production callers.

**Execution orchestration (1 file):**
- executeRSPARROW.R — master legacy executor, only called by runRsparrow.R (inst/legacy/)

**Control-file infrastructure (5 files):**
- findControlFiles.R, generateInputLists.R, makePaths.R, createDirs.R, setupMaps.R

**Settings validation (2 files):**
- testSettings.R, setMapDefaults.R

**Interactive/Windows-only UI (4 files):**
- isScriptSaved.R, openDesign.R, openParameters.R, openVarnames.R

**State/cleanup utilities (2 files):**
- removeObjects.R, deleteFiles.R

**Legacy-only utilities (3 files):**
- RSPARROW_objects.R, copyPriorModelFiles.R, findScriptName.R

**Development tools (2 files):**
- executionTree.R, findCodeStr.R

**Verification:** `ls RSPARROW_master/R/ | wc -l` → 139

---

## Task 4: Delete corresponding man pages (~44 .Rd files)

Delete the .Rd file in `man/` for each of the 25 moved + 19 deleted R files.
Pattern: for each `foo.R` moved/deleted, delete `man/foo.Rd` if it exists.

**Verification:** `ls RSPARROW_master/man/ | wc -l` → ~136

---

## Task 5: Edit startModelRun.R — remove Shiny launch

Remove lines 532–534:
```r
if (enable_ShinyApp == "yes" & batch_mode == "no") {
  runBatchShiny(path_results, path_shinyBrowser)
} # end interactive maps
```

Keep the `save(shinyArgs, ...)` block above it (line 530) for now — it writes an
RDS that the separated Shiny DSS can read later.

**File:** `RSPARROW_master/R/startModelRun.R`
**Verification:** grep for `runBatchShiny` in R/ returns zero hits.

---

## Task 6: Remove 18 packages from DESCRIPTION Imports

Remove these from the Imports field:

| Package | Reason |
|---------|--------|
| shiny | Only Shiny callers (moved) |
| shinyWidgets | Only Shiny callers (moved) |
| shinycssloaders | Only Shiny callers (moved) |
| rhandsontable | Only Shiny callers (moved) |
| htmltools | Only Shiny callers (moved) |
| htmlwidgets | Only Shiny callers (moved) |
| svDialogs | Only isScriptSaved.R (deleted) |
| svGUI | Only svDialogs dependency |
| rstudioapi | Only findScriptName.R (deleted) |
| data.tree | Only executionTree.R (deleted) |
| rstan | Zero callers in remaining code |
| OpenMx | Zero callers in remaining code |
| inline | Zero callers in remaining code |
| roxygen2 | Dev tool, never belongs in Imports |
| gear | Zero callers in remaining code |
| evaluate | Zero callers in remaining code |
| formatR | Zero callers in remaining code |
| highr | Zero callers in remaining code |

**Remaining Imports (22):** car, data.table, dplyr, ggplot2, gplots, gridExtra,
knitr, leaflet, leaflet.extras, magrittr, mapview, markdown, nlmrt, numDeriv,
plotly, plyr, rmarkdown, sf, sp, spdep, stringr, tools

**Verification:** Count Imports entries → 22

---

## Task 7: Remove 15 import() lines from NAMESPACE

Remove these lines:

```
import(gear, except = c(evaluate))
import(htmlwidgets)
import(htmltools, except = c(code))
import(OpenMx)
import(shiny, except = code)
import(shinyWidgets)
import(shinycssloaders)
import(data.tree)
import(svDialogs)
import(rstudioapi)
import(rstan)
import(inline)
import(evaluate)
import(formatR)
import(highr)
```

**Remaining NAMESPACE (22 lines = 21 import + 1 useDynLib):**
```
import(numDeriv)
import(nlmrt)
import(spdep)
import(stringr)
import(gplots, except = c(reorder.factor))
import(ggplot2, except = c(last_plot))
import(plotly)
import(leaflet)
import(leaflet.extras)
import(plyr, except = c(mutate,summarize,arrange,failwith,summarise,id,rename,desc,count))
import(dplyr, except = c(recode,last,between,first))
import(car, except =c(pointLabel))
import(sf)
import(sp)
import(data.table)
import(tools)
import(knitr)
import(rmarkdown)
import(markdown)
import(mapview)
import(magrittr, except = c(extract))
useDynLib(rsparrow, .registration = TRUE)
```

**Verification:** Count non-blank, non-comment lines → 22

---

## Task 8: Remove ~44 entries from DESCRIPTION Collate field

Remove the Collate entry for each of the 25 moved + 19 deleted files.

Files to remove from Collate (alphabetical):
```
allowRemoveRow.R, compileALL.R, compileInput.R, convertHotTables.R,
copyPriorModelFiles.R, createDirs.R, createInteractiveChoices.R,
createRTables.R, deleteFiles.R, dropFunc.R, executeRSPARROW.R,
executionTree.R, findCodeStr.R, findControlFiles.R, findScriptName.R,
generateInputLists.R, goShinyPlot.R, handsOnMod.R, handsOnUI.R,
isScriptSaved.R, makePaths.R, openDesign.R, openParameters.R,
openVarnames.R, removeObjects.R, RSPARROW_objects.R, runBatchShiny.R,
selectAll.R, setMapDefaults.R, setupMaps.R, shapeFunc.R,
shinyErrorTrap.R, shinyMap2.R, shinySavePlot.R, shinyScenarios.R,
shinyScenariosMod.R, shinySiteAttr.R, sourceRedFunc.R, streamCatch.R,
testCosmetic.R, testRedTbl.R, testSettings.R, updateVariable.R,
validCosmetic.R
```

**Verification:** Count remaining Collate entries → 139

---

## Task 9: Add inst/shiny_dss to .Rbuildignore

Add `^inst/shiny_dss$` to `RSPARROW_master/.Rbuildignore` so the separated
Shiny code is excluded from the built tarball.

---

## Task 10: Verify — grep for broken references

Search remaining R/ files for function names from deleted/moved files that
appear as actual calls (not roxygen comments). Key functions to check:

```
executeRSPARROW, runBatchShiny, isScriptSaved, findScriptName,
executionTree, findCodeStr, shinyMap2, goShinyPlot, testCosmetic,
testRedTbl, compileALL, compileInput, createInteractiveChoices,
testSettings, setMapDefaults, setupMaps
```

Expected: zero hits in actual code (roxygen `@item` or `Executed By` comment
references are acceptable — they're stale documentation, not code calls).

---

## Task 11: Verify — R CMD build

```
R CMD build --no-build-vignettes RSPARROW_master/
```

Must produce `rsparrow_2.1.0.tar.gz` successfully.

**Final count verification:**
| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| R/ files | 183 | 139 | -44 |
| man/ pages | 180 | ~136 | ~-44 |
| DESCRIPTION Imports | 40 | 22 | -18 |
| NAMESPACE import() | 37 | 21 | -16* |
| Collate entries | 183 | 139 | -44 |
| inst/shiny_dss/ files | 0 | 25 | +25 |

*One fewer NAMESPACE removal than DESCRIPTION because some DESCRIPTION packages
(rhandsontable, svGUI, roxygen2) had no NAMESPACE import() line.

---

## Task 12: Update project documentation

- **CRAN_PREPARATION_ROADMAP.md:** Mark Shiny separation as done in priority 2;
  update dependency counts; add Plan 02 to completed_plans section
- **CLAUDE.md:** Update file counts, dependency counts, architecture notes
- **MEMORY.md:** Record Plan 02 completion and key outcomes

---

## Risks and Mitigations

1. **Broken function references:** Stale roxygen `Executed By` / `Executes Routines`
   comments will reference deleted functions. These are documentation-only (not code)
   and will be cleaned in a future roxygen rewrite. Not a build blocker.

2. **outputSettings.R / getSett files:** These are called by core functions
   (controlFileTasksModel, startModelRun) and are intentionally NOT removed here.
   They'll be addressed when the core API is redesigned.

3. **markdown package kept:** Retained because render_report.R and predictMaps.R
   reference rmarkdown/knitr which may transitively need it. Safe to reassess in
   the report-removal plan.

4. **shinyArgs save in startModelRun.R:** The `save(shinyArgs, ...)` block is kept
   so the separated Shiny DSS can still read model results. It's a no-op if nobody
   reads the file.
