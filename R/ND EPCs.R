# Load required libraries
library(httr)
library(jsonlite)

# Base URL for the API
base_url <- "https://epc.opendatacommunities.org/api/v1"


# Authentication token
email <- "rayan.azhari.17@ucl.ac.uk"
api_key <- "7c87f640d9d041f4268114ae5b9acd775dc2b8c7"
auth_token <- paste0(email, ":", api_key) %>%
  charToRaw() %>%
  base64enc::base64encode()

# Function to fetch EPC certificates
fetch_epc_certificates <- function(from_year, from_month, to_year, to_month, number_of_records) {
  query_params <- list(
    `from-year` = from_year,
    `from-month` = from_month,
    `to-year` = to_year,
    `to-month` = to_month,
    size = number_of_records
  )
  
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
  
  # Rename column 'lmk-key' to 'lmk_key'
  certificates[["column-names"]][[1]] <- 'lmk_key'
  certificates[[2]]$`lmk_key` <- certificates[[2]]$`lmk-key`
  certificates[[2]]$`lmk-key` <- NULL
  
  return(certificates)
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
from_year <- 2014
from_month <- 1
to_year <- 2023
to_month <- 12
number_of_records <- 10000

# Fetch EPC certificates
certificates <- fetch_epc_certificates(from_year, from_month, to_year, to_month, number_of_records)

# Fetch recommendations for each certificate
certificates_with_recommendations <- lapply(certificates[[2]]$lmk_key, function(lmk_key) {
  recommendations <- fetch_recommendations(lmk_key)
  list(recommendations = recommendations)
})

# Print results
print(certificates_with_recommendations)





