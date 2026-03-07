<plan id="05A">
<title>Plan 05A: Infrastructure and Map Dead Code Removal</title>
<status>PENDING</status>
<predecessor>Plan 04D (complete)</predecessor>
<successor>Plan 05B</successor>

<goal>
Delete 16 REMOVE-list R files from RSPARROW_master/R/. Before any deletion, replace all
calls to these functions from non-REMOVE files with clean inline equivalents. Result: R CMD
build succeeds, 0 calls to deleted functions remain, DESCRIPTION Collate shrinks by 16 entries.
</goal>

<context>
After Plans 01–04D, 16 REMOVE-list files remain in R/ (classified in docs/reference/FUNCTION_INVENTORY.md).
They fall into three groups by deletion complexity. The make_*.R / makeReport_*.R / create_diagnosticPlotList.R
files are also on the REMOVE list but are entangled with REFACTOR diagnostic files — those are deferred to
Plan 05D. This plan handles only the 16 that are safe to delete once caller sites are fixed.
</context>

<reference_documents>
  <doc>docs/reference/FUNCTION_INVENTORY.md — REMOVE classifications</doc>
  <doc>docs/reference/TECHNICAL_DEBT.md — issue "Pervasive Global State Management" (resolved) and
       "eval(parse(text=...)) Anti-Pattern" (partially resolved)</doc>
  <doc>RSPARROW_master/R/controlFileTasksModel.R — mapping block lines 444–476 to remove</doc>
  <doc>RSPARROW_master/R/startModelRun.R — exitRSPARROW/outputSettings/modelCompare call sites</doc>
</reference_documents>

<files_to_delete>
  <group id="1" label="Infrastructure helpers — fix callers first">
    <file path="RSPARROW_master/R/errorOccurred.R" lines="37">
      Calls exitRSPARROW(); prints error message then terminates. Replace all ~11 call sites
      with stop(paste0("Error in ", scriptName, ". Run execution terminated.")).
      Non-REMOVE callers: readParameters.R, checkData1NavigationVars.R, estimateNLLSmetrics.R,
      checkClassificationVars.R, setNLLSWeights.R, checkAnyMissingSubdataVars.R,
      checkMissingSubdataVars.R, createVerifyReachAttr.R, readForecast.R, readData.R,
      addVars.R, selectParmValues.R.
    </file>
    <file path="RSPARROW_master/R/exitRSPARROW.R" lines="16">
      Calls q() or similar. Replace 1 call site in startModelRun.R (line ~185) with stop().
    </file>
    <file path="RSPARROW_master/R/importCSVcontrol.R" lines="91">
      CSV reader with column-count checking. Has its own eval(parse(strEndMessage)) (COMPLEX).
      Non-REMOVE callers: readParameters.R, read_dataDictionary.R, readDesignMatrix.R,
      syncVarNames.R, addVars.R.
      Replacement: inline data.table::fread() + stop() for column mismatch in each caller.
      The design_matrix.csv branch uses read.csv(..., row.names=1) — preserve this in
      readDesignMatrix.R.
    </file>
    <file path="RSPARROW_master/R/outputSettings.R" lines="56">
      Returns a data.frame of setting name/value pairs from file.output.list.
      Non-REMOVE callers: controlFileTasksModel.R (line 459) inside dead batch-mapping block;
      startModelRun.R (line 464) — allSettings used only in log output.
      Replacement: delete the entire batch-mapping block (lines ~444–475) from
      controlFileTasksModel.R (Windows batch mapping was removed in Plan 04; only the save()
      call to batch.RData remains — also dead). Remove allSettings from startModelRun.R.
    </file>
    <file path="RSPARROW_master/R/modelCompare.R" lines="263">
      File-based model comparison utility. Non-REMOVE callers: startModelRun.R (line 467).
      Replacement: remove the modelCompare() call from startModelRun.R. This is non-core
      functionality with no replacement needed in the CRAN API.
    </file>
  </group>

  <group id="2" label="Settings enumerators — no non-REMOVE callers">
    <note>
      Only outputSettings.R (REMOVE) references these. areColors.R references getSpecialSett
      only in a roxygen @examples line — that line will be cleaned up.
    </note>
    <file path="RSPARROW_master/R/getCharSett.R" lines="67"/>
    <file path="RSPARROW_master/R/getNumSett.R" lines="52"/>
    <file path="RSPARROW_master/R/getOptionSett.R" lines="25"/>
    <file path="RSPARROW_master/R/getShortSett.R" lines="59"/>
    <file path="RSPARROW_master/R/getSpecialSett.R" lines="92"/>
    <file path="RSPARROW_master/R/getYesNoSett.R" lines="43"/>
  </group>

  <group id="3" label="Map/visualization and global-state files — no live non-REMOVE callers">
    <note>
      predictMaps.R is referenced only as a comment ("# predictMaps") in controlFileTasksModel.R
      (line 450) — not a real function call. After the Group 1 batch-mapping block is deleted,
      that comment goes with it.
      unPackList.R is referenced inside a dynamically-constructed string in applyUserModify.R
      (not an actual function call) — that string is cleaned in Plan 05C.
    </note>
    <file path="RSPARROW_master/R/diagnosticMaps.R" lines="768">
      59 eval(parse()) calls. No non-REMOVE callers.
    </file>
    <file path="RSPARROW_master/R/mapSiteAttributes.R" lines="433">
      19 eval(parse()) calls. No non-REMOVE callers.
    </file>
    <file path="RSPARROW_master/R/predictMaps.R" lines="1187">
      15 eval(parse()) calls. Referenced only in now-deleted batch-mapping block.
    </file>
    <file path="RSPARROW_master/R/predictMaps_single.R" lines="320">
      23 eval(parse()) calls. Only caller is predictMaps.R (also REMOVE).
    </file>
    <file path="RSPARROW_master/R/unPackList.R" lines="106">
      Global state injector. Only real callers are REMOVE-list files being deleted here.
      applyUserModify.R reference is inside a string literal (cleaned in Plan 05C).
    </file>
  </group>
</files_to_delete>

<implementation_steps>
  <step n="1" label="Fix errorOccurred callers">
    In each of the 12 non-REMOVE callers, replace:
      errorOccurred("scriptName.R")
    with:
      stop("Error in scriptName.R. Run execution terminated.")
    Remove the roxygen @itemize reference to errorOccurred.R from each file's header.
    Files: readParameters.R, checkData1NavigationVars.R, estimateNLLSmetrics.R (2 sites),
    checkClassificationVars.R (2 sites), setNLLSWeights.R, checkAnyMissingSubdataVars.R,
    checkMissingSubdataVars.R, createVerifyReachAttr.R, readForecast.R, readData.R,
    addVars.R, selectParmValues.R.
  </step>

  <step n="2" label="Fix exitRSPARROW caller">
    In startModelRun.R (~line 185), replace:
      exitRSPARROW()
    with:
      stop("RSPARROW run terminated due to errors.")
    Remove the roxygen reference to exitRSPARROW.R.
  </step>

  <step n="3" label="Inline importCSVcontrol in each caller">
    Each caller passes specific Ctype/NAMES/strEndMessage arguments.
    Replacement pattern (for non-design_matrix callers):
      data &lt;- data.table::fread(file = filein, sep = csv_columnSeparator,
        dec = csv_decimalSeparator, header = TRUE, colClasses = Ctype)
      data &lt;- data[apply(data, 1, function(x) any(!is.na(x))), ]
      names(data) &lt;- NAMES
    For readDesignMatrix.R (design_matrix.csv), use:
      data &lt;- read.csv(filein, header = TRUE, row.names = 1,
        dec = csv_decimalSeparator, sep = csv_columnSeparator)
      data &lt;- as.data.frame(matrix(data[apply(data,1,function(x) any(!is.na(x))),],
        ncol = ncol(data), nrow = nrow(data), dimnames = list(rownames(data), colnames(data))))
    Column mismatch check: replace with stop() if needed (rare edge case, callers can omit).
    Remove roxygen references to importCSVcontrol.R from each caller's header.
    Files to update: readParameters.R, read_dataDictionary.R, readDesignMatrix.R,
    syncVarNames.R, addVars.R.
  </step>

  <step n="4" label="Remove dead mapping block from controlFileTasksModel.R">
    Delete lines ~444–475 (the "Predictions Mapping Options" block):
      if (!is.na(master_map_list[1])) { ... MapPredictRunTime ... }
    This block: creates a batch/ dir, calls outputSettings(), save()s to batch.RData.
    All dead since Windows batch mapping was removed in Plan 04A.
    Keep the MapPredictRunTime timing variable only if it's used in the final runTimes list;
    if so, assign MapPredictRunTime &lt;- proc.time() - proc.time() (zero duration) or remove.
    Remove outputSettings from the roxygen @itemize in controlFileTasksModel.R header.
  </step>

  <step n="5" label="Remove outputSettings and modelCompare from startModelRun.R">
    Remove line ~464:  allSettings &lt;- outputSettings(file.output.list, TRUE)
    Remove line ~467:  modelCompare(file.output.list, compare_models, modelComparison_name, if_spatialAutoCorr)
    Remove any variables from the sparrow_state return that were only used for these calls.
    Remove roxygen references to outputSettings.R and modelCompare.R.
  </step>

  <step n="6" label="Clean areColors.R roxygen">
    Remove the roxygen @examples line in areColors.R that references getSpecialSett.
    (Only reference to get*Sett outside the REMOVE-list files.)
  </step>

  <step n="7" label="Delete all 16 REMOVE-list files">
    Delete in order (Group 2 and 3 have no live callers after steps 1–6):
    Group 1: errorOccurred.R, exitRSPARROW.R, importCSVcontrol.R, outputSettings.R, modelCompare.R
    Group 2: getCharSett.R, getNumSett.R, getOptionSett.R, getShortSett.R, getSpecialSett.R, getYesNoSett.R
    Group 3: diagnosticMaps.R, mapSiteAttributes.R, predictMaps.R, predictMaps_single.R, unPackList.R
  </step>

  <step n="8" label="Update DESCRIPTION Collate">
    Remove all 16 deleted filenames from the Collate field in RSPARROW_master/DESCRIPTION.
    Filenames to remove from Collate (sorted alphabetically as Collate requires):
    areColors.R stays but its getSpecialSett reference is cleaned.
    All 16 deleted .R filenames are removed.
  </step>

  <step n="9" label="Verify build">
    Run: R CMD build --no-build-vignettes RSPARROW_master/
    Run: R CMD check rsparrow_2.1.0.tar.gz --no-vignettes (or devtools::check())
    Expected: 0 new errors. Same pre-existing dep-not-installed warnings.
    Also verify: grep -r "errorOccurred\|exitRSPARROW\|importCSVcontrol\|outputSettings\|modelCompare\|unPackList" R/ returns 0 real function calls.
  </step>
</implementation_steps>

<success_criteria>
  <criterion>R CMD build succeeds with 0 errors</criterion>
  <criterion>16 files deleted from RSPARROW_master/R/</criterion>
  <criterion>0 calls to deleted functions remain in non-REMOVE files (grep confirms)</criterion>
  <criterion>DESCRIPTION Collate has 16 fewer entries</criterion>
  <criterion>R file count: 153 → ~137 in R/ (16 fewer)</criterion>
  <criterion>No new R CMD check errors beyond pre-existing dep-not-installed warnings</criterion>
</success_criteria>

<failure_criteria>
  <criterion>R CMD build fails — indicates missed caller replacement; grep for deleted function names</criterion>
  <criterion>Any test failure in tests/testthat/ — indicates a dependency on deleted behavior</criterion>
  <criterion>R/ still contains any of the 16 target files — check with ls RSPARROW_master/R/ | grep -E "errorOccurred|exitRSPARROW|importCSVcontrol|outputSettings|modelCompare|getCharSett|getNumSett|getOptionSett|getShortSett|getSpecialSett|getYesNoSett|diagnosticMaps|mapSiteAttributes|predictMaps|unPackList"</criterion>
</failure_criteria>

<risks>
  <risk level="low">
    importCSVcontrol has subtle column-trimming and separator-handling logic. Verify the
    inlined replacements handle the csv_columnSeparator / csv_decimalSeparator from
    file.output.list correctly in each caller.
  </risk>
  <risk level="low">
    startModelRun.R may use compare_models / modelComparison_name parameters after modelCompare()
    removal. If so, remove those parameters from startModelRun()'s signature too (they may be
    passed from rsparrow_model() — check and remove if no longer needed).
  </risk>
  <risk level="low">
    diagnosticPlotsNLLS_dyn.R calls unPackList() (line 67). It's a REFACTOR file, not REMOVE.
    This call must be fixed (replace with direct $ extraction) BEFORE unPackList.R is deleted.
    Check: grep -n "unPackList" RSPARROW_master/R/diagnosticPlotsNLLS_dyn.R
    If found, inline the extractions as done in Plan 04C for other files.
  </risk>
</risks>

<notes>
  - modelCompare.R is 263 lines of file-based model comparison (reads prior run CSVs). Not needed
    in the CRAN API; rsparrow_model() returns structured objects for comparison in userland.
  - The batch-mapping block in controlFileTasksModel.R was already dead code (Windows batch mode
    removed in Plan 04A). Its removal also eliminates the only live outputSettings() call.
  - make_*.R / makeReport_*.R / create_diagnosticPlotList.R are also on the REMOVE list but are
    deferred to Plan 05D because they are still called from REFACTOR diagnostic files.
</notes>

</plan>
