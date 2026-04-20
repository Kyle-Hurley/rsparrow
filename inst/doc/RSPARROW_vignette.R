knitr::opts_chunk$set(collapse = TRUE, comment = "#>")

# install.packages("rsparrow")
# 
# # Or the development version from GitHub:
# # remotes::install_github("Kyle-Hurley/rsparrow")

library(rsparrow)

str(sparrow_example, max.level = 1)

reaches <- rsparrow_hydseq(sparrow_example$reaches)
head(reaches[order(reaches$hydseq), c("waterid", "fnode", "tnode", "hydseq")])

# td <- tempdir()
# 
# # Write control CSVs
# write.csv(sparrow_example$data_dictionary,
#           file.path(td, "dataDictionary.csv"), row.names = FALSE)
# write.csv(sparrow_example$parameters,
#           file.path(td, "parameters.csv"), row.names = FALSE)
# write.csv(sparrow_example$design_matrix,
#           file.path(td, "design_matrix.csv"), row.names = FALSE)
# 
# # Write reach data with pre-computed hydseq
# reaches <- rsparrow_hydseq(sparrow_example$reaches)
# write.csv(reaches, file.path(td, "data1.csv"), row.names = FALSE)

# model <- rsparrow_model(td, run_id = "ex")

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
# # Predictions (populated when if_predict = "yes")
# names(model$predictions)
# #> [1] "oparmlist"          "loadunits"          "predmatrix"
# #> [4] "oyieldlist"         "yieldunits"         "yldmatrix"

# plot(model, type = "residuals")           # observed vs predicted, residuals
# plot(model, type = "residuals", panel = "B")  # Q-Q, boxplots
# plot(model, type = "sensitivity")         # parameter sensitivity
# plot(model, type = "spatial")             # spatial autocorrelation

# model <- rsparrow_bootstrap(model, n_boot = 200, seed = 42)
# model$bootstrap$bEstimate  # bootstrapped parameter distributions

# # Simulate a 50% reduction in agricultural N loading
# model <- rsparrow_scenario(model, source_changes = list(agN = 0.5))
