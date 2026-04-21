<imports_guide>

<current_state label="post-Plan-14">
As of Plan 14 (dependency reduction), rsparrow has 2 Imports and 13 Suggests.

**Imports (2):** nlmrt, numDeriv
**Suggests (13):** car, stringi, ggplot2, gplots, gridExtra, knitr, leaflet, magrittr,
mapview, plotly, rmarkdown, sf, spdep, testthat

Removed packages:
- data.table (was Imports) — CSV I/O replaced with utils::write.csv / utils::read.csv
- plyr (was Suggests) — plyr::ddply replaced with base R aggregate()
- dplyr (was Suggests) — dplyr::sample_n replaced with base R sample()

Replacement patterns applied in Plan 14:
- `plyr::ddply(xx, plyr::.(grp), dplyr::summarize, n = length(grp))`
  → `aggregate(list(n = xx$grp), list(grp = xx$grp), FUN = length)`
- `plyr::ddply(xx, plyr::.(grp), dplyr::summarize, s = sum(col))`
  → `aggregate(list(s = xx$col), list(grp = xx$grp), FUN = sum)`
- `dplyr::sample_n(df, n)`
  → `df[sample(nrow(df), min(n, nrow(df))), , drop = FALSE]`
- `data.table::fwrite(df, file = path, row.names = FALSE, ...)`
  → `utils::write.csv(df, file = path, row.names = FALSE)`
- `data.table::fread(file = path, sep = s, dec = d, ...)`
  → `utils::read.csv(file = path, sep = s, dec = d, ...)`

Files modified in Plan 14:
- R/sumIncremAttributes.R — 2 ddply → aggregate
- R/selectCalibrationSites.R — 2 ddply → aggregate
- R/setNLLSWeights.R — 2 ddply → aggregate
- R/correlationMatrix.R — 3 sample_n → sample(); removed requireNamespace("dplyr")
- R/predictOutCSV.R — 4 fwrite → write.csv
- R/predictBootsOutCSV.R — 2 fwrite → write.csv
- R/predictSummaryOutCSV.R — 1 fwrite → write.csv
- R/predictScenariosOutCSV.R — 6 fwrite → write.csv
- R/createMasterDataDictionary.R — 1 fread + 1 fwrite → read.csv + write.csv
- R/createInitialParameterControls.R — 2 fread + 3 fwrite → read.csv + write.csv
- R/predictScenariosPrep.R — 2 fread + 3 fwrite → read.csv + write.csv
- R/rsparrow-package.R — removed @importFrom data.table lines
- DESCRIPTION — removed data.table from Imports; removed plyr, dplyr from Suggests
- NAMESPACE — regenerated; all importFrom(data.table,...) removed
</current_state>

<historical_context label="Plans 02-03">
This file originally described the process of converting 21 blanket import() statements
to selective importFrom() directives (Plans 02–03). That work is complete. The sections
below are retained for historical reference only.
</historical_context>

<overview>
This guide provides instructions for converting the 21 blanket import() statements in NAMESPACE
to selective importFrom() directives using roxygen2 tags. This is a CRAN best practice that
eliminates namespace conflicts and makes dependencies explicit.
</overview>

<analysis_process>

<step n="1">
<name>Inventory function usage for each package</name>
<instruction>
For each of the 21 packages, search the codebase to identify which specific functions
are actually called in rsparrow code.

Use Grep to search for package-qualified calls:
- `package::function` (explicit qualification)
- Common function names that might come from the package

Generate a list for each package with:
- Function name
- Number of occurrences
- Files where used
</instruction>
</step>

<step n="2">
<name>Categorize packages by usage pattern</name>
<instruction>
Classify each package as:
- CORE: Essential for estimation/prediction (nlmrt, numDeriv)
- PLOTTING: Used for visualization (ggplot2, gplots, gridExtra)
- OPTIONAL: Only for diagnostics/reports (leaflet, mapview, plotly, knitr, rmarkdown)
- REMOVABLE: Replaced with base R (data.table → utils I/O; plyr/dplyr → aggregate/sample)
</instruction>
</step>

</analysis_process>

<conversion_guidelines>

<package name="nlmrt">
<description>NLLS optimizer - CORE dependency</description>
<common_functions>nlfb</common_functions>
<roxygen_pattern>
```r
#' @importFrom nlmrt nlfb
```
</roxygen_pattern>
</package>

<package name="numDeriv">
<description>Numerical derivatives - CORE dependency</description>
<common_functions>hessian, jacobian</common_functions>
<roxygen_pattern>
```r
#' @importFrom numDeriv hessian jacobian
```
</roxygen_pattern>
</package>

<package name="car">
<description>Regression diagnostics - Suggests; guarded with requireNamespace()</description>
<common_functions>scatterplotMatrix</common_functions>
<notes>Used in correlationMatrix.R behind requireNamespace("car") guard.</notes>
</package>

<package name="spdep">
<description>Spatial autocorrelation - Suggests</description>
<common_functions>nb2listw, poly2nb, moran.test, moran.mc</common_functions>
<notes>Used in diagnosticSpatialAutoCorr.R behind requireNamespace("spdep") guard.</notes>
</package>

<packages_removed>
<description>
These packages were removed entirely in Plans 02–14:
</description>
<package name="data.table">Removed Plan 14 — CSV I/O replaced with utils::read.csv / utils::write.csv</package>
<package name="plyr">Removed Plan 14 — plyr::ddply replaced with base R aggregate()</package>
<package name="dplyr">Removed Plan 14 — dplyr::sample_n replaced with base R sample()</package>
<package name="sp">Removed Plan 02 — zero usage found</package>
<package name="stringr">Removed Plan 02 — zero usage found</package>
<package name="leaflet.extras">Removed Plan 02 — zero usage found</package>
<package name="tools">Removed Plan 02 — zero usage found</package>
<package name="markdown">Removed Plan 02 — zero usage found</package>
<package name="methods">Removed Plan 02 — moved from Depends to implicit base</package>
</packages_removed>

</conversion_guidelines>

</imports_guide>
