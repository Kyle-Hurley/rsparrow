# Archived: Mapping, Visualization, and Plotting Helpers

These files implemented spatial mapping functionality and plotting utilities that were
removed from the core package in Plans 05A, 05D, 08, and 09. They are preserved for
reference and potential future use in a separate mapping extension package.

## Mapping/Visualization (Category 2, Plan 09)

- **checkDrainageareaErrors.R** — checks drainage area consistency; called only from archived verifyDemtarea.R
- **g_legend.R** — extracts shared legend from ggplot objects; called only from archived mapLoopStr.R
- **mapBreaks.R** — computes map color break points; called only from archived mapLoopStr.R
- **mapLoopStr.R** — map loop orchestrator with complex eval/parse patterns; no active callers
- **set_unique_breaks.R** — ensures unique break values; called only from archived mapBreaks.R
- **verifyDemtarea.R** — verifies total drainage area; called only from archived createVerifyReachAttr.R

## Plotting Utilities (Category 4, Plan 09)

- **areColors.R** — checks if strings are valid R colors; no active callers
- **makeAESvector.R** — builds ggplot aes vectors; no active callers

## Previously archived (Plan 08, inst/archived/dynamic/)

- **setupDynamicMaps.R** — dynamic model map setup
- **aggDynamicMapdata.R** — dynamic map data aggregation
- **checkDrainageareaMapPrep.R** — map prep for drainage area validation (dynamic references stripped in Plan 08)

## Note on call-graph verification (Plan 09)

The original plan listed 8 files in Category 2 (including checkDrainageareaMapPrep.R already
archived in Plan 08, and checkBinaryMaps.R). Two were found to be reachable or already archived:

- `checkDrainageareaMapPrep.R` — already archived to `inst/archived/dynamic/` in Plan 08
- `checkBinaryMaps.R` — reachable; called directly from active `diagnosticPlotsNLLS.R` (line 77)

The original plan also listed `hline.R` in Category 4. It was found to be reachable:
- `hline.R` — called directly from active `diagnosticPlotsNLLS.R`, `diagnosticPlots_4panel_A.R`,
  and `diagnosticSpatialAutoCorr.R`
