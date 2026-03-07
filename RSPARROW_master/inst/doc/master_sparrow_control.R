###############################
## RSPARROW CONTROL SCRIPT ####
###############################

# Authors:   L. Gorman-Sanisaca, USGS, Baltimore, MD (lgormansanisaca@usgs.gov)
#            K. Hurley, USGS, Baltimore, MD (khurley@usgs.gov)
#            R. Alexander
# Modified: 2025-04-04
# RSPARROW Version 2.1
# SPARROW URL:  http://water.usgs.gov/nawqa/sparrow/

####################################################################
### SPECIFY USER SETTINGS AND EXECUTE THE ENTIRE CONTROL SCRIPT ####
####################################################################
# NOTE: 
# (1) Users are required to select and execute all statements in the control script for proper 
#   operation of RSPARROW.
# (2) The initial values of settings are for example only.
# (3) To execute RSPARROW, select the "Source" button in the upper right of the control script
#   window in RStudio (located next to the "Run" button).

################################
### 1. DATA IMPORT SETTINGS ####
################################
# Set csv read/write options
csv_decimalSeparator <- "."
csv_columnSeparator <- ","

# Create an initial Data Dictionary file from the data1 column names
# This file will have to be edited prior to executing RSPARROW
# Options: 
# "yes" creates the data dictionary
# "no" skips creating the data dictionary
create_initial_dataDictionary <- "no"

# Create an initial parameter and design_matrix files from names in the Data Dictionary file
# The parameter names must be listed for both the sparrowNames and data1UserNames and the
#   varType should be defined as SOURCE, DELIVF, STRM, or RESV to populate parmType in the
#   (run_id)_parameters.CSV
# The initial file will have to be edited prior to executing RSPARROW
# Options: 
# "yes" creates the paramter control files
# "no" skips creating the parameter control files
create_initial_parameterControlFiles <- "no"

# Select input data file (accepted file types ".csv" or binary file
#   with no extension created in previous RSPARROW run).
# Binary file will be automatically created if file type is not binary
#   for fast import in subsequent runs.
input_data_fileName <- "data1.csv"

# Loads previous binary data input file "(input_data_fileName)_priorImport" from results directory. 
#   This setting will override run_dataImport.
# Options: 
# "yes" loads a previously saved binary version of data1 csv file
# "no" imports the data1 csv file defined in 'input_data_fileName' and saves it as a binary file, 
#   overwriting any prior version of the binary file
# NOTE: The OPTIONS FOR NETWORK ATTRIBUTES AND AREA VERIFICATION (section 2)
#   will ONLY be executed if load_previousDataImport <- "no"
load_previousDataImport <- "no"

# Indicate whether or not to run _userModifyData.R script
# Options: 
# "yes" executes the script
# "no" does not execute the script
if_userModifyData <- "yes"

######################################################
### 2. STREAM NETWORK ATTRIBUTES AND VERIFICATION ####
######################################################
# NOTE: This section is only executed if data import of the csv file is run.
# To run data import, set load_previousDataImport<-"no"

# Verify drainage area accumlation in the network
# NOTE: This requires that precalculated values of 'demtarea' are present in DATA1
# Area totals will be affected by 'frac'
# Options: 
# "yes" executes verification
# "no" skips verification
if_verify_demtarea <- "no"

# Indicate whether maps are to be generated for if_verify_demtarea<-"yes"
# Options: 
# "yes" output verification reports
# "no" skips verification reports
# NOTE: Generating maps can significantly slow processing time for larger models
if_verify_demtarea_maps <- "no"

# Request the calculation of selected reach attributes:
# Identify the attributes for calculation and placement in DATA1
# Select from following: 'hydseq', 'headflag', and/or 'demtarea'
calculate_reach_attribute_list <- NA    # no calculation is requested

# Specify any additional DATA1 variables (and conditions) to be used to filter reaches:
# Default conditions are FNODE > 0 and TNODE > 0
# The filter is used to create 'subdata' object from 'data1'
filter_data1_conditions <- NA

# Indicate whether hydseq in the DATA1 file needs to be reversed
# Options: 
# "yes" reversed the hydseq
# "no" maintains the hydseq as-is in the data1 file
if_reverse_hydseq <- "no"


#############################################
### 3. MONITORING SITE FILTERING OPTIONS ####
#############################################

# The index 'calsites' requires setting in the 'userModifyData.R' script to exclude unwanted sites
# (calsites:  1=site selected for calibration; 0 or NA = site not used)
# Default setting = 1 for sites with positive loads 'depvar > 0'

# Minimum drainage area size for monitoring sites located on headwater reaches
minimum_headwater_site_area <- 0

# Minimum number of reaches between monitoring sites
minimum_reaches_separating_sites <- 1

# Minimum allowable incremental drainage area between monitoring sites
minimum_site_incremental_area <- 0

############################
### 4. MODEL ESTIMATION ####
############################

# Specify the land-to-water delivery function.
# The exponential computation yields an NxS matrix, where N is the number of
# reaches and S is the number of sources (see Chapter 4.4.4.1 for details).
incr_delivery_specification <- "exp(ddliv1 %*% t(dlvdsgn))"

# Specify if the delivery variables are to be mean adjusted (recommended). This
# improves the interpretability of the source coefficients
if_mean_adjust_delivery_vars <- "yes"

# Specify the R reach decay function code
reach_decay_specification <- "exp(-data[,jdecvar[i]] * beta1[,jbdecvar[i]])"

# Specify the R reservoir decay function code
reservoir_decay_specification <- "(1 / (1 + data[,jresvar[i]] * beta1[,jbresvar[i]]))"
# reservoir_decay_specification <- "exp(-data[,jresvar[i]] * beta1[,jbresvar[i]])"
# An alternative simplified Arrhenius temperature dependent function can also be used
#   as described in equation 1.35 in the SPARROW documentation (Schwarz et al. 2006).
#   This requires the specification of an OTHER class variable for temperature.
# OTHER variable (e.g., temp):  
# reservoir_decay_specification <- "(1 / (1 + data[,jresvar[i]] * beta1[,jbresvar[i]])) * (beta1[,jbothervar[1]]+1)**data[,jothervar[1]]"
#   where the OTHER index references the parameter vector sequence, corresponding to the order of 
#   the OTHER variables listed in the parameters.csv file
# NOTE: if using parameter scaling with this equation, the beta1[,jbothervar[1]] coefficient must 
#   be scaled to be consistent with the +1 adjustment OTHER variable (e.g., temp)

# Specify if model estimation is to be performed
# Options: 
# "no" obtains coefficient estimates from a previous estimation; if no previous estimates 
#   available, then the initial coefficient values in the beta file are used
# "yes" indicates that all estimation, prediction, maps, and scenario files from the subdirectory 
#   with the name = run_id will be deleted and only regenerated if settings are turned on
if_estimate <- "yes"

# Specify if model simulation is to be performed using the initial parameter values
# Options: 
# "yes" indicates that all estimation, prediction, maps, and scenario files from the subdirectory 
#   with the name = run_id will be deleted and only regenerated if settings are turned on. This 
#   will over-ride a selection of if_estimate<-"yes".
# "no" indicates the model should be run in simulation mode, without formal NLLS parameter 
#   estimation, using the user-defined initial values (parmInit) in the parameters.csv file as 
#   fixed parameter values.
if_estimate_simulation <- "no"

# Specify if the more accurate Hessian coefficient SEs are to be estimated
# Options: 
# "yes" computes the second derivative Hessian standard errors for the estimated model coefficients. 
#   These calculations can be more computationally demanding than Jacobian estimates.
# "no" for Jacobian estimates and to reduce run times
ifHess <- "yes"

# NLMRT optimization shift setting that tests floating-point equality
# Initially select values between 1.0e+12 and 1.0e+14
# Lower magnitude offset values will execute more NLLS iterations
s_offset <- 1.0e+14

# Select regression weights
# Options: 
# "default": weights = 1.0  (unweighted NLLS)
# "lnload": weights expressed as reciprocal of variance proportional to log of predicted load
# "user": weights assigned by user in userModifyData.R script, expressed as the reciprocal of the 
#   variance proportional to user-selected variables
NLLS_weights <- "default"

#####################################
### 5. MODEL SPATIAL DIAGNOSTICS ####
#####################################

# Specifiy if the spatial autocorrelation diagnostic graphics for Moran's I test are to be output
# Options: 
# "yes" executes a Moran's I test and renders diagnostics_spatialautocorr.html report
# "no" skips test and report
if_spatialAutoCorr <- "yes"

# Specify the R statement for the Moran's I distance weighting function:
# MoranDistanceWeightFunc <- "1/sqrt(distance)"    # inverse square root distance
# MoranDistanceWeightFunc <- "1/(distance)^2"    # inverse squared distance
MoranDistanceWeightFunc <- "1/distance"        # inverse distance

# Specify spatially contiguous discrete classification variables (e.g., HUC-x) for producing site diagnostics
# Diagnostics include: (1) observed-predicted plots
#                      (2) spatial autocorrelation (only the first variable is used)
#                      (3) sensitivities (only the first variable is used)
classvar <- c("huc2", "huc4")

# Specify non-contiguous land use classification variables for boxplots of observed-predicted 
# ratios by decile class
# NOTE that the land use variables listed for "class_landuse" should be defined in areal units 
#   (e.g., sq. km) in the data1.csv file or by defining the variables in the userModifyData.R 
#   subroutine
# In the RSPARROW diagnostic output plots, land use is expressed as a percentage of the incremental 
#   area between monitoring sites
class_landuse <- c("forest", "agric", "crops", "pasture", "urban", "shrubgrass")

# Produces a summary table of reach predictions of the total yield for watersheds with relatively 
#   uniform land use.
# Specify the minimum land-use percentages of the total drainage area above a reach to select 
#   reaches with uniform land use for the land uses listed in the "class_landuse" setting.
class_landuse_percent <- c(90, 50, 75, 75, 80, 10)

# Specify whether bivariate correlations among explanatory variables are to be executed by
#   specifying 'parmCorrGroup' in the parameters.csv file as "1" (yes) or "0" (no)
# Options: 
# "yes" performs bivariate correlations and renders explvars_correlations.pdf and adds associated 
#   plots to the diagnostic_plots.html report
# "no" skips the bivariate correlations, reports, and additional plots
if_corrExplanVars <- "yes"

#########################################
### 6. SELECTION OF VALIDATION SITES ####
#########################################

# Split the monitoring sites into calibration and validation set
# Options: 
# "yes" splits the monitoring sites and renders validation_plots.html and 
#   validation_residuals_maps.html
# "no" does not split the monitoring sites and skips rendering validation reports
if_validate <- "no"

# Indicate the decimal fraction of the monitoring sites as validation sites
# Two methods are available for selecting validation sites (see documentation)
pvalidate <- 0.25

#############################
### 7. MODEL PREDICTIONS ####
#############################

# Specify if standard predictions of load and yield are to be produced.
# NOTE: Bias retransformation correction is applied to all predictions, except "deliv_frac", based 
#   on the Smearing estimator method
# Options: 
# "yes" outputs the predictions
# "no" skips predictions
if_predict <- "yes"

# Load predictions:
#   pload_total                Total load (fully decayed)
#   pload_(sources)            Source load (fully decayed)
#   mpload_total               Monitoring-adjusted total load (fully decayed)
#   mpload_(sources)           Monitoring-adjusted source load (fully decayed)
#   pload_nd_total             Total load delivered to streams (no stream decay)
#   pload_nd_(sources)         Source load delivered to streams (no stream decay)
#   pload_inc                  Total incremental load delivered to streams
#   pload_inc_(sources)        Source incremental load delivered to streams
#   deliv_frac                 Fraction of total load delivered to terminal reach
#   pload_inc_deliv            Total incremental load delivered to terminal reach
#   pload_inc_(sources)_deliv  Source incremental load delivered to terminal reach
#   share_total_(sources)      Source shares for total load (percent)
#   share_inc_(sources)        Source share for incremental load (percent)

# Yield predictions:
#   Concentration              Concentration based on decayed total load and discharge
#   yield_total                Total yield (fully decayed)
#   yield_(sources)            Source yield (fully decayed)
#   myield_total               Monitoring-adjusted total yield (fully decayed)
#   myield_(sources)           Monitoring-adjusted source yield (fully decayed)
#   yield_inc                  Total incremental yield delivered to streams
#   yield_inc_(sources)        Source incremental yield delivered to streams
#   yield_inc_deliv            Total incremental yield delivered to terminal reach
#   yield_inc_(sources)_deliv  Source incremental yield delivered to terminal reach

# Uncertainty predictions (requires prior execution of bootstrap predictions; section 10):
#   se_pload_total             Standard error of the total load (percent of mean)
#   ci_pload_total             95% prediction interval of the total load (percent of mean)


# Specify the load units for predictions and for diagnostic plots
loadUnits <- "kg/year"

# Specify the concentration conversion factor, computed as Concentration = load / discharge * ConcFactor
# (for predictions and diagnostic plots)
# ConcFactor <- 3.170979e-05   # kg/yr and m3/s to mg/L
ConcFactor <- 0.001143648    # kg/yr and ft3/s to mg/L
ConcUnits <- "mg/L"

# Specify the yield conversion factor, computed as Yield = load / demtarea * yieldFactor
# (for predictions and diagnostic plots)
yieldFactor <- 1 / 100     # example, to convert kg/km2/yr to kg/ha/year use 1/100 factor
yieldUnits <- "kg/ha/year"

# Specify additional variables to include in prediction, yield, and residuals csv files
# Can be NA
add_vars <- c("huc2", "huc4")

#####################################
### 8. DIAGNOSTIC PLOTS AND MAPS ####
#####################################

####################################################
# Shape file input/output and geographic coordinates

# Identify the stream reach shape file and 'waterid' common variable in the shape file
lineShapeName <- "ccLinesMRB3"
lineWaterid <- "MRB_ID"

# Identify the stream catchment polygon shape file and 'waterid' common variable in the shapefile
polyShapeName <- "mrb3_cats_usonly_withdata_tn"
polyWaterid <- "MRB_ID"

# Identify optional geospatial shape file for overlay of lines on stream/catchment maps
LineShapeGeo <- "states"

# Identify the desired Coordinate Reference System (CRS) mapping transform for# geographic 
#   coordinates (latitude-longitude)
CRStext <- "+proj=longlat +datum=NAD83"

# Indicate whether shape files are to be converted to binary. 
# NOTE: This is required to be executed at least once to use any RSPARROW mapping feature
# Options: 
# "yes" converts shape files to binary
# "no" skips conversion of shape files to binary
if_create_binary_maps <- "no"

# Convert shape files to binary
convertShapeToBinary.list <- c("lineShapeName", "polyShapeName", "LineShapeGeo")

# Select ERSI shape file output for: 
# (1) streams - variables specified in 'master_map_list'
# (2) catchments - variables specified in 'master_map_list'
# (3) residuals - model residuals when 'if_estimate' is "yes"
# (4) site attributes - monitoring site variables in map_siteAttributes.list in section 8
# Options: 
# "yes" outputs files as shape files
# "no" does not output files as shape files
outputESRImaps <- c("no", "no", "no", "no")

# Specify the geographic units minimum/maximum limits for mapping and prediction maps
# If set to NA (missing), limits will be automatically determined from the monitoring site values
lat_limit <- c(35, 50)
lon_limit <- c(-105, -70)

####################################################
# Maps of model predictions and dataDictionary variables

# Identify list of load and yield predictions for mapping to output files (enter NA for none)
# Any variables listed in the data-dictionary are available for mapping by streams or catchments
# NOTE: To map model predictions, then 'if_predict' must = "yes" or predictions must have been
#   previouly executed
master_map_list <- c("pload_total", "yield_total")

# Identify type of map(s) to output "stream","catchment", or "both"
# Options: 
# "stream" maps values to their stream reach
# "catchment" maps values to their catchment
# "both" maps values both to their stream reach and catchment in separate reports
# NOTE: catchment maps typically require more time to render and more disc space
output_map_type <- c("stream")

# Map display settings for model predictions or dataDictionary variables 
# NOTE: the length of predictionMapColors sets the number of breakpoints
# NOTE: the lineWidth is for stream maps only

# Set the size of the title for prediction maps
predictionTitleSize <- 16

# Set the size of the legend for prediction maps
predictionLegendSize <- 0.5

# Set the background color for prediction map legends
# NOTE: view all standard R colors by executing colors() in the console
predictionLegendBackground <- "white"

# Set the colors and breakpoints for prediction maps
# NOTE: the length of predictionMapColors sets the number of breakpoints
# NOTE: view all standard R colors by executing colors() in the console
predictionMapColors <- c("blue", "darkgreen", "gold", "red", "darkred")

# Set integer indicating the number of decimal places to be rounded for prediction maps
# NOTE: Rounding to a negative number of digits means rounding to a power of ten, so for example
#   rounding to -2 rounds to the neared hundred.
predictionClassRounding <- 3

# Set the background color for prediction maps
# NOTE: view all standard R colors by executing colors() in the console
predictionMapBackground <- "white"

# Set the width of lines for "stream" type maps
lineWidth <- 0.5

####################################################
# Model diagnostics:  Station attribute maps, model plots, residual maps

####################
# SiteAttribute maps

# Set site atributes to be mapped
# NOTE: Any variable in the dataDictionary.csv can be mapped
# Example site attribute R statements in the 'userModifyData.R' subroutine that can also be mapped:
# meanload <- depvar
# meanyield <- depvar / demtarea
# meanconc <- depvar/meanq*ConcFactor
# meanloadSE <- depvar_se/depvar*100
map_siteAttributes.list <- c("meanload", "meanconc")

# Set size of title for site attribute maps
siteAttrTitleSize <- 16

# Set size of legend for site attribute maps
siteAttrLegendSize <- 0.5

# Set colors and breakpoints for site attributes
# NOTE: the length of siteAttrColors sets the number of breakpoints
# NOTE: view all standard R colors by executing colors() in the console
siteAttrColors <- c("blue", "green4", "yellow", "orange", "red")

# Set integer indicating the number of decimal places to be rounded for site attribute maps
# NOTE: Rounding to a negative number of digits means rounding to a power of ten, so for example
#   rounding to -2 rounds to the neared hundred.
siteAttrClassRounding <- 2

# Set the point style for site attributes maps
# NOTE: Follows pch style points
siteAttr_mapPointStyle <- 16

# Set the point size for site attribute maps
siteAttr_mapPointSize <- 1

# Set the background color for site attribute maps
# NOTE: view all standard R colors by executing colors() in the console
siteAttrMapBackground <- "white"

####################
# Diagnostic plots and residual maps from the model estimation

# Set point size for diagnostic plots
diagnosticPlotPointSize <- 0.4

# Set point style for diagnostic plots
diagnosticPlotPointStyle <- 1

# Settings for dynamic model output
# Controls reports of diagnostic, spatial autocorrelation, validation, and sensitivity plots by 
#   time steps
# Options: 
# NA groups all data when plotting
# "season" groups data by unique seasons
# "year" groups data by unique years
diagnosticPlots_timestep <- NA

#  Controls output of reports of observed and predicted load over time
# Options: 
# "yes" generates the reports
# "no" skips generating the reports
diagnostic_timeSeriesPlots <- "no"

####################
# Residual maps

# Set breakpoints for residuals maps
# NOTE: if residual_map_breakpoints is set to NA, then breakpoint defaults will be applied
#   breakpoint defaults are c(-2.5, -0.75, -0.25, 0, 0.25, 0.75, 2.5)
#   breakpoints must have a length of 7 and be centered around 0
residual_map_breakpoints <- c(-2.5, -1.0, -0.5, 0, 0.5, 1.0, 2.5)

# Set breakpoints for observed to predicted ratio maps
# NOTE: Must have length 7
ratio_map_breakpoints <- c(0.3, 0.5, 0.8, 1, 1.25, 2, 3.3)

# Set size of title for residuals maps
residualTitleSize <- 1

# Set size of legend for residuals maps
residualLegendSize <- 1

# Set colors of symbols for residuals maps
# NOTE: residualColors must be length = 8 corresponding to residual_map_breakpoints
# NOTE: view all standard R colors by executing colors() in the console
residualColors <- c(
  "red", "red", "gold", "gold", "darkgreen", "darkgreen", "blue", "blue"
)

# residualPointStyle must be length = 8 corresponding to residual_map_breakpoints
# Examples: 
# 2 = open upward triangle
# 6 = open downward triangle
# 1 = open circle
residualPointStyle <- c(2, 2, 1, 1, 1, 1, 6, 6)


# residualPointSize_breakpoints must be length = 8 corresponding to breakpoints
residualPointSize_breakpoints <- c(0.75, 0.5, 0.4, 0.25, 0.25, 0.4, 0.5, 0.75)

# A factor causing symbol size to increase or decrease
# This scales all point sizes in residualPointSize_breakpoints
residualPointSize_factor <- 1

# Set background color of residual maps
# NOTE: view all standard R colors by executing colors() in the console
residualMapBackground <- "white"

####################################################
# Enable plotly interactive displays for maps (interactive plots are automatic)
# Options: 
# "yes" generates interactive plotly maps in reports
# "no" generates ggplot2 (non-interactive) maps in reports
# NOTE: when "yes", maps will require substantially more computational time, system memory, and 
#   disc space compared to "no". When "yes", many maps will be saved to their own file, outside of 
#   their associated report, to increase likelihood of successful rendering.
enable_plotlyMaps <- "yes"

# Define which dataDictionary variables are displayed in the interactive hover text
# NOTE: For dynamic models, "year" and/or "season" are added by default. For dynamic models, each 
#   variable must be unique fr each reach and timestep else the variable is removed. Latitude and 
#   longitude are automatically included for site attribute maps.
add_plotlyVars <- c("waterid", "rchname", "staid")

# Display grid lines for bivariate plots and boxplots
# Options: 
# "yes"
# "no"
showPlotGrid <- "no"


###################################################
# Dynamic mapping settings to control the time periods and format of the display output

##############################
# Settings for selection of time periods for output
# Options: 
# "all" maps all years and seasons
# "mean"; "median"; "min"; "max" maps the statistic of all years and seasons
# NA for static models or maps all years and seasons
# A numeric year maps the specific year(s). e.g. c(2005, 2006, 2010, 2011)
# A character season maps the specific season(s). e.g. c("summer", "winter")
map_years <- NA
map_seasons <- NA

##############################
# Settings for page formatting of the display output

# Set maximum number of maps per page from 1-4
# NOTE: Fewer maps may appear per page if the mapPageGroupBy selection contains less available data 
#   for maps than mapsPerPage selection
mapsPerPage <- NA

# Set grouping variable for maps on a page
# Options: 
# "season" Maps are grouped by season
# "year" Maps are grouped by year
# NA No grouping
# Examples: 
# GroupBy year Example: If mapsPerPage is 4 and the year 2001 has only 3 seasons of data, setting 
#   the mapPageGroupBy to "year" will result in a 3-panel map for 2001 followed by a 4 panel plot 
#   for 2002 if 4 seasons exist for 2002
# GroupBy season Example: If mapsPerPage is 4 and the year 2001 has only 3 seasons of data, then 
#   grouping by "season" will result in only 1 season being displayed per page. If mapping only 2 
#   years (2001 and 2002), 3 2-panel maps would be generated for each of the 3 seasons that are 
#   present in 2001 and 2002, and 1 1-panel map for the season present in 2002
# No Grouping Example: If mapsPerPage is 4, mapPageGroupBy is NA, and the year 2001 has only 3 
#   seasons of data, the result will be that every page contains 4 maps and the last page of maps 
#   would have any remaining maps. There would be 3 maps from 2001 (one for each season) and 1 map 
#   from 2002 to form the first 4-panel map and then the last page would contain a 3-panel map of 
#   the remaining seasons in 2002, assuming 2002 is the last year being mapped.
mapPageGroupBy <- NA


###################################################################
### 9. RShiny interactive Decision Support System (DSS) mapper ####
###################################################################

# Enable the interactive RShiny mapper
# Options: 
# "yes" Automatically runs the RShiny DSS at the completion of model execution and report rendering
# "no" Does not run the RShiny DSS
enable_ShinyApp <- "yes"

# Specify preferred Web browser for the RShiny display
path_shinyBrowser <- "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe"
# Other common browser file paths:
# path_shinyBrowser <- "C:/Program Files/Mozilla Firefox/firefox.exe"
# path_shinyBrowser <- "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
# path_shinyBrowser <- "C:/Windows/SystemApps/Microsoft.MicrosoftEdge_8wekyb3d8bbwe/MicrosoftEdge.exe"
# path_shinyBrowser <- NA      # user's default browser

# RShiny can be enabled from RStudio in a specified browser (e.g., Chrome) for a previously 
#   executed model by running the following function in the Console window:
# runBatchShiny(path_PastResults = "C:/UserTutorial/results/Model6", path_shinyBrowser = "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe")
# NOTE: replace the argument for 'path_PastResults' with path to the desired model

############################################################
# Simulation of management-change scenarios in the RShiny mapper

# NOTE: Requires prior execution of the model estimation ('if_estimate')
#   and standard predictions ('if_predict').

# Scenarios can be executed using the RShiny interactive mapper using the
#   control setting 'enable_ShinyApp <-"yes"'

###############################################

# Select CSV file to input forecasted values for scenario
# NOTE: The csv must be located in the ".../data" directory
# Options: 
# e.g. "forecastScenario.csv"
# NA to skip forecasting
forecast_filename <- NA

# Specify if sparrowNames (TRUE) or data1UserNames (FALSE) are used in the forecast CSV file
# Options: 
# TRUE use sparrowNames
# FALSE use data1UserNames
use_sparrowNames <- FALSE

# Identify the locations for applying scenarios
# Options: 
# "none" to skip executing scenarios
# "all reaches" execute scenarios of all reaches
# "selected reaches" execute scenarios of only selected reaches
select_scenarioReachAreas <- "none"

# Indicate the watershed locations where the scenarios will be applied to either "all reaches" or 
#   "selected reaches"
# Options: 
# NA executes the scenarios for all non-terminal reaches
# [waterid] executes scenarios for a single watershed defined by and including the outlet [waterid] reach
# c([waterid], [waterid], ...) executes scenarios for multiple watersheds
select_targetReachWatersheds <- NA
# Examples: 
#select_targetReachWatersheds <- 15531 # single watershed
#select_targetReachWatersheds <- c(15531, 14899, 1332) # multiple watersheds

###############################################

# Set scenario source/delivery variable conditions for "all reaches"
#   in user-defined watersheds

# Settings applicable to select_scenarioReachAreas<-"all reaches" option.
# Management changes are applied to "all reaches" in the user-defined watersheds

# List the source and/or delivery variables evaluated in the change scenarios.
# NOTE: The sources must be expressed in mass units (e.g. fertilizer) or areal units (e.g. land use 
# or land cover)
scenario_sources <- c("point", "ndep", "crops") # mass, mass, areal

# For land-use 'scenario_sources' with areal units, specify a land-use source in the model to which 
#   a complimentary area conversion is applied that is equal to the change in area of the 
#   `scenario_source` variable. Note that the converted source variable must differ from those that 
#   appear in 'scenario_sources' setting.
# landuseConversion <- c(NA, NA, "forest") # convert crop area to forested area
landuseConversion <- NA    # option if no land-use variables appear in 'scenario_source' setting

# Source/delivery variable adjustment factors (increase or decrease) applied to "all reaches" in 
#   the user-specified watersheds. Enter a factor of 0.1 or 1.1 to obtain a 10% reduction or 
#   increase in a source, respectively. Order must be consistent with the 'scenario_sources'.
scenario_factors <- c(0.20, 0.10, 0.10)

###############################################

# Set scenario source conditions for "selected reaches" in user-defined watersheds

# Settings applicable to select_scenarioReachAreas<-"selected reaches" option.
# Changes applied to "selected reaches" in the user-defined watersheds.

# (A) Specify the source and/or delivery variable adjustment factors in
#     the 'userModifyData.R' script for each of the "scenario_source" variables.
#      The variable names for the factors are defined by adding the
#      prefix "S_" to the *sparrowNames* variable name for each source.
#      In the example, point sources are reduced by 20% and atmospheric
#      deposition is increased by 10% in Ohio Basin (huc2=5) and cropland
#      area is reduced by 25% in the Upper Mississippi Basin:
#         S_point <- ifelse(huc2 == 5,0.2,1)
#         S_atmdep <- ifelse(huc2 == 5,1.1,1)
#         S_crops <- ifelse(huc2 == 7,0.25,1)

# (B) Specify the land-use types used for land conversion in the 'userModifyData.R'
#      script, in cases where the scenario sources are land use/cover variables,
#      expressed in areal units. The variable names for the conversion types are
#      defined by adding the suffix "_LC" to the *sparrowNames* variable name for
#      each land-use area source.
#      In the example, cropland area is converted to pasture area in reaches of
#      the Upper Mississippi River Basin (huc2=7), and "NA" is assumed for the
#      land conversion for the mass-based point sources and atmospheric sources:
#         S_crops_LC <- ifelse(huc2==7,"pasture",NA)

# (C) Add the variable names for the adjustment factors (e.g., "S_crops")
#      and the conversion land-use type (e.g., "S_crops_LC") as 'sparrowNames'
#      in the dataDictionary.csv file, with an OPEN 'varType'.

#   dataDictionary.csv file:
#        varType   sparrowNames      data1UserNames        varunits    explanation
#         OPEN     S_crops                NA
#         OPEN     S_crops_LC             NA


###############################################

# Specify the scenario output settings

# Set scenario name; this becomes the directory and file name for all scenario output
#  NOTE: only one scenario can be run at a time; avoid using "/" or "\" for name
scenario_name <- "scenario1"

# specify the colors for six classes for mapped predictions
# NOTE: view all standard R colors by executing colors() in the console
scenarioMapColors <- c("lightblue", "blue", "darkgreen", "gold", "red", "darkred")


# Identify prediction variables to display a stream map of the effects of the
#  scenario on water-quality loads. Options include:
#

# RELATIVE METRICS:
# Ratio of the changed load (resulting from the scenario) to the baseline load
# associated with the original (unchanged) mass or area of the model sources.
#  Metric names and explanations:
#   ratio_total                Ratio for the total load (a measure of the watershed-
#                               scale effect of the change scenario)
#   ratio_inc                  Ratio for the total incremental load delivered to
#                               the reach (a measure of the "local" effect of the
#                               change scenario)
# ABSOLUTE METRICS:
# Load prediction names and explanations
#   pload_total                Total load (fully decayed)
#   pload_(sources)            Total source load (fully decayed)
#   pload_nd_total             Total load delivered to streams (no stream decay)
#   pload_nd_(sources)         Total source load delivered to streams (no stream decay)
#   pload_inc                  Total incremental load delivered to reach
#                                 (with 1/2 of reach decay)
#   pload_inc_(sources)        Source incremental load delivered to reach
#                                 (with 1/2 of reach decay)
#   pload_inc_deliv            Total incremental load delivered to terminal reach
#   pload_inc_(sources)_deliv  Total incremental source load delivered to terminal reach
#   share_total_(sources)      Source shares for total load (percent)
#   share_inc_(sources)        Source shares for incremental load (percent)

# Yield prediction names and explanations
#   Concentration              Flow-weighted concentration based on decayed total load
#                                 and mean discharge
#   yield_total                Total yield (fully decayed)
#   yield_(sources)            Total source yield (fully decayed)
#   yield_inc                  Total incremental yield delivered to reach
#                                 (with 1/2 of reach decay)
#   yield_inc_(sources)        Total incremental source yield delivered to reach
#                                 (with 1/2 of reach decay)
#   yield_inc_deliv            Total incremental yield delivered to terminal reach
#   yield_inc_(sources)_deliv  Total incremental source yield delivered to
#                                 terminal reach

scenario_map_list <- c("ratio_total", "ratio_inc", "pload_total")
###########################################
### 10. MODEL PREDICTION UNCERTAINTIES ####
###########################################

# Number of parametric bootstrap iterations
biters <- 0

# Confidence interval setting
confInterval <- 0.90

# Specify the initial seed for the boot_estimate, boot_predict, and if_validate <- "yes" and 
#   pvalidate > 0
# NOTE: This is critical for reproducibility
iseed <- 139933493

# Specify if parametric bootstrap estimation (Monte Carlo) is to be executed. Outputs the model 
#   coefficients and bias-retransformation correction factors for model residuals of each bootstrap 
#   iteration.
# Options: 
# "yes" executes bootstrap estimation
# "no" skips bootstrap estimation
if_boot_estimate <- "no"

# Specify if bootstrap predictions (mean, SE, confidence intervals) are to be executed. Outputs 
#   reach-level bias-corrected mean predictions and their uncertainties for mass-related metrics 
#   (e.g. total load), including source-share related mass metrics.
# Note: Requires bootstrap model parameters (if_boot_estimate) to be executed or previous executed
# Options: 
# "yes" executes bootstrap predictions 
# "no" skips bootstrap predictions
if_boot_predict <- "no"

# Bootstrap load prediction names and explanations
#   mean_pload_total                Bias-adjusted total load (fully decayed)
#   mean_pload_(sources)            Bias-adjusted source load (fully decayed)
#   mean_mpload_total               Bias-adjusted conditional (monitoring-adjusted)
#                                      total load (fully decayed)
#   mean_mpload_(sources)           Bias-adjusted conditional (monitoring-adjusted)
#                                      source load (fully decayed)
#   mean_pload_nd_total             Bias-adjusted total load delivered to streams
#                                      (no stream decay)
#   mean_pload_nd_(sources)         Bias-adjusted source load delivered to streams
#                                      (no stream decay)
#   mean_pload_inc                  Bias-adjusted total incremental load delivered
#                                      to streams
#   mean_pload_inc_(sources)        Bias-adjusted source incremental load delivered
#                                      to streams
#   mean_deliv_frac                 Fraction of total load delivered to terminal reach
#   mean_pload_inc_deliv            Bias-adjusted total incremental load delivered to
#                                      terminal reach
#   mean_pload_inc_(sources)_deliv  Bias-adjusted source incremental load delivered to
#                                      terminal reach
#   mean_share_total_(sources)      Bias-adjusted percent source shares for total load
#   mean_share_inc_(sources)        Bias-adjusted percent source shares for
#                                      incremental load

# Bootstrap yield prediction names and explanations
#   mean_conc_total                 Bias-adjusted concentration based on decayed total
#                                      load and mean annual discharge
#   mean_yield_total                Bias-adjusted total yield (fully decayed)
#   mean_yield_(sources)            Bias-adjusted source yield (fully decayed)
#   mean_myield_total               Bias-adjusted conditional (monitoring-adjusted) total
#                                      yield (fully decayed)
#   mean_myield_(sources)           Bias-adjusted conditional (monitoring-adjusted)
#                                      source yield (fully decayed)
#   mean_yield_inc                  Bias-adjusted total incremental yield delivered to
#                                      streams
#   mean_yield_inc_(sources)        Bias-adjusted source incremental yield delivered to
#                                      streams
#   mean_yield_inc_deliv            Bias-adjusted total incremental yield delivered to
#                                      terminal reach
#   mean_yield_inc_(sources)_deliv  Bias-adjusted source incremental yield delivered to
#                                      terminal reach

#############################################################################
### 11. DIRECTORY AND MODEL IDENTIFICATION AND CONTROL SCRIPT OPERATIONS ####
#############################################################################

# Add a relative or absolute path name to the directory containing all RSPARROW source code
# NOTE: If there are spaces in the file path to the source code then errors may occurr
path_master <- './RSPARROW_master'

# Set the names of the subdirectories containing the raw, GIS, and results data
# NOTE: These subdirectories must be parallel to each other
# Example: ".../[dir_name]/data", ".../[dir_name]/gis", ".../[dir_name]/results"
results_directoryName <- "results"
data_directoryName <- "data"
gis_directoryName <- "gis"

# Select current run_id for the model
run_id <- "Model1"

# Load previous model settings into active control script
# Specify name of old model to copy into results directory for edit and run
# Options: 
# [run_id] to load the previous [run_id] settings of the model
# NA to run the current control files located in ".../[results_directoryName]"
copy_PriorModelFiles <- NA

# Run model comparison summary
# Options
# c([run_id], ...) to compare current model to previously run models found in ".../[results_directoryName]"
# NA to skip model comparison
compare_models <- NA

# Specify model comparison and subdirectory name for the comparison results
# Example: "modelFour_to_modelOne"
modelComparison_name <- NA


# Option to open CSV files from R-session for editing
# Options:
# "yes" opens the control files for editing before running the model
# "no" runs the current model without opening control files for editing first
edit_Parameters <- "no"
edit_DesignMatrix <- "no"
edit_dataDictionary <- "no"

# Allow model operations to be executed in the background as a shell command
# NOTE: RStudio and the Rscript.exe windows must remain open until execution is complete
# Options: 
# "yes" runs the model as a shell command
# "no" runs the model in RStudio
batch_mode <- "no"

# Enable RSPARROW error handling. This allows for custom messaging of RSPARROW errors printed to 
#   the console, and when 'batch_mode' is "yes" the messages will be saved to an error log on the 
#   users system.
# NOTE: When "no", the user can view a full error traceback by executing 'traceback(2)' in the 
#   console. However, errors that occur when 'batch_mode' is "yes" will not be output or saved, 
#   making traceback impossible. When "yes" and an error occurs, to restore original user error 
#   options, execute 'options(backupOptions)' in the console.
RSPARROW_errorOption <- "yes"

# Independent functions available to R developers (see Chapter 7 of the documentation for explanation)
# findCodeStr(path_master,"string name here","all")
# executionTree(...)

#####################################################
### 12. INSTALLATION AND UPDATING OF R LIBRARIES ####
#####################################################

# WARNING: It is highly recommended the code below remain unedited. Use caution if making changes.

# Install required packages
# NOTE: This is a one time process unless a new version of R is installed or more recent packages 
#   are found on CRAN. Packages previously installed by user will be skipped.
if (!"devtools" %in% installed.packages()) {
  install.packages("devtools")
}
suppressWarnings(devtools::install_deps(path_master, upgrade = "never", type = "binary"))

# Load RSPARROW functions (These 2 lines should ALWAYS be run together)
suppressWarnings(remove(list = "runRsparrow"))
devtools::load_all(path_master)

#############################################
## Start Model Run
## DO NOT MAKE EDITS TO THIS SECTION
#############################################
activeFile <- findScriptName() #get activeFile Name
runRsparrow <- "yes"
rstudioapi::setCursorPosition(c(1, 1, 575, 1))
source(paste(path_master, "/R/runRsparrow.R", sep = ""))
