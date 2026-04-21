# 05_codebook_and_coder_template.R
# Builds a draft codebook, coder instructions, and coder template CSV.

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

source(here::here("scripts", "00_config.R"))

codebook <- tibble::tribble(
  ~code, ~label, ~definition, ~include_if, ~exclude_if, ~example,
  "stigma_binary", "Weight stigma present (1) vs absent (0)",
  "Overall decision for whether the post contains weight-stigmatising content.",
  "Any explicit or implied demeaning, blaming, shaming, stereotyping, or moral judgement about body weight.",
  "Neutral, supportive, or clinical discussion without demeaning language.",
  "'People are overweight because they are lazy.'",

  "explicit_blame", "Explicit blame",
  "Directly attributes higher body weight to personal moral failure or laziness.",
  "Statements that assign fault to individuals for body size.",
  "Structural/contextual discussion without blame.",
  "'No excuses, weight gain is your own fault.'",

  "moralising_food_body", "Moralising food/body language",
  "Frames foods or bodies as morally good/bad, clean/dirty, worthy/unworthy.",
  "Good/bad person framing based on eating or body size.",
  "Practical nutrition advice without moral labels.",
  "'Cheat meals make you weak and disgusting.'",

  "appearance_judgement", "Appearance-focused judgement",
  "Judges personal worth or social value based on body appearance.",
  "Ridicule, disgust, or social devaluation tied to body shape.",
  "Neutral reference to appearance in a non-judgemental context.",
  "'Beach bodies are for disciplined people only.'",

  "stereotyping_larger_bodies", "Stereotyping larger bodies",
  "Uses generalisations about people in larger bodies as a group.",
  "Claims that a group is lazy, undisciplined, unhealthy, etc.",
  "Post-specific behaviour without broad group assumptions.",
  "'Overweight people never care about health.'",

  "healthism_personal_failure", "Healthism / implied personal failure",
  "Implies health status is fully controlled by individual choices and willpower.",
  "Ignores social, medical, economic, or environmental determinants of health.",
  "Balanced discussion of multiple determinants.",
  "'If you are sick, you just didn't try hard enough.'",

  "neutral_supportive", "Neutral/supportive/non-stigmatising",
  "Content that is supportive, neutral, or non-judgemental.",
  "Person-centred, empathetic, non-shaming tone.",
  "Any explicit stigmatizing language.",
  "'Health goals should be tailored and respectful to each person.'"
)

readr::write_csv(codebook, here::here("docs", "codebook", "weight_stigma_codebook.csv"), na = "")

coder_instructions <- c(
  "# Coder Instructions: Weight Stigma in Nutrition-Related Posts",
  "",
  "## Aim",
  "Classify each post for weight stigma using the codebook in this folder.",
  "",
  "## Core principles",
  "1. Code stigma separately from sentiment. A negative tone is not automatically stigma.",
  "2. Use the full post context before assigning codes.",
  "3. Assign stigma_binary = 1 when any stigma category applies.",
  "4. Assign stigma_binary = 0 when no stigma categories apply.",
  "5. Mark neutral_supportive = 1 when language is clearly non-stigmatising.",
  "",
  "## Coding steps",
  "1. Read post text once for context.",
  "2. Decide stigma_binary (1/0).",
  "3. Apply all relevant multi-codes (1 = present, 0 = absent).",
  "4. Add short justification in notes for difficult cases.",
  "",
  "## Independent coding",
  "Each coder should complete their own file without discussing coding decisions until reliability is calculated.",
  "",
  "## File naming",
  "Save your file as docs/codebook/ratings/coder_<initials>.csv"
)

writeLines(coder_instructions, here::here("docs", "codebook", "coder_instructions.md"))

# Build coder template from cleaned data if available.
posts_path <- here::here("data_clean", "posts_clean.csv")

if (file.exists(posts_path)) {
  posts <- readr::read_csv(posts_path, show_col_types = FALSE)
} else {
  posts <- readr::read_csv(here::here("data_clean", "example_cleaned_posts.csv"), show_col_types = FALSE)
}

coder_template <- posts %>%
  transmute(
    post_id,
    platform,
    date = date,
    category,
    text,
    url,
    stigma_binary = NA_integer_,
    explicit_blame = NA_integer_,
    moralising_food_body = NA_integer_,
    appearance_judgement = NA_integer_,
    stereotyping_larger_bodies = NA_integer_,
    healthism_personal_failure = NA_integer_,
    neutral_supportive = NA_integer_,
    notes = NA_character_,
    coder_id = NA_character_
  )

readr::write_csv(coder_template, here::here("docs", "codebook", "coder_template.csv"), na = "")

message("Codebook saved to docs/codebook/weight_stigma_codebook.csv")
message("Coder template saved to docs/codebook/coder_template.csv")
