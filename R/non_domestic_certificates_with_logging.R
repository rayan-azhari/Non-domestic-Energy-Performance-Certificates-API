# non_domestic_certificates_with_logging.R

# Load necessary libraries
library(httr)
library(jsonlite)
library(dplyr)
library(logger)
library(purrr)
library(tidyr)

# Define the API endpoint and authentication
base_url <- "https://epc.opendatacommunities.org/api/v1"
api_endpoint <- paste0(base_url, "/non-domestic/search")
cert_endpoint <- paste0(base_url, "/non-domestic/certificate")
rec_endpoint <- paste0(base_url, "/non-domestic/recommendations")
auth_token <- "cmF5YW4uYXpoYXJpLjE3QHVjbC5hYy51azo3Yzg3ZjY0MGQ5ZDA0MWY0MjY4MTE0YWU1YjlhY2Q3NzVkYzJiOGM3"
auth_header <- paste("Basic", auth_token)

# Initialize logger
log_appender(appender_file("api_requests.log"))
log_threshold(DEBUG)

# Function to log and handle errors
handle_error <- function(response, context) {
  log_error("Error in {context}: HTTP {status_code(response)} - {content(response, as = 'text', encoding = 'UTF-8')}")
  if (status_code(response) != 200) {
    stop("Error in ", context, ": HTTP ", status_code(response))
  }
}

# Function to fetch all non-domestic certificates
fetch_certificates <- function(size = 1000) {
  all_data <- list()
  search_after <- NULL
  has_more_data <- TRUE
  
  while (has_more_data) {
    query_params <- list(size = size)
    if (!is.null(search_after)) {
      query_params$`search-after` <- search_after
    }
    
    log_info("Requesting data with parameters: {query_params}")
    response <- GET(api_endpoint, 
                    add_headers(Authorization = auth_header, Accept = "application/json"), 
                    query = query_params)
    
    # Log the raw response content for debugging
    log_info("Response content: {content(response, as = 'text', encoding = 'UTF-8')}")
    
    handle_error(response, "Non-domestic Search API")
    
    data <- content(response, as = "parsed")
    all_data <- append(all_data, list(data))
    
    search_after <- headers(response)[["x-next-search-after"]]
    has_more_data <- !is.null(search_after)
  }
  
  # Flatten the list of data frames into one data frame
  all_data_df <- bind_rows(map(all_data, as_tibble), .id = "source")
  
  return(all_data_df)
}

# Function to fetch recommendations for certificates
fetch_recommendations <- function(certificates) {
  recommendations <- list()
  
  for (lmk_key in certificates$lmk_key) {
    rec_url <- paste0(rec_endpoint, "/", lmk_key)
    log_info("Requesting recommendations for LMK key: {lmk_key}")
    rec_response <- GET(rec_url, add_headers(Authorization = auth_header, Accept = "application/json"))
    
    if (status_code(rec_response) == 200) {
      rec_data <- content(rec_response, as = "parsed")
      recommendations <- append(recommendations, list(rec_data))
    } else if (status_code(rec_response) == 404) {
      log_warning("No recommendations found for LMK key: {lmk_key}")
    } else {
      handle_error(rec_response, paste("Recommendations API for LMK key:", lmk_key))
    }
  }
  
  # Flatten the list of data frames into one data frame
  recommendations_df <- bind_rows(map(recommendations, as_tibble), .id = "source")
  
  return(recommendations_df)
}

# Fetch certificates and recommendations
#all_data <- fetch_certificates()
#recommendations <- fetch_recommendations(all_data)

# Save the combined data to CSV files
#write.csv(all_data, "non_domestic_certificates.csv", row.names = FALSE)
#write.csv(recommendations, "non_domestic_recommendations.csv", row.names = FALSE)
