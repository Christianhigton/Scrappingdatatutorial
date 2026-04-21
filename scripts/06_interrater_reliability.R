# 06_interrater_reliability.R
# Calculates inter-rater reliability and exports disagreement cases.

suppressPackageStartupMessages({
  library(tidyverse)
  library(janitor)
  library(irr)
  library(here)
})

source(here::here("scripts", "00_config.R"))

rating_files <- list.files(project_paths$ratings, pattern = "\\.csv$", full.names = TRUE)

if (length(rating_files) == 0) {
  stop(
    "No coder rating files found in docs/codebook/ratings/. Add coder CSV files and rerun.",
    call. = FALSE
  )
}

ratings_long <- purrr::map_dfr(
  rating_files,
  ~ readr::read_csv(.x, show_col_types = FALSE) %>%
    janitor::clean_names() %>%
    mutate(source_file = basename(.x))
)

required_rating_cols <- c("post_id", "stigma_binary")
missing_rating_cols <- setdiff(required_rating_cols, names(ratings_long))
if (length(missing_rating_cols) > 0) {
  stop(
    "Rating files must include columns: post_id, stigma_binary. Missing: ",
    paste(missing_rating_cols, collapse = ", "),
    call. = FALSE
  )
}

if (!"coder_id" %in% names(ratings_long)) {
  ratings_long <- ratings_long %>%
    mutate(coder_id = stringr::str_remove(source_file, "\\.csv$"))
}

ratings_long <- ratings_long %>%
  mutate(stigma_binary = as.character(stigma_binary)) %>%
  filter(!is.na(post_id), !is.na(coder_id), !is.na(stigma_binary)) %>%
  distinct(post_id, coder_id, .keep_all = TRUE)

ratings_wide <- ratings_long %>%
  select(post_id, coder_id, stigma_binary) %>%
  pivot_wider(names_from = coder_id, values_from = stigma_binary)

coder_cols <- setdiff(names(ratings_wide), "post_id")

if (length(coder_cols) < 2) {
  stop("At least two coders are required for reliability analysis.", call. = FALSE)
}

results <- list()

# Cohen's kappa for the first two coders.
cohen_data <- ratings_wide %>%
  select(all_of(coder_cols[1:2])) %>%
  drop_na() %>%
  mutate(across(everything(), as.factor))

if (nrow(cohen_data) > 0) {
  cohen <- irr::kappa2(cohen_data, weight = "unweighted")
  cohen_kappa <- unname(cohen$value)
  results$cohen <- tibble(
    metric = "Cohen's kappa",
    raters = paste(coder_cols[1], coder_cols[2], sep = " vs "),
    value = cohen_kappa,
    interpretation = interpret_kappa(cohen_kappa)
  )

  confusion <- table(
    rater_1 = cohen_data[[1]],
    rater_2 = cohen_data[[2]]
  )

  confusion_df <- as.data.frame(confusion) %>%
    rename(count = Freq)

  save_table(confusion_df, "reliability_confusion_matrix.csv")

  confusion_plot <- confusion_df %>%
    ggplot(aes(x = rater_1, y = rater_2, fill = count)) +
    geom_tile() +
    geom_text(aes(label = count), color = "white", fontface = "bold") +
    scale_fill_gradient(low = "#4A6FA5", high = "#1B1B3A") +
    labs(
      title = "Confusion Matrix: First Two Coders",
      x = coder_cols[1],
      y = coder_cols[2],
      fill = "Count"
    ) +
    theme_minimal(base_size = 12)

  save_plot(confusion_plot, "reliability_confusion_matrix.png", width = 7, height = 6)
} else {
  warning("No overlapping non-missing rows for the first two coders. Cohen's kappa not computed.")
}

# Fleiss' kappa when >2 coders.
if (length(coder_cols) > 2) {
  fleiss_data <- ratings_wide %>%
    select(all_of(coder_cols)) %>%
    drop_na() %>%
    mutate(across(everything(), as.factor))

  if (nrow(fleiss_data) > 0) {
    fleiss <- irr::kappam.fleiss(as.matrix(fleiss_data))
    fleiss_kappa <- unname(fleiss$value)
    results$fleiss <- tibble(
      metric = "Fleiss' kappa",
      raters = paste(length(coder_cols), "coders"),
      value = fleiss_kappa,
      interpretation = interpret_kappa(fleiss_kappa)
    )
  } else {
    warning("No complete rows across all coders. Fleiss' kappa not computed.")
  }
}

# Export disagreement cases for adjudication.
disagreements <- ratings_wide %>%
  rowwise() %>%
  mutate(disagree = dplyr::n_distinct(stats::na.omit(c_across(all_of(coder_cols)))) > 1) %>%
  ungroup() %>%
  filter(disagree)

posts_path <- here::here("data_clean", "posts_clean.csv")
if (file.exists(posts_path)) {
  posts <- readr::read_csv(posts_path, show_col_types = FALSE) %>%
    select(post_id, category, text, url)
  disagreements <- disagreements %>% left_join(posts, by = "post_id")
}

save_table(disagreements, "reliability_disagreements_for_adjudication.csv")

if (length(results) > 0) {
  reliability_summary <- bind_rows(results)
  save_table(reliability_summary, "reliability_summary.csv")
  print(reliability_summary)
} else {
  warning("No kappa values were computed from the provided data.")
}

message("Reliability outputs saved to outputs/tables and outputs/figures.")
