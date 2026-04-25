# Plan 18: Strip Side Effects and Dead Code from Core Workflow

## Context

rsparrow has been progressively refactored (Plans 01-17) but the estimation pipeline
still has major issues: `estimate.R` (~700 lines) generates diagnostic plots, writes
ESRI shapefiles, and outputs summary CSVs as side effects during model fitting.
`controlFileTasksModel.R` dispatches diagnostic tasks inline. `startModelRun.R` calls
unused helpers and saves Shiny state. Dead code and the Shiny DSS add weight.

The core API workflow is sound: **prepare -> estimate -> predict -> bootstrap/validate/
scenario -> write results -> plot**. All features (scenarios, bootstrapping, validation)
are kept. The goal is to eliminate side effects from the estimation path and archive
dead/Shiny code, so that estimation does ONLY computation and all output (plotting,
file writing) happens on-demand through the S3 methods and `write_rsparrow_results()`.

---

## Plan 18A: Archive Dead Code and Shiny DSS

**Goal:** Remove files with zero active callers and the Shiny DSS.

### Files to archive

**Dead code -> `inst/archived/utilities/` (5 files):**
- `R/createInitialParameterControls.R` (zero active callers — legacy scaffold tool)
- `R/mod_read_utf8.R` (zero active callers; archival fixes GH #6 NOTE)
- `R/checkFileEncoding.R` (only called by mod_read_utf8)
- `R/createMasterDataDictionary.R` (guarded by path_results; file I/O only)
- `R/findMinMaxLatLon.R` (fills mapping display bounds; no computation role)

**Unused diagnostic helpers -> `inst/archived/diagnostics/` (4 files):**
- `R/correlationMatrix.R` (hardcoded "no" in rsparrow_estimate; never runs)
- `R/calcIncremLandUse.R` (only feeds diagnosticPlotsNLLS land-use plots)
- `R/sumIncremAttributes.R` (only called by calcIncremLandUse + correlationMatrix)
- `R/setNAdf.R` (only called by calcIncremLandUse)

**Shiny DSS -> `inst/archived/shiny_dss/` (entire directory, ~33 files):**
- `inst/shiny_dss/` -> `inst/archived/shiny_dss/`

### Code changes in remaining files

1. **`R/startModelRun.R`** — Remove:
   - `createMasterDataDictionary()` call (~line 108, guarded by path_results)
   - `correlationMatrix()` call + `Cor.ExplanVars.list` variable
   - `calcIncremLandUse()` calls + `sitedata.landuse`/`vsitedata.landuse` variables
   - `findMinMaxLatLon()` call
   - `save(shinyArgs, ...)` block (lines 419-435)
   - Boot/map run-time print messages (lines ~413-417)
   - Pass `Cor.ExplanVars.list = NA` to `controlFileTasksModel()` (stub for now)
   - Pass `sitedata.landuse = NA`, `vsitedata.landuse = NA` to `controlFileTasksModel()`

2. **`R/rsparrow_model.R`** — Remove:
   - Shiny params from `.minimal_file_output_list()`: `enable_ShinyApp`,
     `path_shinyBrowser`

3. **DESCRIPTION Suggests** — Remove:
   - `leaflet` (zero usage in R/ — was only in Shiny)
   - `stringi` (only used by archived mod_read_utf8/checkFileEncoding)

### Verification
- `R CMD build --no-build-vignettes .` succeeds
- `R CMD check --no-build-vignettes --no-manual` — 0 errors
- `testthat::test_package('rsparrow')` — all tests pass

---

## Plan 18B: Clean the Estimation Pipeline

**Goal:** Strip all side effects from `estimate.R` so it does ONLY computation.
Archive `diagnosticPlotsNLLS.R` (inline estimation plots). Move file-output calls
to `write_rsparrow_results()`. Diagnostic plots remain available on-demand via
`plot.rsparrow()`.

### Files to archive

**Side-effect estimation diagnostics -> `inst/archived/diagnostics/` (1 file):**
- `R/diagnosticPlotsNLLS.R` — Called during estimation as a side effect. Produces
  15+ plots inline. The core plots (4panel A/B) are already available through
  `plot.rsparrow(type="residuals")`. Extra plots (deciles, classvar groups,
  simulation panels) will be surfaced through new `plot.rsparrow()` types in 18C.

### Code changes

1. **`R/estimate.R`** — Major cleanup. Remove:
   - All `diagnosticPlotsNLLS()` calls (3 call sites: lines ~171, ~333, ~500)
   - All `diagnosticSensitivity()` calls (2 call sites: lines ~315, ~641) — now
     on-demand only via `plot(model, type="sensitivity")`
   - All `estimateNLLStable()` calls (2 call sites: lines ~156, ~490) — moved to
     `write_rsparrow_results()`
   - All `sf::st_write` ESRI shapefile blocks (5 blocks across ~200 lines)
   - Dead `predict_sparrow()` call at end (lines 673-693) — result is discarded;
     the live call is in `controlFileTasksModel()`
   - Legacy "load from prior .rda files" branch (lines 417-443) — file-based
     continuation not part of in-memory API
   - Remove now-unused parameters from signature: `class.input.list`,
     `Cor.ExplanVars.list`, `sitedata.landuse`, `vsitedata.landuse`,
     `sitedata.demtarea.class`, `vsitedata.demtarea.class`, `mapping.input.list`,
     `add_vars`, `data_names`, `if_predict`, `min.sites.list`
   - **What remains (~150 lines):** setup -> estimateOptimize -> estimateNLLSmetrics
     -> (optional validateMetrics) -> return estimate.list

2. **`R/controlFileTasksModel.R`** — Remove:
   - Section B: `diagnosticSpatialAutoCorr` call (lines 172-203) — now on-demand
     via `plot(model, type="spatial")`
   - Remove params from signature that only fed diagnostic calls:
     `Cor.ExplanVars.list`, `sitedata.landuse`, `vsitedata.landuse`,
     `sitedata.demtarea.class`, `vsitedata.demtarea.class`, `min.sites.list`,
     `mapping.input.list`
   - Update the `estimate()` call to match its slimmed signature
   - Update the return value to drop boot/map run times

3. **`R/startModelRun.R`** — Update:
   - `controlFileTasksModel()` call to match slimmed signature
   - `estimate()` receives slimmed params via controlFileTasksModel
   - Remove `Cor.ExplanVars.list` stubs from 18A

4. **`R/write_rsparrow_results.R`** — Add `estimateNLLStable()` call under the
   `"estimates"` section, so summary text/CSV output is still available through
   the explicit file-output path.

5. **DESCRIPTION Suggests** — Remove:
   - `sf` (all sf::st_write blocks in estimate.R now removed)
   - Suggests: `car`, `knitr`, `rmarkdown`, `spdep`, `testthat` (5 total)

### Verification
- Package builds and checks clean
- `plot(model, type="residuals")` works (calls 4panel A/B directly)
- `plot(model, type="sensitivity")` works (calls diagnosticSensitivity directly)
- `plot(model, type="spatial")` works (calls diagnosticSpatialAutoCorr directly)
- `write_rsparrow_results(model, path)` writes summary text via estimateNLLStable
- Estimation no longer produces any plots or files as side effects

---

## Plan 18C: Enhance plot.rsparrow with Diagnostic Plots

**Goal:** Surface the most useful diagnostic plots from the archived
`diagnosticPlotsNLLS` as new on-demand `type=` options in `plot.rsparrow()`.
Also add bootstrap and validation plot support.

### New plot types in `plot.rsparrow()`

Currently supported: `type = "residuals"`, `"sensitivity"`, `"spatial"`

**Add:**
- `type = "simulation"` — Simulation (unconditioned) performance panels:
  4-panel A (obs vs pred load/yield, residuals) + 4-panel B (boxplots, Q-Q).
  Uses `Mdiagnostics.list$ppredict`, `pResids`, `pratio.obs.pred`.
  These show model performance WITHOUT monitoring-load adjustment — essential
  for understanding predictive skill at unmonitored reaches.

- `type = "class"` — By-class diagnostic panels:
  4-panel A faceted by each classvar group level. Shows obs vs pred within
  drainage-area decile classes (or user-defined classes). Helps identify whether
  the model fits well across all watershed types.

- `type = "ratio"` — Obs/pred ratio diagnostics:
  Boxplots of observed/predicted ratio by drainage area deciles and by classvar.
  Quick visual check for systematic bias across watershed size or type.

- `type = "validation"` — Validation performance panels (when `model$validation`
  exists). Same as simulation panels but using vMdiagnostics.list. Only available
  after `rsparrow_validate()` has been called.

- `type = "bootstrap"` — Bootstrap coefficient uncertainty (when
  `model$bootstrap` exists). Histogram or density of bootstrap coefficient
  distributions with confidence intervals. Only available after
  `rsparrow_bootstrap()` has been called.

### Implementation notes
- Each new type gets its own `.rsparrow_plot_*()` internal helper in
  `plot.rsparrow.R`
- Reuse existing `diagnosticPlots_4panel_A()` and `diagnosticPlots_4panel_B()`
- All data comes from `model$data` (estimate.list, sitedata, classvar) — no
  new computation needed
- `type = "validation"` and `type = "bootstrap"` guard with informative errors
  if the relevant data doesn't exist on the model object

### Verification
- All new plot types produce clean base R graphics
- Tests for each new type
- Existing types unaffected

---

## Plan 18D: Final Cleanup and Documentation

**Goal:** Slim remaining function signatures, update docs, close GH issues.

### Tasks

1. **Slim function signatures through the call chain:**
   - `startModelRun()` — remove params that only fed archived features
   - `controlFileTasksModel()` — ensure signature matches what's actually used
   - `estimate()` — minimal signature for pure computation

2. **Remove Shiny code paths from scenario/bootstrap files:**
   - `R/predictScenarios.R` — remove all `Rshiny` branches and the `input` param
   - `R/predictScenariosPrep.R` — remove `Rshiny` guards (resolves 3 eval/parse
     calls, GH #22)
   - `R/predictScenariosOutCSV.R` — remove `Rshiny`/`input` params

3. **Update documentation:**
   - `docs/reference/FUNCTION_INVENTORY.md` — move archived functions
   - `docs/reference/ARCHITECTURE.md` — update module list
   - `docs/reference/TECHNICAL_DEBT.md` — update issue counts
   - Vignette — update if needed

4. **Close GitHub issues resolved:**
   - GH #6 (stringi/xfun undeclared — fixed by archiving checkFileEncoding/mod_read_utf8)
   - GH #22 (eval/parse in predictScenariosPrep — resolved by removing Shiny branches)

5. **Update MEMORY.md**

### Verification
- `R CMD check --no-build-vignettes --no-manual` — 0 errors, 0 warnings
- All tests pass
- Full API workflow: prepare -> estimate -> predict -> bootstrap -> validate ->
  scenario -> write results -> plot (all types)

---

## Summary

| Plan | Archives | Key changes |
|------|----------|-------------|
| 18A  | 9 R files + 33 Shiny | Dead code, unused helpers, Shiny DSS removed |
| 18B  | 1 R file (diagnosticPlotsNLLS) | estimate.R stripped to pure computation (~150 lines); sf removed |
| 18C  | 0 | 5 new plot types: simulation, class, ratio, validation, bootstrap |
| 18D  | 0 | Shiny code stripped from scenario files; docs updated; GH issues closed |

**After all four plans:**
- Active R/ files: ~68 (down from 78)
- Exported functions: 15 (unchanged — all features kept)
- Suggests: 5 (down from 8: sf, leaflet, stringi removed)
- eval/parse remaining: 6 (down from 9: 3 Shiny branches in predictScenariosPrep removed)
- estimate.R: ~150 lines (down from ~700)
- controlFileTasksModel.R: ~150 lines (down from ~375)
- No side-effect plotting or file I/O during estimation
- `plot.rsparrow()` supports 8 types (up from 3): residuals, sensitivity, spatial,
  simulation, class, ratio, validation, bootstrap
- Scenario files cleaned of all Shiny coupling
