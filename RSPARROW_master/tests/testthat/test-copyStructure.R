testthat::test_that("copyStructure returns NULL when depth is 0", {
  
  sample_list <- list(
    "level1a" = list(
      "level2a" = list(
        "level3a" = 1,
        "level3b" = 2
      ),
      "level2b" = list(
        "level3c" = 3,
        "level3d" = 4
      )
    ),
    "level1b" = list(
      "level2c" = list(
        "level3e" = 5
      )
    )
  )
  
  result <- copyStructure(sample_list, 0)
  testthat::expect_null(result)
  
})

testthat::test_that("copyStructure returns NULL for non-list elements", {
  
  result <- copyStructure(123, 2)
  expect_null(result)
  
  result <- copyStructure("test", 2)
  testthat::expect_null(result)
  
})

testthat::test_that("copyStructure creates correct structure at depth 1", {
  
  sample_list <- list(
    "level1a" = list(
      "level2a" = list(
        "level3a" = 1,
        "level3b" = 2
      ),
      "level2b" = list(
        "level3c" = 3,
        "level3d" = 4
      )
    ),
    "level1b" = list(
      "level2c" = list(
        "level3e" = 5
      )
    )
  )
  
  result <- copyStructure(sample_list, 1)
  expected <- list(
    "level1a" = NULL,
    "level1b" = NULL
  )
  testthat::expect_equal(result, expected)
  
})

testthat::test_that("copyStructure creates correct structure at depth 2", {
  
  sample_list <- list(
    "level1a" = list(
      "level2a" = list(
        "level3a" = 1,
        "level3b" = 2
      ),
      "level2b" = list(
        "level3c" = 3,
        "level3d" = 4
      )
    ),
    "level1b" = list(
      "level2c" = list(
        "level3e" = 5
      )
    )
  )
  
  result <- copyStructure(sample_list, 2)
  expected <- list(
    "level1a" = list(
      "level2a" = NULL,
      "level2b" = NULL
    ),
    "level1b" = list(
      "level2c" = NULL
    )
  )
  testthat::expect_equal(result, expected)
  
})

testthat::test_that("copyStructure creates correct structure at depth 3", {
  
  sample_list <- list(
    "level1a" = list(
      "level2a" = list(
        "level3a" = 1,
        "level3b" = 2
      ),
      "level2b" = list(
        "level3c" = 3,
        "level3d" = 4
      )
    ),
    "level1b" = list(
      "level2c" = list(
        "level3e" = 5
      )
    )
  )
  
  result <- copyStructure(sample_list, 3)
  expected <- list(
    "level1a" = list(
      "level2a" = list(
        "level3a" = NULL,
        "level3b" = NULL
      ),
      "level2b" = list(
        "level3c" = NULL,
        "level3d" = NULL
      )
    ),
    "level1b" = list(
      "level2c" = list(
        "level3e" = NULL
      )
    )
  )
  testthat::expect_equal(result, expected)
  
})

testthat::test_that("copyStructure stops recursion correctly", {
  
  sample_list <- list(
    "level1a" = list(
      "level2a" = list(
        "level3a" = 1,
        "level3b" = 2
      ),
      "level2b" = list(
        "level3c" = 3,
        "level3d" = 4
      )
    ),
    "level1b" = list(
      "level2c" = list(
        "level3e" = 5
      )
    )
  )
  
  result <- copyStructure(sample_list, 2)
  testthat::expect_length(result, 2)
  testthat::expect_length(result$level1a, 2)
  testthat::expect_null(result$level1a$level2a)
  testthat::expect_null(result$level1a$level2b)
  
})
