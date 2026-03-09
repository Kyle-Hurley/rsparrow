## ============================================================
## rsparrow Package Walkthrough
## ============================================================
## Run this script section-by-section in an R session.
## Working directory should be the repo root (rsparrow-master/).
## ============================================================

## ── 0. Install the package from source ──────────────────────────────────────
## Build and install (run once, or whenever R/ files change).
## From the terminal:
##   R CMD build --no-build-vignettes .
##   R CMD INSTALL rsparrow_2.1.0.tar.gz

## Or directly from the repo root inside R:
Sys.setenv(R_LIBS = "/home/kp/R/libs")   # where your dependencies live
install.packages(".", repos = NULL, type = "source", lib = "/home/kp/R/libs",
                 INSTALL_opts = "--no-multiarch")

## ── 1. Load the package ──────────────────────────────────────────────────────
library(rsparrow, lib.loc = "/home/kp/R/libs")


## ── 2. Explore the exported API ──────────────────────────────────────────────
## Main functions:
##   rsparrow_model()    – estimate a SPARROW model (full run)
##   read_sparrow_data() – read input data without running the model
##   rsparrow_hydseq()   – compute hydrological sequencing only
##   rsparrow_bootstrap()– parametric bootstrap for coefficient uncertainty
##   rsparrow_scenario() – scenario analysis (change source loads)
##   rsparrow_validate() – hold-out validation metrics
##   predict()           – reach-level load/yield predictions (S3)
##   print() / summary() / coef() / residuals() / vcov() / plot()  (S3)

help(package = "rsparrow")       # full function index
?rsparrow_model                  # detailed docs for any function


## ── 3. read_sparrow_data() – inspect inputs before fitting ───────────────────
## read_sparrow_data() reads the three required control files:
##   parameters.csv      – parameter names, bounds, types (SOURCE/DELIVF/STRM/RESV)
##   design_matrix.csv   – binary matrix mapping parameters to sources
##   dataDictionary.csv  – variable metadata (sparrowNames, data1UserNames, varType)
## and the reach-network data file (default: data1.csv).

## The UserTutorial ships those files with a "Model1_" prefix.  Copy them to a
## temp directory under the expected plain names so read_sparrow_data() can find
## them.
tutorial_src <- file.path(getwd(), "UserTutorial", "results", "Model1")
path_main    <- file.path(tempdir(), "rsparrow_demo")
dir.create(path_main, showWarnings = FALSE)

file.copy(file.path(tutorial_src, "Model1_parameters.csv"),
          file.path(path_main, "parameters.csv"), overwrite = TRUE)
file.copy(file.path(tutorial_src, "Model1_design_matrix.csv"),
          file.path(path_main, "design_matrix.csv"), overwrite = TRUE)
file.copy(file.path("UserTutorial", "data", "dataDictionary.csv"),
          file.path(path_main, "dataDictionary.csv"), overwrite = TRUE)
file.copy(file.path("UserTutorial", "data", "data1.csv"),
          file.path(path_main, "data1.csv"), overwrite = TRUE)

sparrow_data <- read_sparrow_data(path_main = path_main, run_id = "demo")

## What did we get?
names(sparrow_data)            # "file.output.list"  "data1"  "data_names"

## Reach network data (one row per stream reach)
nrow(sparrow_data$data1)      # ~3,000+ reaches for the MRB3 TN example
head(sparrow_data$data1[, 1:8])

## Variable dictionary (sparrowNames ↔ data1UserNames)
head(sparrow_data$data_names)


## ── 4. rsparrow_hydseq() – topological ordering of the reach network ─────────
## Computes the hydrological sequencing (which reaches are upstream of which).
## Takes a data.frame with at minimum: waterid, fnode, tnode.

net <- sparrow_data$data1
net_ordered <- rsparrow_hydseq(net, from_col = "fnode", to_col = "tnode")

## Returns the same data.frame with a new "hydseq" column appended.
## More negative = further downstream; headwater reaches have the largest values.
head(net_ordered[order(net_ordered$hydseq), c("waterid", "fnode", "tnode", "hydseq")])


## ── 5. rsparrow_model() – full SPARROW estimation ────────────────────────────
## This runs the complete pipeline:
##   read data → validate network → hydseq → build DataMatrix → NLLS optimize
##   → fit stats → (optionally) predict
##
## NOTE: The UserTutorial requires its own sparrow_control.R settings
## (reach/reservoir decay specs, NLLS weights, etc.) that are baked into the
## legacy control file.  The new API picks up those settings automatically
## when path_main contains the control CSVs set up above.
##
## A full run on the MRB3 ~3,000-reach network takes ~1-2 minutes.

model <- rsparrow_model(
  path_main  = path_main,
  run_id     = "demo",
  model_type = "static",
  if_estimate = "yes",
  if_predict  = "yes"   # compute reach predictions after estimation
)


## ── 6. S3 methods – explore the fitted model ─────────────────────────────────
class(model)            # "rsparrow"

## Quick summary
print(model)            # coefficients table + fit stats
summary(model)          # detailed ANOVA + parameter table

## Extract components
coef(model)             # named vector of estimated parameters
residuals(model)        # residuals at calibration sites (log-load scale)
vcov(model)             # variance-covariance matrix (Hessian-based)

## Fit statistics
model$fit_stats         # list: R2, RMSE, npar, nobs, convergence
model$fit_stats$R2
model$fit_stats$RMSE


## ── 7. predict() – reach-level load and yield predictions ────────────────────
## predict() returns a matrix of predicted loads, yields, and concentrations
## for every reach in the network.

preds <- predict(model, type = "all")
str(preds)              # matrix: rows = reaches, cols = pload_total, yld_total, ...

## Re-attach predictions to the reach data for inspection
reach_preds <- cbind(
  waterid    = model$data$subdata$waterid,
  demtarea   = model$data$subdata$demtarea,
  pload_total = preds[, "pload_total"],   # total load (kg/yr)
  yld_total   = preds[, "yld_total"]     # total yield (kg/km2/yr)
)
head(reach_preds)


## ── 8. plot() – diagnostic plots ─────────────────────────────────────────────
## Three built-in plot types (type= argument):
##   "residuals"   – observed vs fitted + residual diagnostics
##   "sensitivity" – parameter sensitivity analysis
##   "spatial"     – spatially referenced residual maps

plot(model, type = "residuals")
plot(model, type = "sensitivity")
# plot(model, type = "spatial")  # requires sf/spdep in Suggests


## ── 9. rsparrow_bootstrap() – parameter uncertainty ─────────────────────────
## Parametric bootstrap re-estimation.  Use a small n_boot for a quick demo;
## production runs typically use 200–500 iterations.

model_boot <- rsparrow_bootstrap(model, n_boot = 20, seed = 42)
model_boot$bootstrap    # list of boot coefficients + summary stats


## ── 10. rsparrow_scenario() – what-if source changes ─────────────────────────
## Multiply a named source by a scalar factor (e.g. 50 % reduction in crops N).

model_scen <- rsparrow_scenario(
  object         = model,
  source_changes = list(crops = 0.50)   # halve cropland N loading
)
model_scen$predictions   # new predictions under the scenario


## ── 11. rsparrow_validate() – hold-out validation ────────────────────────────
## Requires the model to have been estimated with if_validate = "yes".
## (Re-run rsparrow_model() with that flag to enable.)

model_val <- rsparrow_model(
  path_main    = path_main,
  run_id       = "demo_val",
  if_validate  = "yes"
)
val_result <- rsparrow_validate(model_val)
val_result$validation    # validation metrics: R2, RMSE at held-out sites


## ── 12. Working with the model$data slot ─────────────────────────────────────
## model$data contains all the internal SPARROW data objects:
names(model$data)
##  subdata            – reach network data.frame (main input)
##  sitedata           – calibration site subset of subdata
##  DataMatrix.list    – numeric matrices fed to the Fortran optimizer
##  SelParmValues      – parameter configuration from parameters.csv
##  estimate.list      – full estimation results (JacobResults, ANOVA.list, …)
##  estimate.input.list– unit factors, run settings
##  file.output.list   – paths and filenames used internally

## Access estimation internals
est <- model$data$estimate.list
names(est)                         # JacobResults, HesResults, ANOVA.list, …
est$JacobResults$oEstimate         # parameter point estimates
est$JacobResults$oSEj              # Jacobian-based standard errors
est$ANOVA.list$RSQ                 # R-squared
