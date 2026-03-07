<sparrow_methodology>

<overview>
SPARROW (SPAtially Referenced Regressions On Watershed attributes) is a hybrid statistical-
mechanistic water quality model developed by the USGS. It relates in-stream water quality
measurements at monitoring sites to upstream sources, land-to-water delivery factors, and
in-stream loss processes using a spatially explicit, mass-balance-constrained nonlinear
regression framework.
</overview>

<model_structure>
<reach_network>
The model operates on a one-dimensional network of stream segments (reaches) and their
contributing drainage areas. Each reach has: a from-node (fnode), a to-node (tnode),
incremental drainage area, and upstream connectivity. Data is ordered by hydrological
sequence (hydseq) from upstream headwaters to downstream outlets.
</reach_network>

<three_components>
<component name="Source Generation">
Contaminant sources (e.g., fertilizer, wastewater, atmospheric deposition, land use areas)
generate mass loads at each reach. Source coefficients (beta_src) scale source inputs.
Mathematical form: load_src[j] = beta_src[j] * source_data[j]
</component>

<component name="Land-to-Water Delivery">
Delivery factors control the fraction of source mass reaching the stream. Factors include
climate variables, soil properties, land characteristics. A design matrix maps delivery
variables to sources, allowing source-specific delivery.
Mathematical form: delivery = exp(sum(beta_dlv[i] * dlv_data[i]) %*% t(design_matrix))
</component>

<component name="In-Stream Transport and Decay">
Stream decay: first-order decay along reach length.
  reach_decay = exp(-length * beta_dec)
Reservoir decay: loss in reservoirs/impoundments.
  reservoir_decay = 1 / (1 + storage * beta_res)
Transport factor: frac * reach_decay * reservoir_decay
The frac variable indicates whether a reach transfers flow downstream (0 or 1).
</component>
</three_components>

<load_accumulation>
Incremental load for reach i:
  incr_load[i] = sum_j(beta_src[j] * source[i,j] * delivery[i,j]) * sqrt(reach_decay) * reservoir_decay

Total load accumulates downstream via Fortran subroutine (tnoder/ptnoder):
  reach_load[i] = incr_load[i] + transport_factor[i] * node_load[fnode[i]]
  node_load[tnode[i]] += iftran[i] * reach_load[i]

Monitoring load substitution (conditioned predictions):
  When depvar > 0 at a monitoring site, the observed load replaces the modeled load
  for downstream accumulation (ifadjust=1).
</load_accumulation>
</model_structure>

<estimation>
<objective_function>
Weighted nonlinear least squares on log-transformed loads:
  residual[k] = sqrt(weight[k]) * (log(observed[k]) - log(predicted[k]))
Minimized using nlmrt::nlfb() (Levenberg-Marquardt variant) with box constraints.
</objective_function>

<parameter_types>
SOURCE (beta_src): Must be >= 0 (lower bound)
DELIVF (beta_dlv): Land-to-water delivery coefficients
STRM (beta_dec): In-stream decay coefficients
RESV (beta_res): Reservoir decay coefficients
Parameters can be fixed (constant) or estimated, controlled by parameters.csv.
</parameter_types>

<diagnostics>
- Jacobian-based standard errors and t-statistics
- Hessian-based covariance matrix (optional)
- Leverage and Cook's distance
- ANOVA by classification variables (e.g., drainage area class)
- Spatial autocorrelation (Moran's I)
- Parametric bootstrap for coefficient uncertainty
</diagnostics>
</estimation>

<prediction>
<output_types>
- Total load (fully decayed): pload_total
- Monitoring-adjusted total load: mpload_total
- Non-decayed total load: pload_nd_total
- Incremental load: pload_inc
- Source-specific loads for all above categories
- Delivery fraction to terminal reach: deliv_frac
- Yield (load / drainage area): yield_total, yield_inc, etc.
- Concentration (load / discharge): concentration
- Source share percentages
</output_types>

<bootstrap_predictions>
Parametric bootstrap samples coefficient vectors from the estimated covariance matrix,
computes predictions for each sample, and derives standard errors and confidence intervals
for all prediction metrics.
</bootstrap_predictions>

<scenario_analysis>
Users specify percentage or absolute changes to source variables and/or delivery variables.
Modified data is passed through the prediction pipeline to evaluate effects on downstream
water quality. Supports both interactive (Shiny) and batch evaluation.
</scenario_analysis>
</prediction>

<dynamic_model>
RSPARROW 2.1 extends the static model to handle time-varying data. Observations can be
seasonal (4 seasons), annual (multiple years), or time series (seasons x years).
The model structure is identical but data includes year/season identifiers, and diagnostics
are stratified by time period. Dynamic models lack explicit storage components, so temporal
predictions are approximate.
</dynamic_model>

<references>
- Schwarz et al. (2006) SPARROW model documentation: USGS TM 6-B3
- Alexander et al. (2008) SPARROW model for nutrients: USGS SIR 2008-5232
- Robertson and Saad (2011): Referenced in UserTutorial (TN model for MRB3)
- RSPARROW documentation: RSPARROW_master/inst/doc/RSPARROW_docV2.1.pdf
</references>

</sparrow_methodology>
