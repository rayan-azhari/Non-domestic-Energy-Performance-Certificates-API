# tests/test_non_domestic_certificates.R

# Load necessary libraries
library(testthat)
library(httr)
library(jsonlite)
library(dplyr)
source("../R/non_domestic_certificates_with_logging.R")

# Mock API responses
mock_certificates_response <- function(size, search_after) {
  # Create a mock response
  response <- list(
    lmk_key = c("1234567890123456789012345678901234567890"),
    address = c("Mock Address 1"),
    postcode = c("AB1 2CD")
  )
  return(data.frame(response))
}

mock_recommendations_response <- function(lmk_key) {
  # Create a mock response
  response <- list(
    lmk_key = lmk_key,
    improvement_description = "Mock Recommendation"
  )
  return(data.frame(response))
}

# Test fetching certificates
test_that("fetch_certificates returns a dataframe", {
  with_mock(
    `httr::GET` = function(...) {
      response <- list(
        status_code = 200,
        content = function(as, encoding) {
          toJSON(list(
            lmk_key = c("1234567890123456789012345678901234567890"),
            address = c("Mock Address 1"),
            postcode = c("AB1 2CD")
          ))
        },
        headers = function() {
          list(`x-next-search-after` = NULL)
        }
      )
      return(response)
    },
    {
      certificates <- fetch_certificates(size = 10)
      expect_true(is.data.frame(certificates))
      expect_equal(ncol(certificates), 3)
    }
  )
})

# Test fetching recommendations
test_that("fetch_recommendations returns a dataframe", {
  mock_certificates <- mock_certificates_response(size = 10, search_after = NULL)
  
  with_mock(
    `httr::GET` = function(...) {
      response <- list(
        status_code = 200,
        content = function(as, encoding) {
          toJSON(list(
            lmk_key = c("1234567890123456789012345678901234567890"),
            improvement_description = "Mock Recommendation"
          ))
        }
      )
      return(response)
    },
    {
      recommendations <- fetch_recommendations(mock_certificates)
      expect_true(is.data.frame(recommendations))
      expect_equal(ncol(recommendations), 2)
    }
  )
})
