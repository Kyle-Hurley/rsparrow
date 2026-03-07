<imports_guide>

<overview>
This guide provides instructions for converting the 21 blanket import() statements in NAMESPACE
to selective importFrom() directives using roxygen2 tags. This is a CRAN best practice that
eliminates namespace conflicts and makes dependencies explicit.
</overview>

<current_state>
<imports>
The current NAMESPACE (post-Plan 02) contains 21 blanket import() statements:
car, data.table, dplyr, ggplot2, gplots, gridExtra, knitr, leaflet, leaflet.extras,
magrittr, mapview, markdown, nlmrt, numDeriv, plotly, plyr, rmarkdown, sf, sp, spdep,
stringr, tools
</imports>

<problem>
Blanket imports bring in ALL functions from a package, causing:
- Namespace conflicts (multiple packages with same function names)
- Unclear dependencies (which functions are actually used?)
- R CMD check warnings about non-selective imports
</problem>
</current_state>

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

<example>
```bash
# Example: Search for data.table functions
grep -r "data.table(" RSPARROW_master/R/
grep -r "setDT(" RSPARROW_master/R/
grep -r ":=" RSPARROW_master/R/
grep -r "setnames(" RSPARROW_master/R/
```

Expected output:
```
data.table: 89 occurrences across 45 files
setDT: 12 occurrences across 8 files
:= (assignment): 45 occurrences across 23 files
setnames: 8 occurrences across 6 files
.N: 15 occurrences
.SD: 7 occurrences
```
</example>
</step>

<step n="2">
<name>Categorize packages by usage pattern</name>
<instruction>
Classify each package as:
- CORE: Essential for estimation/prediction (nlmrt, numDeriv, data.table, sf, spdep)
- PLOTTING: Used for visualization (ggplot2, gplots, gridExtra)
- OPTIONAL: Only for diagnostics/reports (leaflet, mapview, plotly, markdown, knitr, rmarkdown)
- UTILITY: Data manipulation (dplyr, stringr, magrittr, plyr)
- REMOVABLE: Only used in code marked for deletion in Plan 05
</instruction>
</step>

<step n="3">
<name>Identify conflicts</name>
<instruction>
Check for function name conflicts between packages. Common conflicts:
- filter() in dplyr vs stats
- select() in dplyr vs MASS
- lag() in dplyr vs stats

Document any conflicts found and note which package's version is currently used.
</instruction>
</step>

</analysis_process>

<conversion_guidelines>

<package name="data.table">
<description>Heavy usage throughout codebase for data manipulation</description>
<common_functions>
data.table, setDT, :=, setnames, .N, .SD, .I, .GRP, setkey, setorder, rbindlist, fread
</common_functions>
<roxygen_pattern>
```r
#' @importFrom data.table data.table
#' @importFrom data.table setDT
#' @importFrom data.table :=
#' @importFrom data.table setnames
#' @importFrom data.table .N
#' @importFrom data.table .SD
#' @importFrom data.table .I
```
</roxygen_pattern>
<notes>
The := operator and .N/.SD/.I special symbols MUST be imported explicitly.
Use separate @importFrom lines for each.
</notes>
</package>

<package name="dplyr">
<description>Tidyverse data manipulation verbs</description>
<common_functions>
filter, mutate, select, group_by, summarise, arrange, left_join, right_join, inner_join,
bind_rows, bind_cols, distinct, rename, ungroup
</common_functions>
<roxygen_pattern>
```r
#' @importFrom dplyr filter mutate select group_by summarise
#' @importFrom dplyr arrange left_join ungroup bind_rows distinct
```
</roxygen_pattern>
<notes>
Can list multiple functions on one @importFrom line. Check for conflicts with stats::filter.
</notes>
</package>

<package name="magrittr">
<description>Pipe operator %>%</description>
<common_functions>%>%</common_functions>
<roxygen_pattern>
```r
#' @importFrom magrittr %>%
```
</roxygen_pattern>
<notes>
Even though R >= 4.4.0 has native |> pipe, current code uses %>% extensively.
Must import explicitly.
</notes>
</package>

<package name="nlmrt">
<description>NLLS optimizer - CORE dependency</description>
<common_functions>nlfb, nlsLM</common_functions>
<roxygen_pattern>
```r
#' @importFrom nlmrt nlfb nlsLM
```
</roxygen_pattern>
</package>

<package name="numDeriv">
<description>Numerical derivatives - CORE dependency</description>
<common_functions>hessian, jacobian, grad</common_functions>
<roxygen_pattern>
```r
#' @importFrom numDeriv hessian jacobian grad
```
</roxygen_pattern>
</package>

<package name="sf">
<description>Spatial data handling - CORE dependency</description>
<common_functions>
st_as_sf, st_crs, st_transform, st_geometry, st_bbox, st_coordinates, st_drop_geometry,
st_intersects, st_buffer, st_union
</common_functions>
<roxygen_pattern>
```r
#' @importFrom sf st_as_sf st_crs st_transform st_geometry
#' @importFrom sf st_bbox st_coordinates st_drop_geometry
```
</roxygen_pattern>
</package>

<package name="sp">
<description>Legacy spatial objects - may be replaceable with sf</description>
<common_functions>
coordinates, proj4string, CRS, SpatialPointsDataFrame, SpatialPolygonsDataFrame
</common_functions>
<roxygen_pattern>
```r
#' @importFrom sp coordinates proj4string CRS SpatialPointsDataFrame
```
</roxygen_pattern>
<notes>
Consider if sp can be removed entirely and replaced with sf in future plans.
For Plan 03, import only functions actually used.
</notes>
</package>

<package name="spdep">
<description>Spatial autocorrelation - CORE for diagnostics</description>
<common_functions>nb2listw, poly2nb, moran.test, moran.mc</common_functions>
<roxygen_pattern>
```r
#' @importFrom spdep nb2listw poly2nb moran.test
```
</roxygen_pattern>
</package>

<package name="ggplot2">
<description>Plotting - used in plot.rsparrow and diagnostics</description>
<common_functions>
ggplot, aes, geom_point, geom_line, geom_histogram, geom_density, theme_bw, theme_minimal,
labs, ggtitle, xlab, ylab, scale_x_continuous, scale_y_continuous
</common_functions>
<roxygen_pattern>
```r
#' @importFrom ggplot2 ggplot aes geom_point geom_line geom_histogram
#' @importFrom ggplot2 theme_bw labs ggtitle xlab ylab
```
</roxygen_pattern>
</package>

<package name="stringr">
<description>String manipulation utilities</description>
<common_functions>
str_detect, str_replace, str_replace_all, str_trim, str_split, str_c, str_sub, str_extract
</common_functions>
<roxygen_pattern>
```r
#' @importFrom stringr str_detect str_replace str_replace_all str_trim
#' @importFrom stringr str_split str_c
```
</roxygen_pattern>
</package>

<package name="car">
<description>Regression diagnostics (Anova, vif)</description>
<common_functions>Anova, vif, durbinWatsonTest</common_functions>
<roxygen_pattern>
```r
#' @importFrom car Anova vif
```
</roxygen_pattern>
<notes>
Check if actually used in core functions or only in diagnostics marked for removal.
</notes>
</package>

<package name="tools">
<description>File utilities</description>
<common_functions>file_path_sans_ext, file_ext</common_functions>
<roxygen_pattern>
```r
#' @importFrom tools file_path_sans_ext file_ext
```
</roxygen_pattern>
</package>

<packages_for_suggests>
<description>
These packages should be moved from Imports to Suggests in DESCRIPTION and conditionally
loaded with requireNamespace() checks.
</description>

<package name="gplots">Only for specialized heatmaps/plots</package>
<package name="gridExtra">Only for multi-panel plot layouts</package>
<package name="plyr">Check if replaceable with dplyr; otherwise move to Suggests</package>
<package name="leaflet">Interactive maps - optional</package>
<package name="leaflet.extras">Interactive maps - optional</package>
<package name="mapview">Interactive maps - optional</package>
<package name="plotly">Interactive plots - optional</package>
<package name="markdown">Report generation - optional</package>
<package name="knitr">Report generation - optional</package>
<package name="rmarkdown">Report generation - optional</package>

<conditional_usage_pattern>
```r
# In functions that use optional packages:
if (!requireNamespace("plotly", quietly = TRUE)) {
  stop("Package 'plotly' is needed for interactive plots. ",
       "Install with: install.packages('plotly')",
       call. = FALSE)
}

# Then use plotly::function() explicit qualification
plotly::plot_ly(...)
```
</conditional_usage_pattern>

</packages_for_suggests>

</conversion_guidelines>

<roxygen_implementation>

<file name="R/rsparrow-package.R">
<description>
Create a package-level documentation file that contains all @importFrom tags.
This centralizes imports in one location for easy maintenance.
</description>

<example>
```r
#' rsparrow: SPARROW Water Quality Modeling in R
#'
#' Implements the USGS SPARROW (SPAtially Referenced Regressions On Watershed
#' attributes) model for estimating contaminant sources, watershed delivery, and
#' in-stream transport in river networks.
#'
#' @section Main Functions:
#' \itemize{
#'   \item \code{\link{rsparrow_model}}: Estimate a SPARROW model
#'   \item \code{\link{predict.rsparrow}}: Predict loads and yields
#'   \item \code{\link{summary.rsparrow}}: Summarize estimation results
#' }
#'
#' @docType package
#' @name rsparrow-package
#' @aliases rsparrow
#'
#' @useDynLib rsparrow, .registration = TRUE
#'
#' @importFrom car Anova vif
#' @importFrom data.table data.table setDT := setnames .N .SD .I
#' @importFrom dplyr filter mutate select group_by summarise left_join
#' @importFrom dplyr arrange ungroup bind_rows distinct
#' @importFrom ggplot2 ggplot aes geom_point geom_line geom_histogram
#' @importFrom ggplot2 theme_bw labs ggtitle xlab ylab
#' @importFrom magrittr %>%
#' @importFrom nlmrt nlfb nlsLM
#' @importFrom numDeriv hessian jacobian grad
#' @importFrom sf st_as_sf st_crs st_transform st_geometry st_bbox
#' @importFrom sf st_coordinates st_drop_geometry
#' @importFrom sp coordinates proj4string CRS SpatialPointsDataFrame
#' @importFrom spdep nb2listw poly2nb moran.test
#' @importFrom stringr str_detect str_replace str_replace_all str_trim str_split str_c
#' @importFrom tools file_path_sans_ext file_ext
#'
#' @keywords internal
"_PACKAGE"
```
</example>

<notes>
- The "_PACKAGE" sentinel is a special roxygen2 convention for package documentation
- All @importFrom tags go in this one file for centralized management
- The @useDynLib directive also goes here (moved from hand-edited NAMESPACE)
- Use @keywords internal to hide this from user-facing documentation index
</notes>
</file>

</roxygen_implementation>

<verification_steps>

<step n="1">
<name>Generate updated NAMESPACE</name>
<command>roxygen2::roxygenize("RSPARROW_master")</command>
<expected_result>
NAMESPACE file with:
- Comment: # Generated by roxygen2: do not edit by hand
- 50-80 importFrom() lines
- 0 blanket import() lines
- 1 useDynLib() line
- 10-15 export() lines
- 6+ S3method() registrations
</expected_result>
</step>

<step n="2">
<name>Check for missing imports</name>
<command>R CMD check --as-cran rsparrow_2.1.0.tar.gz</command>
<expected_issues>
If a required function is missing from @importFrom, R CMD check will report:
"object 'function_name' not found" or "could not find function 'function_name'"

Fix by adding the missing function to the @importFrom line in rsparrow-package.R
</expected_issues>
</step>

<step n="3">
<name>Test package loading</name>
<command>
```r
library(rsparrow)
# Should load without errors or warnings about masked functions
```
</command>
</step>

</verification_steps>

<troubleshooting>

<issue>
<problem>Function still not found after adding @importFrom</problem>
<solution>
Check if function is actually exported by the package. Use:
`getNamespaceExports("package_name")`
Some functions are internal and cannot be imported.
</solution>
</issue>

<issue>
<problem>Special operators (:=, %>%, %in%) not importing correctly</problem>
<solution>
These need special syntax in @importFrom:
`@importFrom data.table :=`
`@importFrom magrittr %>%`
%in% is in base R, no import needed.
</solution>
</issue>

<issue>
<problem>Too many importFrom lines, NAMESPACE is huge</problem>
<solution>
This is acceptable for Plan 03. After Plan 05 removes non-core functions,
many imports will become unnecessary and can be trimmed.
</solution>
</issue>

</troubleshooting>

</imports_guide>
