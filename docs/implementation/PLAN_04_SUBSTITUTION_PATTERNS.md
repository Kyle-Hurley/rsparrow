<substitution_patterns>
<overview>
Four antipatterns must be eliminated from the core execution path. Each has a canonical
replacement. Apply these patterns consistently across all affected files in Plan 04.
</overview>

<subplan_map label="Which sub-plan uses which pattern">
  Plan 04-A  (tasks 1-3): global_assign (after_option_1 accumulator), batch_mode_removal  [COMPLETE]
  Plan 04-B  (tasks 4-5): global_assign (after_option_2 explicit return), specification_string  [COMPLETE]
  Plan 04-C  (tasks 6-7): unpack_list, dynamic_column  [PENDING]
  Plan 04-D  (tasks 8-13): no antipattern removal — skeleton implementations only  [PENDING]
</subplan_map>

<pattern name="global_assign" cran_blocker="yes" status="RESOLVED">
<problem>
assign("x", value, envir = .GlobalEnv) pollutes the global namespace, prevents concurrent
model runs, and is rejected by CRAN reviewers. All 51 occurrences eliminated: 28 in Plan 04A
(startModelRun.R + controlFileTasksModel.R), 23 in Plan 04B (13 remaining files). Zero remain.
</problem>
<before>
```r
result <- compute_something(data)
assign("result", result, envir = .GlobalEnv)
```
</before>
<after_option_1 label="accumulator list (for startModelRun.R)">
```r
# At function start:
sparrow_state <- list()

# Replace each assign:
result <- compute_something(data)
sparrow_state$result <- result   # was: assign("result", result, envir = .GlobalEnv)

# At function end:
return(sparrow_state)
```
</after_option_1>
<after_option_2 label="explicit return value (for single-assign functions)">
```r
# Function now returns the value instead of side-effecting
compute_and_return <- function(...) {
  result <- compute_something(data)
  result   # return explicitly; caller captures it
}

# Caller site:
result <- compute_and_return(...)   # was: compute_and_return(...); use result from GlobalEnv
```
</after_option_2>
<call_site_discovery>
Before changing any function signature, find all callers:
  grep -r "functionName(" RSPARROW_master/R/
REMOVE-classified files (Plan 05 deletion list) will call old signatures — acceptable,
they will be deleted before CRAN submission.
</call_site_discovery>
<files_priority>
  startModelRun.R (27 assigns) — use accumulator list pattern
  findMinMaxLatLon.R (4)       — return named list; caller unpacks
  estimate.R (4)               — include in estimate.list return value
  checkDrainageareaMapPrep.R (2), dataInputPrep.R (2), predictBootstraps.R (2),
  predictScenarios.R (2)       — return as named list elements
  correlationMatrix.R (1), diagnosticSensitivity.R (1), estimateBootstraps.R (1),
  estimateWeightedErrors.R (1), predict.R (1), replaceData1Names.R (1),
  setNLLSWeights.R (1), controlFileTasksModel.R (1) — return value directly
</files_priority>
</pattern>

<pattern name="unpack_list" cran_blocker="no" priority="high">
<problem>
unPackList() injects variables into parent.frame() via assign(). This makes data flow
invisible — variables appear without being passed as arguments. 125 occurrences in 75 files.
Not a direct CRAN blocker, but prevents unit testing and reasoning about state.
</problem>
<before>
```r
myFunction <- function(DataMatrix.list, SelParmValues, estimate.input.list) {
  unPackList(
    lists = list(
      data.index.list     = DataMatrix.list$data.index.list,
      SelParmValues       = SelParmValues,
      estimate.input.list = estimate.input.list
    ),
    parentObj = list(NA, NA, NA)
  )
  # ... now uses jstaid, jfnode, ifHess etc. as bare names
  x <- data[, jstaid]
  if (ifHess == "yes") { ... }
}
```
</before>
<after>
```r
myFunction <- function(DataMatrix.list, SelParmValues, estimate.input.list) {
  # Access list elements directly — no unPackList needed
  data.index.list <- DataMatrix.list$data.index.list

  x <- data[, data.index.list$jstaid]
  if (estimate.input.list$ifHess == "yes") { ... }
}
```
</after>
<data_index_list_note>
data.index.list contains ~20 column index variables (jstaid, jfnode, jtnode, jdepvar,
jiftran, jsrcvar, jbsrcvar, jdlvvar, jbdlvvar, jresvar, jbresvar, jdecvar, jbdecvar,
jfrac, jstaidseq, jcalsites, jload, jdepvar, etc.).
Do NOT add these as 20 individual function parameters — that creates unwieldy signatures.
Instead accept data.index.list as one argument and use data.index.list$jstaid throughout.
</data_index_list_note>
<file_list_lists_pattern>
unPackList is called with either:
  parentObj = list(NA)           → unpacking a plain list (use list$element directly)
  parentObj = list(data_frame)   → unpacking columns of a data.frame (use df[[colname]])
Check the parentObj argument to determine which replacement to use.
</file_list_lists_pattern>
</pattern>

<pattern name="specification_string" cran_blocker="no" priority="high" status="RESOLVED">
<problem>
Three model specification strings (always the same SPARROW standard expressions) were stored
as character strings and eval(parse())'d at runtime inside the NLLS objective function.
All 21 occurrences inlined in Plan 04B. Spec-string variables removed from settings
infrastructure (getCharSett.R, getShortSett.R, estimateOptimize.R).
</problem>
<strings_and_replacements>
```r
# reach_decay_specification = "exp(-data[,jdecvar[i]] * beta1[,jbdecvar[i]])"
# BEFORE:
rchdcayf[, 1] <- rchdcayf[, 1] * eval(parse(text = reach_decay_specification))
# AFTER:
rchdcayf[, 1] <- rchdcayf[, 1] * exp(-data[, jdecvar[i]] * beta1[, jbdecvar[i]])

# reservoir_decay_specification = "(1 / (1 + data[,jresvar[i]] * beta1[,jbresvar[i]]))"
# BEFORE:
resdcayf[, 1] <- resdcayf[, 1] * eval(parse(text = reservoir_decay_specification))
# AFTER:
resdcayf[, 1] <- resdcayf[, 1] * (1 / (1 + data[, jresvar[i]] * beta1[, jbresvar[i]]))

# incr_delivery_specification = "exp(ddliv1 %*% t(dlvdsgn))"
# BEFORE:
ddliv2 <- eval(parse(text = incr_delivery_specification))
# AFTER:
ddliv2 <- exp(ddliv1 %*% t(dlvdsgn))
```
</strings_and_replacements>
<affected_files>
  estimateFeval.R, estimateFevalNoadj.R, validateFevalNoadj.R  (3 occurrences each)
  predict.R, predictBoot.R, predictSensitivity.R, predictScenarios.R (3 each)
  Total: 21 eval(parse()) calls replaced by inlined expressions
</affected_files>
<cleanup_after>
Once all 21 occurrences are replaced:
1. Remove the three variable names from getCharSett.R's settings list
2. Remove from getShortSett.R's settings list
3. Remove the three lines in estimateOptimize.R (~lines 111-113) that copy these into
   sparrowEsts (they are no longer passed through estimate.input.list)
4. Grep to confirm no remaining references:
   grep -r "reach_decay_specification\|reservoir_decay_specification\|incr_delivery_specification" RSPARROW_master/R/
</cleanup_after>
<rationale>
These specification strings are NOT user-configurable in practice — they represent the
SPARROW standard mathematical forms (exponential reach decay, first-order reservoir decay,
matrix exponential delivery). Users who need different forms must fork the package code.
The strings appear in getCharSett.R only because legacy control files could technically
override them; no published SPARROW application has done so.
</rationale>
</pattern>

<pattern name="dynamic_column" cran_blocker="no" priority="high">
<problem>
Dynamic data frame column access via eval(parse(text=paste0("df$",varname))) is the most
common eval/parse usage. The equivalent in base R is simply df[[varname]].
</problem>
<before>
```r
# Various forms found in the codebase:
eval(parse(text = paste0("subdata$", varname)))
eval(parse(text = paste0("data1$", colname)))
eval(parse(text = paste0(settname, "<-input$`", settname, "`")))
eval(parse(text = paste0("betavalues$", parmname)))
```
</before>
<after>
```r
subdata[[varname]]
data1[[colname]]
invalue[[settname]] <- input[[settname]]      # assignment form
betavalues[[parmname]]
```
</after>
<files_with_dynamic_column_access>
  createDataMatrix.R (7), applyUserModify.R (6), readForecast.R (6),
  checkData1NavigationVars.R (4), checkingMissingVars.R (4), importCSVcontrol.R (2),
  readParameters.R (2), createSubdataSorted.R (2), verifyDemtarea.R (2),
  createVerifyReachAttr.R (2), accumulateIncrArea.R (2), estimateNLLSmetrics.R (2),
  estimateNLLStable.R (1), estimateOptimize.R (1), correlationMatrix.R (4),
  naOmitFuncStr.R (1), replaceNAs.R (1), replaceData1Names.R (1), setNAdf.R (1)
</files_with_dynamic_column_access>
<warning>
Some eval(parse()) in the codebase involve more complex expressions than simple column
access (e.g. multi-statement blocks in applyUserModify.R for user-defined modifications).
These require case-by-case analysis. Check the full expression before replacing.
</warning>
</pattern>

<pattern name="batch_mode_removal" cran_blocker="yes" priority="critical" status="RESOLVED">
<problem>
batch_mode=="yes" branches existed throughout the core execution chain to write duplicate
messages to Windows log files. All removed in Plan 04A Task 1 from non-REMOVE files.
Remaining batch_mode references exist only in REMOVE-list files (Plan 05 deletes them).
</problem>
<actions>
1. Remove batch_mode from startModelRun() and controlFileTasksModel() signatures.
2. Search all remaining R/ files: grep -r "batch_mode" RSPARROW_master/R/
3. For each file: delete the if (batch_mode == "yes") { cat(...) } blocks entirely.
4. Remove batch_mode from all function call sites within the package.
</actions>
<affected_files>
startModelRun.R, controlFileTasksModel.R, and ~15 additional files that accept batch_mode
as a parameter and pass it through. Removing from startModelRun() cascades automatically
once callers are updated.
</affected_files>
</pattern>

</substitution_patterns>
