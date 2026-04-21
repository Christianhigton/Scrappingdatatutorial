# 01_setup_packages.R
# Installs and loads required packages, then ensures project folders exist.

required_packages <- c(
  "tidyverse",
  "tidytext",
  "textdata",
  "janitor",
  "lubridate",
  "stringi",
  "SnowballC",
  "here",
  "irr",
  "effectsize",
  "scales",
  "patchwork"
)

missing_packages <- required_packages[!vapply(required_packages, requireNamespace, FUN.VALUE = logical(1), quietly = TRUE)]

if (length(missing_packages) > 0) {
  install.packages(missing_packages, repos = "https://cloud.r-project.org")
}

invisible(lapply(required_packages, library, character.only = TRUE))

source(here::here("scripts", "00_config.R"))

message("Setup complete.")
message("Place raw CSV files in: ", here::here("data_raw"))
message("Outputs will be saved to: ", here::here("outputs"))
