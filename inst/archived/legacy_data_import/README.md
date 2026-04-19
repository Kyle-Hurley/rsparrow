# Archived: Legacy Data Import Pipeline

These files implemented the original data preparation pipeline, which was superseded
by read_sparrow_data() and startModelRun() in Plan 04D (2026). They are preserved
here for reference. Known bugs: calcHeadflag.R (GH #2), checkData1NavigationVars.R (GH #1).

## Files

- **addVars.R** — adds variables to the data dictionary
- **calcHeadflag.R** — computes headwater flags (known cross-index bug, GH #2)
- **checkData1NavigationVars.R** — validates reach network connectivity (boolean condition bug, GH #1)
- **checkDupVarnames.R** — checks for duplicate variable names
- **checkMissingData1Vars.R** — checks for missing data1 variables
- **createInitialDataDictionary.R** — creates initial data dictionary from data1
- **createVerifyReachAttr.R** — computes and verifies reach attributes (hydseq, headflag, termflag, demtarea)
- **dataInputPrep.R** — orchestrates data reading and navigation variable checking
- **replaceData1Names.R** — renames data1 columns using the data dictionary

## Note on call-graph verification (Plan 09)

The original plan listed 12 files in this category. Three were found to be **reachable**
from active code and were NOT archived:

- `calcDemtareaClass.R` — called from `startModelRun.R` (lines 303, 310)
- `calcIncremLandUse.R` — called from `startModelRun.R` (lines 301, 308)
- `startEndmodifySubdata.R` — called from `startModelRun.R` (line 176)
