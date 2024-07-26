# Load required libraries
library(httr)
library(jsonlite)
library(tidyverse)

# Base URL for the API
base_url <- "https://epc.opendatacommunities.org/api/v1"

# Authentication token
email <- "rayan.azhari.17@ucl.ac.uk"
api_key <- "7c87f640d9d041f4268114ae5b9acd775dc2b8c7"
auth_token <- paste0(email, ":", api_key) %>%
  charToRaw() %>%
  base64enc::base64encode()

# Function to fetch all EPC certificates using pagination
fetch_all_epc_certificates <- function(from_year, from_month, to_year, to_month) {
  start_time <- Sys.time()  # Start time measurement
  
  query_params <- list(
    `from-year` = from_year,
    `from-month` = from_month,
    `to-year` = to_year,
    `to-month` = to_month,
    size = 5000 # maximum page size
  )
  
  all_certificates <- list()
  first_request <- TRUE
  search_after <- NULL
  
  repeat {
    if (!first_request) {
      query_params["search-after"] <- search_after
    }
    
    response <- GET(
      url = paste0(base_url, "/non-domestic/search"),
      add_headers(
        "Accept" = "application/json",
        "Authorization" = paste("Basic", auth_token)
      ),
      query = query_params
    )
    
    stop_for_status(response)
    certificates <- content(response, "parsed", simplifyDataFrame = TRUE)
    
    if (first_request) {
      certificates[["column-names"]][[1]] <- 'lmk_key'
    }
    
    certificates[[2]]$`lmk_key` <- certificates[[2]]$`lmk-key`
    certificates[[2]]$`lmk-key` <- NULL
    
    all_certificates <- rbind(all_certificates, certificates[[2]])
    
    search_after <- headers(response)[["x-next-search-after"]]
    if (is.null(search_after)) {
      break
    }
    
    first_request <- FALSE
  }
  
  end_time <- Sys.time()  # End time measurement
  duration <- end_time - start_time
  
  list(
    certificates = all_certificates,
    duration = duration
  )
}

# Function to fetch recommendations for a specific certificate
fetch_recommendations <- function(lmk_key) {
  response <- GET(
    url = paste0(base_url, "/non-domestic/recommendations/", lmk_key),
    add_headers(
      "Accept" = "application/json",
      "Authorization" = paste("Basic", auth_token)
    )
  )
  
  if (http_status(response)$category == "Success") {
    content(response, "parsed", simplifyDataFrame = TRUE)
  } else {
    NULL
  }
}

# Main script
from_year <- 2020
from_month <- 1
to_year <- 2020
to_month <- 1

# Fetch all EPC certificates
result <- fetch_all_epc_certificates(from_year, from_month, to_year, to_month)
all_certificates <- result$certificates
duration <- result$duration

# Print the time taken
print(paste("Time taken to fetch all EPC certificates:", duration))

# Fetch recommendations for each certificate
certificates_with_recommendations <- lapply(all_certificates$lmk_key, function(lmk_key) {
  recommendations <- fetch_recommendations(lmk_key)
  list(
    certificate = all_certificates[all_certificates$lmk_key == lmk_key, ],
    recommendations = recommendations
  )
})

# Print results
print(certificates_with_recommendations)
