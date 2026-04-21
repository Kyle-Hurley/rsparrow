## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")


## ----install, eval=FALSE------------------------------------------------------
# install.packages("rsparrow")
# 
# # Or the development version from GitHub:
# # remotes::install_github("Kyle-Hurley/rsparrow")


## ----load-data----------------------------------------------------------------
library(rsparrow)

str(sparrow_example, max.level = 1)


## ----hydseq-------------------------------------------------------------------
network <- rsparrow_hydseq(sparrow_example$reaches)
head(network[order(network$hydseq), c("waterid", "fnode", "tnode", "hydseq")])


## ----fit-model, eval=FALSE----------------------------------------------------
# model <- rsparrow_model(
#   sparrow_example$reaches,
#   sparrow_example$parameters,
#   sparrow_example$design_matrix,
#   sparrow_example$data_dictionary
# )


## ----examine, eval=FALSE------------------------------------------------------
# # Compact summary
# print(model)
# 
# # Full estimation summary
# summary(model)
# 
# # Parameter estimates
# coef(model)
# #>        agN        ppt
# #>  3.4176761 -0.0015935
# 
# # Log residuals at calibration sites
# residuals(model)
# 
# # Parameter covariance matrix
# vcov(model)
# 
# # Predictions (populated when if_predict = TRUE)
# names(model$predictions)
# #> [1] "oparmlist"          "loadunits"          "predmatrix"
# #> [4] "oyieldlist"         "yieldunits"         "yldmatrix"


## ----plots, eval=FALSE--------------------------------------------------------
# plot(model, type = "residuals")           # observed vs predicted, residuals
# plot(model, type = "residuals", panel = "B")  # Q-Q, boxplots
# plot(model, type = "sensitivity")         # parameter sensitivity
# plot(model, type = "spatial")             # spatial autocorrelation


## ----bootstrap, eval=FALSE----------------------------------------------------
# model <- rsparrow_bootstrap(model, n_boot = 200, seed = 42)
# model$bootstrap$bEstimate  # bootstrapped parameter distributions


## ----scenario, eval=FALSE-----------------------------------------------------
# # Simulate a 50% reduction in agricultural N loading
# model <- rsparrow_scenario(model, source_changes = list(agN = 0.5))

