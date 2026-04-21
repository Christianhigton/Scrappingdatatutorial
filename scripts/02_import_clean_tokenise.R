# 02_import_clean_tokenise.R
# Imports raw CSV files, cleans text, and creates tokenised datasets.

suppressPackageStartupMessages({
  library(tidyverse)
  library(tidytext)
  library(janitor)
  library(lubridate)
  library(stringi)
  library(SnowballC)
  library(here)
})

source(here::here("scripts", "00_config.R"))

raw_files <- list.files(project_paths$raw, pattern = "\\.csv$", full.names = TRUE)

if (length(raw_files) == 0) {
  stop("No CSV files found in data_raw/. Add at least one CSV and rerun script 02.", call. = FALSE)
}

raw_posts <- purrr::map_dfr(
  raw_files,
  ~ readr::read_csv(.x, show_col_types = FALSE) %>%
    mutate(source_file = basename(.x))
)

raw_posts <- janitor::clean_names(raw_posts)
check_required_columns(raw_posts)

allowed_categories <- c("weight_loss", "health_focused")

do_stemming <- FALSE

clean_posts <- raw_posts %>%
  mutate(
    category = normalise_category(category),
    category = if_else(category %in% allowed_categories, category, NA_character_),
    date_parsed = suppressWarnings(
      parse_date_time(
        as.character(date),
        orders = c(
          "Ymd HMS", "Ymd HM", "Ymd", "dmy HMS", "dmy HM", "dmy",
          "mdy HMS", "mdy HM", "mdy", "Y-m-d", "Y/m/d"
        ),
        tz = "UTC"
      )
    ),
    text_original = text,
    text_no_url = str_remove_all(text_original, "https?://\\S+|www\\.\\S+"),
    text_no_emoji = stringi::stri_replace_all_regex(text_no_url, "[\\p{So}\\p{Cn}]", " "),
    text_no_punct = str_replace_all(text_no_emoji, "[[:punct:]]+", " "),
    text_no_num = str_replace_all(text_no_punct, "[[:digit:]]+", " "),
    text_clean = text_no_num %>% str_to_lower() %>% str_squish()
  ) %>%
  filter(!is.na(text_clean), text_clean != "")

if (any(is.na(clean_posts$category))) {
  warning("Some rows have categories outside {weight_loss, health_focused}. They are kept with NA category.")
}

readr::write_csv(clean_posts, here::here("data_clean", "posts_clean.csv"), na = "")
saveRDS(clean_posts, here::here("data_clean", "posts_clean.rds"))

tokens <- clean_posts %>%
  select(post_id, category, date_parsed, text_clean) %>%
  unnest_tokens(word, text_clean) %>%
  filter(str_detect(word, "^[a-z']+$")) %>%
  anti_join(stop_words, by = "word")

if (do_stemming) {
  tokens <- tokens %>% mutate(word = SnowballC::wordStem(word))
}

readr::write_csv(tokens, here::here("data_clean", "tokens_no_stop.csv"), na = "")

message("Saved cleaned posts to data_clean/posts_clean.csv")
message("Saved token dataset to data_clean/tokens_no_stop.csv")
