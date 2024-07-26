# non_domestic_certificates_test.R

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

# Function to create an empty template data frame with all possible columns
create_template <- function(columns) {
  df <- as.data.frame(matrix(ncol = length(columns), nrow = 0))
  colnames(df) <- columns
  return(df)
}

# Function to standardize columns and data types
standardize_columns <- function(df, template) {
  for (col in names(template)) {
    if (!col %in% names(df)) {
      df[[col]] <- NA
    } else {
      df[[col]] <- as.character(df[[col]])
    }
  }
  df <- df %>% select(names(template))
  return(df)
}

# Function to fetch a small sample of non-domestic certificates
fetch_sample_certificates <- function(size = 10) {
  query_params <- list(size = size)
  
  response <- GET(api_endpoint, 
                  add_headers(Authorization = auth_header, Accept = "application/json"), 
                  query = query_params)
  
  handle_error(response, "Non-domestic Search API")
  
  data <- content(response, as = "parsed", simplifyVector = TRUE)
  
  # Convert to a list of data frames for each record
  records <- lapply(data, as_tibble)
  
  # Determine the union of all columns
  all_columns <- unique(unlist(lapply(records, names)))
  
  # Create a template data frame
  template <- create_template(all_columns)
  
  # Standardize all records to have the same columns and data types
  standardized_records <- lapply(records, standardize_columns, template)
  
  # Combine all standardized records into a single data frame
  all_data_df <- bind_rows(standardized_records)
  
  # Debugging: Print the structure of the data
  print(str(all_data_df))
  
  return(all_data_df)
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
      rec_data <- content(rec_response, as = "parsed", simplifyVector = TRUE)
      rec_data <- as_tibble(rec_data)
      
      # Ensure that rec_data has the same columns as certificates
      rec_data <- standardize_columns(rec_data, create_template(names(certificates)))
      recommendations <- append(recommendations, list(rec_data))
      total_recommendations <- total_recommendations + nrow(rec_data)
    } else if (status_code(rec_response) == 404) {
      # No recommendations found for LMK key
    } else {
      handle_error(rec_response, paste("Recommendations API for LMK key:", lmk_key))
    }
  }
  
  # Flatten the list of data frames into one data frame
  if (length(recommendations) > 0) {
    all_columns <- unique(unlist(lapply(recommendations, names)))
    template <- create_template(all_columns)
    recommendations_df <- bind_rows(lapply(recommendations, standardize_columns, template))
  } else {
    recommendations_df <- create_template(names(certificates))
  }
  
  cat("\nTotal recommendations fetched:", total_recommendations, "\n")
  
  return(recommendations_df)
}

# Fetch a sample of certificates (2 for testing)
sample_certificates <- fetch_sample_certificates(size = 2)

# Rename 'lmk-key' to 'lmk_key'
sample_certificates <- sample_certificates %>%
  rename(lmk_key = `lmk-key`)

# Create a template for standardizing columns
template <- create_template(names(sample_certificates))

# Standardize columns of sample certificates
sample_certificates <- standardize_columns(sample_certificates, template)

# Fetch recommendations for the sample certificates
sample_recommendations <- fetch_recommendations(sample_certificates)

# Standardize columns of recommendations
sample_recommendations <- standardize_columns(sample_recommendations, template)

# Save the sample data to CSV files
write.csv(sample_certificates, "sample_non_domestic_certificates.csv", row.names = FALSE)
write.csv(sample_recommendations, "sample_non_domestic_recommendations.csv", row.names = FALSE)

cat("Sample data fetching complete.\n")
