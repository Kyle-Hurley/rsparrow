# Fixture build script for Plan 06 test suite.
# Wrapped in if (FALSE) so R CMD check never auto-executes it.
# Run manually from the package root to regenerate fixtures:
#   source("tests/testthat/helper-build-fixtures.R")
#
# Fixtures are saved to tests/testthat/fixtures/ and committed to the repo.

if (FALSE) {

  fixtures_dir <- "tests/testthat/fixtures"
  dir.create(fixtures_dir, showWarnings = FALSE, recursive = TRUE)

  # ---------------------------------------------------------------------------
  # Fixture 1: mini_network_raw
  # A 7-reach Y-shaped synthetic stream network.
  # ---------------------------------------------------------------------------
  mini_network_raw <- data.frame(
    waterid  = 1:7,
    fnode    = c(1L, 2L, 3L, 4L, 10L, 11L, 12L),
    tnode    = c(10L, 10L, 11L, 11L, 12L, 12L, 99L),
    frac     = rep(1.0, 7),
    iftran   = rep(1L, 7),
    demiarea = c(5, 5, 4, 4, 3, 4, 2),
    demtarea = c(5, 5, 4, 4, 13, 13, 26),
    meanq    = c(0.01, 0.01, 0.01, 0.01, 0.05, 0.05, 0.1),
    headflag = c(1L, 1L, 1L, 1L, 0L, 0L, 0L),
    termflag = c(0L, 0L, 0L, 0L, 0L, 0L, 1L),
    depvar   = c(0, 0, 0, 0, 0, 0, 100),
    staidseq = c(0L, 0L, 0L, 0L, 0L, 0L, 1L),
    calsites = c(0L, 0L, 0L, 0L, 0L, 0L, 1L),
    s1       = c(3, 3, 2, 2, 1, 2, 1),
    d1       = c(0.2, 0.2, 0.3, 0.3, 0.1, 0.2, 0.1),
    k1       = c(0.05, 0.05, 0.03, 0.03, 0.02, 0.02, 0.01),
    stringsAsFactors = FALSE
  )

  save(mini_network_raw,
       file = file.path(fixtures_dir, "mini_network.rda"))
  message("Saved mini_network.rda")

  # ---------------------------------------------------------------------------
  # Fixture 2: mini_model_inputs
  # Minimal DataMatrix.list + supporting objects for estimateFeval /
  # predict_sparrow unit tests.  No optimizer run needed — estimate.list is
  # hand-coded with fixed known coefficients.
  # ---------------------------------------------------------------------------

  # The data matrix uses mini_network_raw row order (rows 1-7 correspond to
  # waterid 1-7).  hydseq ordering is handled internally by estimateFeval via
  # the Fortran tnoder subroutine, which uses fnode/tnode to traverse the DAG.

  data_mat <- matrix(
    c(
      mini_network_raw$s1,        # col 1: jsrcvar
      mini_network_raw$d1,        # col 2: jdlvvar
      mini_network_raw$k1,        # col 3: jdecvar
      mini_network_raw$frac,      # col 4: jfrac
      mini_network_raw$fnode,     # col 5: jfnode
      mini_network_raw$tnode,     # col 6: jtnode
      mini_network_raw$depvar,    # col 7: jdepvar
      mini_network_raw$iftran,    # col 8: jiftran
      mini_network_raw$staidseq,  # col 9: jstaid
      mini_network_raw$calsites   # col 10: jtarget
    ),
    nrow = 7, ncol = 10
  )

  data.index.list <- list(
    jsrcvar  = 1L,
    jdlvvar  = 2L,
    jdecvar  = 3L,
    jresvar  = integer(0),
    jfrac    = 4L,
    jfnode   = 5L,
    jtnode   = 6L,
    jdepvar  = 7L,
    jiftran  = 8L,
    jstaid   = 9L,
    jtarget  = 10L,
    jbsrcvar = 1L,
    jbdlvvar = 2L,
    jbdecvar = 3L,
    jbresvar = integer(0)
  )

  DataMatrix.list <- list(
    data            = data_mat,
    data.index.list = data.index.list,
    beta            = matrix(c(0.5, -0.5, 0.1), nrow = 1)
  )

  SelParmValues <- list(
    beta0        = c(0.5, -0.5, 0.1),
    betamin      = c(0, -10, 0),
    betamax      = c(100, 0, 10),
    betaconstant = c(0L, 0L, 0L),
    bcols        = 3L,
    srcvar       = "s1",
    dlvvar       = "d1",
    decvar       = "k1",
    resvar       = character(0),
    sparrowNames = c("beta_s1", "beta_d1", "beta_k1"),
    bCorrGroup   = c(1L, 1L, 0L)
  )

  Csites.weights.list <- list(
    weight = rep(1.0, 7),
    tiarea = mini_network_raw$demiarea
  )

  estimate.input.list <- list(
    ifHess                       = "no",
    s_offset                     = 0.0,
    NLLS_weights                 = "no",
    if_auto_scaling              = "no",
    if_mean_adjust_delivery_vars = "no",
    yieldFactor                  = 0.01,
    ConcFactor                   = 1.0,
    loadUnits                    = "kg/yr",
    yieldUnits                   = "kg/km2/yr",
    ConcUnits                    = "mg/L"
  )

  dlvdsgn <- matrix(1, nrow = 1, ncol = 1)

  # Mock estimate.list — hand-coded, no optimizer required.
  estimate.list <- list(
    JacobResults = list(
      oEstimate               = c(0.5, -0.5, 0.1),
      Parmnames               = c("beta_s1", "beta_d1", "beta_k1"),
      mean_exp_weighted_error = 1.0,
      leverage                = rep(0, 7),
      boot_resid              = NULL,
      Obs                     = c(100),
      predict                 = c(NA_real_),
      Resids                  = c(NA_real_)
    ),
    ANOVA.list = list(
      RSQ  = NA_real_,
      RMSE = NA_real_,
      npar = 3L,
      mobs = 1L
    ),
    HesResults   = NULL,
    sparrowEsts  = NULL
  )

  mini_inputs <- list(
    DataMatrix.list     = DataMatrix.list,
    SelParmValues       = SelParmValues,
    Csites.weights.list = Csites.weights.list,
    estimate.input.list = estimate.input.list,
    dlvdsgn             = dlvdsgn,
    estimate.list       = estimate.list
  )

  save(mini_inputs,
       file = file.path(fixtures_dir, "mini_model_inputs.rda"))
  message("Saved mini_model_inputs.rda")

} # end if (FALSE)
