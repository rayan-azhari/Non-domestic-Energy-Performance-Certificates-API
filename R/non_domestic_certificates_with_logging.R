# R/non_domestic_certificates_with_logging.R

# Load necessary libraries
library(httr)
library(jsonlite)
library(dplyr)
library(logger)

# Define the API endpoint and authentication
base_url <- "https://epc.opendatacommunities.org/api/v1"
api_endpoint <- paste0(base_url, "/non-domestic/search")
cert_endpoint <- paste0(base_url, "/non-domestic/certificate")
rec_endpoint <- paste0(base_url, "/non-domestic/recommendations")
api_key <- "<your_api_key>"
auth_header <- paste("Basic", base64_enc(paste("<your_email>", api_key, sep=":")))

# Initialize logger
log_appender(appender_file("api_requests.log"))
log_threshold(DEBUG)

# Function to log and handle errors
handle_error <- function(response, context) {
  if (status_code(response) != 200) {
    log_error("Error in {context}: HTTP {status_code(response)} - {content(response, as = 'text', encoding = 'UTF-8')}")
    stop("Error in ", context, ": HTTP ", status_code(response))
  }
}

# Function to fetch all non-domestic certificates
fetch_certificates <- function(size = 1000) {
  all_data <- data.frame()
  search_after <- NULL
  has_more_data <- TRUE
  
  while (has_more_data) {
    query_params <- list(size = size)
    if (!is.null(search_after)) {
      query_params$`search-after` <- search_after
    }
    
    log_info("Requesting data with parameters: {query_params}")
    response <- GET(api_endpoint, add_headers(Authorization = auth_header), query = query_params)
    handle_error(response, "Non-domestic Search API")
    
    data <- content(response, as = "text", encoding = "UTF-8")
    data_df <- fromJSON(data)
    all_data <- bind_rows(all_data, data_df)
    
    search_after <- headers(response)[["x-next-search-after"]]
    has_more_data <- !is.null(search_after)
  }
  
  return(all_data)
}

# Function to fetch recommendations for certificates
fetch_recommendations <- function(certificates) {
  recommendations <- data.frame()
  
  for (lmk_key in certificates$lmk_key) {
    rec_url <- paste0(rec_endpoint, "/", lmk_key)
    log_info("Requesting recommendations for LMK key: {lmk_key}")
    rec_response <- GET(rec_url, add_headers(Authorization = auth_header))
    
    if (status_code(rec_response) == 200) {
      rec_data <- content(rec_response, as = "text", encoding = "UTF-8")
      rec_df <- fromJSON(rec_data)
      recommendations <- bind_rows(recommendations, rec_df)
    } else if (status_code(rec_response) == 404) {
      log_warning("No recommendations found for LMK key: {lmk_key}")
    } else {
      handle_error(rec_response, paste("Recommendations API for LMK key:", lmk_key))
    }
  }
  
  return(recommendations)
}

# Fetch certificates and recommendations
all_data <- fetch_certificates()
recommendations <- fetch_recommendations(all_data)

# Save the combined data to CSV files
write.csv(all_data, "non_domestic_certificates.csv", row.names = FALSE)
write.csv(recommendations, "non_domestic_recommendations.csv", row.names = FALSE)
