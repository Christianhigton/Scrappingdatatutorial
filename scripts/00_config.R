# Shared configuration and helper utilities.
# Run scripts from project root so here::here() resolves correctly.

suppressPackageStartupMessages({
  library(here)
  library(readr)
  library(dplyr)
  library(stringr)
  library(ggplot2)
})

project_paths <- list(
  raw = here::here("data_raw"),
  clean = here::here("data_clean"),
  outputs = here::here("outputs"),
  figures = here::here("outputs", "figures"),
  tables = here::here("outputs", "tables"),
  codebook = here::here("docs", "codebook"),
  ratings = here::here("docs", "codebook", "ratings"),
  report = here::here("report")
)

invisible(lapply(project_paths, dir.create, recursive = TRUE, showWarnings = FALSE))

required_columns <- c(
  "post_id", "platform", "date", "author", "text", "url", "category"
)

check_required_columns <- function(df, required = required_columns) {
  missing_cols <- setdiff(required, names(df))
  if (length(missing_cols) > 0) {
    stop(
      "Missing required columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }
}

normalise_category <- function(x) {
  x <- stringr::str_to_lower(x)
  x <- stringr::str_replace_all(x, "[-\\s]+", "_")
  x
}

save_table <- function(df, file_name) {
  readr::write_csv(df, here::here("outputs", "tables", file_name), na = "")
}

save_plot <- function(plot_obj, file_name, width = 10, height = 6, dpi = 320) {
  ggplot2::ggsave(
    filename = here::here("outputs", "figures", file_name),
    plot = plot_obj,
    width = width,
    height = height,
    dpi = dpi,
    bg = "white"
  )
}

interpret_kappa <- function(kappa_value) {
  dplyr::case_when(
    is.na(kappa_value) ~ "Not available",
    kappa_value < 0.00 ~ "Less than chance agreement",
    kappa_value < 0.21 ~ "Slight agreement",
    kappa_value < 0.41 ~ "Fair agreement",
    kappa_value < 0.61 ~ "Moderate agreement",
    kappa_value < 0.81 ~ "Substantial agreement",
    TRUE ~ "Almost perfect agreement"
  )
}
