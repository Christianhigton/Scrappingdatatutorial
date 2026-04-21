# 07_statistics_and_visuals.R
# Descriptive and inferential comparisons of stigma by category.

suppressPackageStartupMessages({
  library(tidyverse)
  library(effectsize)
  library(scales)
  library(here)
})

source(here::here("scripts", "00_config.R"))

posts <- readr::read_csv(here::here("data_clean", "posts_clean.csv"), show_col_types = FALSE)

adjudicated_path <- here::here("docs", "codebook", "adjudicated_codes.csv")

if (!file.exists(adjudicated_path)) {
  stop(
    "Missing docs/codebook/adjudicated_codes.csv. Create an adjudicated file with at least post_id and stigma_binary.",
    call. = FALSE
  )
}

codes <- readr::read_csv(adjudicated_path, show_col_types = FALSE)

required_code_cols <- c("post_id", "stigma_binary")
missing_code_cols <- setdiff(required_code_cols, names(codes))
if (length(missing_code_cols) > 0) {
  stop(
    "Adjudicated file must include post_id and stigma_binary. Missing: ",
    paste(missing_code_cols, collapse = ", "),
    call. = FALSE
  )
}

analysis_df <- posts %>%
  select(post_id, category) %>%
  left_join(codes, by = "post_id") %>%
  mutate(
    category = normalise_category(category),
    stigma_binary = as.integer(stigma_binary)
  ) %>%
  filter(!is.na(category), !is.na(stigma_binary))

# Descriptive prevalence table.
prevalence <- analysis_df %>%
  count(category, stigma_binary, name = "n") %>%
  group_by(category) %>%
  mutate(percent = 100 * n / sum(n)) %>%
  ungroup() %>%
  mutate(stigma_binary = factor(stigma_binary, levels = c(0, 1), labels = c("Absent", "Present")))

save_table(prevalence, "stigma_prevalence_by_category.csv")

# Chi-square test.
contingency <- table(analysis_df$category, analysis_df$stigma_binary)
chi <- chisq.test(contingency, correct = FALSE)

effect <- effectsize::cramers_v(contingency)

chi_results <- tibble(
  test = "Chi-square test of stigma presence by category",
  statistic = unname(chi$statistic),
  df = unname(chi$parameter),
  p_value = chi$p.value,
  cramers_v = unname(effect$Cramers_v),
  interpretation = case_when(
    effect$Cramers_v < 0.10 ~ "Very small",
    effect$Cramers_v < 0.30 ~ "Small",
    effect$Cramers_v < 0.50 ~ "Medium",
    TRUE ~ "Large"
  )
)

save_table(chi_results, "stigma_chi_square_results.csv")

# Plot prevalence.
plot_prevalence <- prevalence %>%
  ggplot(aes(x = category, y = percent, fill = stigma_binary)) +
  geom_col(position = "stack") +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  scale_fill_manual(values = c("Absent" = "#6C757D", "Present" = "#B23A48")) +
  labs(
    title = "Weight Stigma Prevalence by Category",
    x = NULL,
    y = "Percent of posts",
    fill = "Stigma"
  ) +
  theme_minimal(base_size = 12)

save_plot(plot_prevalence, "stigma_prevalence_by_category.png")

# Optional multi-code distribution plot (if columns exist).
multi_code_cols <- c(
  "explicit_blame",
  "moralising_food_body",
  "appearance_judgement",
  "stereotyping_larger_bodies",
  "healthism_personal_failure",
  "neutral_supportive"
)

available_multi_codes <- intersect(multi_code_cols, names(codes))

if (length(available_multi_codes) > 0) {
  multi_long <- analysis_df %>%
    pivot_longer(cols = all_of(available_multi_codes), names_to = "code", values_to = "present") %>%
    mutate(present = as.integer(present)) %>%
    filter(!is.na(present), present == 1) %>%
    count(category, code, name = "n")

  save_table(multi_long, "stigma_multicode_counts.csv")

  plot_multicode <- multi_long %>%
    ggplot(aes(x = n, y = reorder(code, n), fill = category)) +
    geom_col(position = "dodge") +
    labs(
      title = "Frequency of Stigma Subtypes by Category",
      x = "Count",
      y = NULL,
      fill = "Category"
    ) +
    theme_minimal(base_size = 12)

  save_plot(plot_multicode, "stigma_multicode_by_category.png")
}

message("Statistical outputs saved to outputs/tables and outputs/figures.")
