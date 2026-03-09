# Archived: Dynamic Model Infrastructure

These files implemented the "dynamic" (seasonal/annual time-varying) variant of the
SPARROW model. Dynamic mode performed temporal diagnostic stratification over a single
unified parameter set — users can replicate this by including temporal columns in their
data and subsetting results. The infrastructure was removed in Plan 08 (2026-03-08).

Files archived:

- `diagnosticPlotsNLLS_dyn.R` — Dynamic diagnostic plots (loop over timesteps)
- `checkDynamic.R` — Check if data has dynamic columns (year/season)
- `aggDynamicMapdata.R` — Aggregate map data across time periods
- `setupDynamicMaps.R` — Dynamic map configuration (page layout by year/season)
- `diagnosticPlotsNLLS_timeSeries.R` — Time series diagnostic plots
- `readForecast.R` — Read forecast/dynamic scenario data
- `checkDrainageareaMapPrep.R` — Drainage area map prep with dynamic paging
  (also archived here as it called setupDynamicMaps and was unreachable dead code)
