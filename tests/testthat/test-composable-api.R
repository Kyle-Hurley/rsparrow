# Tests for the composable API introduced in Plan 17:
#   rsparrow_prepare() and rsparrow_estimate()

# ---- rsparrow_prepare() structural tests --------------------------------

test_that("rsparrow_prepare returns rsparrow_data object", {
  result <- rsparrow_prepare(
    sparrow_example$reaches,
    sparrow_example$parameters,
    sparrow_example$design_matrix
  )
  expect_s3_class(result, "rsparrow_data")
  expect_names_present(result, c("data1", "betavalues", "dmatrixin", "data_names"))
})

test_that("rsparrow_prepare works without data_dictionary (identity mapping)", {
  result <- rsparrow_prepare(
    sparrow_example$reaches,
    sparrow_example$parameters,
    sparrow_example$design_matrix
    # data_dictionary omitted — should default to NULL
  )
  expect_s3_class(result, "rsparrow_data")
  # data_names should have sparrowNames == data1UserNames for reach columns
  dn <- result$data_names
  expect_true(all(dn$sparrowNames == dn$data1UserNames))
})

test_that("rsparrow_prepare works with data_dictionary (backward compat)", {
  result <- rsparrow_prepare(
    sparrow_example$reaches,
    sparrow_example$parameters,
    sparrow_example$design_matrix,
    data_dictionary = sparrow_example$data_dictionary
  )
  expect_s3_class(result, "rsparrow_data")
})

test_that("rsparrow_prepare validates required reaches columns", {
  expect_error(
    rsparrow_prepare(
      reaches       = data.frame(x = 1),
      parameters    = sparrow_example$parameters,
      design_matrix = sparrow_example$design_matrix
    ),
    regexp = "missing required columns|reaches"
  )
})

test_that("rsparrow_prepare validates SOURCE presence in parameters", {
  bad_params <- sparrow_example$parameters
  bad_params$parmType <- "DELIVF"
  expect_error(
    rsparrow_prepare(
      reaches       = sparrow_example$reaches,
      parameters    = bad_params,
      design_matrix = sparrow_example$design_matrix
    ),
    regexp = "SOURCE"
  )
})

test_that("rsparrow_prepare stops with informative error for missing data_dictionary columns", {
  bad_dict <- data.frame(x = 1)
  expect_error(
    rsparrow_prepare(
      sparrow_example$reaches,
      sparrow_example$parameters,
      sparrow_example$design_matrix,
      data_dictionary = bad_dict
    ),
    regexp = "missing required columns|data_dictionary"
  )
})

# ---- print.rsparrow_data ------------------------------------------------

test_that("print.rsparrow_data returns object invisibly without error", {
  d <- rsparrow_prepare(
    sparrow_example$reaches,
    sparrow_example$parameters,
    sparrow_example$design_matrix
  )
  out <- capture.output(result <- print(d))
  expect_identical(result, d)
  expect_true(any(grepl("rsparrow_data", out)))
})

# ---- rsparrow_estimate() structural tests -------------------------------

test_that("rsparrow_estimate requires rsparrow_data input", {
  expect_error(rsparrow_estimate(list()), regexp = "rsparrow_data")
  expect_error(rsparrow_estimate("not_data"), regexp = "rsparrow_data")
})

test_that("rsparrow_estimate has expected formal arguments", {
  args <- names(formals(rsparrow_estimate))
  expect_true("data"        %in% args)
  expect_true("run_id"      %in% args)
  expect_true("output_dir"  %in% args)
  expect_true("if_estimate" %in% args)
  expect_true("if_predict"  %in% args)
  expect_true("if_validate" %in% args)
  expect_true("hessian"     %in% args)
  expect_true("mean_adjust" %in% args)
  expect_true("weights"     %in% args)
  expect_true("load_units"  %in% args)
  expect_true("yield_units" %in% args)
})

# ---- rsparrow_model() argument contract (Plan 13 + Plan 17) ------------

test_that("rsparrow_model has correct formal arguments (Plan 17: data_dictionary now optional)", {
  args <- names(formals(rsparrow_model))
  expect_true("reaches"         %in% args)
  expect_true("parameters"      %in% args)
  expect_true("design_matrix"   %in% args)
  expect_true("data_dictionary" %in% args)
  expect_true("run_id"          %in% args)
  expect_true("output_dir"      %in% args)
  expect_true("if_estimate"     %in% args)
  expect_true("if_predict"      %in% args)
  expect_true("if_validate"     %in% args)
  # data_dictionary should now have a default (NULL), not be required
  expect_true(is.null(formals(rsparrow_model)$data_dictionary))
})

test_that("rsparrow_model works without data_dictionary (Plan 17)", {
  skip("integration test — requires full estimation; run manually")
})
