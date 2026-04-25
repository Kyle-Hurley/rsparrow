# Plan 18A: Archive Dead Code and Shiny DSS

<plan_metadata>
  <id>18A</id>
  <title>Archive Dead Code and Shiny DSS</title>
  <parent>Plan 18: Strip Side Effects and Dead Code from Core Workflow</parent>
  <depends_on>Plans 01–17 (all complete)</depends_on>
  <blocked_by>none</blocked_by>
  <blocks>18B, 18C, 18D</blocks>
</plan_metadata>

## Objective

<objective>
Remove 9 R files with zero active callers from R/ to inst/archived/, move the entire
inst/shiny_dss/ directory to inst/archived/shiny_dss/, remove references to dead functions
from calling code in startModelRun.R and rsparrow_model.R, and drop unused Suggests packages.
After this plan, the package builds and checks clean with fewer files and dependencies.
</objective>

---

## Context

<context>
The following files in R/ have zero active callers in the remaining codebase. Some are
only called by other dead files. The Shiny DSS (25 files) is an interactive dashboard
that is not part of the package API and has never been exported.

**Current file counts:** 78 R files in R/, 25 in inst/shiny_dss/, 8 Suggests packages.
**Target file counts:** 69 R files in R/, 0 in inst/shiny_dss/, 6 Suggests packages.
</context>

---

## Task 1: Archive Dead Utility Files

<task id="18A-1">
  <title>Move 5 dead utility files to inst/archived/utilities/</title>
  <description>
  These files have zero active callers in R/ (confirmed by grep across all .R files).
  Move them to inst/archived/utilities/ (directory already exists from Plan 16B).
  </description>

  <files_to_move>
    <file>
      <source>R/createInitialParameterControls.R</source>
      <destination>inst/archived/utilities/createInitialParameterControls.R</destination>
      <reason>Legacy scaffold tool; zero callers in R/</reason>
    </file>
    <file>
      <source>R/mod_read_utf8.R</source>
      <destination>inst/archived/utilities/mod_read_utf8.R</destination>
      <reason>Zero callers in R/; archival fixes GH #6 NOTE (undeclared stringi)</reason>
    </file>
    <file>
      <source>R/checkFileEncoding.R</source>
      <destination>inst/archived/utilities/checkFileEncoding.R</destination>
      <reason>Only called by mod_read_utf8 (also being archived)</reason>
    </file>
    <file>
      <source>R/createMasterDataDictionary.R</source>
      <destination>inst/archived/utilities/createMasterDataDictionary.R</destination>
      <reason>Guarded by path_results; file I/O only utility with no computation role</reason>
    </file>
    <file>
      <source>R/findMinMaxLatLon.R</source>
      <destination>inst/archived/utilities/findMinMaxLatLon.R</destination>
      <reason>Fills mapping display bounds; no computation role in estimation/prediction</reason>
    </file>
  </files_to_move>

  <subtasks>
    <subtask id="18A-1a">
      Verify inst/archived/utilities/ directory exists (created in Plan 16B).
      If not, create it.
    </subtask>
    <subtask id="18A-1b">
      Use `git mv` to move each file from R/ to inst/archived/utilities/.
    </subtask>
    <subtask id="18A-1c">
      Verify no remaining references to these functions in R/ files (grep for each
      function name across R/*.R). Expected: zero hits after the calling code is
      updated in Task 3.
    </subtask>
  </subtasks>
</task>

---

## Task 2: Archive Dead Diagnostic Helper Files

<task id="18A-2">
  <title>Move 4 dead diagnostic helper files to inst/archived/diagnostics/</title>
  <description>
  These files are either hardcoded to never run, or only feed other dead code.
  Create inst/archived/diagnostics/ directory and move them there.
  </description>

  <files_to_move>
    <file>
      <source>R/correlationMatrix.R</source>
      <destination>inst/archived/diagnostics/correlationMatrix.R</destination>
      <reason>
      Called in startModelRun.R line 318, but guarded by if_corrExplanVars == "yes".
      The default in .minimal_file_output_list() is if_corrExplanVars = "no", and the
      rsparrow_estimate() API hardcodes this to "no". So it never runs in the API path.
      Its output (Cor.ExplanVars.list) is passed through the call chain but always NA.
      </reason>
    </file>
    <file>
      <source>R/calcIncremLandUse.R</source>
      <destination>inst/archived/diagnostics/calcIncremLandUse.R</destination>
      <reason>Only feeds diagnosticPlotsNLLS land-use plots (sitedata.landuse param)</reason>
    </file>
    <file>
      <source>R/sumIncremAttributes.R</source>
      <destination>inst/archived/diagnostics/sumIncremAttributes.R</destination>
      <reason>Only called by calcIncremLandUse and correlationMatrix (both being archived)</reason>
    </file>
    <file>
      <source>R/setNAdf.R</source>
      <destination>inst/archived/diagnostics/setNAdf.R</destination>
      <reason>Only called by calcIncremLandUse (being archived)</reason>
    </file>
  </files_to_move>

  <subtasks>
    <subtask id="18A-2a">
      Create inst/archived/diagnostics/ directory.
    </subtask>
    <subtask id="18A-2b">
      Use `git mv` to move each file.
    </subtask>
  </subtasks>
</task>

---

## Task 3: Archive Shiny DSS

<task id="18A-3">
  <title>Move inst/shiny_dss/ to inst/archived/shiny_dss/</title>
  <description>
  The entire Shiny DSS directory (25 files) is not part of the package API.
  Move the whole directory to inst/archived/shiny_dss/.
  </description>

  <subtasks>
    <subtask id="18A-3a">
      Use `git mv inst/shiny_dss inst/archived/shiny_dss` to move the directory.
    </subtask>
    <subtask id="18A-3b">
      Verify 25 files moved (ls inst/archived/shiny_dss/ | wc -l).
    </subtask>
  </subtasks>
</task>

---

## Task 4: Update startModelRun.R

<task id="18A-4">
  <title>Remove dead function calls from startModelRun.R</title>
  <description>
  Remove all calls to archived functions and their associated variable assignments.
  Replace with stubs (NA values) where the variables are still passed downstream.
  The downstream signature cleanup happens in Plan 18B.
  </description>

  <changes>
    <change id="18A-4a">
      <location>R/startModelRun.R, lines 107–110</location>
      <action>DELETE</action>
      <description>
      Remove the createMasterDataDictionary() call block:
      ```r
      # compile master_dataDictionary (skipped when running in-memory)
      if (!is.null(file.output.list$path_results)) {
        createMasterDataDictionary(file.output.list)
      }
      ```
      </description>
    </change>

    <change id="18A-4b">
      <location>R/startModelRun.R, lines 242–246</location>
      <action>REPLACE</action>
      <description>
      Remove the findMinMaxLatLon() call and replace with stubs:
      ```r
      # OLD (lines 242–246):
      geo_result <- findMinMaxLatLon(sitedata, mapping.input.list)
      sitegeolimits <- geo_result$sitegeolimits
      mapping.input.list <- geo_result$mapping.input.list
      sparrow_state$sitegeolimits <- sitegeolimits

      # NEW:
      sitegeolimits <- NA
      sparrow_state$sitegeolimits <- sitegeolimits
      ```
      Also remove the print message at lines 249–250:
      ```r
      message("Monitoring station latitude and longitude minimums and maximums = ")
      print(unlist(sitegeolimits))
      ```
      </description>
    </change>

    <change id="18A-4c">
      <location>R/startModelRun.R, lines 264–277</location>
      <action>REPLACE</action>
      <description>
      Remove calcIncremLandUse() calls and replace with stubs:
      ```r
      # OLD (lines 264–277):
      if (numsites > 0) {
        sitedata.landuse <- calcIncremLandUse(...)
        sitedata.demtarea.class <- calcDemtareaClass(sitedata$demtarea)
        sparrow_state$sitedata.landuse <- sitedata.landuse
        sparrow_state$sitedata.demtarea.class <- sitedata.demtarea.class
      }
      if (vnumsites > 0) {
        vsitedata.landuse <- calcIncremLandUse(...)
        vsitedata.demtarea.class <- calcDemtareaClass(vsitedata$demtarea)
        sparrow_state$vsitedata.landuse <- vsitedata.landuse
        sparrow_state$vsitedata.demtarea.class <- vsitedata.demtarea.class
      }

      # NEW:
      sitedata.landuse <- NA
      vsitedata.landuse <- NA
      if (numsites > 0) {
        sitedata.demtarea.class <- calcDemtareaClass(sitedata$demtarea)
        sparrow_state$sitedata.demtarea.class <- sitedata.demtarea.class
      }
      if (vnumsites > 0) {
        vsitedata.demtarea.class <- calcDemtareaClass(vsitedata$demtarea)
        sparrow_state$vsitedata.demtarea.class <- vsitedata.demtarea.class
      }
      ```
      NOTE: Keep calcDemtareaClass() — it is NOT dead. It is used by diagnosticSensitivity()
      via class.input.list and sitedata.demtarea.class.
      </description>
    </change>

    <change id="18A-4d">
      <location>R/startModelRun.R, lines 309–321</location>
      <action>REPLACE</action>
      <description>
      Remove correlationMatrix() call and replace with stub:
      ```r
      # OLD (lines 309–321):
      Cor.ExplanVars.list <- NA
      if (if_corrExplanVars == "yes") {
        maxsamples <- 500
        names <- SelParmValues$sparrowNames[SelParmValues$bCorrGroup == 1]
        if (length(names) > 1) {
          message("Running correlations among explanatory variables...")
          Cor.ExplanVars.list <- correlationMatrix(file.output.list, SelParmValues, subdata)
        }
      }

      # NEW:
      Cor.ExplanVars.list <- NA
      ```
      </description>
    </change>

    <change id="18A-4e">
      <location>R/startModelRun.R, lines 386–399</location>
      <action>DELETE</action>
      <description>
      Remove boot/map run-time print messages:
      ```r
      if (if_boot_estimate == "yes") {
        message("Bootstrap estimation run time")
        print(runTimes$BootEstRunTime)
      }
      if (if_boot_predict == "yes") {
        message("Bootstrap prediction run time")
        print(runTimes$BootPredictRunTime)
      }
      if (!is.na(master_map_list[1])) {
        message("Map predictions run time")
        print(runTimes$MapPredictRunTime)
      }
      ```
      </description>
    </change>

    <change id="18A-4f">
      <location>R/startModelRun.R, lines 417–436</location>
      <action>DELETE</action>
      <description>
      Remove the save(shinyArgs, ...) block entirely:
      ```r
      if (!is.null(estimate.list) && !is.null(path_results)) {
        shinyArgs <- named.list(...)
        save(shinyArgs, file = paste0(path_results, ...))
      }
      ```
      </description>
    </change>
  </changes>
</task>

---

## Task 5: Update rsparrow_model.R

<task id="18A-5">
  <title>Remove Shiny params from .minimal_file_output_list()</title>
  <description>
  Remove the two Shiny-only entries from .minimal_file_output_list() in rsparrow_model.R.
  </description>

  <changes>
    <change id="18A-5a">
      <location>R/rsparrow_model.R, inside .minimal_file_output_list() (near end of the list)</location>
      <action>DELETE</action>
      <description>
      Remove these two lines from the list:
      ```r
      enable_ShinyApp         = "no",
      path_shinyBrowser       = NA
      ```
      These are the last two entries in the list (before the closing paren).
      </description>
    </change>
  </changes>
</task>

---

## Task 6: Update DESCRIPTION Suggests

<task id="18A-6">
  <title>Remove leaflet and stringi from Suggests</title>
  <description>
  Remove packages that are only used by archived code.
  </description>

  <changes>
    <change id="18A-6a">
      <location>DESCRIPTION, Suggests field</location>
      <action>DELETE two lines</action>
      <description>
      Remove:
      ```
      leaflet (>= 2.0.3),
      stringi (>= 1.7.0),
      ```
      After removal, Suggests should be (6 packages):
      ```
      Suggests:
          car (>= 3.0-10),
          knitr (>= 1.30),
          rmarkdown (>= 2.5),
          sf (>= 0.9-6),
          spdep (>= 1.1-5),
          testthat (>= 3.0.0)
      ```
      </description>
    </change>
  </changes>
</task>

---

## Task 7: Remove if_corrExplanVars extraction

<task id="18A-7">
  <title>Remove unused variable extraction in startModelRun.R</title>
  <description>
  The variable `if_corrExplanVars` at line 100 of startModelRun.R was only used by
  the correlationMatrix() call block. After Task 4d removes that block, this extraction
  is dead. Remove it.
  </description>

  <changes>
    <change id="18A-7a">
      <location>R/startModelRun.R, line 100</location>
      <action>DELETE</action>
      <description>
      Remove: `if_corrExplanVars <- estimate.input.list$if_corrExplanVars`
      </description>
    </change>
  </changes>
</task>

---

## Verification

<verification>
  <step id="v1">
    <command>R CMD build --no-build-vignettes .</command>
    <expected>Package builds successfully as rsparrow_2.1.0.tar.gz</expected>
  </step>
  <step id="v2">
    <command>R_LIBS=/home/kp/R/libs _R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-build-vignettes --no-manual rsparrow_2.1.0.tar.gz</command>
    <expected>0 errors, 0 warnings (NOTEs may reduce since stringi/leaflet removed from Suggests)</expected>
  </step>
  <step id="v3">
    <command>R_LIBS=/home/kp/R/libs R CMD INSTALL --no-multiarch . && R_LIBS=/home/kp/R/libs Rscript -e "testthat::test_package('rsparrow')"</command>
    <expected>All tests pass (FAIL 0)</expected>
  </step>
  <step id="v4">
    <command>grep -rn "createMasterDataDictionary\|correlationMatrix\|calcIncremLandUse\|findMinMaxLatLon\|sumIncremAttributes\|setNAdf\|checkFileEncoding\|mod_read_utf8\|createInitialParameterControls" R/*.R</command>
    <expected>Zero hits — no remaining references to archived functions in R/</expected>
  </step>
  <step id="v5">
    <command>ls inst/shiny_dss/ 2>/dev/null</command>
    <expected>Directory does not exist (moved to inst/archived/shiny_dss/)</expected>
  </step>
</verification>

---

## Success Criteria

<success_criteria>
  <criterion>9 R files moved from R/ to inst/archived/ (5 utilities + 4 diagnostics)</criterion>
  <criterion>25 Shiny DSS files moved from inst/shiny_dss/ to inst/archived/shiny_dss/</criterion>
  <criterion>startModelRun.R has no calls to archived functions</criterion>
  <criterion>.minimal_file_output_list() has no Shiny params</criterion>
  <criterion>DESCRIPTION Suggests reduced from 8 to 6 packages</criterion>
  <criterion>R CMD check: 0 errors, 0 warnings</criterion>
  <criterion>All tests pass</criterion>
  <criterion>Active R/ file count: 69 (down from 78)</criterion>
</success_criteria>

---

## Important Notes for Implementation

<implementation_notes>
  <note>
  Use `git mv` for all file moves so git tracks the rename history.
  </note>
  <note>
  Do NOT modify controlFileTasksModel.R or estimate.R signatures in this plan.
  They still receive the stub values (Cor.ExplanVars.list = NA, sitedata.landuse = NA, etc.)
  and pass them through. Signature cleanup happens in Plan 18B.
  </note>
  <note>
  The calcDemtareaClass() function is NOT dead — keep it. It creates
  sitedata.demtarea.class which is used by diagnosticSensitivity() and plot.rsparrow().
  </note>
  <note>
  After archiving correlationMatrix.R, the Cor.ExplanVars.list variable becomes permanently
  NA throughout the call chain. Code that checks `!identical(Cor.ExplanVars.list, NA)` will
  simply skip — this is safe.
  </note>
  <note>
  The save(shinyArgs) block at lines 417–436 also references variables like
  map_uncertainties and BootUncertainties (lines 402–412). After removing the save block,
  check whether lines 402–412 are still needed. They load BootUncertainties from disk and
  store them in sparrow_state. If nothing downstream uses sparrow_state$map_uncertainties
  or sparrow_state$BootUncertainties, remove lines 402–412 as well.
  </note>
  <note>
  Commit message convention: `Co-Authored-By: Claude` (no email, no angle brackets).
  </note>
</implementation_notes>
