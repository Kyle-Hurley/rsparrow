#' @title shinySavePlot
#' 
#' @description 
#' Save plotly map generated in shiny as html.
#' 
#' Executed By: \itemize{
#'              \item interactiveBatchRun.R, 
#'              \item goShinyPlot.R}
#' 
#' Executes Routines: \itemize{
#'              \item makeReport_header.R, 
#'              \item render_report.R}
#' 
#' @param plotObj Plot object from Shiny to be saved in html report.
#' @param filename Character string indicating output html file name
#' @param title Title of the document.
#'
#' @return A saved html with embedded plot object

shinySavePlot <- function(plotObj, filename, title = "Shiny Plot") {
  
  header <- makeReport_header(
    title = title, 
    as_pdf = FALSE
  )
  
  code_chunk <- paste0(
    "```{r}\n", 
    "plotObj\n", 
    "```\n\n"
  )
  
  rmd_content <- paste0(header, code_chunk)
  
  tryCatch(
    expr = {
      render_report(
        rmd_content = rmd_content, 
        filename = filename, 
        as_pdf = FALSE
      )
    }, 
    error = \(e) {
      cat("Error rendering the Shiny plot", title, ":\n", e$message)
    }
  )
  
}