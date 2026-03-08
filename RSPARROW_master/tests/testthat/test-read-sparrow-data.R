make_minimal_sparrow_dir <- function() {
  td <- tempfile()
  dir.create(td)

  # parameters.csv and design_matrix.csv only need to exist (read_sparrow_data
  # checks file.exists() but does NOT read them itself)
  write.csv(
    data.frame(sparrowNames = "s1", parmType = "SOURCE", parmInit = 1,
               parmMin = 0, parmMax = 10, parmCorrGroup = 1L, parmConstant = 0L),
    file.path(td, "parameters.csv"), row.names = FALSE
  )
  write.csv(
    data.frame(s1 = 1L),
    file.path(td, "design_matrix.csv"), row.names = FALSE
  )

  # dataDictionary.csv must have 5 columns consumed by read_dataDictionary():
  # varType, sparrowNames, data1UserNames, varunits, explanation
  write.csv(
    data.frame(
      varType       = c("integer", "integer", "integer"),
      sparrowNames  = c("waterid", "fnode", "tnode"),
      data1UserNames = c("waterid", "fnode", "tnode"),
      varunits      = c("", "", ""),
      explanation   = c("reach ID", "from node", "to node")
    ),
    file.path(td, "dataDictionary.csv"), row.names = FALSE
  )

  # data1.csv read by readData() via data.table::fread
  write.csv(
    data.frame(waterid = 1:3, fnode = c(1L, 2L, 3L), tnode = c(2L, 3L, 99L)),
    file.path(td, "data1.csv"), row.names = FALSE
  )

  td
}

test_that("read_sparrow_data returns a list", {
  td <- make_minimal_sparrow_dir()
  on.exit(unlink(td, recursive = TRUE))
  result <- read_sparrow_data(path_main = td, run_id = "run1")
  expect_true(is.list(result))
})

test_that("read_sparrow_data result contains file.output.list, data1, data_names", {
  td <- make_minimal_sparrow_dir()
  on.exit(unlink(td, recursive = TRUE))
  result <- read_sparrow_data(path_main = td, run_id = "run1")
  expect_names_present(result, c("file.output.list", "data1", "data_names"))
})

test_that("read_sparrow_data stops with clear error if path_main does not exist", {
  expect_error(
    read_sparrow_data(path_main = "/nonexistent/path/xyz", run_id = "run1"),
    regexp = "does not exist|path_main"
  )
})

test_that("read_sparrow_data stops with clear error if parameters.csv is missing", {
  td <- make_minimal_sparrow_dir()
  on.exit(unlink(td, recursive = TRUE))
  file.remove(file.path(td, "parameters.csv"))
  expect_error(read_sparrow_data(path_main = td, run_id = "run1"))
})

test_that("read_sparrow_data creates run_id-prefixed dataDictionary.csv in results dir", {
  td <- make_minimal_sparrow_dir()
  on.exit(unlink(td, recursive = TRUE))
  read_sparrow_data(path_main = td, run_id = "run1")
  expected_copy <- file.path(td, "results", "run1", "run1_dataDictionary.csv")
  expect_true(file.exists(expected_copy))
})
