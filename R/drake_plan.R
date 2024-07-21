# R/drake_plan.R

library(drake)
library(tidyverse)
library(rmarkdown)
source("R/non_domestic_certificates_with_logging.R")

# Define the drake plan
plan <- drake_plan(
  # Fetch certificates
  certificates = fetch_certificates(),
  
  # Fetch recommendations
  recommendations = fetch_recommendations(certificates),
  
  # Save certificates to CSV
  save_certificates = write.csv(certificates, "non_domestic_certificates.csv", row.names = FALSE),
  
  # Save recommendations to CSV
  save_recommendations = write.csv(recommendations, "non_domestic_recommendations.csv", row.names = FALSE),
  
  # Generate summary report
  generate_report = rmarkdown::render(
    knitr_in("reports/data_summary.Rmd"),
    output_file = file_out("reports/data_summary.html"),
    quiet = TRUE
  ),
  
  # Log completion
  log_completion = log_info("Data fetching, saving, and reporting completed successfully.")
)

# Execute the drake plan
make(plan)
