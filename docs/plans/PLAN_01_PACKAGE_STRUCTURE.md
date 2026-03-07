# Plan 01: Package Structure Foundation

## Objective

Get RSPARROW into a state where `R CMD check` can execute at all. This addresses
the mechanical, non-controversial Priority 1 blockers from the CRAN Preparation
Roadmap that don't require architectural decisions or code refactoring. These are
prerequisites for every subsequent task.

## Current State

- 0 of 22 CRAN checklist items pass
- `R CMD check` cannot run successfully against the current package
- Package is structured as a sourced-script workflow, not an installable R package

## Scope

This plan covers **structural cleanup only** — file deletions, DESCRIPTION fixes,
Fortran directive removal, and build configuration. It does NOT cover:
- API design or export decisions (Plan 02)
- Global state elimination (Plan 03)
- Function removal/separation (Plan 04)
- Test suite creation (Plan 05)

---

## Tasks

### Task 1: Remove pre-compiled DLLs from src/

**Why:** CRAN requires source-only packages. Pre-compiled binaries are an instant rejection.

**Action:** Delete these 6 files from `RSPARROW_master/src/`:
- `tnoder.dll`
- `ptnoder.dll`
- `mptnoder.dll`
- `deliv_fraction.dll`
- `sites_incr.dll`
- `sum_atts.dll`

**Risk:** None. CRAN builds binaries from Fortran source during `R CMD INSTALL`.

**Verification:** `ls RSPARROW_master/src/*.dll` returns no results.

---

### Task 2: Remove Windows-specific Fortran directives

**Why:** `!GCC$ ATTRIBUTES DLLEXPORT` is a GCC-specific Windows directive that breaks
compilation on other platforms and is not needed for standard R package builds.

**Action:** Remove the `!GCC$ ATTRIBUTES DLLEXPORT::subroutine_name` line from each
of these 6 Fortran source files in `RSPARROW_master/src/`:
- `tnoder.for`
- `ptnoder.for`
- `mptnoder.for`
- `deliv_fraction.for`
- `sites_incr.for`
- `sum_atts.for`

**Risk:** Low. R's build system handles symbol registration via `useDynLib()` in
NAMESPACE; the DLLEXPORT directive is redundant.

**Verification:** `grep -r "DLLEXPORT" RSPARROW_master/src/` returns no results.

---

### Task 3: Remove runRsparrow.R from R/

**Why:** All files in `R/` must contain only function, method, or class definitions.
`runRsparrow.R` contains top-level executable code: `if(exists(...))` checks,
`dyn.load()` calls, global `options()` modification, and error handler setup.

**Action:** Move `RSPARROW_master/R/runRsparrow.R` to `RSPARROW_master/inst/legacy/runRsparrow.R`.
This preserves the file for reference during future refactoring but removes it from
the package's R/ directory.

**Risk:** None for package structure. The script-based workflow is being replaced by
a proper function-based API in later plans.

**Verification:** File no longer exists in `RSPARROW_master/R/`.

---

### Task 4: Fix DESCRIPTION — Version format

**Why:** CRAN requires `x.y.z` semantic versioning.

**Action:** Change `Version: 2.1` to `Version: 2.1.0` in `RSPARROW_master/DESCRIPTION`.

**Risk:** None.

---

### Task 5: Fix DESCRIPTION — Package name

**Why:** CRAN convention requires lowercase package names without underscores.

**Action:** Change `Package: RSPARROW` to `Package: rsparrow` in `RSPARROW_master/DESCRIPTION`.

**Cascading changes required:**
- Update `useDynLib` entries in NAMESPACE (deferred to Task 10)
- The package directory name (`RSPARROW_master/`) does NOT need to match the package
  name — only the DESCRIPTION `Package:` field matters for CRAN.

**Risk:** Low. This is a metadata-only change at this stage.

---

### Task 6: Fix DESCRIPTION — Maintainer and Authors

**Why:** CRAN requires exactly one maintainer and the modern `Authors@R` format.

**Action:** Replace the current `Author:` and `Maintainer:` fields with:

```
Authors@R: c(
    person("Lillian", "Gorman Sanisaca", email = "lgormansanisaca@usgs.gov",
           role = c("aut", "cre")),
    person("Kyle", "Hurley", email = "khurley@usgs.gov",
           role = "aut"),
    person("Richard", "Alexander", email = "ralex@usgs.gov",
           role = "aut")
)
```

**Decision needed:** Which of the three authors should be `cre` (maintainer)?
Default to Lillian Gorman Sanisaca (listed first in current DESCRIPTION) unless
the user specifies otherwise.

**Risk:** Low. The user may want to adjust the maintainer choice.

---

### Task 7: Fix DESCRIPTION — License

**Why:** DESCRIPTION declares `GPL (>= 2)` but `LICENSE.md` contains a USGS Software
User Rights Notice, which is a public domain dedication, not GPL.

**Action (recommended):** Since USGS software is in the public domain, the most
accurate CRAN-compatible license is:

```
License: CC0
```

Also update `LICENSE.md` to contain the CC0 1.0 Universal text with a note that
this is a U.S. Government work not subject to copyright.

**Alternative:** If GPL is preferred, remove the USGS notice from LICENSE.md and
use `License: GPL (>= 2)`.

**Decision needed:** User must choose between CC0 (public domain, matching USGS
policy) or GPL-2+ (more restrictive but common in R ecosystem). **CC0 is
recommended** as it accurately reflects USGS policy for government-produced software.

**Risk:** Medium — requires understanding of USGS licensing intent. Marking as
a decision point for the user.

---

### Task 8: Remove non-package files from repo

**Why:** These files bloat the package, violate CRAN policies, or serve no purpose
in a proper R package.

**Actions:**
1. **Delete `R-4.4.2.zip`** from repo root (~413 MB bundled R interpreter)
2. **Delete `code.json`** from repo root (extraneous metadata)
3. **Delete `RSPARROW_master/inst/sas/`** directory (legacy SAS scripts: `import_data1.sas`, `output_SAS_labels.sas`)
4. **Delete `RSPARROW_master/batch/`** directory (8 Windows-only batch scripts)
5. **Delete any `Thumbs.db`** files if present

**Risk:** None. These files are not used by the R package.

**Note:** `R-4.4.2.zip` deletion saves ~413 MB. Confirm with user before deleting
in case they use it for other purposes.

---

### Task 9: Create .Rbuildignore

**Why:** Without `.Rbuildignore`, `R CMD build` includes everything in the package
tarball, leading to bloat and potential CRAN rejection.

**Action:** Create `RSPARROW_master/.Rbuildignore` with:

```
^\.gitlab$
^\.claude$
^docs$
^UserTutorial$
^UserTutorialDynamic$
^CRAN_PREPARATION_ROADMAP\.md$
^CLAUDE\.md$
^PLAN_.*\.md$
^LICENSE\.md$
^README\.md$
^code\.json$
^\.Rproj\.user$
^.*\.Rproj$
^batch$
```

**Risk:** None. This only affects what goes into the build tarball.

---

### Task 10: Fix NAMESPACE — useDynLib registration

**Why:** Current NAMESPACE has 6 separate `useDynLib(subroutine_name)` entries,
which is non-standard. CRAN best practice is package-level registration.

**Action:** Replace the 6 individual `useDynLib()` lines:
```
useDynLib(deliv_fraction)
useDynLib(mptnoder)
useDynLib(ptnoder)
useDynLib(sites_incr)
useDynLib(tnoder)
useDynLib(sum_atts)
```

With a single line:
```
useDynLib(rsparrow, .registration = TRUE)
```

Also remove the duplicate `import(spdep)` (appears on lines 6 and 25).

**Note:** Full NAMESPACE rewrite (blanket imports -> importFrom) is deferred to
Plan 02 when the exported API is defined. This task only fixes the DynLib
registration and the duplicate import.

**Risk:** Low. May require adding a `src/init.c` registration file if R CMD check
complains. This can be auto-generated with `tools::package_native_routine_registration_skeleton()`.

---

### Task 11: Add Makevars for Fortran compilation

**Why:** After removing the pre-compiled DLLs and DLLEXPORT directives, we need to
ensure the Fortran source compiles correctly on all platforms via R's build system.

**Action:** Create `RSPARROW_master/src/Makevars` (Unix/macOS) and optionally
`RSPARROW_master/src/Makevars.win` (Windows) if needed. For standard Fortran
compilation, this may not be necessary — R's defaults handle `.for` files. But
verify by running:

```
R CMD INSTALL RSPARROW_master/
```

If Fortran compilation fails, add a Makevars with appropriate FFLAGS.

**Risk:** Low. R handles `.for` files natively. Only needed if non-standard flags
are required.

**Verification:** Fortran subroutines compile without errors on `R CMD INSTALL`.

---

## Execution Order

```
Task 1:  Remove DLLs                          [no dependencies]
Task 2:  Remove DLLEXPORT directives           [no dependencies]
Task 3:  Move runRsparrow.R out of R/          [no dependencies]
Task 4:  Fix Version in DESCRIPTION            [no dependencies]
Task 5:  Fix Package name in DESCRIPTION       [no dependencies]
Task 6:  Fix Authors in DESCRIPTION            [needs user decision on maintainer]
Task 7:  Fix License in DESCRIPTION            [needs user decision on CC0 vs GPL]
Task 8:  Remove non-package files              [needs user confirmation for R-4.4.2.zip]
Task 9:  Create .Rbuildignore                  [no dependencies]
Task 10: Fix NAMESPACE useDynLib               [depends on Task 5 for package name]
Task 11: Verify Fortran compilation            [depends on Tasks 1, 2, 10]
```

Tasks 1-5 and 9 can be executed in parallel (no dependencies, no decisions needed).
Tasks 6, 7, 8 need brief user input.
Tasks 10-11 should be done last as verification.

## Decision Points (Require User Input)

1. **Maintainer choice** (Task 6): Which of the three authors should be the CRAN
   maintainer (role = "cre")? Default: Lillian Gorman Sanisaca.

2. **License choice** (Task 7): CC0 (public domain, matches USGS policy) or
   GPL (>= 2) (more common in R ecosystem)? Recommended: CC0.

3. **R-4.4.2.zip deletion** (Task 8): Confirm this bundled R installer is not
   needed for other purposes before deleting.

## Success Criteria

After completing all 11 tasks:
- [ ] `RSPARROW_master/src/` contains only `.for` files (no `.dll`)
- [ ] No `!GCC$ ATTRIBUTES DLLEXPORT` in any Fortran file
- [ ] No executable code in `RSPARROW_master/R/` (runRsparrow.R removed)
- [ ] `DESCRIPTION` has `Package: rsparrow`, `Version: 2.1.0`, single maintainer in `Authors@R` format, resolved license
- [ ] `.Rbuildignore` exists and excludes non-package files
- [ ] `NAMESPACE` has `useDynLib(rsparrow, .registration = TRUE)` and no duplicate imports
- [ ] `R CMD build RSPARROW_master/` produces a tarball without errors
- [ ] `R CMD check` gets further than it currently does (new errors expected from missing exports, etc. — those are Plan 02)

## What This Does NOT Fix (Deferred)

These remain broken after Plan 01 and are addressed in subsequent plans:
- Zero exported functions (Plan 02: API Design)
- 74 assign(.GlobalEnv) calls (Plan 03: State Elimination)
- 339 eval(parse()) calls (Plan 03: State Elimination)
- 38 bloated Imports (Plan 02: API Design)
- Blanket import() in NAMESPACE (Plan 02: API Design)
- Shiny/GUI code in R/ (Plan 04: Function Separation)
- ~120 non-core functions (Plan 04: Function Separation)
- Missing tests (Plan 05: Test Suite)
- Missing documentation (Plan 02: API Design)
- Windows-only shell.exec() calls (Plan 04: Function Separation — removed with GUI code)
