<data_structures>

<user_input_files>
<file name="sparrow_control.R" format="R script">
Master control file sourced by user. Sets ~100 global variables controlling all aspects of
execution: paths, model options, estimation toggles, mapping settings, scenario definitions.
Located in user's results directory (e.g., UserTutorial/results/sparrow_control.R).
</file>

<file name="data1.csv" format="CSV">
Primary input data. One row per reach (or per reach-time for dynamic models).
Required columns (mapped via dataDictionary): waterid, fnode, tnode, frac, iftran, demtarea,
dession, hydseq, headflag, termflag, depvar (monitored load), source variables, delivery
variables, decay variables. Located in user's data/ directory.
</file>

<file name="parameters.csv" format="CSV">
Parameter specification file. Columns: sparrowNames, parmUnits, parmType (SOURCE/DELIVF/STRM/RESV),
parmMin, parmMax, parmInit, parmCorrGroup, parmConstant. One row per model parameter.
Located in user's results directory.
</file>

<file name="design_matrix.csv" format="CSV">
Source-delivery interaction matrix. Rows = delivery variables, Columns = source variables.
Values 0 or 1 indicating which delivery factors apply to which sources.
Located in user's results directory.
</file>

<file name="dataDictionary.csv" format="CSV">
Maps between user's variable names (data1UserNames) and SPARROW internal names (sparrowNames).
Also defines classification variables, additional output variables, and variable descriptions.
Located in user's results directory.
</file>
</user_input_files>

<core_runtime_objects>
<object name="subdata" type="data.frame">
Filtered and sorted version of data1. Contains all reaches meeting filter criteria, sorted by
hydseq (upstream to downstream). Columns include all sparrowNames variables plus computed
attributes (headflag, termflag, staid, staidseq, depvar, calsites). This is the primary
data object used throughout estimation and prediction.
</object>

<object name="sitedata" type="data.frame">
Subset of subdata for calibration sites: subdata[(subdata$depvar > 0 and subdata$calsites==1), ].
Used for diagnostic plots, residual analysis, and model performance metrics.
</object>

<object name="DataMatrix.list" type="named list">
<element name="data">Numeric matrix (nreach x ncols) with column indices mapping to data variables.
Columns ordered by: source vars, delivery vars, decay vars, reservoir vars, network vars
(fnode, tnode, depvar, etc.). Used directly by estimateFeval.</element>
<element name="beta">Matrix (1 x bcols) of initial parameter values for optimization.</element>
<element name="data.index.list">Named list of column index vectors: jsrcvar, jdlvvar, jdecvar,
jresvar, jfrac, jfnode, jtnode, jdepvar, jiftran, jstaid, jtarget, and corresponding beta
index vectors (jbsrcvar, jbdlvvar, jbdecvar, jbresvar).</element>
</object>

<object name="SelParmValues" type="named list">
<element name="beta0">Initial parameter values for estimation.</element>
<element name="betamin, betamax">Parameter bounds.</element>
<element name="betaconstant">Binary vector; 1=fixed, 0=estimated.</element>
<element name="bcols">Total parameter count (estimated + constant).</element>
<element name="srcvar, dlvvar, decvar, resvar">Variable name vectors by type.</element>
<element name="sparrowNames">All parameter names.</element>
<element name="bCorrGroup">Correlation group indicator.</element>
</object>

<object name="estimate.list" type="named list">
<element name="sparrowEsts">NLLS results: $resid, $jacobian, $coefficients, $ssquares,
$lower, $upper, and dlvdsgn. (Specification-string variables removed from sparrowEsts
in Plan 04B — decay/delivery expressions now inlined directly in math files.)</element>
<element name="JacobResults">Diagnostics: $oEstimate (final params), $Parmnames,
$mean_exp_weighted_error (bias correction), $leverage, $boot_resid, $standardResids,
$ratio.obs.pred, $Obs, $predict (site predictions).</element>
<element name="HesResults">Optional Hessian-based: covariance, correlations, eigenvalues.</element>
<element name="ANOVA.list">Performance metrics by classification variable.</element>
<element name="Mdiagnostics.list">Overall model diagnostics (RSQ, RMSE, etc.).</element>
</object>

<object name="predict.list" type="named list">
<element name="predmatrix">Matrix (nreach x ncols) of load predictions: total, by source,
monitoring-adjusted, non-decayed, incremental, delivered, source shares.</element>
<element name="yldmatrix">Matrix of yield predictions: concentration, total yield, source
yields, incremental yields, delivered yields.</element>
<element name="oparmlist, oyieldlist">Column name vectors for predmatrix and yldmatrix.</element>
<element name="predict.source.list">Source name vectors for load/yield categories.</element>
</object>

<object name="file.output.list" type="named list">
Paths and file settings: path_results, path_data, path_gis, path_master, run_id,
input_data_fileName, loadUnits, yieldUnits, ConcUnits, ConcFactor, yieldFactor, and ~90
additional control settings. Previously generated by generateInputLists() (deleted in Plan 02).
Plan 04D-3 replaced it with explicit construction in rsparrow_model() containing sensible
defaults for all ~100 settings. Now stored in model$data$file.output.list for wrapper access.
</object>

<object name="rsparrow" type="S3 object (named list)">
The primary user-facing result object returned by rsparrow_model(). All exported functions
either accept or return an rsparrow object (excluding rsparrow_hydseq and read_sparrow_data).
<element name="call">Matched call to rsparrow_model().</element>
<element name="coefficients">Named numeric vector of final parameter estimates (oEstimate with Parmnames).</element>
<element name="std_errors">Named numeric vector of Jacobian standard errors (oSEj).</element>
<element name="vcov">Hessian-based covariance matrix; NULL if ifHess="no".</element>
<element name="residuals">Numeric vector of residuals at calibration sites (Mdiagnostics.list$Resids).</element>
<element name="fitted_values">Numeric vector of fitted loads at calibration sites (Mdiagnostics.list$predict).</element>
<element name="fit_stats">List with R2 (ANOVA.list$RSQ), RMSE (ANOVA.list$RMSE), npar, nobs, convergence.</element>
<element name="data">Named list of all inputs needed by wrapper functions:
  subdata, sitedata, vsitedata (NULL if if_validate="no"),
  DataMatrix.list, SelParmValues, dlvdsgn,
  Csites.weights.list, Vsites.list (NULL if if_validate="no"),
  classvar (NA_character_ if none; "sitedata.demtarea.class" normally),
  estimate.list (full list from controlFileTasksModel — used by predict/bootstrap/validate/scenario),
  estimate.input.list (with ConcFactor=1.0, loadUnits, yieldUnits, ConcUnits, yieldFactor=0.01),
  scenario.input.list, mapping.input.list, data_names, file.output.list.</element>
<element name="predictions">NULL initially; populated by predict(model) or rsparrow_model(if_predict="yes").
  Contains predmatrix, yldmatrix, oparmlist, oyieldlist, predict.source.list from predict_sparrow().</element>
<element name="bootstrap">NULL initially; populated by rsparrow_bootstrap().
  Contains bEstimate, bootmean_exp_weighted_error, boot_resids, boot_lev.</element>
<element name="validation">NULL initially; populated by rsparrow_validate() (requires if_validate="yes").
  Contains vANOVA.list, vMdiagnostics.list from validateMetrics().</element>
<element name="metadata">List with version, timestamp, run_id, model_type, path_main.</element>
</object>

<object name="Csites.weights.list" type="named list">
NLLS regression weights: $weight (vector of weights for calibration sites),
$tiarea (incremental area). Default weights are 1.0 unless area-based weighting selected.
</object>

<object name="mapping.input.list" type="named list">
All mapping-related settings: lat_limit, lon_limit, CRStext, lineShapeName, polyShapeName,
residual_map_breakpoints, master_map_list, output_map_type, map_siteAttributes.list, etc.
</object>
</core_runtime_objects>

<fortran_data_interface>
<interface name="tnoder (estimation)">
Input: ifadjust(int), nreach(int), nnode(int), data2(nreach,4)[fnode,tnode,depvar,iftran],
       incddsrc(nreach), carryf(nreach)
Output: ee(nreach) - residuals at monitoring sites
</interface>

<interface name="ptnoder (prediction)">
Input: Same as tnoder
Output: pred(nreach) - predicted load at every reach
</interface>

<interface name="mptnoder (monitoring-adjusted source)">
Input: Same as ptnoder + share(nreach) - source share vector
Output: pred(nreach) - monitoring-adjusted source load
</interface>

<interface name="deliv_fraction">
Input: nreach, waterid(nreach), nnode, data2(nreach,5)[fnode,tnode,frac,iftran,termflag],
       incdecay(nreach), totdecay(nreach)
Output: sumatt(nreach) - delivery fraction for each reach
Note: Processes in REVERSE hydrological order (downstream to upstream)
</interface>
</fortran_data_interface>

<file_output>
<output dir="estimate/">
(run_id)_sparrowEsts - Binary R object of NLLS results
(run_id)_JacobResults - Binary R object of Jacobian diagnostics
(run_id)_HessianResults - Binary R object of Hessian (optional)
(run_id)_summary.txt - Text summary of estimation metrics
(run_id)_diagnostic_plots.html - HTML diagnostic report
(run_id)_log.txt - Optimization log from sink()
</output>
<output dir="predict/">
(run_id)_predicts_loads.csv - Load predictions for all reaches
(run_id)_predicts_yield.csv - Yield predictions for all reaches
(run_id)_predict.list - Binary R object
</output>
<output dir="maps/">
Leaflet/Plotly HTML maps, ESRI shapefiles, batch PNG maps
</output>
<output dir="scenarios/">
Scenario prediction CSVs and comparison output
</output>
</file_output>

</data_structures>
