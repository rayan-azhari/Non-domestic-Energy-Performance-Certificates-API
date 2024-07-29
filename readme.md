---
title: "Readme"
author: "Rayan Azhari"
date: "2024-07-26"
output: html_document
---

# Non domestic EPC Certificates Fetcher API

This R script fetches Energy Performance Certificate (EPC) data from the [Open Data Communities EPC API](https://epc.opendatacommunities.org/) and retrieves recommendations associated with each certificate. The script supports fetching all EPC certificates within a specified date range using pagination.

## Features

-   **Fetch EPC Certificates**: Retrieves EPC certificates based on the specified date range using the Open Data Communities EPC API.

-   **Pagination Handling**: Implements pagination to fetch all certificates beyond the default page size limit.

-   **Fetch Recommendations**: Retrieves recommendations for each EPC certificate.

-   **Timing Measurement**: Measures and prints the time taken to fetch all EPC certificates.

-   **Configuration Management**: Uses a `config.json` file to securely manage API credentials.

## Prerequisites

-   R installed on your system.

-   The following R packages installed:

    -   `httr`

    -   `jsonlite`

    -   `data.table`

## Setup

1.  **Clone the Repository**:

    ```{sh}
    git clone https://github.com/yourusername/epc-certificates-fetcher.git
    cd epc-certificates-fetcher

    ```

2.  **Install Required Packages**:

    ```{r}
    install.packages(c("httr", "jsonlite", "data.table", "tidyverse"))

    ```

3.  **Create a `config.json` File**:

    -   Create a file named `config.json` in the root directory of the project with the following content:

        ```{jason}
        {
          "email": "your-email@example.com",
          "api_key": "your-api-key"
        }

        ```

    -   Ensure `config.json` is added to `.gitignore` to keep your credentials secure.

4.  **Run the Script**:

    -   Open your R environment (RStudio or other).

    -   Source and run the script.

## Usage

The script performs the following steps:

1.  **Load Required Libraries**: Loads the necessary libraries (`httr`, `jsonlite`, and `data.table`).

2.  **Read Configuration**: Reads the `config.json` file to obtain the email and API key for authentication.

3.  **Generate Authentication Token**: Creates a Base64-encoded authentication token using the email and API key.

4.  **Fetch EPC Certificates**:

    -   Uses the `fetch_all_epc_certificates` function to retrieve all EPC certificates within the specified date range.

    -   Handles pagination using the `search-after` parameter.

    -   Measures and prints the time taken to fetch the certificates.

5.  **Fetch Recommendations**:

    -   Uses the `fetch_recommendations` function to fetch recommendations for each certificate.

    -   Prints the fetched certificates along with their recommendations.

## Example

Here's an example of how to use the script:

```{r}
# Set date range for fetching EPC certificates
from_year <- 2023
from_month <- 1
to_year <- 2023
to_month <- 12

# Fetch all EPC certificates and measure time
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

```

## Contributing

Feel free to open issues or submit pull requests if you have any improvements or bug fixes.

## License

This project is licensed under the MIT License.

This README provides a comprehensive overview of what the script does, how to set it up, and how to use it, making it easy for others to understand and get started with the project.
