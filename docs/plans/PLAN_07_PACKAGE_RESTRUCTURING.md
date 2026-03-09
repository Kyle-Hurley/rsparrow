<plan id="07" label="Package Restructuring" status="complete" completed="2026-03-08" commit="e5b58b4">

<objective>
Move the package root from RSPARROW_master/ to the repo root, delete compiled .o/.so artifacts
from src/, and remove the Collate field from DESCRIPTION. After this plan every subsequent plan
works from the standard package layout that devtools, roxygen2, usethis, and CRAN tooling expect.
</objective>

<context>
The package has lived in RSPARROW_master/ since before the refactor. This forces every R CMD
command to specify a subdirectory, breaks devtools::install()/check()/document() defaults, and
confuses CRAN tooling. Additionally, six compiled object files (.o) and a shared library (.so)
were left in src/ after building — CRAN requires source-only packages and will reject any tarball
containing pre-compiled binaries. Finally, the Collate field in DESCRIPTION lists all 118 R files
by name; it is unnecessary for an S3 package with no load-order dependencies, creates a
maintenance burden on every file rename, and will draw CRAN reviewer questions.

All three issues are mechanical and low-risk. They must be done together, and they must be done
before Plans 08–12, because every subsequent plan references file paths and build commands that
assume the package is at the repo root.
</context>

<gh_issues>GH #10, #11, #12</gh_issues>

<reference_documents>
  docs/plans/CRAN_ROADMAP.md — priority 1 blockers B1, B2, B3, B10
  RSPARROW_master/DESCRIPTION — Collate field to remove; paths to update
  RSPARROW_master/.Rbuildignore — verify exists and is correct after move
  Makefile — all targets reference RSPARROW_master/; must be updated
  scripts/renv.sh — R_LIBS path; any RSPARROW_master references must be updated
  CLAUDE.md — commands section references RSPARROW_master/; update after move
</reference_documents>

<tasks>

<task id="07-1" status="done">
<subject>Inventory all RSPARROW_master/ path references outside the package tree</subject>
<description>
Before moving anything, identify every file outside RSPARROW_master/ that contains a hard-coded
reference to the old subdirectory path. These must all be updated after the move.

Search targets:
  grep -r "RSPARROW_master" --include="*.R" --include="*.md" --include="*.sh" \
       --include="Makefile" --include="*.Rmd" .

Expected locations:
  - Makefile (build/check/install/test/document targets)
  - scripts/renv.sh (if it sets R_LIBS or changes directory)
  - docs/ (plan documents, CLAUDE.md — documentation only, not broken by move)
  - walkthrough.R (if it exists at repo root)
  - Any .github/workflows/*.yml (CI configuration)

Create a plain-text list of every file:line that needs updating. Document it in the commit
message so the change is auditable.

This task is read-only — do not modify any files yet.
</description>
<files_modified>None — inventory only</files_modified>
<success_criteria>
  - Complete list of external RSPARROW_master/ references recorded
  - Distinction between files that will break (Makefile, scripts) vs. documentation-only
    references that are stale but not load-bearing
</success_criteria>
</task>

<task id="07-2" status="done">
<subject>Delete compiled .o and .so artifacts from src/</subject>
<description>
Delete the seven compiled artifacts from RSPARROW_master/src/. These were generated during a
previous R CMD INSTALL and must not be distributed. The .f Fortran source files remain and will
be recompiled automatically by R CMD INSTALL.

Files to delete:
  RSPARROW_master/src/deliv_fraction.o
  RSPARROW_master/src/mptnoder.o
  RSPARROW_master/src/ptnoder.o
  RSPARROW_master/src/sites_incr.o
  RSPARROW_master/src/sum_atts.o
  RSPARROW_master/src/tnoder.o
  RSPARROW_master/src/rsparrow.so

Verify after deletion:
  ls RSPARROW_master/src/
  # Expected: only *.f files remain

This can be done before the directory move (it is independent). Doing it early ensures the move
does not carry these artifacts along and that git does not track them going forward.

Add src/*.o and src/*.so to .gitignore at the repo root (or at RSPARROW_master/ level, whichever
will become the canonical location after the move — do this at both levels to be safe).
</description>
<files_modified>
  DELETE: RSPARROW_master/src/deliv_fraction.o
  DELETE: RSPARROW_master/src/mptnoder.o
  DELETE: RSPARROW_master/src/ptnoder.o
  DELETE: RSPARROW_master/src/sites_incr.o
  DELETE: RSPARROW_master/src/sum_atts.o
  DELETE: RSPARROW_master/src/tnoder.o
  DELETE: RSPARROW_master/src/rsparrow.so
  EDIT: .gitignore (add src/*.o, src/*.so, src/*.so.dSYM)
</files_modified>
<success_criteria>
  - ls RSPARROW_master/src/ shows only *.f files
  - .gitignore prevents future accidental commit of compiled artifacts
</success_criteria>
</task>

<task id="07-3" status="done">
<subject>Remove Collate field from DESCRIPTION</subject>
<description>
Remove the entire Collate: section from RSPARROW_master/DESCRIPTION. R loads all files in R/
in alphabetical order by default. The Collate field is only needed for S4 class hierarchies where
one class definition must load before another. rsparrow is an S3 package with no such dependency.

The Collate field currently spans many lines listing all 118 R source files. Its removal:
  - Eliminates a CRAN reviewer question about its purpose
  - Removes the maintenance burden of updating it on every file add/remove/rename
  - Plans 08 and 09 will remove many R files; without Collate removal those plans each require
    updating DESCRIPTION as an additional step

Implementation: Remove all lines from "Collate:" through the last quoted filename. The line
immediately following (typically blank or the next DESCRIPTION field) must be preserved.

After removal, verify DESCRIPTION is still valid:
  R CMD build --no-build-vignettes RSPARROW_master/
  # Should succeed and produce rsparrow_2.1.0.tar.gz

Do NOT update Config/testthat/edition or any other field at this time. Only the Collate section.
</description>
<files_modified>EDIT: RSPARROW_master/DESCRIPTION (remove Collate section)</files_modified>
<success_criteria>
  - DESCRIPTION contains no Collate: field
  - R CMD build succeeds after removal
  - R CMD check produces no new errors or warnings
</success_criteria>
</task>

<task id="07-4" status="done">
<subject>Move package contents from RSPARROW_master/ to repo root</subject>
<description>
Move all package-constituting files and directories from RSPARROW_master/ to the repo root.
Use `git mv` for each to preserve history.

Directories and files to move:
  git mv RSPARROW_master/R           R
  git mv RSPARROW_master/src         src
  git mv RSPARROW_master/man         man
  git mv RSPARROW_master/tests       tests
  git mv RSPARROW_master/inst        inst
  git mv RSPARROW_master/DESCRIPTION DESCRIPTION
  git mv RSPARROW_master/NAMESPACE   NAMESPACE
  git mv RSPARROW_master/.Rbuildignore .Rbuildignore   (if present)

After the moves, RSPARROW_master/ should be empty or contain only non-package files. Verify:
  ls RSPARROW_master/
  # Expected: nothing, or only files that were explicitly left behind (none expected)

Then remove the now-empty directory:
  rmdir RSPARROW_master/    # only if truly empty; use rm -rf if git leaves hidden files

Note: UserTutorial/ and UserTutorialDynamic/ are currently outside RSPARROW_master/ at the
repo root. They stay where they are (or are explicitly moved to a separate location). They
must not end up inside the package tree.
</description>
<files_modified>
  git mv: RSPARROW_master/R -> R/
  git mv: RSPARROW_master/src -> src/
  git mv: RSPARROW_master/man -> man/
  git mv: RSPARROW_master/tests -> tests/
  git mv: RSPARROW_master/inst -> inst/
  git mv: RSPARROW_master/DESCRIPTION -> DESCRIPTION
  git mv: RSPARROW_master/NAMESPACE -> NAMESPACE
  DELETE: RSPARROW_master/ (directory)
</files_modified>
<success_criteria>
  - RSPARROW_master/ directory no longer exists
  - R/, src/, man/, tests/, inst/, DESCRIPTION, NAMESPACE all exist at repo root
  - git log --follow R/estimate.R shows full history preserved
</success_criteria>
</task>

<task id="07-5" status="done">
<subject>Create and verify .Rbuildignore at repo root</subject>
<description>
After the move, the repo root contains non-package directories that R CMD build must not include
in the tarball: docs/, scripts/, UserTutorial/, UserTutorialDynamic/, Makefile, CLAUDE.md,
walkthrough.R, and any other non-package files.

Create or update .Rbuildignore at the repo root with the following exclusion patterns:

  ^docs$
  ^scripts$
  ^UserTutorial$
  ^UserTutorialDynamic$
  ^Makefile$
  ^CLAUDE.md$
  ^walkthrough\.R$
  ^\.github$
  ^.*\.tar\.gz$
  ^.*\.Rcheck$

Patterns use ERE (extended regular expressions anchored to the package root). Each line is
anchored with ^ and $ as required by R CMD build.

Verify by running:
  R CMD build --no-build-vignettes .
  tar tzf rsparrow_2.1.0.tar.gz | grep -v "^rsparrow/"
  # Expected: no output (only package contents in tarball)

Also check that inst/legacy/, inst/shiny_dss/, inst/archived/ (created in Plans 08/09) are NOT
in .Rbuildignore — inst/ subdirectories ARE included in the tarball by design. Only root-level
non-package directories need exclusion.
</description>
<files_modified>CREATE or EDIT: .Rbuildignore</files_modified>
<success_criteria>
  - R CMD build produces a tarball that contains only standard package files
  - docs/, scripts/, UserTutorial*/ are NOT in the tarball
  - inst/ contents (legacy, shiny_dss) ARE in the tarball
  - No new R CMD check warnings related to non-package files
</success_criteria>
</task>

<task id="07-6" status="done">
<subject>Update Makefile, scripts/, and CLAUDE.md for new package root</subject>
<description>
Update all files identified in Task 07-1 that contain hard-coded RSPARROW_master/ references.

Makefile — update every target:
  OLD: R CMD build --no-build-vignettes RSPARROW_master/
  NEW: R CMD build --no-build-vignettes .

  OLD: R CMD check --no-build-vignettes RSPARROW_master/
  NEW: R CMD check --no-build-vignettes rsparrow_2.1.0.tar.gz
       (or: R CMD check --as-cran rsparrow_2.1.0.tar.gz)

  OLD: R CMD INSTALL --no-multiarch RSPARROW_master/
  NEW: R CMD INSTALL --no-multiarch .

  OLD: roxygen2::roxygenise('RSPARROW_master/')
  NEW: roxygen2::roxygenise('.')

  OLD: testthat::test_package('rsparrow') (may already be correct)
       testthat::test_file('RSPARROW_master/tests/testthat/<file>.R')
  NEW: testthat::test_file('tests/testthat/<file>.R')

scripts/renv.sh — remove any `cd RSPARROW_master` or path manipulations.

CLAUDE.md — update the commands section. This is documentation; update for accuracy but the
package will work regardless of what CLAUDE.md says.

walkthrough.R — if it sets path_main or similar to RSPARROW_master/, update those paths.

After updates, run the full build+check sequence from repo root:
  source scripts/renv.sh
  R CMD build --no-build-vignettes .
  R_LIBS=/home/kp/R/libs _R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-build-vignettes rsparrow_2.1.0.tar.gz

Expected baseline: same 4 WARNINGs and 3 NOTEs as Plan 06F (no regressions). WARNINGs and NOTEs
from the pre-existing issues tracked in GH #5, #6, #7 are expected and are addressed in Plans 11/12.
</description>
<files_modified>
  EDIT: Makefile
  EDIT: scripts/renv.sh (if applicable)
  EDIT: CLAUDE.md (commands section)
  EDIT: walkthrough.R (if applicable)
</files_modified>
<success_criteria>
  - `make build` runs successfully from repo root
  - `make check` runs successfully from repo root with no new errors
  - `make test` runs all 98 tests with 0 failures
  - No remaining RSPARROW_master/ references in load-bearing files (Makefile, scripts/)
</success_criteria>
</task>

<task id="07-7" status="done">
<subject>Verify R CMD check baseline after restructuring</subject>
<description>
Run the full R CMD check suite from the new package root to confirm no regressions were
introduced by the restructuring.

Commands:
  source scripts/renv.sh
  R CMD build --no-build-vignettes .
  R_LIBS=/home/kp/R/libs _R_CHECK_FORCE_SUGGESTS_=false \
    R CMD check --no-build-vignettes rsparrow_2.1.0.tar.gz

Also run the test suite directly:
  R_LIBS=/home/kp/R/libs R CMD INSTALL --no-multiarch .
  R_LIBS=/home/kp/R/libs Rscript -e "testthat::test_package('rsparrow')"

Expected results (same as Plan 06F baseline):
  - 0 ERRORs
  - 4 WARNINGs (pre-existing: Rd codoc, stringi/xfun, layout(), predictSensitivity)
  - 3 NOTEs (pre-existing)
  - 98 tests pass, 0 failures

If any new ERROR or WARNING appears, it must be investigated and resolved before committing.
New NOTEs related to the moved package structure (e.g., "package root is not the repository root"
NOTE disappearing) are expected and welcome.

Close GH issues #10, #11, #12 after the final check passes.
</description>
<files_modified>None — verification only</files_modified>
<success_criteria>
  - 0 ERRORs
  - No new WARNINGs beyond the 4 pre-existing ones
  - 98 tests pass
  - GH #10, #11, #12 closed
</success_criteria>
</task>

</tasks>

<success_criteria>
<criterion status="met">RSPARROW_master/ directory does not exist in the repo</criterion>
<criterion status="met">R/, src/, man/, tests/, inst/, DESCRIPTION, NAMESPACE at repo root</criterion>
<criterion status="met">src/ contains only *.f Fortran source files (no .o, .so)</criterion>
<criterion status="met">DESCRIPTION has no Collate: field</criterion>
<criterion status="met">.Rbuildignore at repo root excludes docs/, scripts/, UserTutorial*/, Makefile</criterion>
<criterion status="met">R CMD build . produces rsparrow_2.1.0.tar.gz with correct contents</criterion>
<criterion status="met">R CMD check produces 0 ERRORs, same 4 WARNINGs; 4 NOTEs (3 pre-existing + 1 pre-existing
  inst/doc/figures NOTE previously masked by source-dir check method)</criterion>
<criterion status="met">Test suite: FAIL 0 | PASS 194 | SKIP 1 (0 regressions)</criterion>
<criterion status="met">GH #10, #11, #12 closed</criterion>
</success_criteria>

<failure_criteria>
<criterion>R CMD build fails after the move — indicates a broken path reference</criterion>
<criterion>Any compiled artifact (.o, .so) in the tarball</criterion>
<criterion>New R CMD check ERROR introduced by the move</criterion>
<criterion>Any test regression (fewer than 98 passing)</criterion>
</failure_criteria>

<risks>
<risk level="low">
  git mv may not preserve the working-tree state correctly on some systems. Verify with
  `git status` that all moves show as renamed (not deleted+added) to preserve history.
</risk>
<risk level="low">
  .Rbuildignore patterns use ERE anchored at the package root. A pattern without ^ will
  exclude files in subdirectories too. Test carefully with tar tzf after building.
</risk>
<risk level="low">
  If any test fixture uses an absolute path containing RSPARROW_master/, those tests will
  fail after the move. Search tests/testthat/ for any hardcoded paths before moving.
</risk>
</risks>

<notes>
- Tasks 07-2 and 07-3 (delete compiled artifacts; remove Collate) are independent and can be
  done before the directory move if that simplifies the git history.
- All subsequent plans (08–12) assume the package is at the repo root. If this plan is not
  completed first, all file paths in those plans will be wrong.
- The UserTutorial/ and UserTutorialDynamic/ directories at repo root are not part of the
  package and need no action in this plan. They are excluded from the tarball via .Rbuildignore.
- inst/legacy/, inst/shiny_dss/ are intentionally included in the package (inst/ is always
  installed). They do not need .Rbuildignore entries.
</notes>

</plan>
