# 03_frequency_ngrams_tfidf.R
# Word frequency, n-grams, and TF-IDF comparisons by category.

suppressPackageStartupMessages({
  library(tidyverse)
  library(tidytext)
  library(scales)
  library(here)
})

source(here::here("scripts", "00_config.R"))

tokens <- readr::read_csv(here::here("data_clean", "tokens_no_stop.csv"), show_col_types = FALSE)
clean_posts <- readr::read_csv(here::here("data_clean", "posts_clean.csv"), show_col_types = FALSE)

if (nrow(tokens) == 0) {
  stop("Token dataset is empty. Run script 02 after adding data.", call. = FALSE)
}

# Most frequent words overall.
overall_words <- tokens %>% count(word, sort = TRUE)

# Most frequent words by category.
words_by_category <- tokens %>% count(category, word, sort = TRUE)

# Build bigrams and remove stopword-only noise.
stop_words_vec <- tidytext::stop_words$word

bigrams <- clean_posts %>%
  select(post_id, category, text_clean) %>%
  unnest_tokens(bigram, text_clean, token = "ngrams", n = 2) %>%
  separate(bigram, into = c("word1", "word2"), sep = " ", fill = "right", extra = "drop") %>%
  filter(
    !is.na(word1), !is.na(word2),
    !word1 %in% stop_words_vec,
    !word2 %in% stop_words_vec
  ) %>%
  unite(bigram, word1, word2, sep = " ") %>%
  count(category, bigram, sort = TRUE)

trigrams <- clean_posts %>%
  select(post_id, category, text_clean) %>%
  unnest_tokens(trigram, text_clean, token = "ngrams", n = 3) %>%
  separate(trigram, into = c("word1", "word2", "word3"), sep = " ", fill = "right", extra = "drop") %>%
  filter(
    !is.na(word1), !is.na(word2), !is.na(word3),
    !word1 %in% stop_words_vec,
    !word2 %in% stop_words_vec,
    !word3 %in% stop_words_vec
  ) %>%
  unite(trigram, word1, word2, word3, sep = " ") %>%
  count(category, trigram, sort = TRUE)

# TF-IDF to show terms that are distinctive to each category.
tfidf_terms <- tokens %>%
  count(category, word, sort = TRUE) %>%
  bind_tf_idf(term = word, document = category, n = n) %>%
  arrange(desc(tf_idf))

# Save tables.
save_table(overall_words, "top_words_overall.csv")
save_table(words_by_category, "top_words_by_category.csv")
save_table(bigrams, "top_bigrams_by_category.csv")
save_table(trigrams, "top_trigrams_by_category.csv")
save_table(tfidf_terms, "tfidf_by_category.csv")

# Plot: top words overall.
plot_overall <- overall_words %>%
  slice_max(order_by = n, n = 20, with_ties = FALSE) %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(x = n, y = word)) +
  geom_col(fill = "#0D5C63") +
  scale_x_continuous(labels = comma) +
  labs(
    title = "Top 20 Words Overall",
    x = "Frequency",
    y = NULL
  ) +
  theme_minimal(base_size = 12)

# Plot: top words by category.
plot_by_category <- words_by_category %>%
  filter(!is.na(category)) %>%
  group_by(category) %>%
  slice_max(order_by = n, n = 15, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(word = tidytext::reorder_within(word, n, category)) %>%
  ggplot(aes(x = n, y = word, fill = category)) +
  geom_col(show.legend = FALSE) +
  tidytext::scale_y_reordered() +
  facet_wrap(~ category, scales = "free_y") +
  scale_x_continuous(labels = comma) +
  labs(
    title = "Top Words by Category",
    x = "Frequency",
    y = NULL
  ) +
  theme_minimal(base_size = 12)

# Plot: top TF-IDF terms by category.
plot_tfidf <- tfidf_terms %>%
  filter(!is.na(category)) %>%
  group_by(category) %>%
  slice_max(order_by = tf_idf, n = 15, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(word = tidytext::reorder_within(word, tf_idf, category)) %>%
  ggplot(aes(x = tf_idf, y = word, fill = category)) +
  geom_col(show.legend = FALSE) +
  tidytext::scale_y_reordered() +
  facet_wrap(~ category, scales = "free_y") +
  labs(
    title = "Most Distinctive Terms by Category (TF-IDF)",
    x = "TF-IDF",
    y = NULL
  ) +
  theme_minimal(base_size = 12)

# Save figures.
save_plot(plot_overall, "word_frequency_overall.png")
save_plot(plot_by_category, "word_frequency_by_category.png")
save_plot(plot_tfidf, "tfidf_by_category.png")

message("Frequency, n-gram, and TF-IDF outputs saved.")
