# 04_sentiment_analysis.R
# Lexicon-based sentiment analysis as a complementary (not primary) analysis.

suppressPackageStartupMessages({
  library(tidyverse)
  library(tidytext)
  library(scales)
  library(here)
})

source(here::here("scripts", "00_config.R"))

tokens <- readr::read_csv(here::here("data_clean", "tokens_no_stop.csv"), show_col_types = FALSE)

if (nrow(tokens) == 0) {
  stop("Token dataset is empty. Run script 02 first.", call. = FALSE)
}

# Important conceptual note:
# Sentiment is not equivalent to weight stigma.
# Use these outputs as exploratory context only.

# BING: positive/negative labels.
bing_sent <- tokens %>%
  inner_join(get_sentiments("bing"), by = "word")

overall_bing <- bing_sent %>%
  count(sentiment, sort = TRUE) %>%
  mutate(prop = n / sum(n))

by_category_bing <- bing_sent %>%
  filter(!is.na(category)) %>%
  count(category, sentiment, sort = TRUE) %>%
  group_by(category) %>%
  mutate(prop = n / sum(n)) %>%
  ungroup()

# NRC: emotion categories plus positive/negative.
# If the NRC resource is unavailable, continue with BING + AFINN and log a warning.
nrc_lexicon <- tryCatch(
  get_sentiments("nrc"),
  error = function(e) {
    warning("NRC lexicon unavailable. Skipping NRC emotion outputs. Details: ", e$message)
    NULL
  }
)

if (!is.null(nrc_lexicon)) {
  nrc_sent <- tokens %>%
    inner_join(nrc_lexicon, by = "word")

  nrc_emotions <- nrc_sent %>%
    filter(!sentiment %in% c("positive", "negative"), !is.na(category)) %>%
    count(category, sentiment, sort = TRUE)
} else {
  nrc_emotions <- tibble(
    category = character(),
    sentiment = character(),
    n = integer()
  )
}

# AFINN: numeric valence scores.
afinn_lexicon <- tryCatch(
  get_sentiments("afinn"),
  error = function(e) {
    warning("AFINN lexicon unavailable. Skipping AFINN outputs. Details: ", e$message)
    NULL
  }
)

if (!is.null(afinn_lexicon)) {
  afinn_scores <- tokens %>%
    inner_join(afinn_lexicon, by = "word") %>%
    group_by(post_id, category) %>%
    summarise(
      afinn_mean = mean(value, na.rm = TRUE),
      afinn_sum = sum(value, na.rm = TRUE),
      matched_tokens = dplyr::n(),
      .groups = "drop"
    )

  afinn_summary <- afinn_scores %>%
    filter(!is.na(category)) %>%
    group_by(category) %>%
    summarise(
      mean_afinn = mean(afinn_mean, na.rm = TRUE),
      median_afinn = median(afinn_mean, na.rm = TRUE),
      sd_afinn = sd(afinn_mean, na.rm = TRUE),
      posts_with_scores = dplyr::n(),
      .groups = "drop"
    )
} else {
  afinn_scores <- tibble(
    post_id = character(),
    category = character(),
    afinn_mean = numeric(),
    afinn_sum = numeric(),
    matched_tokens = integer()
  )
  afinn_summary <- tibble(
    category = character(),
    mean_afinn = numeric(),
    median_afinn = numeric(),
    sd_afinn = numeric(),
    posts_with_scores = integer()
  )
}

# Save tables.
save_table(overall_bing, "sentiment_overall_bing.csv")
save_table(by_category_bing, "sentiment_by_category_bing.csv")
save_table(nrc_emotions, "sentiment_nrc_emotions_by_category.csv")
save_table(afinn_scores, "sentiment_afinn_post_scores.csv")
save_table(afinn_summary, "sentiment_afinn_summary_by_category.csv")

# Plot: BING sentiment proportions by category.
plot_bing <- by_category_bing %>%
  ggplot(aes(x = category, y = prop, fill = sentiment)) +
  geom_col(position = "stack") +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = c(negative = "#B23A48", positive = "#2A9D8F")) +
  labs(
    title = "Sentiment Composition by Category (BING)",
    x = NULL,
    y = "Proportion of matched sentiment words",
    fill = "Sentiment"
  ) +
  theme_minimal(base_size = 12)

if (nrow(nrc_emotions) > 0) {
  # Plot: NRC emotions by category.
  plot_nrc <- nrc_emotions %>%
    group_by(category) %>%
    slice_max(order_by = n, n = 8, with_ties = FALSE) %>%
    ungroup() %>%
    mutate(sentiment = tidytext::reorder_within(sentiment, n, category)) %>%
    ggplot(aes(x = n, y = sentiment, fill = category)) +
    geom_col(show.legend = FALSE) +
    tidytext::scale_y_reordered() +
    facet_wrap(~ category, scales = "free_y") +
    scale_x_continuous(labels = comma) +
    labs(
      title = "Top NRC Emotion Terms by Category",
      x = "Count",
      y = NULL
    ) +
    theme_minimal(base_size = 12)
}

if (nrow(afinn_scores) > 0) {
  # Plot: AFINN distribution by category.
  plot_afinn <- afinn_scores %>%
    filter(!is.na(category)) %>%
    ggplot(aes(x = category, y = afinn_mean, fill = category)) +
    geom_boxplot(alpha = 0.8, width = 0.55, show.legend = FALSE) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey30") +
    labs(
      title = "Distribution of AFINN Scores by Category",
      x = NULL,
      y = "Mean AFINN score per post"
    ) +
    theme_minimal(base_size = 12)
}

# Save figures.
save_plot(plot_bing, "sentiment_bing_by_category.png")
if (nrow(nrc_emotions) > 0) {
  save_plot(plot_nrc, "sentiment_nrc_by_category.png")
}
if (nrow(afinn_scores) > 0) {
  save_plot(plot_afinn, "sentiment_afinn_by_category.png")
}

message("Sentiment tables and figures saved.")
