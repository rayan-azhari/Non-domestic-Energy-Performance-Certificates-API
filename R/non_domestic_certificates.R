# non_domestic_certificates_by_year.R

# Load necessary libraries
library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
library(tidyr)
library(progress)

# Define the API endpoint and authentication
base_url <- "https://epc.opendatacommunities.org/api/v1"
api_endpoint <- paste0(base_url, "/non-domestic/search")
rec_endpoint <- paste0(base_url, "/non-domestic/recommendations")
auth_token <- "cmF5YW4uYXpoYXJpLjE3QHVjbC5hYy51azo3Yzg3ZjY0MGQ5ZDA0MWY0MjY4MTE0YWU1YjlhY2Q3NzVkYzJiOGM3"
auth_header <- paste("Basic", auth_token)

# Function to handle errors
handle_error <- function(response, context) {
  if (status_code(response) != 200) {
    stop("Error in ", context, ": HTTP ", status_code(response))
  }
}

# Function to fetch non-domestic certificates for a specific year
fetch_certificates_by_year <- function(year, size = 1000) {
  all_data <- list()
  search_after <- NULL
  has_more_data <- TRUE
  total_records <- 0
  
  while (has_more_data) {
    query_params <- list(size = size, `from-date` = paste0(year, "-01-01"), `to-date` = paste0(year, "-12-31"))
    if (!is.null(search_after)) {
      query_params$`search-after` <- search_after
    }
    
    response <- GET(api_endpoint, 
                    add_headers(Authorization = auth_header, Accept = "application/json"), 
                    query = query_params)
    
    handle_error(response, "Non-domestic Search API")
    
    data <- content(response, as = "parsed")
    all_data <- append(all_data, list(data))
    
    search_after <- headers(response)[["x-next-search-after"]]
    has_more_data <- !is.null(search_after)
    
    # Update total records
    total_records <- total_records + length(data$lmk_key)
  }
  
  # Flatten the list of data frames into one data frame
  all_data_df <- bind_rows(map(all_data, as_tibble), .id = "source")
  
  return(list(data = all_data_df, total_records = total_records))
}

# Function to fetch recommendations for certificates
fetch_recommendations <- function(certificates) {
  recommendations <- list()
  total_recommendations <- 0
  
  pb <- progress_bar$new(
    format = "  Fetching recommendations [:bar] :percent in :elapsed",
    total = nrow(certificates),
    clear = FALSE,
    width = 60
  )
  
  for (lmk_key in certificates$lmk_key) {
    pb$tick()
    rec_url <- paste0(rec_endpoint, "/", lmk_key)
    rec_response <- GET(rec_url, add_headers(Authorization = auth_header, Accept = "application/json"))
    
    if (status_code(rec_response) == 200) {
      rec_data <- content(rec_response, as = "parsed")
      recommendations <- append(recommendations, list(rec_data))
      total_recommendations <- total_recommendations + length(rec_data$lmk_key)
    } else if (status_code(rec_response) == 404) {
      # No recommendations found for LMK key
    } else {
      handle_error(rec_response, paste("Recommendations API for LMK key:", lmk_key))
    }
  }
  
  # Flatten the list of data frames into one data frame
  recommendations_df <- bind_rows(map(recommendations, as_tibble), .id = "source")
  
  cat("\nTotal recommendations fetched:", total_recommendations, "\n")
  
  return(recommendations_df)
}

# Function to fetch and combine data for multiple years
fetch_certificates_for_years <- function(start_year, end_year) {
  all_years_data <- list()
  years <- start_year:end_year
  
  # Initialize progress bar
  pb <- progress_bar$new(
    format = "  Fetching data for [:bar] :percent in :elapsed",
    total = length(years),
    clear = FALSE,
    width = 60
  )
  
  total_records <- 0
  
  for (year in years) {
    pb$tick()
    result <- fetch_certificates_by_year(year)
    year_data <- result$data
    total_records <- total_records + result$total_records
    all_years_data <- append(all_years_data, list(year_data))
  }
  
  combined_data <- bind_rows(all_years_data)
  cat("\nTotal records fetched:", total_records, "\n")
  
  return(combined_data)
}

# Fetch certificates for a range of years (e.g., 2015 to 2023)
start_year <- 2015
end_year <- 2016
all_data <- fetch_certificates_for_years(start_year, end_year)

# Fetch recommendations for the combined certificates data
recommendations <- fetch_recommendations(all_data)

# Save the combined data to CSV files
write.csv(all_data, "non_domestic_certificates_combined.csv", row.names = FALSE)
write.csv(recommendations, "non_domestic_recommendations_combined.csv", row.names = FALSE)
