# non_domestic_certificates.R

# Load necessary libraries
library(httr)
library(jsonlite)
library(dplyr)

# Define the API endpoint and authentication
base_url <- "https://epc.opendatacommunities.org/api/v1"
api_endpoint <- paste0(base_url, "/non-domestic/search")
cert_endpoint <- paste0(base_url, "/non-domestic/certificate")
rec_endpoint <- paste0(base_url, "/non-domestic/recommendations")
api_key <- "<your_api_key>"
auth_header <- paste("Basic", base64_enc(paste("<your_email>", api_key, sep=":")))

# Initialize an empty dataframe to store results
all_data <- data.frame()

# Set initial pagination parameters
size <- 1000
search_after <- NULL
has_more_data <- TRUE

# Loop through pages
while (has_more_data) {
  # Create query parameters
  query_params <- list(size = size)
  if (!is.null(search_after)) {
    query_params$`search-after` <- search_after
  }
  
  # Make the API request
  response <- GET(api_endpoint, add_headers(Authorization = auth_header), query = query_params)
  
  # Check if the request was successful
  if (status_code(response) != 200) {
    stop("API request failed with status: ", status_code(response))
  }
  
  # Parse the response
  data <- content(response, as = "text", encoding = "UTF-8")
  data_df <- fromJSON(data)
  
  # Append to the all_data dataframe
  all_data <- bind_rows(all_data, data_df)
  
  # Check if there are more pages
  search_after <- headers(response)[["x-next-search-after"]]
  has_more_data <- !is.null(search_after)
}

# Fetch recommendations for each certificate
recommendations <- data.frame()
for (lmk_key in all_data$lmk_key) {
  rec_url <- paste0(rec_endpoint, "/", lmk_key)
  rec_response <- GET(rec_url, add_headers(Authorization = auth_header))
  
  if (status_code(rec_response) == 200) {
    rec_data <- content(rec_response, as = "text", encoding = "UTF-8")
    rec_df <- fromJSON(rec_data)
    recommendations <- bind_rows(recommendations, rec_df)
  }
}

# Save the combined data to CSV files
write.csv(all_data, "non_domestic_certificates.csv", row.names = FALSE)
write.csv(recommendations, "non_domestic_recommendations.csv", row.names = FALSE)
