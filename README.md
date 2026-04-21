# Weight Stigma Social Media Project (R + Positron)

## Run order

1. `source("scripts/01_setup_packages.R")`
2. `source("scripts/02_import_clean_tokenise.R")`
3. `source("scripts/03_frequency_ngrams_tfidf.R")`
4. `source("scripts/04_sentiment_analysis.R")`
5. `source("scripts/05_codebook_and_coder_template.R")`
6. Place coder files in `docs/codebook/ratings/`
7. `source("scripts/06_interrater_reliability.R")`
8. Create `docs/codebook/adjudicated_codes.csv`
9. `source("scripts/07_statistics_and_visuals.R")`

## Data input

Put your raw CSV files in `data_raw/`.

Required columns:

- `post_id`
- `platform`
- `date`
- `author`
- `text`
- `url`
- `category` (`weight_loss` or `health_focused`)

## Outputs

- Figures: `outputs/figures/`
- Tables: `outputs/tables/`
- Codebook assets: `docs/codebook/`
- Quarto tutorial: `report/qmd_tutorial_weight_stigma_project.qmd`

## GitHub Pages (No Actions)

This repo is configured for branch-based Pages deployment (not GitHub Actions):

1. In GitHub, open `Settings -> Pages`.
2. Set `Source` to `Deploy from a branch`.
3. Choose branch `main` and folder `/ (root)`.
4. Save.

The live page is served from:

- `index.html`
- `qmd_tutorial_weight_stigma_project_files/` (page assets)
