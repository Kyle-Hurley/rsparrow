# RSPARROW Manual Reference Index

**Source:** `RSPARROW_master/inst/doc/RSPARROW_docV2.1.Rmd` (8,581 lines)
**Validity:** Manual describes the pre-refactoring v2.1.0 codebase. Validity annotations reflect
post-Plan-05D state (118 R files, `rsparrow_model()` API, 0 GlobalEnv assigns).

**Usage:** Use `Read` with `offset` + `limit` to jump directly to any section.

---

## Section Index

| Lines | Section | Topic | Status |
|-------|---------|-------|--------|
| 26–94 | Ch 1 Introduction | SPARROW overview, static vs dynamic caveats, features | **VALID** |
| 180–480 | Ch 2 Directories | Directory layout, control script execution | OBSOLETE |
| 485–562 | §3.1 data1.csv | Master reach data file; UTF-8 encoding requirement | **VALID** |
| 526–730 | §3.2 dataDictionary.csv | Variable types, sparrowNames — **Table 4 inline below** | **VALID** |
| 731–793 | §3.3 parameters.csv | Parameter file columns — **Table 5 inline below** | **VALID** |
| 794–797 | §3.4 design_matrix.csv | SOURCE × DELIVF interaction binary matrix | **VALID** |
| 798–1017 | §3.5 userModifyData.R | Pre-modeling user calculations; hydseq ordering rules | **VALID** |
| 1021–1430 | §4.1–4.3 Control overview | sparrow_control.R settings crosswalk | OBSOLETE (mechanics); setting *names* useful for control-file lookup |
| 1657–1867 | §4.4.4 Estimation | NLLS spec, convergence tips, parameter bounds, simulation mode | **VALID** |
| 1868–1943 | §4.4.4 Performance | RSQ, RSQ-YIELD, RMSE, bias-correction factor, outlier metrics | **VALID** |
| 1944–2066 | §4.4.4 Diagnostics | Residual plot interpretation, Cook's D, standardized residuals | **VALID** |
| 2090–2260 | §4.4.4 Bootstrap/WNLLS | Parametric Monte Carlo uncertainty; weighted NLLS | **VALID** |
| 2325–2400 | §4.4.5 Spatial diag | classvar, class_landuse, Moran's I | **VALID** |
| 2426–2457 | §4.4.6 Validation | valsites selection methods; validation metrics | **VALID** |
| 2458–2547 | §4.4.7 Prediction types | Prediction variable glossary; conditioned vs unconditioned | **VALID** |
| 2548–2590 | §4.4.7 Units | loadUnits, ConcFactor, ConcUnits, yieldFactor, yieldUnits formulas | **VALID** |
| 4122–4420 | §5.1 data dir | subdata, sitedata, vsitedata, DataMatrix.list schemas | **VALID** |
| 4421–5693 | §5.2 estimate dir | SelParmValues, estimate.list components | **VALID** |
| 5081–5130 | §5.2 sparrowEsts | nlmrt output object structure | **VALID** |
| 5124–5202 | §5.2 JacobResults | Jacobian, oEstimate, oSEj, oTj, VIF, leverage | **VALID** |
| 5176–5262 | §5.2 HessResults | Hessian covariance | **VALID** |
| 5203–5260 | §5.2 Mdiagnostics.list | Obs, predict, Resids, pResids, standardResids, CooksD | **VALID** |
| 5261–5310 | §5.2 ANOVA.list | RSQ, RMSE, SSE, DF, npar, mobs | **VALID** |
| 5690–5943 | §5.3 predict dir | predict.list; bootstrap predictions; BootUncertainties | **VALID** |
| 5989–6152 | §5.4 scenarios dir | predictScenarios.list; DataMatrixScenarios.list | **VALID** |
| 6201–7149 | Ch 6 Tutorial (static TN) | Eight model iterations; scenario evaluation examples | PARTIAL (educational) |
| 7150–7651 | Ch 7 Tutorial (dynamic TP) | Dynamic seasonal/annual model examples | PARTIAL (educational) |
| 7793–8409 | Ch 8 Developer docs | Function types; findCodeStr/executionTree tools | OBSOLETE (205-function pre-refactor codebase) |

---

## Variable Types — Table 4 (lines 564–728)

Defined in `dataDictionary.csv` (`varType` column) and `parameters.csv` (`parmType` column).

| varType | Mathematical role |
|---------|------------------|
| **REQUIRED** | Reach topology enabling load accumulation: `waterid`, `fnode`, `tnode`, `frac`, `iftran`, `demiarea`, `hydseq`, `termflag`, `rchtype`, `calsites` |
| **FIXED** | Additional network/site attributes for full NLLS: `lat`, `lon`, `length`, `meanq` (flow), `rchtot` (time-of-travel), `hload` (hydraulic load), `depvar` (response var), `depvar_se`, `weight`, `staid`, `station_id`, `station_name`, `demtarea`, `headflag`, `target`, `mapping_waterid`, `season`, `year` |
| **SOURCE** | Contaminant sources: `pload_inc += beta_s × source_s × delivery_s`. beta\_s ≥ 0. At least one SOURCE required. |
| **DELIVF** | Land-to-water delivery factors: `delivery = exp(Σ alpha_d × factor_d)`. alpha\_d unconstrained (can be negative). At least one DELIVF must be defined even if not estimated. |
| **STRM** | Stream decay: `transport = exp(−k1 × rchtot)`. k1 ≥ 0. Uses `meanq`, `rchtot`. |
| **RESV** | Reservoir decay: `transport = 1/(1 + k2 × hload)`. k2 ≥ 0. Applies to `rchtype` = 1 or 2. Uses `hload`. |
| **OTHER** | Additional stream/reservoir decay terms; coefficient can be +/−. |
| **OPEN** | Diagnostic/mapping/scenario variables; no direct math role. Subtypes: `LULC_variables`, `CLASS_variables`, `S_source_variables` (prefix "S\_" required for scenario source changes), `valsites` (validation flag). |

Key `sparrowNames` that cannot be renamed (system-reserved):
- `hydseq` — ascending sort key for Fortran load accumulation; must be unique per reach×time period in dynamic models
- `frac` — reach transport fraction [0, 1]; 1 = no diversion
- `iftran` — transport indicator: 0 = no transport (coastal, lake shoreline); 1 = yes
- `rchtype` — 0 = stream, 1 = reservoir internal, 2 = reservoir outlet, 3 = coastal segment
- `depvar` — mean annual load (response variable); must be > 0 at calibration sites
- `target` — terminal reach flag for delivery-to-target calculations
- `mapping_waterid` — unique reach ID excluding time dimension (required for dynamic models)
- `calsites` — calibration site flag: 0 = not selected, 1 = selected; one site per reach allowed

---

## Parameter File Constraints — Table 5 (lines 753–790)

Columns: `sparrowNames`, `description`, `parmUnits`, `parmInit`, `parmMin`, `parmMax`, `parmType`, `parmCorrGroup`

| Condition | Meaning |
|-----------|---------|
| `parmMin = 0` and `parmMax = 0` (or both NA) | Variable **excluded** from estimation |
| `parmInit = parmMin = parmMax` (same non-zero value) | Parameter **fixed** at `parmInit`; not estimated |
| `parmMin < parmMax` | Parameter **estimated** via NLLS; `parmInit` is the starting value |

Sign conventions:
- SOURCE: `parmMin ≥ 0`, large positive `parmMax`
- DELIVF: `parmMin` often negative (e.g., −10000); coefficient can be negative (delivery suppression)
- STRM / RESV: `parmMin ≥ 0` (decay rates must be non-negative)
- OTHER: `parmMin` can be negative

The SOURCE and DELIVF variables in `parameters.csv` must match exactly those listed in `design_matrix.csv`.

---

## Design Matrix — §3.4 (lines 794–797)

`design_matrix.csv`: binary SOURCE × DELIVF matrix.
- Rows = SOURCE variables; columns = DELIVF variables (must match `parameters.csv` exactly)
- Cell = `1`: that DELIVF mediates (interacts with) that SOURCE in the delivery exponent
- Cell = `0`: no interaction — that delivery factor does not affect that source

---

## Prediction Variable Glossary (lines 2477–2514)

| Prefix | Meaning |
|--------|---------|
| `pload_total` | Total load, fully decayed — **unconditioned** (mass-conserving) |
| `mpload_total` | Total load — **conditioned** (observed load substituted at monitoring sites) |
| `pload_nd_*` | Load delivered to streams, no aquatic decay applied |
| `pload_inc` | Incremental load delivered to the reach (half-reach decay applied) |
| `pload_inc_deliv` | Incremental load delivered to terminal `target` reach |
| `deliv_frac` | Fraction of total load delivered to terminal reach (no bias correction applied) |
| `share_total_*` | Source shares of total load (percent) — unconditioned |
| `share_inc_*` | Source shares of incremental load (percent) |

All load/yield predictions corrected for log-retransformation bias via Smearing Estimator
(`mean_exp_weighted_error` in `estimate.list$JacobResults`). Exception: `deliv_frac`.

Conditioned predictions: preferred for load quantification and coefficient estimation.
Unconditioned predictions: preferred for mass balance, source shares, and model skill assessment.

---

## Unit Conversion Formulas (lines 2548–2590)

```
Concentration = load / meanq × ConcFactor
  ConcFactor = 3.170979e-05  (kg/yr, m³/s → mg/L)
  ConcFactor = 0.001143648   (kg/yr, ft³/s → mg/L)

Yield = load / demtarea × yieldFactor
  yieldFactor = 0.01         (kg/km²/yr → Mg/km²/yr, or kg/km²/yr → kg/ha/yr)
  yieldFactor = 0.001        (m³/yr → mm/yr)
```

`yieldFactor = 0.01` is the package default (in `estimate.input.list`).

---

## Quick-Reference Line Jumps

```r
# Use Read with file_path="RSPARROW_master/inst/doc/RSPARROW_docV2.1.Rmd"
Table 4 full content:          offset=564,  limit=165
Table 5 full content:          offset=753,  limit=40
Design matrix §3.4:            offset=794,  limit=5
NLLS estimation settings:      offset=1657, limit=210
Performance metrics:           offset=1868, limit=75
Diagnostic plot guidelines:    offset=1944, limit=80
Bootstrap/WNLLS methods:       offset=2090, limit=170
Prediction variable glossary:  offset=2477, limit=40
Unit conversion formulas:      offset=2548, limit=45
estimate.list / JacobResults:  offset=5081, limit=100
Mdiagnostics.list structure:   offset=5203, limit=60
ANOVA.list structure:          offset=5261, limit=50
predict.list structure:        offset=5690, limit=115
Tutorial Model 6 (final TN):   offset=6513, limit=130
Dynamic tutorial overview:     offset=7150, limit=80
```
